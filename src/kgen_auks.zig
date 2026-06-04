const std = @import("std");
const equal = std.mem.eql;
const prs = @import("mecha_prs.zig");
const tpj = prs.Tipoj;

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

    default_value_string = std.mem.concatWithSentinel(std.heap.page_allocator, u8, &[_][]const u8{ ".", default_value_string }, 0) catch unreachable;
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
        finalBaseTypo = std.fmt.allocPrint(std.heap.page_allocator, "{s}{s}{s} = {s} ", .{ opt, rep, baseType, dfv }) catch unreachable;
    } else finalBaseTypo = std.fmt.allocPrint(std.heap.page_allocator, "{s}{s}{s}{s}", .{ opt, rep, baseType, nul }) catch unreachable;

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
            std.heap.page_allocator,
            "{s}.{s}",
            .{ alias, baseType },
        ) catch unreachable;
    }

    const finalBaseTypo: []u8 = std.fmt.allocPrint(std.heap.page_allocator, "{s}", .{baseType}) catch unreachable;

    return finalBaseTypo;
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
        .TYPE_INT32,
        .TYPE_INT64,
        .TYPE_UINT32,
        .TYPE_UINT64,
        .TYPE_SINT32,
        .TYPE_SINT64,
        .TYPE_FIXED32,
        .TYPE_FIXED64,
        .TYPE_SFIXED32,
        .TYPE_SFIXED64,
        .TYPE_FLOAT,
        .TYPE_DOUBLE,
        .TYPE_BOOL,
        .TYPE_ENUM => true,
        else => false,
    };
}

pub fn printEncodeMethod(verkisto: *std.Io.Writer, field_type: tpj, prefix: []const u8, field_name: []const u8) void {
    return switch (field_type) {
        .TYPE_MESSAGE => verkisto.print("{s}{s}.seriigi( allocator, buffer );\n", .{ prefix, field_name }) catch {},
        .TYPE_ENUM => verkisto.print("buffer.encodeVarint( @intFromEnum({s}{s}) );\n", .{ prefix, field_name }) catch {},
        .TYPE_BOOL => verkisto.print("buffer.encodeBool( {s}{s} );\n", .{ prefix, field_name }) catch {},
        .TYPE_STRING => verkisto.print("buffer.encodeString( {s}{s} );\n", .{ prefix, field_name }) catch {},
        .TYPE_INT32 => verkisto.print("buffer.encodeInt32( {s}{s} );\n", .{ prefix, field_name }) catch {},
        .TYPE_INT64 => verkisto.print("buffer.encodeInt64( {s}{s} );\n", .{ prefix, field_name }) catch {},
        .TYPE_SINT32 => verkisto.print("buffer.encodeSint32( {s}{s} );\n", .{ prefix, field_name }) catch {},
        .TYPE_SINT64 => verkisto.print("buffer.encodeSint64( {s}{s} );\n", .{ prefix, field_name }) catch {},
        .TYPE_SFIXED32 => verkisto.print("buffer.encodeSfixed32( {s}{s} );\n", .{ prefix, field_name }) catch {},
        .TYPE_SFIXED64 => verkisto.print("buffer.encodeSfixed64( {s}{s} );\n", .{ prefix, field_name }) catch {},
        .TYPE_UINT32 => verkisto.print("buffer.encodeUint32( {s}{s} );\n", .{ prefix, field_name }) catch {},
        .TYPE_UINT64 => verkisto.print("buffer.encodeUint64( {s}{s} );\n", .{ prefix, field_name }) catch {},
        .TYPE_FIXED32 => verkisto.print("buffer.encodeFixed32( {s}{s} );\n", .{ prefix, field_name }) catch {},
        .TYPE_FIXED64 => verkisto.print("buffer.encodeFixed64( {s}{s} );\n", .{ prefix, field_name }) catch {},
        .TYPE_FLOAT => verkisto.print("buffer.encodeFloat( {s}{s} );\n", .{ prefix, field_name }) catch {},
        .TYPE_DOUBLE => verkisto.print("buffer.encodeDouble( {s}{s} );\n", .{ prefix, field_name }) catch {},
        .TYPE_BYTES => verkisto.print("buffer.encodeBytes( {s}{s} );\n", .{ prefix, field_name }) catch {},
        else => verkisto.print("buffer.encodeVarint( {s}{s} );\n", .{ prefix, field_name }) catch {},
    };
}

pub fn printDecodeMethod(verkisto: *std.Io.Writer, field_type: tpj, prefix: []const u8, field_name: []const u8, extra: []const u8) void {
    return switch (field_type) {
        .TYPE_MESSAGE => {
            if (std.mem.indexOfScalar(u8, prefix, '.')) |_| {
                const zig_type = mapiProtoTiponAlZig(prefix);
                verkisto.print(
                    "{s}.deseriigiElBin(allocator, try buffer.decodeBytes( {s} ), .BF_PROTOBUF ){s}",
                    .{ zig_type, extra, field_name },
                ) catch {};
            } else {
                verkisto.print(
                    "{s}.deseriigi(allocator, buffer, {s} ){s}",
                    .{ prefix, extra, field_name },
                ) catch {};
            }
        },
        .TYPE_ENUM => verkisto.print("std.meta.intToEnum({s}, try buffer.decodeVarint() ) {s}", .{ prefix, field_name }) catch {},
        .TYPE_BOOL => verkisto.print("buffer.decodeBool(){s}", .{field_name}) catch {},
        .TYPE_STRING => verkisto.print("buffer.decodeString( {s} try buffer.decodeVarint() ){s}", .{ prefix, field_name }) catch {},
        .TYPE_INT32 => verkisto.print("buffer.decodeInt32(){s}", .{field_name}) catch {},
        .TYPE_INT64 => verkisto.print("buffer.decodeInt64(){s}", .{field_name}) catch {},
        .TYPE_SINT32 => verkisto.print("buffer.decodeSint32(){s}", .{field_name}) catch {},
        .TYPE_SINT64 => verkisto.print("buffer.decodeSint64(){s}", .{field_name}) catch {},
        .TYPE_SFIXED32 => verkisto.print("buffer.decodeSfixed32(){s}", .{field_name}) catch {},
        .TYPE_SFIXED64 => verkisto.print("buffer.decodeSfixed64(){s}", .{field_name}) catch {},
        .TYPE_UINT32 => verkisto.print("buffer.decodeUint32(){s}", .{field_name}) catch {},
        .TYPE_UINT64 => verkisto.print("buffer.decodeUint64(){s}", .{field_name}) catch {},
        .TYPE_FIXED32 => verkisto.print("buffer.decodeFixed32(){s}", .{field_name}) catch {},
        .TYPE_FIXED64 => verkisto.print("buffer.decodeFixed64(){s}", .{field_name}) catch {},
        .TYPE_FLOAT => verkisto.print("buffer.decodeFloat(){s}", .{field_name}) catch {},
        .TYPE_DOUBLE => verkisto.print("buffer.decodeDouble(){s}", .{field_name}) catch {},
        .TYPE_BYTES => verkisto.print("buffer.decodeBytes( {s} try buffer.decodeVarint() ){s}", .{ prefix, field_name }) catch {},
        else => verkisto.print("buffer.decodeVarint(){s}", .{field_name}) catch {},
    };
}

pub fn estasLongaVar(field_type: tpj) bool {
    if (field_type == .TYPE_BYTES) return true;
    if (field_type == .TYPE_STRING) return true;
    if (field_type == .TYPE_MESSAGE) return true;

    return false;
}

pub fn printParseType(verkisto: *std.Io.Writer, field_type: tpj, name: []const u8) void {
    return switch (field_type) {
        .TYPE_INT32, .TYPE_SINT32, .TYPE_SFIXED32 => verkisto.print("mia_Mesagho.{s} =  std.fmt.parseInt(i32,val,10) catch 0;\n", .{name}) catch {},
        .TYPE_INT64, .TYPE_SINT64, .TYPE_SFIXED64 => verkisto.print("mia_Mesagho.{s} =  std.fmt.parseInt(i64,val,10) catch 0;\n", .{name}) catch {},
        .TYPE_UINT32, .TYPE_FIXED32 => verkisto.print("mia_Mesagho.{s} =  std.fmt.parseInt(u32,val,10) catch 0;\n", .{name}) catch {},
        .TYPE_UINT64, .TYPE_FIXED64 => verkisto.print("mia_Mesagho.{s} =  std.fmt.parseInt(u64,val,10) catch 0;\n", .{name}) catch {},
        .TYPE_FLOAT => verkisto.print("mia_Mesagho.{s} =  std.fmt.parseFloat(f32,val) catch 0.0;\n", .{name}) catch {},
        .TYPE_DOUBLE => verkisto.print("mia_Mesagho.{s} =  std.fmt.parseFloat(f64,val) catch 0.0;\n", .{name}) catch {},
        .TYPE_ENUM => verkisto.print("mia_Mesagho.{s} =  std.fmt.parseFloat(f64,val) catch 0;\n", .{name}) catch {},
        .TYPE_BOOL => verkisto.print("mia_Mesagho.{s} =  if( equal(u8, val,\"true\") ) true else false;\n", .{name}) catch {},
        .TYPE_STRING, .TYPE_BYTES => verkisto.print("mia_Mesagho.{s} =  allocator.dupe(u8, val) catch \"\";\n", .{name}) catch {},
        else => {},
    };
}

pub fn printParseValueExpr(
    verkisto: *std.Io.Writer,
    field_type: tpj,
    field_zig_type: []const u8,
    val_expr: []const u8,
) void {
    return switch (field_type) {
        .TYPE_INT32, .TYPE_SINT32, .TYPE_SFIXED32 =>
            verkisto.print("std.fmt.parseInt(i32,{s},10) catch 0", .{val_expr}) catch {},
        .TYPE_INT64, .TYPE_SINT64, .TYPE_SFIXED64 =>
            verkisto.print("std.fmt.parseInt(i64,{s},10) catch 0", .{val_expr}) catch {},
        .TYPE_UINT32, .TYPE_FIXED32 =>
            verkisto.print("std.fmt.parseInt(u32,{s},10) catch 0", .{val_expr}) catch {},
        .TYPE_UINT64, .TYPE_FIXED64 =>
            verkisto.print("std.fmt.parseInt(u64,{s},10) catch 0", .{val_expr}) catch {},
        .TYPE_FLOAT =>
            verkisto.print("std.fmt.parseFloat(f32,{s}) catch 0.0", .{val_expr}) catch {},
        .TYPE_DOUBLE =>
            verkisto.print("std.fmt.parseFloat(f64,{s}) catch 0.0", .{val_expr}) catch {},
        .TYPE_BOOL =>
            verkisto.print("if (equal(u8, {s}, \"true\")) true else false", .{val_expr}) catch {},
        .TYPE_ENUM =>
            verkisto.print("parseEnumValue({s}, {s}) catch (std.meta.intToEnum({s}, 0) catch unreachable)", .{ field_zig_type, val_expr, field_zig_type }) catch {},
        .TYPE_STRING, .TYPE_BYTES =>
            verkisto.print("allocator.dupe(u8, {s}) catch \"\"", .{val_expr}) catch {},
        else =>
            verkisto.print("{s}", .{val_expr}) catch {},
    };
}
