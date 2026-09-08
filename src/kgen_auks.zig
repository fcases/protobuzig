/// kgen_auks.zig
///
const std = @import("std");
const equal = std.mem.eql;
const prs = @import("mecha_prs.zig");
const tpj = prs.Tipoj;

// ============================================================================
// L2 (2026-09-07): arena de generacion en vez de page_allocator disperso.
//
// Antes cada helper reservaba strings con page_allocator (mmap por string) y
// la mayoria nunca se liberaba: fugas invisibles en el CLI (el proceso sale)
// pero reales si el generador se reutiliza en proceso, y lentas (syscall por
// asignacion). Ahora shpa apunta al allocator de un ArenaAllocator: reservar
// es un bump (rapido) y arenoFini() libera TODO de golpe al terminar la
// generacion (cero fugas). Los free sueltos de temporales ya no hacen falta
// (el arena los libera al final; un free no-cola es no-op).
// ============================================================================
var areno_buf: std.heap.ArenaAllocator = undefined;

/// shpa: allocator de los temporales de generacion (arena). Mutable para
/// poder apuntarlo al arena en arenoInici().
pub var shpa: std.mem.Allocator = std.heap.page_allocator;

/// Inicia el arena de generacion y apunta shpa a el.
pub fn arenoInici() void {
    areno_buf = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    shpa = areno_buf.allocator();
}

/// Libera TODO lo reservado en el arena y restaura shpa.
pub fn arenoFini() void {
    areno_buf.deinit();
    shpa = std.heap.page_allocator;
}

/// Rebobina el arena (retain_capacity: reutiliza los buffers, casi cero
/// llamadas al allocator tras el primer ciclo). Solo cuando nada del arena
/// siga referenciado (p. ej. entre la generacion raw y la API).
pub fn arenoReset() void {
    _ = areno_buf.reset(.retain_capacity);
}

/////////////////////////////////////
/// Auksiliaraj Funkcioj
/////////////////////////////////////
///
pub fn skribiFieldInit(verkisto: *std.Io.Writer, field: prs.Field) !void {
    if (field.label_enum == .LABEL_REPEATED) {
        try verkisto.print("try allocator.alloc({s}, 0),\n", .{mapiProtoTiponAlZig(field.field_type)});
    } else if (field.label_enum == .LABEL_OPTIONAL) {
        if (field.default_value != null) {
            if (field.field_type_enum == .TYPE_ENUM)
                try skribiEnumValue(verkisto, field)
            else
                try verkisto.print("{s},\n", .{field.default_value.?});
        } else try verkisto.print("{s}", .{"null,\n"});
    } else {
        if (field.default_value != null) {
            if (field.field_type_enum == .TYPE_ENUM)
                try skribiEnumValue(verkisto, field)
            else
                try verkisto.print("{s},\n", .{field.default_value.?});
        } else {
            return switch (field.field_type_enum) {
                .TYPE_INT32, .TYPE_UINT32, .TYPE_INT64, .TYPE_UINT64 => try verkisto.print("0,\n", .{}),
                .TYPE_BOOL => try verkisto.print("false,\n", .{}),
                .TYPE_STRING => try verkisto.print("\"\", \n", .{}),
                .TYPE_MESSAGE => try verkisto.print("{s}.initDefault(allocator),\n", .{field.field_type}),
                // .TYPE_ENUM => try skribiEnumValue(field),
                else => try verkisto.print("undefined, \n", .{}),
            };
        }
    }
    return;
}

fn skribiEnumValue(verkisto: *std.Io.Writer, field: prs.Field) !void {
    var default_value_string: []const u8 = field.default_value orelse "null";

    default_value_string = std.mem.concatWithSentinel(shpa, u8, &[_][]const u8{ ".", default_value_string }, 0) catch unreachable;
    try verkisto.print("{s},\n", .{default_value_string});
}

pub fn mapiZigType(protoType: []const u8, label: []const u8, default_value: ?[]const u8) []const u8 {
    const baseType: []const u8 = mapiProtoTiponAlZig(protoType);

    const bRep = equal(u8, label, "repeated");
    const bOpt = equal(u8, label, "optional");
    const bIsNull = if (default_value == null and bOpt) true else false;

    const rep = if (bRep) "[]" else "";
    const opt = if (bOpt) "?" else "";
    const nul = if (bIsNull) " = null" else "";
    const dfv = default_value orelse "";

    var finalBaseTypo: []u8 = undefined;
    if (default_value != null) {
        finalBaseTypo = std.fmt.allocPrint(shpa, "{s}{s}{s} = {s} ", .{ opt, rep, baseType, dfv }) catch unreachable;
    } else if (bRep) {
        // repeated sin default: slice vacio ESTATICO como default de
        // declaracion, para que ZON/JSON rellenen el campo ausente en vez de
        // fallar con MissingField. deinit libera slices con guard de longitud
        // (if len > 0) para no liberar el literal estatico.
        finalBaseTypo = std.fmt.allocPrint(shpa, "{s}{s} = &.{{}}", .{ rep, baseType }) catch unreachable;
    } else finalBaseTypo = std.fmt.allocPrint(shpa, "{s}{s}{s}{s}", .{ opt, rep, baseType, nul }) catch unreachable;

    return finalBaseTypo;
}

pub fn mapiProtoTiponAlZig(protoType: []const u8) []const u8 {
    var baseType: []const u8 = protoType;

    if (equal(u8, protoType, "bool")) {
        baseType = "bool";
    } else if (equal(u8, protoType, "string")) {
        baseType = "[]const u8";
    } else if (equal(u8, protoType, "int32")) {
        baseType = "i32";
    } else if (equal(u8, protoType, "int64")) {
        baseType = "i64";
    } else if (equal(u8, protoType, "sint32")) {
        baseType = "i32";
    } else if (equal(u8, protoType, "sint64")) {
        baseType = "i64";
    } else if (equal(u8, protoType, "sfixed32")) {
        baseType = "i32";
    } else if (equal(u8, protoType, "sfixed64")) {
        baseType = "i64";
    } else if (equal(u8, protoType, "uint32")) {
        baseType = "u32";
    } else if (equal(u8, protoType, "uint64")) {
        baseType = "u64";
    } else if (equal(u8, protoType, "fixed32")) {
        baseType = "u32";
    } else if (equal(u8, protoType, "fixed64")) {
        baseType = "u64";
    } else if (equal(u8, protoType, "float")) {
        baseType = "f32";
    } else if (equal(u8, protoType, "double")) {
        baseType = "f64";
    } else if (equal(u8, protoType, "bytes")) {
        baseType = "[]const u8";
    }

    // Tipo cualificado/importado, por ejemplo:
    //     k6bus.msg.Msg
    // Si Packet.zig importa Msg.zig como:
    //     const Msg = @import("Msg.zig");
    // el tipo usable es:
    //     Msg.k6bus.msg.Msg
    // Heuristica temporal: si el tipo contiene puntos, el ultimo segmento
    // se usa como alias del modulo importado.
    if (std.mem.lastIndexOfScalar(u8, baseType, '.')) |last_dot| {
        const alias = baseType[last_dot + 1 ..];
        baseType = std.fmt.allocPrint(
            shpa,
            "{s}.{s}",
            .{ alias, baseType },
        ) catch unreachable;
    }

    const finalBaseTypo: []u8 = std.fmt.allocPrint(shpa, "{s}", .{baseType}) catch unreachable;

    return finalBaseTypo;
}

/////////////////////////////////////
/// OneOf - Auksiliaraj Funkcioj
/////////////////////////////////////
///
/// Estas funkcioj ne generas kodon rekte.
/// Ili helpas al kgeneratoro.zig trakti oneof-ojn kiel Zig union(enum).
///
/// Ekzemploj:
///     params           -> Params
///     transport_params -> TransportParams
///
/// Noto:
/// - En protobuf, oneof ne havas propran wire-formaton.
/// - Cxiu kampo de oneof seriigxas kiel normala kampo.
/// - La semantiko "nur unu aktiva alternativo" apartenas al la generita kodo.
pub fn mapiOneOfNomonAlZigTipo(oneof_name: []const u8) []const u8 {
    if (oneof_name.len == 0) {
        return "OneOf";
    }

    var out = std.ArrayList(u8).empty;
    var upper_next = true;

    for (oneof_name) |c| {
        if (c == '_') {
            upper_next = true;
            continue;
        }

        if (upper_next) {
            out.append(shpa, std.ascii.toUpper(c)) catch {};
            upper_next = false;
        } else {
            out.append(shpa, c) catch {};
        }
    }

    return out.toOwnedSlice(shpa) catch &[_]u8{};
}

/// Devuelve el tipo Zig de una alternativa de oneof.
///
/// Ejemplo:
///     MCastConfig mcast = 10;
///
/// Devuelve:
///     MCastConfig
///
/// Si el tipo esta cualificado/importado, reutiliza la misma logica que los
/// campos normales.
pub fn mapiOneOfFieldTiponAlZig(field: prs.OneOfField) []const u8 {
    return mapiProtoTiponAlZig(field.field_type);
}

/// Devuelve el wire type protobuf de una alternativa oneof.
///
/// Importante:
/// - oneof NO tiene wire type propio.
/// - Cada alternativa usa el wire type de su tipo real.
pub fn getOneOfWireType(field: prs.OneOfField) u3 {
    return getWireType(field.field_type_enum);
}

/// Indica si una alternativa de oneof requiere limpieza explicita.
///
/// Casos que requieren deinit/free:
/// - message: debe llamar a deinit(allocator)
/// - string: debe liberar memoria si ha sido duplicada
/// - bytes: debe liberar memoria si ha sido duplicada
///
/// En TransportConfig.params todos los casos actuales son mensajes, por tanto
/// todos necesitan deinit.
pub fn oneOfFieldNeedsDeinit(field: prs.OneOfField) bool {
    return switch (field.field_type_enum) {
        .TYPE_MESSAGE,
        .TYPE_STRING,
        .TYPE_BYTES,
        => true,

        else => false,
    };
}

/// Indica si un oneof completo necesita allocator durante deinit.
///
/// Se usara para decidir si el deinit generado debe marcar allocator como usado.
pub fn oneOfNeedsAllocator(oneof_decl: prs.OneOfDecl) bool {
    for (oneof_decl.fields) |field| {
        if (oneOfFieldNeedsDeinit(field)) {
            return true;
        }
    }

    return false;
}

/// Indica si algun oneof de un mensaje necesita allocator en deinit.
pub fn anyOneOfNeedsAllocator(oneofs: []prs.OneOfDecl) bool {
    for (oneofs) |oneof_decl| {
        if (oneOfNeedsAllocator(oneof_decl)) {
            return true;
        }
    }

    return false;
}

// Wire Type        Valor   Descripción Tipos Lógicos Mapeados
// Varint           0       El valor es una secuencia de bytes de longitud variable: int32, int64, uint32, uint64, sint32, sint64, bool, enum
// 64-bit           1       El valor es un entero de 8 bytes (64 bits) de longitud fija: fixed64, sfixed64, double
// Length-delimited 2       El valor está precedido por su longitud codificada como Varint: string, bytes, message, repeated (packed)
// Start group      3       Marca el inicio de un grupo (Obsoleto): group
// End group        4       Marca el final de un grupo (Obsoleto): group
// 32-bit           5       El valor es un entero de 4 bytes (32 bits) de longitud fija: fixed32, sfixed32, float
pub fn getWireType(field_type: tpj) u3 {
    return switch (field_type) {
        .TYPE_FLOAT, .TYPE_FIXED32, .TYPE_SFIXED32 => 5,
        .TYPE_STRING, .TYPE_BYTES, .TYPE_MESSAGE => 2,
        .TYPE_DOUBLE, .TYPE_FIXED64, .TYPE_SFIXED64 => 1,
        else => 0, // Varint (0)
    };
}

pub fn estasPackable(field_type: tpj) bool {
    return switch (field_type) {
        .TYPE_INT32, .TYPE_INT64, .TYPE_UINT32, .TYPE_UINT64, .TYPE_SINT32, .TYPE_SINT64, .TYPE_FIXED32, .TYPE_FIXED64, .TYPE_SFIXED32, .TYPE_SFIXED64, .TYPE_FLOAT, .TYPE_DOUBLE, .TYPE_BOOL, .TYPE_ENUM => true,
        else => false,
    };
}

pub fn printEncodeMethod(verkisto: *std.Io.Writer, field_type: tpj, prefix: []const u8, field_name: []const u8)!void {
    return switch (field_type) {
        .TYPE_MESSAGE => try verkisto.print("{s}{s}.seriigi( allocator, buffer );\n", .{ prefix, field_name }),
        .TYPE_ENUM => try verkisto.print("buffer.encodeVarint( @intFromEnum({s}{s}) );\n", .{ prefix, field_name }),
        .TYPE_BOOL => try verkisto.print("buffer.encodeBool( {s}{s} );\n", .{ prefix, field_name }),
        .TYPE_STRING => try verkisto.print("buffer.encodeString( {s}{s} );\n", .{ prefix, field_name }),
        .TYPE_INT32 => try verkisto.print("buffer.encodeInt32( {s}{s} );\n", .{ prefix, field_name }),
        .TYPE_INT64 => try verkisto.print("buffer.encodeInt64( {s}{s} );\n", .{ prefix, field_name }),
        .TYPE_SINT32 => try verkisto.print("buffer.encodeSint32( {s}{s} );\n", .{ prefix, field_name }),
        .TYPE_SINT64 => try verkisto.print("buffer.encodeSint64( {s}{s} );\n", .{ prefix, field_name }),
        .TYPE_SFIXED32 => try verkisto.print("buffer.encodeSfixed32( {s}{s} );\n", .{ prefix, field_name }),
        .TYPE_SFIXED64 => try verkisto.print("buffer.encodeSfixed64( {s}{s} );\n", .{ prefix, field_name }),
        .TYPE_UINT32 => try verkisto.print("buffer.encodeUint32( {s}{s} );\n", .{ prefix, field_name }),
        .TYPE_UINT64 => try verkisto.print("buffer.encodeUint64( {s}{s} );\n", .{ prefix, field_name }),
        .TYPE_FIXED32 => try verkisto.print("buffer.encodeFixed32( {s}{s} );\n", .{ prefix, field_name }),
        .TYPE_FIXED64 => try verkisto.print("buffer.encodeFixed64( {s}{s} );\n", .{ prefix, field_name }),
        .TYPE_FLOAT => try verkisto.print("buffer.encodeFloat( {s}{s} );\n", .{ prefix, field_name }),
        .TYPE_DOUBLE => try verkisto.print("buffer.encodeDouble( {s}{s} );\n", .{ prefix, field_name }),
        .TYPE_BYTES => try verkisto.print("buffer.encodeBytes( {s}{s} );\n", .{ prefix, field_name }),
        else => try verkisto.print("buffer.encodeVarint( {s}{s} );\n", .{ prefix, field_name }),
    };
}

pub fn printDecodeMethod(verkisto: *std.Io.Writer, field_type: tpj, prefix: []const u8, field_name: []const u8, extra: []const u8)!void {
    return switch (field_type) {
        .TYPE_MESSAGE => {
            if (std.mem.indexOfScalar(u8, prefix, '.')) |_| {
                const zig_type = mapiProtoTiponAlZig(prefix);
                try verkisto.print(
                    "{s}.deseriigiElBin(allocator, try buffer.decodeBytes( {s} ), .BF_PROTOBUF ){s}",
                    .{ zig_type, extra, field_name },
                );
            } else {
                try verkisto.print(
                    "{s}.deseriigi(allocator, buffer, {s} ){s}",
                    .{ prefix, extra, field_name },
                );
            }
        },
        .TYPE_ENUM => try verkisto.print("std.meta.intToEnum({s}, try buffer.decodeVarint() ) {s}", .{ prefix, field_name }),
        .TYPE_BOOL => try verkisto.print("buffer.decodeBool(){s}", .{field_name}),
        .TYPE_STRING => try verkisto.print("buffer.decodeString( {s} try buffer.decodeVarint() ){s}", .{ prefix, field_name }),
        .TYPE_INT32 => try verkisto.print("buffer.decodeInt32(){s}", .{field_name}),
        .TYPE_INT64 => try verkisto.print("buffer.decodeInt64(){s}", .{field_name}),
        .TYPE_SINT32 => try verkisto.print("buffer.decodeSint32(){s}", .{field_name}),
        .TYPE_SINT64 => try verkisto.print("buffer.decodeSint64(){s}", .{field_name}),
        .TYPE_SFIXED32 => try verkisto.print("buffer.decodeSfixed32(){s}", .{field_name}),
        .TYPE_SFIXED64 => try verkisto.print("buffer.decodeSfixed64(){s}", .{field_name}),
        .TYPE_UINT32 => try verkisto.print("buffer.decodeUint32(){s}", .{field_name}),
        .TYPE_UINT64 => try verkisto.print("buffer.decodeUint64(){s}", .{field_name}),
        .TYPE_FIXED32 => try verkisto.print("buffer.decodeFixed32(){s}", .{field_name}),
        .TYPE_FIXED64 => try verkisto.print("buffer.decodeFixed64(){s}", .{field_name}),
        .TYPE_FLOAT => try verkisto.print("buffer.decodeFloat(){s}", .{field_name}),
        .TYPE_DOUBLE => try verkisto.print("buffer.decodeDouble(){s}", .{field_name}),
        .TYPE_BYTES => try verkisto.print("buffer.decodeBytes( {s} try buffer.decodeVarint() ){s}", .{ prefix, field_name }),
        else => try verkisto.print("buffer.decodeVarint(){s}", .{field_name}),
    };
}

pub fn estasLongaVar(field_type: tpj) bool {
    if (field_type == .TYPE_BYTES) return true;
    if (field_type == .TYPE_STRING) return true;
    if (field_type == .TYPE_MESSAGE) return true;

    return false;
}

pub fn printParseType(verkisto: *std.Io.Writer, field_type: tpj, name: []const u8)!void {
    return switch (field_type) {
        .TYPE_INT32, .TYPE_SINT32, .TYPE_SFIXED32 => try verkisto.print("mia_Mesagho.{s} =  std.fmt.parseInt(i32,val,10) catch 0;\n", .{name}),
        .TYPE_INT64, .TYPE_SINT64, .TYPE_SFIXED64 => try verkisto.print("mia_Mesagho.{s} =  std.fmt.parseInt(i64,val,10) catch 0;\n", .{name}),
        .TYPE_UINT32, .TYPE_FIXED32 => try verkisto.print("mia_Mesagho.{s} =  std.fmt.parseInt(u32,val,10) catch 0;\n", .{name}),
        .TYPE_UINT64, .TYPE_FIXED64 => try verkisto.print("mia_Mesagho.{s} =  std.fmt.parseInt(u64,val,10) catch 0;\n", .{name}),
        .TYPE_FLOAT => try verkisto.print("mia_Mesagho.{s} =  std.fmt.parseFloat(f32,val) catch 0.0;\n", .{name}),
        .TYPE_DOUBLE => try verkisto.print("mia_Mesagho.{s} =  std.fmt.parseFloat(f64,val) catch 0.0;\n", .{name}),
        .TYPE_ENUM => try verkisto.print("mia_Mesagho.{s} =  std.fmt.parseFloat(f64,val) catch 0;\n", .{name}),
        .TYPE_BOOL => try verkisto.print("mia_Mesagho.{s} =  if( equal(u8, val,\"true\") ) true else false;\n", .{name}),
        .TYPE_STRING, .TYPE_BYTES => try verkisto.print("mia_Mesagho.{s} =  allocator.dupe(u8, val) catch \"\";\n", .{name}),
        else => {},
    };
}

pub fn printParseValueExpr(
    verkisto: *std.Io.Writer,
    field_type: tpj,
    field_zig_type: []const u8,
    val_expr: []const u8,
)!void {
    return switch (field_type) {
        .TYPE_INT32, .TYPE_SINT32, .TYPE_SFIXED32 => try verkisto.print("std.fmt.parseInt(i32,{s},10) catch 0", .{val_expr}),
        .TYPE_INT64, .TYPE_SINT64, .TYPE_SFIXED64 => try verkisto.print("std.fmt.parseInt(i64,{s},10) catch 0", .{val_expr}),
        .TYPE_UINT32, .TYPE_FIXED32 => try verkisto.print("std.fmt.parseInt(u32,{s},10) catch 0", .{val_expr}),
        .TYPE_UINT64, .TYPE_FIXED64 => try verkisto.print("std.fmt.parseInt(u64,{s},10) catch 0", .{val_expr}),
        .TYPE_FLOAT => try verkisto.print("std.fmt.parseFloat(f32,{s}) catch 0.0", .{val_expr}),
        .TYPE_DOUBLE => try verkisto.print("std.fmt.parseFloat(f64,{s}) catch 0.0", .{val_expr}),
        .TYPE_BOOL => try verkisto.print("if (equal(u8, {s}, \"true\")) true else false", .{val_expr}),
        .TYPE_ENUM => try verkisto.print("parseEnumValue({s}, {s}) catch (std.meta.intToEnum({s}, 0) catch unreachable)", .{ field_zig_type, val_expr, field_zig_type }),
        .TYPE_STRING, .TYPE_BYTES => try verkisto.print("allocator.dupe(u8, {s}) catch \"\"", .{val_expr}),
        else => try verkisto.print("{s}", .{val_expr}),
    };
}
