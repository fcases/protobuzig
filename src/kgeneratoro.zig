/// kgeneratoro.zig
///
const std = @import("std");
const equal = std.mem.eql;
const prs = @import("mecha_prs.zig");
const pf = prs.ProtoFile;
const tpj = prs.Tipoj;

const auks = @import("kgen_auks.zig");

var verkisto: *std.Io.Writer = undefined;

fn estasImportitaTipo(field_type: []const u8) bool {
    return std.mem.indexOfScalar(u8, field_type, '.') != null;
}

pub fn generiZigKodon(
    dosiera_nomo: []const u8,
    output_dir: []const u8,
    proto: *pf,
) !void {
    var buffer: [512]u8 = .{0} ** 512;

    const nuda = std.fs.path.basename(dosiera_nomo);
    const punkta_indekso = std.mem.lastIndexOfScalar(u8, nuda, '.') orelse nuda.len;
    const basa_nomo = nuda[0..punkta_indekso];

    try std.fs.cwd().makePath(output_dir);

    const zig_nomo = try std.fmt.bufPrint(
        &buffer,
        "{s}/{s}.zig",
        .{ output_dir, basa_nomo },
    );

    var zig_dosiero = try std.fs.cwd().createFile(zig_nomo, .{ .truncate = true });
    defer zig_dosiero.close();

    const TAM = 65536;
    var zig_buffero: [TAM]u8 = .{0} ** TAM;
    var zig_verkisto = zig_dosiero.writer(&zig_buffero);
    verkisto = &zig_verkisto.interface;

    // La tuta kodoj por generiĝas ĉiuij:
    try skribiKaplinion(proto);
    const tabs = try skribiIniPakaghon(proto.package_name);
    try skribiEnums(proto.enums, "");
    try skribiMesaghojn(proto.messages, "");
    try skribiFiniPakaghon(proto.package_name, tabs);
    try skribiGeneralajnFunkciojn();
}

/////////////////////////////////////
/// Chefa Funkcioj:
/// - skribiKaplinion
/// - skribiIniPakaghon
/// - skribiEnums
/// - skribiMesaghojn
/// - skribiFiniPakaghon
/// - skribiGeneralajnFunkciojn
/////////////////////////////////////

fn skribiKaplinion(proto: *pf) !void {
    try verkisto.print(
        \\const std = @import("std");
        \\const dbg = std.debug;
        \\const all = std.mem;
        \\const equal = std.mem.eql;
        \\const  io = std.Io;
        \\
        \\const encdec = @import("encdec.zig");
        \\const EncodeBuffer = encdec.EncodeBuffer;
        \\const DecodeBuffer = encdec.DecodeBuffer;
        \\
        \\const TokenIterType = std.mem.TokenIterator(u8, .any);
        \\
    , .{});

    for (proto.imports) |imp| {
        // imp puede venir con comillas desde el parser: "Msg.proto".
        // Normalizamos aqui para no romper defaults string que tambien usan quoted_string.
        var import_name = imp;
        if (import_name.len >= 2 and import_name[0] == '"' and import_name[import_name.len - 1] == '"') {
            import_name = import_name[1 .. import_name.len - 1];
        }

        const base = std.fs.path.basename(import_name);
        const punkta_indekso = std.mem.lastIndexOfScalar(u8, base, '.') orelse base.len;
        const basa_nomo = base[0..punkta_indekso];

        try verkisto.print(
            \\const {s} = @import("{s}.zig");
            \\
        , .{ basa_nomo, basa_nomo });
    }
    try verkisto.print("\n", .{});
}

fn skribiIniPakaghon(pnamo: ?[]const u8) !u8 {
    var i: u8 = 0;
    if (pnamo) |pkg_name| {
        if (pkg_name.len == 0) return 0;
        var tokenizer = std.mem.splitAny(u8, pkg_name, ".");
        while (tokenizer.next()) |parto| : (i = i + 1) {
            for (0..i) |_| {
                try verkisto.print("    ", .{});
            }
            try verkisto.print("pub const {s} = struct {{\n\n", .{parto});
        }
        try verkisto.print("\n", .{});
    }
    return i;
}

fn skribiEnums(enums: []prs.Enum, ind: []const u8) !void {
    for (enums) |enm| {
        try verkisto.print(
            \\{s}pub const {s} = enum(u64) {{
            \\
        , .{ ind, enm.name });

        for (enm.values) |val| {
            try verkisto.print("{s}   {s} = {d},\n", .{ ind, val.name, val.number });
        }
        try verkisto.print("{s}}};\n\n", .{ind});
    }
}

/////////////////////////////////////
/// OneOf - Generado de Protobuf Text
/////////////////////////////////////
/// Genera el codigo de escritura Protobuf Text de un oneof.
/// Importante:
/// - En Protobuf Text, el oneof no se escribe como contenedor.
/// - Se escribe directamente la alternativa activa.
/// - Ejemplo:
///     mcast {
///         mcast_address: "239.255.0.1"
///         port: 40069
///     }
/// - .none no se escribe.
fn skribiPBTekstoOneOf(oneof_decl: prs.OneOfDecl, ind: []const u8) !void {
    try verkisto.print(
        \\{s}        switch (self.{s}) {{
        \\{s}            .none => {{}},
        \\
    , .{
        ind,
        oneof_decl.name,
        ind,
    });

    for (oneof_decl.fields) |field| {
        switch (field.field_type_enum) {
            .TYPE_MESSAGE => {
                try verkisto.print(
                    \\{s}            .{s} => |val| {{
                    \\{s}                const indent = std.mem.concatWithSentinel(allocator, u8, &[_][]const u8{{ ind, "    " }}, 0) catch unreachable;
                    \\{s}                defer allocator.free(indent);
                    \\
                , .{
                    ind,
                    field.name,
                    ind,
                    ind,
                });

                if (estasImportitaTipo(field.field_type)) {
                    try verkisto.print(
                        \\{s}                var {s}_item = val;
                        \\{s}                const {s}_text = try {s}_item.skribiAlTeksto(allocator, .TF_PROTOBUF);
                        \\{s}                defer allocator.free({s}_text);
                        \\
                        \\{s}                try bufro.print(allocator, "{{s}}{s} {{{{\n{{s}}{{s}}}}}}\n", .{{ ind, {s}_text, ind }});
                        \\{s}            }},
                        \\
                    , .{
                        ind,
                        field.name,

                        ind,
                        field.name,
                        field.name,

                        ind,
                        field.name,

                        ind,
                        field.name,
                        field.name,

                        ind,
                    });
                } else {
                    try verkisto.print(
                        \\{s}                const {s}_text = try val.skribiAlProtobufTeksto(allocator, indent);
                        \\{s}                defer allocator.free({s}_text);
                        \\
                        \\{s}                try bufro.print(allocator, "{{s}}{s} {{{{\n{{s}}{{s}}}}}}\n", .{{ ind, {s}_text, ind }});
                        \\{s}            }},
                        \\
                    , .{
                        ind,
                        field.name,

                        ind,
                        field.name,

                        ind,
                        field.name,
                        field.name,

                        ind,
                    });
                }
            },

            .TYPE_STRING => {
                try verkisto.print(
                    \\{s}            .{s} => |val| {{
                    \\{s}                try bufro.print(allocator, "{{s}}{s}: \"{{s}}\"\n", .{{ ind, val }});
                    \\{s}            }},
                    \\
                , .{
                    ind,
                    field.name,

                    ind,
                    field.name,

                    ind,
                });
            },

            .TYPE_ENUM => {
                try verkisto.print(
                    \\{s}            .{s} => |val| {{
                    \\{s}                try bufro.print(allocator, "{{s}}{s}: {{s}}\n", .{{ ind, @tagName(val) }});
                    \\{s}            }},
                    \\
                , .{
                    ind,
                    field.name,

                    ind,
                    field.name,

                    ind,
                });
            },

            else => {
                try verkisto.print(
                    \\{s}            .{s} => |val| {{
                    \\{s}                try bufro.print(allocator, "{{s}}{s}: {{any}}\n", .{{ ind, val }});
                    \\{s}            }},
                    \\
                , .{
                    ind,
                    field.name,

                    ind,
                    field.name,

                    ind,
                });
            },
        }
    }

    try verkisto.print(
        \\{s}        }}
        \\
        \\
    , .{
        ind,
    });
}

/// Genera escritura Protobuf Text para todos los oneofs de un mensaje.
fn skribiPBTekstoOneOfs(msg: prs.Message, ind: []const u8) !void {
    for (msg.oneofs) |oneof_decl| {
        try skribiPBTekstoOneOf(oneof_decl, ind);
    }
}

/////////////////////////////////////
/// OneOf - Lectura Protobuf Text
/////////////////////////////////////
/// Genera las ramas de lectura Protobuf Text para un oneof.
/// En Protobuf Text, el oneof no aparece como contenedor.
/// La alternativa aparece directamente:
///     mcast {
///         ...
///     }
/// Por tanto se detecta por tok == "mcast", "bcast", etc.
/// Regla:
/// Si aparece mas de una alternativa del mismo oneof, gana la ultima.
/// Antes de asignar una nueva alternativa, liberamos la anterior.
fn skribiLegiPBTekstoOneOf(oneof_decl: prs.OneOfDecl, ind: []const u8) !void {
    const union_name = auks.mapiOneOfNomonAlZigTipo(oneof_decl.name);

    for (oneof_decl.fields) |field| {
        const temp_name = std.fmt.allocPrint(
            std.heap.page_allocator,
            "{s}_{s}_val",
            .{ oneof_decl.name, field.name },
        ) catch unreachable;

        switch (field.field_type_enum) {
            .TYPE_MESSAGE => {
                try verkisto.print(
                    \\{s}            if( equal(u8, tok, "{s}" ) ) {{
                    \\{s}                if( ! equal(u8, val, "{{" ) ) return error.InvalidFormat;
                    \\{s}                const {s} = try {s}.legiElProtobufTeksto(allocator, it);
                    \\
                    \\{s}                mia_Mesagho.deinit{s}(allocator);
                    \\{s}                mia_Mesagho.{s} = .{{ .{s} = {s} }};
                    \\{s}                continue;
                    \\{s}            }}
                    \\
                , .{
                    ind,
                    field.name,

                    ind,

                    ind,
                    temp_name,
                    field.field_type,

                    ind,
                    union_name,

                    ind,
                    oneof_decl.name,
                    field.name,
                    temp_name,

                    ind,

                    ind,
                });
            },

            else => {
                // De momento cubrimos TYPE_MESSAGE, que es el caso actual:
                // TransportConfig.params y PanelSimple.datos.
                //
                // Las ramas scalar/string/enum se pueden anadir despues si
                // aparece un oneof con alternativas no-message.
            },
        }
    }
}

/// Genera lectura Protobuf Text para todos los oneofs de un mensaje.
fn skribiLegiPBTekstoOneOfs(msg: prs.Message, ind: []const u8) !void {
    for (msg.oneofs) |oneof_decl| {
        try skribiLegiPBTekstoOneOf(oneof_decl, ind);
    }
}

/////////////////////////////////////
/// OneOf - Generado de union(enum)
/////////////////////////////////////
/// Genera los tipos Zig asociados a los oneof de un mensaje.
/// Ejemplo protobuf:
///     oneof params {
///         MCastConfig mcast = 10;
///         BCastConfig bcast = 11;
///     }
/// Salida Zig:
///     pub const Params = union(enum) {
///         none: void,
///         mcast: MCastConfig,
///         bcast: BCastConfig,
///     };
/// Nota importante:
/// - El nombre del oneof se transforma a PascalCase.
/// - La alternativa "none" no existe en protobuf.
/// - "none" es una convencion interna para que initDefault() tenga un estado
///   explicito y seguro.
fn skribiOneOfUnion(oneof_decl: prs.OneOfDecl, ind: []const u8) !void {
    const union_name = auks.mapiOneOfNomonAlZigTipo(oneof_decl.name);

    try verkisto.print(
        \\{s}pub const {s} = union(enum) {{
        \\{s}    none: void,
        \\
    , .{
        ind,
        union_name,
        ind,
    });

    for (oneof_decl.fields) |field| {
        try verkisto.print(
            \\{s}    {s}: {s},
            \\
        , .{
            ind,
            field.name,
            auks.mapiOneOfFieldTiponAlZig(field),
        });
    }

    try verkisto.print(
        \\{s}}};
        \\
        \\
    , .{ind});
}

/// Genera todos los union(enum) oneof definidos dentro de un mensaje.
fn skribiOneOfUnions(msg: prs.Message, ind: []const u8) !void {
    for (msg.oneofs) |oneof_decl| {
        try skribiOneOfUnion(oneof_decl, ind);
    }
}

/////////////////////////////////////
/// OneOf - Generado de deinit helpers
/////////////////////*///////////////
/// Genera una funcion auxiliar por cada oneof del mensaje.
/// Ejemplo:
///     fn deinitParams(self: *const T*ansportConfig, allocator: all.Allo*ator) void {
///         switch (s*lf.params) {
///             .none => {},
///             .mcast => |*v| v.deinit(allocator),
///         }
///     }
/// Esta funcion se usa en dos sitios:
/// - deinit() general del mensaje.
/// - deseriigi(), antes de sobrescribir una alternativa oneof ya activa.
///
/// Razon protobuf:
/// Si aparecen varias alternativas del mismo oneof en el wire, gana la ultima.
/// Por tanto, al leer una nueva alternativa hay que liberar la anterior.
fn skribiOneOfDeinitHelper(msg: prs.Message, oneof_decl: prs.OneOfDecl, ind: []const u8) !void {
    const union_name = auks.mapiOneOfNomonAlZigTipo(oneof_decl.name);

    try verkisto.print(
        \\{s}fn deinit{s}(self: *const {s}, allocator: all.Allocator) void {{
        \\{s}    switch (self.{s}) {{
        \\{s}        .none => {{}},
        \\
    , .{
        ind,
        union_name,
        msg.name,
        ind,
        oneof_decl.name,
        ind,
    });

    for (oneof_decl.fields) |field| {
        switch (field.field_type_enum) {
            .TYPE_MESSAGE => {
                try verkisto.print(
                    \\{s}        .{s} => |*v| v.deinit(allocator),
                    \\
                , .{
                    ind,
                    field.name,
                });
            },

            .TYPE_STRING,
            .TYPE_BYTES,
            => {
                try verkisto.print(
                    \\{s}        .{s} => |v| allocator.free(v),
                    \\
                , .{
                    ind,
                    field.name,
                });
            },

            else => {
                try verkisto.print(
                    \\{s}        .{s} => {{}},
                    \\
                , .{
                    ind,
                    field.name,
                });
            },
        }
    }

    try verkisto.print(
        \\{s}    }}
        \\{s}}}
        \\
        \\
    , .{
        ind,
        ind,
    });
}

/// Genera todos los helpers *e deinit asociados a oneof dentro *e un mensaje.
fn skribiOneOfDeinitHelpers(msg: prs.Message, ind: []const u8) !void {
    for (msg.oneofs) |oneof_decl| {
        try skribiOneOfDeinitHelper(msg, oneof_decl, ind);
    }
}

/////////////////////////////////////
/// OneOf - Generado de seriigi()
/////////////////////////////////////
/// Genera el codigo de serializacion binaria de un oneof.
/// Importante:
/// - En protobuf, oneof no tiene wire-format propio.
/// - Cada alternativa se codifica como si fuese un campo normal.
/// - Solo se serializa la alternativa activa.
/// - La alternativa .none no se serializa.
/// Como EncodeBuffer escribe hacia atras, este bloque debe emitirse antes que
/// los campos normales cuando los field numbers del oneof sean mayores.
fn skribiSeriigiOneOf(oneof_decl: prs.OneOfDecl, ind: []const u8) !void {
    try verkisto.print(
        \\    {s}    switch (self.{s}) {{
        \\    {s}        .none => {{}},
        \\
    , .{
        ind,
        oneof_decl.name,
        ind,
    });

    for (oneof_decl.fields) |field| {
        const wire_type = auks.getOneOfWireType(field);
        const temp_name = try std.fmt.allocPrint(
            std.heap.page_allocator,
            "{s}_{s}_longa",
            .{ oneof_decl.name, field.name },
        );

        switch (field.field_type_enum) {
            .TYPE_MESSAGE => {
                if (estasImportitaTipo(field.field_type)) {
                    try verkisto.print(
                        \\    {s}        .{s} => |val| {{
                        \\    {s}            var item = val;
                        \\    {s}            const {s}_bytes = try item.seriigiAlBin(allocator, .BF_PROTOBUF);
                        \\    {s}            defer allocator.free({s}_bytes);
                        \\    {s}            const {s} = try buffer.encodeBytes({s}_bytes);
                        \\    {s}            tuta_longo += {s};
                        \\    {s}            tuta_longo += try buffer.encodeVarint({s});
                        \\    {s}            tuta_longo += try buffer.encodeVarint((@as(u32, {d}) << 3) | {d});
                        \\    {s}        }},
                        \\
                    , .{
                        ind,       field.name,
                        ind,       ind,
                        temp_name, ind,
                        temp_name, ind,
                        temp_name, temp_name,
                        ind,       temp_name,
                        ind,       temp_name,
                        ind,       field.number,
                        wire_type, ind,
                    });
                } else {
                    try verkisto.print(
                        \\    {s}        .{s} => |val| {{
                        \\    {s}            const {s} = try val.seriigi(allocator, buffer);
                        \\    {s}            tuta_longo += {s};
                        \\    {s}            tuta_longo += try buffer.encodeVarint({s});
                        \\    {s}            tuta_longo += try buffer.encodeVarint((@as(u32, {d}) << 3) | {d});
                        \\    {s}        }},
                        \\
                    , .{
                        ind,       field.name,
                        ind,       temp_name,
                        ind,       temp_name,
                        ind,       temp_name,
                        ind,       field.number,
                        wire_type, ind,
                    });
                }
            },

            else => {
                try verkisto.print(
                    \\    {s}        .{s} => |val| {{
                    \\    {s}            tuta_longo += try 
                , .{
                    ind,
                    field.name,
                    ind,
                });

                auks.printEncodeMethod(
                    verkisto,
                    field.field_type_enum,
                    "val",
                    "",
                );

                try verkisto.print(
                    \\    {s}            tuta_longo += try buffer.encodeVarint((@as(u32, {d}) << 3) | {d});
                    \\    {s}        }},
                    \\
                , .{
                    ind,
                    field.number,
                    wire_type,
                    ind,
                });
            },
        }
    }

    try verkisto.print(
        \\    {s}    }}
        \\
        \\
    , .{ind});
}

/// Genera serializacion para todos los oneofs de un mensaje.
fn skribiSeriigiOneOfs(msg: prs.Message, ind: []const u8) !void {
    for (msg.oneofs) |oneof_decl| {
        try skribiSeriigiOneOf(oneof_decl, ind);
    }
}

/////////////////////////////////////
/// OneOf - Generado de deseriigi()
/////////////////////////////////////
fn skribiDeseriigiOneOfBranches(
    oneof_decl: prs.OneOfDecl,
    indent: []const u8,
    unua: *bool,
) !void {
    const union_name = auks.mapiOneOfNomonAlZigTipo(oneof_decl.name);

    for (oneof_decl.fields) |field| {
        const field_type = field.field_type;
        const field_type_enum = field.field_type_enum;
        const field_number = field.number;
        const wire_type = auks.getOneOfWireType(field);

        const temp_name = std.fmt.allocPrint(
            std.heap.page_allocator,
            "{s}_{s}_val",
            .{ oneof_decl.name, field.name },
        ) catch unreachable;

        try verkisto.print(
            \\{s}        {s} ( field_number == {d} and wire_type == {d} )
            \\
        , .{
            indent,
            if (unua.*) "if" else "else if",
            field_number,
            wire_type,
        });

        switch (field_type_enum) {
            .TYPE_MESSAGE => {
                if (estasImportitaTipo(field_type)) {
                    try verkisto.print(
                        \\{s}        {{
                        \\{s}            const raw = try buffer.decodeBytes(try buffer.decodeVarint());
                        \\{s}            defer allocator.free(raw);
                        \\{s}
                        \\{s}            const {s} =
                        \\{s}                try {s}.deseriigiElBin(
                        \\{s}                    allocator,
                        \\{s}                    raw,
                        \\{s}                    .BF_PROTOBUF,
                        \\{s}                );
                        \\{s}
                        \\{s}            mia_Mesagho.deinit{s}(allocator);
                        \\{s}            mia_Mesagho.{s} = .{{ .{s} = {s} }};
                        \\{s}        }}
                        \\
                    , .{
                        indent,
                        indent,
                        indent,
                        indent,
                        indent,
                        temp_name,
                        indent,
                        auks.mapiProtoTiponAlZig(field_type),
                        indent,
                        indent,
                        indent,
                        indent,
                        indent,
                        indent,
                        union_name,
                        indent,
                        oneof_decl.name,
                        field.name,
                        temp_name,
                        indent,
                    });
                } else {
                    try verkisto.print(
                        \\{s}        {{
                        \\{s}            const {s} = try {s}.deseriigi(
                        \\{s}                allocator,
                        \\{s}                buffer,
                        \\{s}                try buffer.decodeVarint(),
                        \\{s}            );
                        \\{s}
                        \\{s}            mia_Mesagho.deinit{s}(allocator);
                        \\{s}            mia_Mesagho.{s} = .{{ .{s} = {s} }};
                        \\{s}        }}
                        \\
                    , .{
                        indent,
                        indent,
                        temp_name,
                        field_type,
                        indent,
                        indent,
                        indent,
                        indent,
                        indent,
                        indent,
                        union_name,
                        indent,
                        oneof_decl.name,
                        field.name,
                        temp_name,
                        indent,
                    });
                }
            },

            .TYPE_STRING => {
                try verkisto.print(
                    \\{s}        {{
                    \\{s}            const {s} = try buffer.decodeString(try buffer.decodeVarint());
                    \\{s}            mia_Mesagho.deinit{s}(allocator);
                    \\{s}            mia_Mesagho.{s} = .{{ .{s} = {s} }};
                    \\{s}        }}
                    \\
                , .{
                    indent,
                    indent,
                    temp_name,
                    indent,
                    union_name,
                    indent,
                    oneof_decl.name,
                    field.name,
                    temp_name,
                    indent,
                });
            },

            .TYPE_BYTES => {
                try verkisto.print(
                    \\{s}        {{
                    \\{s}            const {s} = try buffer.decodeBytes(try buffer.decodeVarint());
                    \\{s}            mia_Mesagho.deinit{s}(allocator);
                    \\{s}            mia_Mesagho.{s} = .{{ .{s} = {s} }};
                    \\{s}        }}
                    \\
                , .{
                    indent,
                    indent,
                    temp_name,
                    indent,
                    union_name,
                    indent,
                    oneof_decl.name,
                    field.name,
                    temp_name,
                    indent,
                });
            },

            .TYPE_ENUM => {
                try verkisto.print(
                    \\{s}        {{
                    \\{s}            const {s} = try std.meta.intToEnum({s}, try buffer.decodeVarint());
                    \\{s}            mia_Mesagho.deinit{s}(allocator);
                    \\{s}            mia_Mesagho.{s} = .{{ .{s} = {s} }};
                    \\{s}        }}
                    \\
                , .{
                    indent,
                    indent,
                    temp_name,
                    field_type,
                    indent,
                    union_name,
                    indent,
                    oneof_decl.name,
                    field.name,
                    temp_name,
                    indent,
                });
            },

            else => {
                try verkisto.print(
                    \\{s}        {{
                    \\{s}            const {s} = try 
                , .{
                    indent,
                    indent,
                    temp_name,
                });

                auks.printDecodeMethod(
                    verkisto,
                    field_type_enum,
                    "",
                    ";\n",
                    "try buffer.decodeVarint()",
                );

                try verkisto.print(
                    \\{s}            mia_Mesagho.deinit{s}(allocator);
                    \\{s}            mia_Mesagho.{s} = .{{ .{s} = {s} }};
                    \\{s}        }}
                    \\
                , .{
                    indent,
                    union_name,
                    indent,
                    oneof_decl.name,
                    field.name,
                    temp_name,
                    indent,
                });
            },
        }

        unua.* = false;
    }
}

/// Genera las ramas de deserializacion de todos los oneofs de un mensaje.
fn skribiDeseriigiOneOfs(
    msg: prs.Message,
    indent: []const u8,
    unua: *bool,
) !void {
    for (msg.oneofs) |oneof_decl| {
        try skribiDeseriigiOneOfBranches(oneof_decl, indent, unua);
    }
}

fn skribiMesaghojn(messages: []prs.Message, ind: []const u8) !void {
    for (messages) |msg| {
        try verkisto.print("{s}pub const {s} = struct {{\n", .{ ind, msg.name });

        const indent = std.mem.concatWithSentinel(
            std.heap.page_allocator,
            u8,
            &[_][]const u8{ ind, "    " },
            0,
        ) catch unreachable;

        if (msg.internal_enums.len > 0) {
            try skribiEnums(msg.internal_enums, indent);
        }

        if (msg.internal_msgs.len > 0) {
            try skribiMesaghojn(msg.internal_msgs, indent);
        }

        // /////////////
        // Skribi oneof union(enum)
        // Los oneof se generan como tipos internos del mensaje.
        // Ejemplo:
        //     pub const Params = union(enum) {
        //         none: void,
        //         mcast: MCastConfig,
        //         bcast: BCastConfig,
        //     };
        if (msg.oneofs.len > 0) {
            try skribiOneOfUnions(msg, indent);
        }

        // /////////////
        // Skribi kampoj normalaj
        for (msg.fields, 0..) |field, i| {
            var default_value_string: []const u8 = field.default_value orelse "null";
            if (field.default_value != null and msg.fields[i].field_type_enum == .TYPE_ENUM) {
                default_value_string = std.mem.concatWithSentinel(
                    std.heap.page_allocator,
                    u8,
                    &[_][]const u8{ ".", default_value_string },
                    0,
                ) catch unreachable;

                const zigType = auks.mapiZigType(
                    field.field_type,
                    field.label,
                    default_value_string,
                );

                try verkisto.print(
                    "{s}    {s}: {s},\n",
                    .{ ind, field.name, zigType },
                );
            } else {
                const zigType = auks.mapiZigType(
                    field.field_type,
                    field.label,
                    field.default_value,
                );

                try verkisto.print(
                    "{s}    {s}: {s},\n",
                    .{ ind, field.name, zigType },
                );
            }
        }

        // /////////////
        // Skribi kampoj oneof
        // Cada oneof se representa como un campo cuyo tipo es la union(enum)
        // generada previamente dentro del mismo struct.
        // Ejemplo:
        //     pub const Params = union(enum) { ... };
        //     params: Params,
        for (msg.oneofs) |oneof_decl| {
            const union_name = auks.mapiOneOfNomonAlZigTipo(oneof_decl.name);

            try verkisto.print(
                "{s}    {s}: {s},\n",
                .{ ind, oneof_decl.name, union_name },
            );
        }
        try verkisto.print("\n", .{});

        try skribiInitDefault(msg, indent);
        if (msg.oneofs.len > 0) {
            try skribiOneOfDeinitHelpers(msg, indent);
        }
        try skribiDeInit(msg, indent);

        // /////////////
        // Skribi kaj Legi funkcion al/el .TF_XXX teksto
        try skribiAlTeksto(msg, ind);
        try legiElTeksto(msg, ind);

        // /////////////
        // Skribi kaj Legi funkcion al/el PB teksto
        try skribiSkribiAlPBTeksto(msg, ind);
        try skribiLegiElPBTeksto(msg, ind);

        // /////////////
        // Skribi funkcion por seriigi al binara formato
        // Skribi funkcion por deseriigi al binara formato
        try skribiSeriigi(msg, ind);
        try skribiDeseriigi(msg, ind);

        try verkisto.print("\n{s}}};    // {s}\n\n", .{ ind, msg.name });
        try verkisto.flush();
    }
}

fn skribiFiniPakaghon(pnamo: ?[]const u8, tabs: u8) !void {
    var j = tabs;
    if (pnamo) |pkg_name| {
        if (pkg_name.len == 0) return;
        var tokenizer = std.mem.splitBackwardsAny(u8, pkg_name, ".");
        while (tokenizer.next()) |parto| : (j -= 1) {
            for (0..j - 1) |_| {
                try verkisto.print("    ", .{});
            }
            try verkisto.print("}};   // {s}\n", .{parto});
        }
        try verkisto.print("\n", .{});
    }
    try verkisto.flush();
}

fn skribiGeneralajnFunkciojn() !void {
    try verkisto.print(
        \\//////////////////////////////////////////////
        \\/// //////////////////////////////////////////
        \\/// //////////////////////////////////////////
        \\//////////////////////////////////////////////
        \\
        \\
    , .{});
    try verkisto.flush();

    //////////////////////////////////////////////
    //// Seriigi Binaran Tipon
    //////////////////////////////////////////////

    try verkisto.print(
        \\//////////////////////////////////////////////
        \\/// Seriigi Binaran Tipon
        \\/// //////////////////////////////////////////
        \\
        \\pub const BinaraFormato = enum(u32) {{
        \\    BF_PROTOBUF = 0,
        \\    BF_OMG_CDR = 1,
        \\    BF_ASN1_BER = 2,
        \\    BF_ASN1_DER = 3,
        \\    BF_BASE64 = 10,
        \\    BF_BINPB2TEKSTO_HEX = 11,
        \\    BF_BINPB2TEKSTO_DEC = 12,
        \\}};
        \\
        \\
    , .{});
    try verkisto.flush();

    try verkisto.print(
        \\fn seriigiTipon(allocator: all.Allocator, comptime T: type, value: * const T) ![]const u8 {{
        \\    var mia_enc = try EncodeBuffer.init(allocator, 48 * 1024);
        \\    defer mia_enc.deinit();
        \\
        \\    const longo = try value.seriigi(allocator, &mia_enc);
        \\    const bytes = try allocator.alloc(u8, longo);
        \\    std.mem.copyForwards(u8, bytes, mia_enc.data());
        \\    return bytes;
        \\}}
        \\
        \\
    , .{});
    try verkisto.flush();

    try verkisto.print(
        \\fn seriigiTiponAlBin(allocator: all.Allocator, comptime T: type, value: * const T, b_formato: BinaraFormato) ![]const u8 {{
        \\    var parsed: []const u8 = undefined;
        \\    switch (b_formato) {{
        \\        .BF_PROTOBUF => {{
        \\            parsed = try seriigiTipon(allocator, T, value);
        \\        }},
        \\        .BF_BASE64 => {{
        \\            const binaraj_bitoj = try seriigiTipon(allocator, T, value);
        \\            defer allocator.free(binaraj_bitoj);
        \\
        \\            const enc=std.base64.standard.Encoder;
        \\            const base64_longo = enc.calcSize(binaraj_bitoj.len);
        \\            const base64_bitoj = try allocator.alloc(u8, base64_longo);
        \\            parsed = enc.encode(base64_bitoj, binaraj_bitoj);
        \\        }},
        \\        .BF_BINPB2TEKSTO_HEX => {{
        \\            const binaraj_bitoj = try seriigiTipon(allocator, T, value);
        \\            defer allocator.free(binaraj_bitoj);
        \\
        \\            var bin2teksto_bitoj:std.ArrayList(u8)= .empty;
        \\            const hex = "0123456789ABCDEF";
        \\            try bin2teksto_bitoj.print(allocator,"{{{{ ", .{{}});
        \\            for (binaraj_bitoj, 0..) |val, i| {{
        \\                const hi: u8 = @intCast((val >> 4) & 0xF);
        \\                const lo: u8 = @intCast(val & 0xF);
        \\                try bin2teksto_bitoj.print(allocator,"0x{{c}}{{c}}{{s}} ", .{{ hex[hi], hex[lo], if (i!=binaraj_bitoj.len-1) "," else ""}});
        \\
        \\                if ((i + 1) % 20 == 0) try bin2teksto_bitoj.print(allocator,"\n", .{{}});
        \\            }}
        \\            try bin2teksto_bitoj.print(allocator,"}}}}", .{{}});
        \\            parsed = try bin2teksto_bitoj.toOwnedSlice(allocator);
        \\        }},
        \\        .BF_BINPB2TEKSTO_DEC => {{
        \\            const binaraj_bitoj = try seriigiTipon(allocator, T, value);
        \\            defer allocator.free(binaraj_bitoj);
        \\
        \\            var bin2teksto_bitoj:std.ArrayList(u8)= .empty;
        \\            bin2teksto_bitoj.print(allocator,"{{any}}",.{{binaraj_bitoj}}) catch |err| {{
        \\                std.debug.print("eraro dum bin2teksto: {{}}\n", .{{err}});
        \\                return err;
        \\            }};
        \\            parsed = try bin2teksto_bitoj.toOwnedSlice(allocator);
        \\        }},    
        \\        else => {{
        \\            return error.UnsupportedFormat;
        \\        }},
        \\    }}
        \\
        \\    return parsed;
        \\}}
        \\
        \\
    , .{});
    try verkisto.flush();

    try verkisto.print(
        \\fn seriigiTiponAlDosiero(allocator: all.Allocator, comptime T: type, value: * const T, b_formato: BinaraFormato, path: []const u8) !void {{
        \\    const teksto = try seriigiTiponAlBin(allocator, T, value, b_formato);
        \\    defer allocator.free(teksto);
        \\
        \\    var dosiero = try std.fs.cwd().createFile(path, .{{ .truncate = true }});
        \\    defer dosiero.close();
        \\    try dosiero.writeAll(teksto);
        \\}}
        \\
        \\
    , .{});
    try verkisto.flush();

    //////////////////////////////////////////////
    //// Deseriigi Binaran Tipon
    //////////////////////////////////////////////

    try verkisto.print(
        \\//////////////////////////////////////////////
        \\//// Deseriigi Binaran Tipon
        \\//////////////////////////////////////////////
        \\
        \\
    , .{});
    try verkisto.flush();

    try verkisto.print(
        \\fn deseriigiTipon(allocator: all.Allocator, comptime T: type, input: []const u8) !T {{
        \\    var mia_dec = DecodeBuffer.init(allocator, input, 0, -1);
        \\    defer mia_dec.deinit();
        \\
        \\    const obj = try T.deseriigi(allocator, &mia_dec, null);
        \\    return obj;
        \\}}
        \\
        \\
    , .{});
    try verkisto.flush();

    try verkisto.print(
        \\fn deseriigiTiponElBin(allocator: all.Allocator, comptime T: type, input: []const u8, b_formato: BinaraFormato) !T {{
        \\    var parsed: []const u8 = undefined;
        \\    switch (b_formato) {{
        \\        .BF_PROTOBUF => {{
        \\            parsed = input;
        \\        }},
        \\        .BF_BASE64 => {{
        \\            const dec=std.base64.standard.Decoder;
        \\            const base64_decoded_longo = try dec.calcSizeForSlice(input);
        \\            const base64_decoded = try allocator.alloc(u8, base64_decoded_longo);
        \\
        \\            dec.decode(base64_decoded,input) catch |err| {{
        \\                std.debug.print("eraro dum deseriigo: {{}}\n", .{{err}});
        \\                return err;
        \\            }};
        \\            parsed = base64_decoded;
        \\        }},
        \\        .BF_BINPB2TEKSTO_HEX, .BF_BINPB2TEKSTO_DEC => {{
        \\            var it = std.mem.tokenizeAny(u8, input, "{{}}, \n\r\t");
        \\            var bytes: std.ArrayList(u8) = .empty;
        \\            while (it.next()) |tok| {{
        \\                const val = std.fmt.parseUnsigned(u8, tok, 0) catch |err| {{
        \\                    std.debug.print("eraro dum parseInt dec: {{}}\n", .{{err}});
        \\                    return err;
        \\                }};
        \\                bytes.append(allocator, val) catch |err| {{
        \\                    std.debug.print("eraro dum append dec: {{}}\n", .{{err}});
        \\                    return err;
        \\                }};
        \\            }}
        \\            parsed = try bytes.toOwnedSlice(allocator);
        \\        }},
        \\        else => {{
        \\            return error.UnsupportedFormat;
        \\        }},
        \\    }}
        \\
        \\    return deseriigiTipon(allocator, T, parsed);
        \\}}
        \\
        \\
    , .{});
    try verkisto.flush();

    try verkisto.print(
        \\fn deseriigiTiponElDosiero(allocator: all.Allocator, comptime T: type, path: []const u8, b_formato: BinaraFormato) !T {{
        \\    var dosiero = try std.fs.cwd().openFile(path, .{{}});
        \\    defer dosiero.close();
        \\
        \\    const dosiera_long = try dosiero.getEndPos();
        \\    var enhavo = allocator.alloc(u8, dosiera_long + 1) catch return error.OutOfMemory;
        \\    defer allocator.free(enhavo);
        \\
        \\    _ = try dosiero.readAll(enhavo[0..dosiera_long]);
        \\    enhavo[dosiera_long] = 0;
        \\
        \\    return deseriigiTiponElBin(allocator, T, enhavo[0..dosiera_long :0], b_formato);
        \\}}
        \\
        \\
    , .{});
    try verkisto.flush();

    try verkisto.print(
        \\//////////////////////////////////////////////
        \\/// //////////////////////////////////////////
        \\/// //////////////////////////////////////////
        \\//////////////////////////////////////////////
        \\
        \\
    , .{});
    try verkisto.flush();

    //////////////////////////////////////////////
    //// Seriigi Binaran Tipon
    //////////////////////////////////////////////

    try verkisto.print(
        \\const zon = std.zon;
        \\
        \\fn parseEnumValue(comptime E: type, tok: []const u8) !E {{
        \\    if (std.meta.stringToEnum(E, tok)) |v| return v;
        \\    const n = try std.fmt.parseInt(u64, tok, 10);
        \\    return try std.meta.intToEnum(E, n);
        \\}}
        \\
        \\fn legiSubProtobufTeksto(allocator: all.Allocator, it: *TokenIterType) ![]const u8 {{
        \\    var bufro: std.ArrayList(u8) = .empty;
        \\    var depth: usize = 1;
        \\
        \\    while (it.next()) |tok| {{
        \\        if (equal(u8, tok, "{{")) {{
        \\            depth += 1;
        \\            try bufro.print(allocator, "{{ ", .{{}});
        \\            continue;
        \\        }}
        \\
        \\        if (equal(u8, tok, "}}")) {{
        \\            depth -= 1;
        \\            if (depth == 0) break;
        \\            try bufro.print(allocator, "}} ", .{{}});
        \\            continue;
        \\        }}
        \\
        \\        try bufro.print(allocator, "{{s}} ", .{{tok}});
        \\    }}
        \\
        \\    if (depth != 0) return error.InvalidFormat;
        \\    return try bufro.toOwnedSlice(allocator);
        \\}}
        \\
        \\pub const TekstaFormato = enum(u32) {{
        \\    TF_ZIG_ZON,
        \\    TF_PROTOBUF,
        \\    TF_JSON,
        \\    TF_ASN1,
        \\}};
        \\
        \\//////////////////////////////////////////////
        \\//// Skribi Tipon Al Teksto
        \\//////////////////////////////////////////////
        \\
        \\pub fn skribiTiponAlTeksto(allocator: all.Allocator, comptime T: type, value: *T, t_formato: TekstaFormato) ![]const u8 {{
        \\    var skribila_asignilo = std.Io.Writer.Allocating.init(allocator);
        \\
        \\    const self = @as(T, value.*);
        \\    var bytes: []const u8 = undefined;
        \\    switch (t_formato) {{
        \\        .TF_ZIG_ZON => {{
        \\            zon.stringify.serialize(self, .{{}}, &skribila_asignilo.writer) catch |err| {{
        \\                std.debug.print("eraro dum seriigo: {{}}\n", .{{err}});
        \\                return err;
        \\            }};
        \\            bytes = skribila_asignilo.toOwnedSlice() catch |err| {{
        \\                std.debug.print("eraro dum seriigo: {{}}\n", .{{err}});
        \\               return err;
        \\            }};
        \\        }},
        \\        .TF_JSON => {{
        \\            std.json.fmt(self, .{{ .whitespace = .indent_3 }}).format(&skribila_asignilo.writer) catch |err| {{
        \\                std.debug.print("eraro dum seriigo: {{}}\n", .{{err}});
        \\                return err;
        \\            }};
        \\            bytes = skribila_asignilo.toOwnedSlice() catch |err| {{
        \\                std.debug.print("eraro dum seriigo: {{}}\n", .{{err}});
        \\               return err;
        \\            }};
        \\        }},
        \\        .TF_PROTOBUF => {{
        \\            bytes = self.skribiAlProtobufTeksto(allocator, "") catch |err| {{
        \\                std.debug.print("eraro dum seriigo: {{}}\n", .{{err}});
        \\                return err;
        \\            }};
        \\        }},
        \\        else => {{
        \\            return error.UnsupportedFormat;
        \\        }},
        \\    }}
        \\
        \\    return bytes;
        \\}}
        \\
        \\fn skribiTiponAlDosiero(allocator: all.Allocator, comptime T: type, value: *T, path: []const u8, t_formato: TekstaFormato) !void {{
        \\    const teksto = try skribiTiponAlTeksto(allocator, T, value, t_formato);
        \\    defer allocator.free(teksto);
        \\
        \\    var dosiero = try std.fs.cwd().createFile(path, .{{ .truncate = true }});
        \\    defer dosiero.close();
        \\    try dosiero.writeAll(teksto);
        \\}}
        \\
    , .{});
    try verkisto.flush();

    try verkisto.print(
        \\
        \\//////////////////////////////////////////////
        \\//// Legi Tipon El Teksto
        \\//////////////////////////////////////////////
        \\
        \\pub fn legiTiponElTeksto(allocator: all.Allocator, comptime T: type, input: []const u8, t_formato: TekstaFormato) !T {{
        \\    var parsed: T = undefined;
        \\    switch (t_formato) {{
        \\        .TF_ZIG_ZON => {{
        \\            parsed = zon.parse.fromSlice(T, allocator, @ptrCast(input), null, .{{}}) catch |err| {{
        \\                std.debug.print("eraro dun deseriigo: {{}}\n", .{{err}});
        \\                return err;
        \\            }};
        \\        }},
        \\        .TF_JSON => {{
        \\            parsed = std.json.parseFromSliceLeaky(T, allocator, input, .{{ .ignore_unknown_fields = false, .allocate = .alloc_always }}) catch |err| {{
        \\                std.debug.print("eraro dun deseriigo: {{}}\n", .{{err}});
        \\                return err;
        \\            }};
        \\        }},
        \\        .TF_PROTOBUF => {{
        \\            var it: TokenIterType = std.mem.tokenizeAny(u8, input, ":\", \n\r\t");
        \\            parsed = T.legiElProtobufTeksto(allocator, &it) catch |err| {{
        \\                std.debug.print("eraro dun deseriigo: {{}}\n", .{{err}});
        \\                return err;
        \\            }};
        \\            _=it.peek();
        \\        }},
        \\        else => {{
        \\            return error.UnsupportedFormat;
        \\        }},
        \\    }}
        \\
        \\    return parsed;
        \\}}
        \\
        \\pub fn legiTiponElDosiero(allocator: all.Allocator, comptime T: type, path: []const u8, t_formato: TekstaFormato) !T {{
        \\    var dosiero = try std.fs.cwd().openFile(path, .{{}});
        \\    defer dosiero.close();
        \\
        \\    const dosiera_long = try dosiero.getEndPos();
        \\    var enhavo = allocator.alloc(u8, dosiera_long + 1) catch return error.OutOfMemory;
        \\    defer allocator.free(enhavo);
        \\
        \\    _ = try dosiero.readAll(enhavo[0..dosiera_long]);
        \\    enhavo[dosiera_long] = 0;
        \\
        \\    return legiTiponElTeksto(allocator, T, enhavo[0..dosiera_long :0], t_formato);
        \\}}
        \\
    , .{});
    try verkisto.flush();
}

/////////////////////////////////////
/// Seriigi kaj Deseriigi Funkcioj:
/// -Teksta formato: ZON, Protobuf, JSON
// /     - skribiAlTeksto: generica por ZON, Protobuf, JSON
// /     - legiElTeksto:  generica por ZON, Protobuf, JSON
// /     - skribiSkribiAlPBTeksto
/// -Binara formato: Protobuf
///     - skribiSeriigi
///     - skribiDeseriigi
/////////////////////////////////////

fn skribiAlTeksto(msg: prs.Message, ind: []const u8) !void {
    // /////////////
    // Skribi funkcion por seriigi al teksta bufro
    try verkisto.print(
        \\{s}    pub fn skribiAlTeksto(self: *{s}, allocator: all.Allocator, t_formato: TekstaFormato) ![]const u8 {{
        \\{s}        return try skribiTiponAlTeksto(allocator, {s}, @as(*{s}, self), t_formato);
        \\{s}    }}
        \\
    , .{ ind, msg.name, ind, msg.name, msg.name, ind });
    try verkisto.print("\n", .{});

    // /////////////
    // Skribi funkcion por seriigi al dosiero
    try verkisto.print(
        \\{s}    pub fn skribiAlDosiero(self: *{s}, allocator: all.Allocator, path: []const u8, t_formato: TekstaFormato) !void {{
        \\{s}        try skribiTiponAlDosiero(allocator, {s}, @as(*{s}, self), path, t_formato);
        \\{s}    }}
        \\
    , .{ ind, msg.name, ind, msg.name, msg.name, ind });
    try verkisto.print("\n", .{});
}

fn legiElTeksto(msg: prs.Message, ind: []const u8) !void {
    // /////////////
    // Skribi funkcion por deseriigi el teksta bufro
    try verkisto.print(
        \\{s}    pub fn legiElTeksto(allocator: all.Allocator, input: []const u8, t_formato: TekstaFormato) !{s} {{
        \\{s}        return try legiTiponElTeksto(allocator, {s}, input, t_formato);
        \\{s}    }}
        \\
    , .{ ind, msg.name, ind, msg.name, ind });
    try verkisto.print("\n", .{});

    // /////////////
    // Skribi funkcion por deseriigi el dosiero
    try verkisto.print(
        \\{s}    pub fn legiElDosiero(allocator: all.Allocator, path: []const u8, t_formato: TekstaFormato) !{s} {{
        \\{s}        return try legiTiponElDosiero(allocator, {s}, path, t_formato);
        \\{s}    }}
        \\
    , .{ ind, msg.name, ind, msg.name, ind });
    try verkisto.print("\n", .{});
}

fn skribiSkribiAlPBTeksto(msg: prs.Message, ind: []const u8) !void {
    try verkisto.print(
        \\{s}    fn skribiAlProtobufTeksto(self: *const {s}, allocator: all.Allocator,ind: []const u8) ![]const u8 {{
        \\{s}        var bufro:std.ArrayList(u8)= .empty;
        \\
        \\
    , .{ ind, msg.name, ind });

    for (msg.fields) |f| {
        if (f.label_enum == .LABEL_REPEATED) {
            try verkisto.print(
                \\{s}        for(self.{s}) |obj| {{
                \\{s}
            , .{
                ind, f.name, "    ",
            });
        } else if (f.label_enum == .LABEL_OPTIONAL) {
            try verkisto.print(
                \\{s}        if( self.{s} ) |val|  {s}
                \\{s}
            , .{ ind, f.name, if (f.field_type_enum == .TYPE_MESSAGE) "{" else "", "    " });
        }

        var needs_indent = false;
        if (f.field_type_enum == .TYPE_MESSAGE and
            !estasImportitaTipo(f.field_type))
        {
            needs_indent = true;
        }

        if (f.field_type_enum == .TYPE_MESSAGE) {
            if (needs_indent) {
                try verkisto.print(
                    \\{s}        const indent = std.mem.concatWithSentinel(allocator, u8, &[_][]const u8{{ ind, "    " }}, 0) catch unreachable;
                    \\{s}            defer allocator.free(indent);
                    \\
                , .{ ind, ind });
            }

            if (estasImportitaTipo(f.field_type)) {
                if (f.label_enum == .LABEL_OPTIONAL) {
                    try verkisto.print(
                        \\{s}        var {s}_item = val;
                        \\{s}        const {s}_text = try {s}_item.skribiAlTeksto(allocator, .TF_PROTOBUF);
                        \\{s}        defer allocator.free({s}_text);
                        \\{s}        try bufro.print(allocator, "{{s}}{s} {{{{\n{{s}}{{s}}}}}}\n", .{{ ind, {s}_text, ind }});
                        \\
                    , .{
                        ind,    f.name,
                        ind,    f.name,
                        f.name, ind,
                        f.name, ind,
                        f.name, f.name,
                    });
                } else if (f.label_enum == .LABEL_REPEATED) {
                    try verkisto.print(
                        \\{s}        var {s}_item = obj;
                        \\{s}        const {s}_text = try {s}_item.skribiAlTeksto(allocator, .TF_PROTOBUF);
                        \\{s}        defer allocator.free({s}_text);
                        \\{s}        try bufro.print(allocator, "{{s}}{s} {{{{\n{{s}}{{s}}}}}}\n", .{{ ind, {s}_text, ind }});
                        \\
                    , .{
                        ind,    f.name,
                        ind,    f.name,
                        f.name, ind,
                        f.name, ind,
                        f.name, f.name,
                    });
                } else {
                    try verkisto.print(
                        \\{s}        var {s}_item = self.{s};
                        \\{s}        const {s}_text = try {s}_item.skribiAlTeksto(allocator, .TF_PROTOBUF);
                        \\{s}        defer allocator.free({s}_text);
                        \\{s}        try bufro.print(allocator, "{{s}}{s} {{{{\n{{s}}{{s}}}}}}\n", .{{ ind, {s}_text, ind }});
                        \\
                    , .{
                        ind,    f.name, f.name,
                        ind,    f.name, f.name,
                        ind,    f.name, ind,
                        f.name, f.name,
                    });
                }
            } else if (f.label_enum == .LABEL_OPTIONAL) {
                try verkisto.print(
                    \\{s}            const {s}_text = try val.skribiAlProtobufTeksto(allocator, indent);
                    \\{s}            defer allocator.free({s}_text);
                    \\
                    \\{s}            try bufro.print(allocator, "{{s}}{s} {{{{\n{{s}}{{s}}}}}}\n", .{{ ind, {s}_text, ind }});
                    \\
                , .{
                    ind,    f.name,
                    ind,    f.name,
                    ind,    f.name,
                    f.name,
                });
            } else {
                try verkisto.print(
                    \\{s}            const {s}_text = try {s}{s}.skribiAlProtobufTeksto(allocator, indent);
                    \\{s}            defer allocator.free({s}_text);
                    \\
                    \\{s}            try bufro.print(allocator, "{{s}}{s} {{{{\n{{s}}{{s}}}}}}\n", .{{ ind, {s}_text, ind }});
                    \\
                , .{
                    ind,                                                  f.name,
                    if (f.label_enum == .LABEL_REPEATED) "" else "self.", if (f.label_enum == .LABEL_REPEATED) "obj" else f.name,
                    ind,                                                  f.name,
                    ind,                                                  f.name,
                    f.name,
                });
            }
        } else {
            if (f.field_type_enum == .TYPE_ENUM) {
                if (f.label_enum == .LABEL_REPEATED) {
                    try verkisto.print(
                        \\{s}        try bufro.print(allocator, "{{s}}{s}: {{s}}\n", .{{ ind, @tagName(obj) }});
                        \\
                    , .{
                        ind, f.name,
                    });
                } else if (f.label_enum == .LABEL_OPTIONAL) {
                    try verkisto.print(
                        \\{s}        try bufro.print(allocator, "{{s}}{s}: {{s}}\n", .{{ ind, @tagName(val) }});
                        \\
                    , .{
                        ind, f.name,
                    });
                } else {
                    try verkisto.print(
                        \\{s}        try bufro.print(allocator, "{{s}}{s}: {{s}}\n", .{{ ind, @tagName(self.{s}) }});
                        \\
                    , .{
                        ind,
                        f.name,
                        f.name,
                    });
                }
            } else if (f.label_enum == .LABEL_REPEATED) {
                try verkisto.print(
                    \\{s}        try bufro.print(allocator,"{{s}}{s}: {s}{{{s}}}{s}\n",.{{ind, obj }});
                    \\
                , .{
                    ind,
                    f.name,
                    if (f.field_type_enum == .TYPE_STRING) "\\\"" else "",
                    if (f.field_type_enum == .TYPE_STRING) "s" else "any",
                    if (f.field_type_enum == .TYPE_STRING) "\\\"" else "",
                });
            } else if (f.label_enum == .LABEL_OPTIONAL) {
                try verkisto.print(
                    \\{s}        try bufro.print(allocator,"{{s}}{s}: {s}{{{s}}}{s}\n",.{{ ind, val }});
                    \\
                , .{
                    ind,
                    f.name,
                    if (f.field_type_enum == .TYPE_STRING) "\\\"" else "",
                    if (f.field_type_enum == .TYPE_STRING) "s" else "any",
                    if (f.field_type_enum == .TYPE_STRING) "\\\"" else "",
                });
            } else {
                try verkisto.print(
                    \\{s}        try bufro.print(allocator,"{{s}}{s}: {s}{{{s}}}{s}\n",.{{ind, self.{s} }});
                    \\
                , .{
                    ind,
                    f.name,
                    if (f.field_type_enum == .TYPE_STRING) "\\\"" else "",
                    if (f.field_type_enum == .TYPE_STRING) "s" else "any",
                    if (f.field_type_enum == .TYPE_STRING) "\\\"" else "",
                    f.name,
                });
            }
        }
        if (f.label_enum == .LABEL_REPEATED or
            (f.label_enum == .LABEL_OPTIONAL and f.field_type_enum == .TYPE_MESSAGE))
        {
            try verkisto.print(
                \\{s}        }}
                \\
            , .{ind});
        }
    }

    if (msg.oneofs.len > 0) {
        try skribiPBTekstoOneOfs(msg, ind);
    }

    try verkisto.print(
        \\
        \\{s}        return bufro.toOwnedSlice(allocator);
        \\{s}    }}
        \\
    , .{ ind, ind });
    try verkisto.print("\n", .{});
}

fn skribiLegiElPBTeksto(msg: prs.Message, ind: []const u8) !void {
    // const indent = std.mem.concatWithSentinel(std.heap.page_allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;

    try verkisto.print(
        \\{s}    fn legiElProtobufTeksto(allocator: all.Allocator, it: *TokenIterType) !{s} {{
        \\{s}        var mia_Mesagho= try {s}.initDefault(allocator); 
        \\
        \\
    , .{ ind, msg.name, ind, msg.name });

    for (msg.fields) |field| {
        if (field.label_enum == .LABEL_REPEATED) {
            try verkisto.print(
                \\{s}        var {s}_list: std.ArrayList({s}) = .empty; 
            , .{
                ind, field.name, auks.mapiProtoTiponAlZig(field.field_type),
            });
        }
    }

    try verkisto.print(
        \\
        \\{s}        while (it.next()) |tok| {{
        \\{s}            if( equal(u8, tok, "}}" ) ) break;
        \\{s}            const val = it.next() orelse return error.InvalidFormat;
        \\
        \\
    , .{ ind, ind, ind });

    for (msg.fields) |field| {
        try verkisto.print(
            \\{s}            if( equal(u8, tok, "{s}" ) ) {{ 
            \\
        , .{ ind, field.name });

        if (field.field_type_enum == .TYPE_MESSAGE) {
            if (estasImportitaTipo(field.field_type)) {
                try verkisto.print(
                    \\{s}                const sub_text = try legiSubProtobufTeksto(allocator, it);
                    \\{s}                const sub_msg = try {s}.legiElTeksto(allocator, sub_text, .TF_PROTOBUF);
                    \\
                , .{
                    ind,
                    ind,
                    auks.mapiProtoTiponAlZig(field.field_type),
                });
            } else {
                try verkisto.print(
                    \\{s}                const sub_msg = try {s}.legiElProtobufTeksto(allocator, it); 
                    \\
                , .{
                    ind,
                    field.field_type,
                });
            }
            if (field.label_enum == .LABEL_REPEATED) {
                try verkisto.print(
                    \\{s}                try {s}_list.append(allocator, sub_msg); 
                    \\
                , .{ ind, field.name });
            } else {
                try verkisto.print(
                    \\{s}                mia_Mesagho.{s} = sub_msg; 
                    \\
                , .{ ind, field.name });
            }
        } else {
            if (field.label_enum == .LABEL_REPEATED) {
                try verkisto.print("{s}                try {s}_list.append(allocator, ", .{ ind, field.name });
                auks.printParseValueExpr(
                    verkisto,
                    field.field_type_enum,
                    field.field_type,
                    "val",
                );
                try verkisto.print(");\n", .{});
            } else {
                try verkisto.print(
                    \\{s}                
                , .{ind});
                if (field.field_type_enum == .TYPE_ENUM) {
                    try verkisto.print(
                        "mia_Mesagho.{s} = parseEnumValue({s}, val) catch (std.meta.intToEnum({s}, 0) catch unreachable);\n",
                        .{ field.name, field.field_type, field.field_type },
                    );
                } else {
                    auks.printParseType(verkisto, field.field_type_enum, field.name);
                }
            }
        }

        try verkisto.print( // Fino de la if(tok
            \\{s}                continue;
            \\{s}            }}
            \\
        , .{ ind, ind });
    }

    if (msg.oneofs.len > 0) {
        try skribiLegiPBTekstoOneOfs(msg, ind);
    }

    try verkisto.print( // Fino de la while(it.next())
        \\{s}        }}
        \\
    , .{ind});

    for (msg.fields) |field| {
        if (field.label_enum == .LABEL_REPEATED) {
            try verkisto.print(
                \\{s}        mia_Mesagho.{s} = try {s}_list.toOwnedSlice(allocator); 
                \\
            , .{
                ind, field.name, field.name,
            });
        }
    }

    try verkisto.print(
        \\
        \\{s}        return mia_Mesagho;
        \\{s}    }}
        \\
    , .{ ind, ind });

    try verkisto.print("\n", .{});
}

fn skribiSeriigi(msg: prs.Message, ind: []const u8) !void {
    try verkisto.print(
        \\    {s}pub fn seriigiAlBin(self: *const {s}, allocator: all.Allocator, b_formato: BinaraFormato) ![]const u8 {{
        \\    {s}    return try seriigiTiponAlBin(allocator, {s}, self, b_formato);
        \\    {s}}}
        \\
        \\
    , .{
        ind, msg.name, // fn
        ind, msg.name, // return
        ind, // }
    });

    try verkisto.print(
        \\    {s}pub fn seriigiAlDosiero(self: *const {s}, allocator: all.Allocator, path: []const u8, b_formato: BinaraFormato) !void {{
        \\    {s}    return try seriigiTiponAlDosiero(allocator, {s}, @as(*{s}, self), path, b_formato);
        \\    {s}}}
        \\
        \\
    , .{
        ind, msg.name, // fn
        ind, msg.name, msg.name, // return
        ind, // }
    });

    var uses_allocator = false;
    for (msg.fields) |f| {
        if (f.field_type_enum == .TYPE_MESSAGE) {
            uses_allocator = true;
            break;
        }
    }

    // -----------------------------------------
    // OneOfs
    // -----------------------------------------
    if (!uses_allocator) {
        for (msg.oneofs) |oneof_decl| {
            for (oneof_decl.fields) |field| {
                if (field.field_type_enum == .TYPE_MESSAGE or
                    field.field_type_enum == .TYPE_STRING or
                    field.field_type_enum == .TYPE_BYTES)
                {
                    uses_allocator = true;
                    break;
                }
            }

            if (uses_allocator) break;
        }
    }

    try verkisto.print(
        \\    {s}fn seriigi(self: *const {s}, allocator: all.Allocator, buffer: *EncodeBuffer) !usize {{
        \\ 
        \\
    , .{
        ind, msg.name,
    });

    if (!uses_allocator) {
        try verkisto.print(
            \\    {s}    _ = allocator;
            \\
        , .{ind});
    }

    try verkisto.print(
        \\    {s}    var tuta_longo: usize = 0;
        \\ 
        \\
    , .{
        ind,
    });

    // -----------------------------------------
    // OneOfs
    // -----------------------------------------
    if (msg.oneofs.len > 0) {
        try skribiSeriigiOneOfs(msg, ind);
    }

    const nf = msg.fields.len;
    for (msg.fields, 0..) |_, i| {
        const field = msg.fields[nf - 1 - i];
        const field_name = field.name;
        const field_type_enum = field.field_type_enum;
        const base_wire_type = auks.getWireType(field_type_enum);
        const is_packed = field.label_enum == .LABEL_REPEATED and
            field.packed_value and
            auks.estasPackable(field_type_enum);
        const wire_type = if (is_packed) 2 else base_wire_type;
        const default_value: []const u8 = field.default_value orelse "null";
        const packed_value = field.packed_value;

        const estas_variabla_longo = auks.estasLongaVar(field_type_enum);
        const havas_default = field.default_value != null;

        switch (field.label_enum) {
            .LABEL_OPTIONAL => {
                if (!havas_default and !estas_variabla_longo) {
                    skribiOptionalNoDefaultNoVarLong(ind, field_name, field_type_enum, field.number, wire_type) catch {};
                    continue;
                }

                if (havas_default and !estas_variabla_longo) {
                    skribiOptionalDefaultNoVarLong(ind, field_name, field_type_enum, field.number, wire_type, default_value) catch {};
                    continue;
                }

                if (!havas_default and estas_variabla_longo) {
                    skribiOptionalNoDefaultVarLong(ind, field_name, field_type_enum, field.number, wire_type) catch {};
                    continue;
                }

                if (havas_default and estas_variabla_longo) {
                    skribiOptionalDefaultVarLong(ind, field_name, field_type_enum, field.number, wire_type, default_value) catch {};
                    continue;
                }
            },
            .LABEL_REQUIRED => {
                if (!havas_default and !estas_variabla_longo) {
                    skribiRequiredNoDefaultNoVarLong(ind, field_name, field_type_enum, field.number, wire_type) catch {};
                    continue;
                }

                if (havas_default and !estas_variabla_longo) {
                    skribiRequiredDefaultNoVarLong(ind, field_name, field_type_enum, field.number, wire_type, default_value) catch {};
                    continue;
                }

                if (!havas_default and estas_variabla_longo) {
                    skribiRequiredNoDefaultVarLong(ind, field_name, field_type_enum, field.number, wire_type) catch {};
                    continue;
                }

                if (havas_default and estas_variabla_longo) {
                    skribiRequiredDefaultVarLong(ind, field_name, field_type_enum, field.number, wire_type, default_value) catch {};
                    continue;
                }
            },
            .LABEL_REPEATED => {
                if (!havas_default and !estas_variabla_longo) {
                    skribiRepeatedNoDefaultNoVarLong(ind, field_name, field_type_enum, field.number, wire_type, packed_value) catch {};
                    continue;
                }

                if (!havas_default and estas_variabla_longo) {
                    skribiRepeatedNoDefaultVarLong(ind, field_name, field_type_enum, field.field_type, field.number, wire_type) catch {};
                    continue;
                }
            },
        }
    }
    try verkisto.print("    {s}    return tuta_longo;\n    {s}}}\n\n", .{ ind, ind });

    try verkisto.flush();
}

fn skribiDeseriigi(msg: prs.Message, ind: []const u8) !void {
    const indent = std.mem.concatWithSentinel(std.heap.page_allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;

    try verkisto.print(
        \\{s}pub fn deseriigiElBin(allocator: all.Allocator,input: []const u8, b_formato: BinaraFormato) !{s} {{
        \\{s}    return try deseriigiTiponElBin(allocator, {s}, input, b_formato);
        \\{s}}}
        \\
        \\
    , .{
        indent, msg.name, // fn
        indent, msg.name, // return
        indent, // }
    });

    try verkisto.print(
        \\{s}    pub fn deseriigiElDosiero(allocator: all.Allocator, path: [:0]const u8, b_formato: BinaraFormato) !{s} {{
        \\{s}        return try deseriigiTiponElDosiero(allocator, {s}, path, b_formato);
        \\{s}    }}
        \\
        \\
    , .{ ind, msg.name, ind, msg.name, ind });

    try verkisto.print(
        \\{s}fn deseriigi(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !{s} {{
        \\{s}    var mia_Mesagho= try {s}.initDefault(allocator);
        \\
        \\{s}    var end: usize = undefined;
        \\{s}    if (data_length) |val|
        \\{s}        end = buffer.read_index + val
        \\{s}    else
        \\{s}        end = buffer.buffer.len;
        \\
        \\
    , .{
        indent, msg.name,
        indent, msg.name,
        indent, indent,
        indent, indent,
        indent,
    });

    for (msg.fields) |field| {
        if (field.label_enum == .LABEL_REPEATED) {
            try verkisto.print(
                \\{s}    var {s}_list: std.ArrayList({s}) = .empty; 
                \\
            , .{
                indent, field.name, auks.mapiProtoTiponAlZig(field.field_type),
            });
        }
    }

    try verkisto.print(
        \\
        \\{s}    while (buffer.read_index < end) {{
        \\{s}        const key: u64 = buffer.decodeVarint() catch 0 ;    
        \\{s}        const wire_type = key & 0x7;  
        \\{s}        const field_number = key >> 3;
        \\
        \\
    , .{
        indent, // while
        indent,
        indent,
        indent,
    });

    var unua = true;
    if (msg.oneofs.len > 0) {
        try skribiDeseriigiOneOfs(msg, indent, &unua);
    }
    const field_nums = msg.fields.len;
    for (msg.fields, 0..) |field, i| {
        const field_name = field.name;
        const field_type = field.field_type;
        const field_type_enum = field.field_type_enum;
        const field_label = field.label_enum;
        const field_number = field.number;
        const base_wire_type = auks.getWireType(field_type_enum);
        const is_packed = field.label_enum == .LABEL_REPEATED and
            field.packed_value and
            auks.estasPackable(field_type_enum);
        const wire_type = if (is_packed) 2 else base_wire_type;

        try verkisto.print(
            \\{s}        {s} ( field_number == {d} and wire_type == {d} ) 
            \\
        , .{
            indent, if (unua) "if" else "else if", field_number, wire_type,
        });

        // ====================================

        // switch (field_label) {
        //     .LABEL_REPEATED => {
        //         if (field.packed_value and auks.estasPackable(field_type_enum)) {
        //             const typename_len = std.mem.concatWithSentinel(std.heap.page_allocator, u8, &[_][]const u8{ field_name, "_len" }, 0) catch unreachable;
        //             try verkisto.print(
        //                 \\{s}        {{
        //                 \\{s}            const {s}_len = try buffer.decodeVarint();
        //                 \\{s}            const {s}_end = buffer.read_index + {s}_len;
        //                 \\{s}            while (buffer.read_index < {s}_end)
        //                 \\{s}                try {s}_list.append( allocator, try
        //             , .{
        //                 indent,
        //                 indent, field_name, // const _len
        //                 indent, field_name, field_name, // const _end
        //                 indent, field_name, // while
        //                 indent, field_name, // append
        //             });
        //             auks.printDecodeMethod(verkisto, field_type_enum, field_type, "", typename_len);
        //             try verkisto.print(
        //                 \\ );
        //                 \\{s}            if (buffer.read_index != {s}_end) return error.AllocationFailed;
        //                 \\{s}        }}
        //                 \\
        //             , .{
        //                 indent, field_name,
        //                 indent,
        //             });
        //         } else {
        //             try verkisto.print(
        //                 \\{s}            {{ try {s}_list.append( allocator, try
        //             , .{
        //                 indent, field_name,
        //             });
        //             auks.printDecodeMethod(verkisto, field_type_enum, if (field_type_enum == .TYPE_MESSAGE or field_type_enum == .TYPE_ENUM) field_type else "", "", "try buffer.decodeVarint()");
        //             try verkisto.print(" ); }}\n", .{});
        //         }
        //     },
        //     .LABEL_REQUIRED => {
        //         try verkisto.print(
        //             \\{s}            mia_Mesagho.{s} = try
        //         , .{
        //             indent, field.name,
        //         });
        //         auks.printDecodeMethod(verkisto, field_type_enum, if (field_type_enum == .TYPE_MESSAGE or field_type_enum == .TYPE_ENUM) field_type else "", if (i == field_nums - 1) ";\n" else "\n", "try buffer.decodeVarint()");
        //     },
        //     else => {
        //         try verkisto.print(
        //             \\{s}            mia_Mesagho.{s} = try
        //         , .{
        //             indent, field.name,
        //         });
        //         auks.printDecodeMethod(verkisto, field_type_enum, if (field_type_enum == .TYPE_MESSAGE or field_type_enum == .TYPE_ENUM) field_type else "", if (i == field_nums - 1) ";\n" else "\n", "try buffer.decodeVarint()");
        //     },
        // }
        // ====================================
        switch (field_label) {
            .LABEL_REPEATED => {
                // packed repeated
                if (field.packed_value and auks.estasPackable(field_type_enum)) {
                    const typename_len = std.mem.concatWithSentinel(
                        std.heap.page_allocator,
                        u8,
                        &[_][]const u8{ field_name, "_len" },
                        0,
                    ) catch unreachable;

                    try verkisto.print(
                        \\{s}        {{
                        \\{s}            const {s}_len = try buffer.decodeVarint();
                        \\{s}            const {s}_end = buffer.read_index + {s}_len;
                        \\{s}            while (buffer.read_index < {s}_end)
                        \\{s}                try {s}_list.append( allocator, try 
                    , .{
                        indent,
                        indent,
                        field_name,
                        indent,
                        field_name,
                        field_name,
                        indent,
                        field_name,
                        indent,
                        field_name,
                    });

                    auks.printDecodeMethod(verkisto, field_type_enum, field_type, "", typename_len);

                    try verkisto.print(
                        \\ );
                        \\{s}            if (buffer.read_index != {s}_end) return error.AllocationFailed;
                        \\{s}        }}
                        \\
                    , .{
                        indent, field_name,
                        indent,
                    });
                } else {
                    // imported message
                    if (field_type_enum == .TYPE_MESSAGE and estasImportitaTipo(field_type)) {
                        try verkisto.print(
                            \\{s}        {{
                            \\{s}            const raw = try buffer.decodeBytes(try buffer.decodeVarint());
                            \\{s}            defer allocator.free(raw);
                            \\{s}
                            \\{s}            try {s}_list.append(
                            \\{s}                allocator,
                            \\{s}                try {s}.deseriigiElBin(
                            \\{s}                    allocator,
                            \\{s}                    raw,
                            \\{s}                    .BF_PROTOBUF,
                            \\{s}                )
                            \\{s}            );
                            \\{s}        }}
                            \\
                        , .{
                            indent,
                            indent,
                            indent,
                            indent,
                            indent,
                            field_name,
                            indent,
                            indent,
                            auks.mapiProtoTiponAlZig(field_type),
                            indent,
                            indent,
                            indent,
                            indent,
                            indent,
                            indent,
                        });
                    } else {
                        try verkisto.print(
                            \\{s}            {{ try {s}_list.append( allocator, try 
                        , .{
                            indent,
                            field_name,
                        });

                        auks.printDecodeMethod(
                            verkisto,
                            field_type_enum,
                            if (field_type_enum == .TYPE_MESSAGE or field_type_enum == .TYPE_ENUM)
                                field_type
                            else
                                "",
                            "",
                            "try buffer.decodeVarint()",
                        );

                        try verkisto.print(" ); }}\n", .{});
                    }
                }
            },
            .LABEL_REQUIRED => {
                // imported message
                if (field_type_enum == .TYPE_MESSAGE and estasImportitaTipo(field_type)) {
                    try verkisto.print(
                        \\{s}        {{
                        \\{s}            const raw = try buffer.decodeBytes(try buffer.decodeVarint());
                        \\{s}            defer allocator.free(raw);
                        \\{s}
                        \\{s}            mia_Mesagho.{s} =
                        \\{s}                try {s}.deseriigiElBin(
                        \\{s}                    allocator,
                        \\{s}                    raw,
                        \\{s}                    .BF_PROTOBUF,
                        \\{s}                );
                        \\{s}        }}
                        \\
                    , .{
                        indent,
                        indent,
                        indent,
                        indent,
                        indent,
                        field.name,
                        indent,
                        auks.mapiProtoTiponAlZig(field_type),
                        indent,
                        indent,
                        indent,
                        indent,
                        indent,
                    });
                } else {
                    try verkisto.print(
                        \\{s}            mia_Mesagho.{s} = try 
                    , .{
                        indent,
                        field.name,
                    });

                    auks.printDecodeMethod(
                        verkisto,
                        field_type_enum,
                        if (field_type_enum == .TYPE_MESSAGE or field_type_enum == .TYPE_ENUM)
                            field_type
                        else
                            "",
                        if (i == field_nums - 1) ";\n" else "\n",
                        "try buffer.decodeVarint()",
                    );
                }
            },
            else => {
                // optional message
                if (field_type_enum == .TYPE_MESSAGE and estasImportitaTipo(field_type)) {
                    try verkisto.print(
                        \\{s}        {{
                        \\{s}            const raw = try buffer.decodeBytes(try buffer.decodeVarint());
                        \\{s}            defer allocator.free(raw);
                        \\{s}
                        \\{s}            mia_Mesagho.{s} =
                        \\{s}                try {s}.deseriigiElBin(
                        \\{s}                    allocator,
                        \\{s}                    raw,
                        \\{s}                    .BF_PROTOBUF,
                        \\{s}                );
                        \\{s}       }}
                        \\
                    , .{
                        indent,
                        indent,
                        indent,
                        indent,
                        indent,
                        field.name,
                        indent,
                        auks.mapiProtoTiponAlZig(field_type),
                        indent,
                        indent,
                        indent,
                        indent,
                        indent,
                    });
                } else {
                    try verkisto.print(
                        \\{s}            mia_Mesagho.{s} = try 
                    , .{
                        indent,
                        field.name,
                    });

                    auks.printDecodeMethod(
                        verkisto,
                        field_type_enum,
                        if (field_type_enum == .TYPE_MESSAGE or field_type_enum == .TYPE_ENUM)
                            field_type
                        else
                            "",
                        if (i == field_nums - 1) ";\n" else "\n",
                        "try buffer.decodeVarint()",
                    );
                }
            },
        }
        // ====================================

        unua = false;
    }

    try verkisto.print(
        \\{s}    }}
        \\
        \\
    , .{indent});

    for (msg.fields) |field| {
        if (field.label_enum == .LABEL_REPEATED) {
            try verkisto.print(
                \\{s}    mia_Mesagho.{s} = try {s}_list.toOwnedSlice(allocator); 
                \\
            , .{
                indent, field.name, field.name,
            });
        }
    }

    try verkisto.print(
        \\
        \\{s}    return mia_Mesagho;
        \\{s}}}
    , .{
        indent, indent,
    });

    try verkisto.flush();
}

/////////////////////////////////////
/// skribiSeriigi: Optional Funkcioj
/////////////////////////////////////
///
fn skribiOptionalNoDefaultNoVarLong(indent: []const u8, field_name: []const u8, field_type: tpj, field_number: u32, wire_type: u3) !void {
    try verkisto.print(
        \\    {s}    if( self.{s} ) |val| {{
        \\    {s}        tuta_longo += try 
    , .{
        indent, field_name, // if (non-null )
        indent,
    });
    auks.printEncodeMethod(verkisto, field_type, "val", "");
    try verkisto.print(
        \\    {s}        tuta_longo += try buffer.encodeVarint({d});
        \\    {s}    }}   //1 opt - no def - no varlong
        \\
        \\
    , .{
        indent, (@as(u32, field_number) << 3) | wire_type, // if (non-null )
        indent,
    });
}

fn skribiOptionalDefaultNoVarLong(indent: []const u8, field_name: []const u8, field_type: tpj, field_number: u32, wire_type: u3, default: []const u8) !void {
    var default_value_string = default;

    if (field_type == .TYPE_ENUM) {
        if (!equal(u8, default, "null"))
            default_value_string = std.mem.concatWithSentinel(std.heap.page_allocator, u8, &[_][]const u8{ ".", default }, 0) catch unreachable
        else
            default_value_string = "null";
    }

    try verkisto.print(
        \\{s}    if( self.{s} ) |val| {{
        \\{s}        if( val != {s} )  {{
        \\{s}            tuta_longo += try 
    , .{
        indent, field_name, // if (non-null )
        indent, default_value_string, // if !default )
        indent,
    });
    auks.printEncodeMethod(verkisto, field_type, "val", "");
    try verkisto.print(
        \\{s}            tuta_longo += try buffer.encodeVarint({d});
        \\{s}        }}
        \\{s}    }}  //2 opt - def - no varlong
        \\
        \\
    , .{
        indent, (@as(u32, field_number) << 3) | wire_type, // if (non-null )
        indent, indent,
    });
}

fn skribiOptionalNoDefaultVarLong(indent: []const u8, field_name: []const u8, field_type: tpj, field_number: u32, wire_type: u3) !void {
    try verkisto.print(
        \\{s}    if ( self.{s} ) |val| {{
        \\{s}        const st_longa = try 
    , .{
        indent, field_name, // if (non-null )
        indent,
    });
    auks.printEncodeMethod(verkisto, field_type, "val", "");
    try verkisto.print(
        \\{s}        tuta_longo += st_longa;
        \\{s}        tuta_longo += try buffer.encodeVarint(st_longa);
        \\{s}        tuta_longo += try buffer.encodeVarint({d});
        \\{s}    }}  //3  opt - no def - varlong
        \\
        \\
    , .{
        indent,
        indent,
        indent,
        (@as(u32, field_number) << 3) | wire_type,
        indent,
    });
}

fn skribiOptionalDefaultVarLong(indent: []const u8, field_name: []const u8, field_type: tpj, field_number: u32, wire_type: u3, default: []const u8) !void {
    if (field_type != .TYPE_STRING) {
        skribiOptionalNoDefaultVarLong(indent, field_name, field_type, field_number, wire_type) catch {};
        return;
    }

    try verkisto.print(
        \\{s}    if ( self.{s} ) |val| {{
        \\{s}        if ( ! equal(u8, val, {s}) ) {{
        \\{s}            const st_longa = try 
    , .{
        indent, field_name, // if (non-null )
        indent, default,
        indent,
    });
    auks.printEncodeMethod(verkisto, field_type, "val", "");
    try verkisto.print(
        \\{s}            tuta_longo += st_longa;
        \\{s}            tuta_longo += try buffer.encodeVarint(st_longa);
        \\{s}            tuta_longo += try buffer.encodeVarint({d});
        \\{s}        }}  
        \\{s}    }}  //4  opt - def - varlong
        \\
        \\
    , .{
        indent,
        indent,
        indent,
        (@as(u32, field_number) << 3) | wire_type,
        indent,
        indent,
    });
}

/////////////////////////////////////
/// skribiSeriigi: Required Funkcioj
/////////////////////////////////////
///
fn skribiRequiredNoDefaultNoVarLong(indent: []const u8, field_name: []const u8, field_type: tpj, field_number: u32, wire_type: u3) !void {
    try verkisto.print(
        \\    {s}    tuta_longo += try 
    , .{
        indent,
    });
    auks.printEncodeMethod(verkisto, field_type, "self.", field_name);
    try verkisto.print(
        \\    {s}    tuta_longo += try buffer.encodeVarint({d});
        \\    {s}    //5 req - no def - no varlong
        \\
        \\
    , .{
        indent, (@as(u32, field_number) << 3) | wire_type,
        indent,
    });
}

fn skribiRequiredDefaultNoVarLong(indent: []const u8, field_name: []const u8, field_type: tpj, field_number: u32, wire_type: u3, default: []const u8) !void {
    var default_value_string = default;

    if (field_type == .TYPE_ENUM) {
        if (!equal(u8, default, "null"))
            default_value_string = std.mem.concatWithSentinel(std.heap.page_allocator, u8, &[_][]const u8{ ".", default }, 0) catch unreachable
        else
            default_value_string = "null";
    }

    try verkisto.print(
        \\    {s}    if( self.{s} != {s} )  {{
        \\    {s}        tuta_longo += try 
    , .{
        indent, field_name, default_value_string, // if !default )
        indent,
    });
    auks.printEncodeMethod(verkisto, field_type, "self.", field_name);
    try verkisto.print(
        \\    {s}        tuta_longo += try buffer.encodeVarint({d});
        \\{s}    }}  //6  req - def - no varlong
        \\
        \\
    , .{
        indent, (@as(u32, field_number) << 3) | wire_type,
        indent,
    });
}

fn skribiRequiredNoDefaultVarLong(indent: []const u8, field_name: []const u8, field_type: tpj, field_number: u32, wire_type: u3) !void {
    try verkisto.print(
        \\    {s}    const {s}_longa = try 
    , .{
        indent, field_name,
    });
    auks.printEncodeMethod(verkisto, field_type, "self.", field_name);
    try verkisto.print(
        \\    {s}    tuta_longo += {s}_longa;
        \\    {s}    tuta_longo += try buffer.encodeVarint({s}_longa);
        \\    {s}    tuta_longo += try buffer.encodeVarint({d});
        \\    {s}    //7  req - no def - varlong
        \\
        \\
    , .{
        indent, field_name,
        indent, field_name,
        indent, (@as(u32, field_number) << 3) | wire_type,
        indent,
    });
}

fn skribiRequiredDefaultVarLong(indent: []const u8, field_name: []const u8, field_type: tpj, field_number: u32, wire_type: u3, default: []const u8) !void {
    if (field_type != .TYPE_STRING) {
        skribiRequiredNoDefaultVarLong(indent, field_name, field_type, field_number, wire_type) catch {};
        return;
    }

    try verkisto.print(
        \\{s}    if ( ! equal(u8, self.{s}, {s}) ) {{
        \\{s}        const st_longa = try 
    , .{
        indent, field_name, default, // if !def
        indent,
    });
    auks.printEncodeMethod(verkisto, field_type, "self.", field_name);
    try verkisto.print(
        \\{s}        tuta_longo += st_longa;
        \\{s}        tuta_longo += try buffer.encodeVarint(st_longa);
        \\{s}        tuta_longo += try buffer.encodeVarint({d});
        \\{s}    }}  //8 req - def - varlong
        \\
        \\
    , .{
        indent,
        indent,
        indent,
        (@as(u32, field_number) << 3) | wire_type,
        indent,
    });
}

/////////////////////////////////////
/// skribiSeriigi: Repeted Funkcioj
/////////////////////////////////////
///
fn skribiRepeatedNoDefaultNoVarLong(indent: []const u8, field_name: []const u8, field_type: tpj, field_number: u32, wire_type: u3, pck: bool) !void {
    if (pck) {
        try verkisto.print(
            \\    {s}    var {s}_longa: usize = 0; 
            \\    {s}    for (self.{s}) |item| 
            \\    {s}        {s}_longa += try 
        , .{
            indent, field_name, // s_longa
            indent, field_name, // for
            indent, field_name, // try
        });
        auks.printEncodeMethod(verkisto, field_type, "", "item");
        try verkisto.print(
            \\    {s}    tuta_longo += {s}_longa;
            \\    {s}    tuta_longo += try buffer.encodeVarint({s}_longa);
            \\    {s}    tuta_longo += try buffer.encodeVarint({d});
            \\    // 9 rept - no def - no varlong  PACKED
            \\
            \\
        , .{
            indent, field_name, // tuta = {s}_long
            indent, field_name, // tuta = encode {s}_long
            indent, (@as(u32, field_number) << 3) | wire_type, // encode key
        });
        return;
    }

    try verkisto.print(
        \\    {s}    for (self.{s}) |item| {{
        \\    {s}        tuta_longo += try 
    , .{
        indent, field_name, // for
        indent, // try
    });
    auks.printEncodeMethod(verkisto, field_type, "", "item");
    try verkisto.print(
        \\    {s}        tuta_longo += try buffer.encodeVarint({d});
        \\    {s}    }}  // 9 rept - no def - no varlong 
        \\
        \\
    , .{
        indent, (@as(u32, field_number) << 3) | wire_type, // encode key
        indent,
    });
}

fn skribiRepeatedNoDefaultVarLong(indent: []const u8, field_name: []const u8, field_type: tpj, field_type_name: []const u8, field_number: u32, wire_type: u3) !void {
    if (field_type == .TYPE_MESSAGE and estasImportitaTipo(field_type_name)) {
        try verkisto.print(
            \\{s}    for (self.{s}) |item| {{
            \\{s}        var {s}_item = item;
            \\{s}        const {s}_bytes = try {s}_item.seriigiAlBin(allocator, .BF_PROTOBUF);
            \\{s}        defer allocator.free({s}_bytes);
            \\{s}        const {s}_longa = try buffer.encodeBytes({s}_bytes);
            \\{s}        tuta_longo += {s}_longa;
            \\{s}        tuta_longo += try buffer.encodeVarint({s}_longa);
            \\{s}        tuta_longo += try buffer.encodeVarint({d});
            \\{s}    }}  // 11 rept - imported message - varlong
            \\
            \\
        , .{
            indent,     field_name,
            indent,     field_name,
            indent,     field_name,
            field_name, indent,
            field_name, indent,
            field_name, field_name,
            indent,     field_name,
            indent,     field_name,
            indent,     (@as(u32, field_number) << 3) | wire_type,
            indent,
        });
        return;
    }

    try verkisto.print(
        \\{s}    for (self.{s}) |item| {{
        \\{s}        const {s}_longa = try 
    , .{
        indent, field_name, // for
        indent, field_name, // try
    });
    auks.printEncodeMethod(verkisto, field_type, "", "item");
    try verkisto.print(
        \\{s}        tuta_longo += {s}_longa;
        \\{s}        tuta_longo += try buffer.encodeVarint({s}_longa);
        \\{s}        tuta_longo += try buffer.encodeVarint({d});
        \\{s}    }}  // 11  rept - no def - varlong 
        \\
        \\
    , .{
        indent, field_name,
        indent, field_name,
        indent, (@as(u32, field_number) << 3) | wire_type, // encode key
        indent,
    });
}

/////////////////////////////////////
/// Konstruktoriloj
/////////////////////////////////////
///
fn skribiInitDefault(msg: prs.Message, ind: []const u8) !void {

    // -----------------------------------------
    // Generar cabecera
    // -----------------------------------------
    try verkisto.print(
        \\{s}pub fn initDefault(allocator: all.Allocator) !{s} {{
        \\
        // , .{ indent, msg.name });
    , .{ ind, msg.name });

    // -----------------------------------------
    // Detectar si se usa allocator
    // -----------------------------------------
    var uses_allocator = false;
    for (msg.fields) |f| {
        if (f.label_enum == .LABEL_REPEATED or
            f.field_type_enum == .TYPE_STRING or
            f.field_type_enum == .TYPE_BYTES or
            f.field_type_enum == .TYPE_MESSAGE)
        {
            uses_allocator = true;
            break;
        }
    }
    if (!uses_allocator) {
        try verkisto.print(
            \\{s}    _ = allocator;
            \\
            // , .{indent});
        , .{ind});
    }

    // -----------------------------------------
    // Generar return
    // -----------------------------------------
    try verkisto.print(
        \\{s}    return {s} {{
        \\
        // , .{ indent, msg.name });
    , .{ ind, msg.name });

    // -----------------------------------------
    // Campos
    // -----------------------------------------
    for (msg.fields) |f| {
        // -------------------------
        // repeated
        // -------------------------
        if (f.label_enum == .LABEL_REPEATED) {
            try verkisto.print(
                \\{s}        .{s} = try allocator.alloc({s}, 0),
                \\
            , .{ ind, f.name, auks.mapiProtoTiponAlZig(f.field_type) });
            // , .{ indent, f.name, auks.mapiProtoTiponAlZig(f.field_type) });
            continue;
        }

        // -------------------------
        // tiene default explícito
        // -------------------------
        if (f.default_value) |def| {
            // enum
            if (f.field_type_enum == .TYPE_ENUM) {
                try verkisto.print(
                    \\{s}        .{s} = .{s},
                    \\
                , .{ ind, f.name, def });
                // string y bytes
            } else if (f.field_type_enum == .TYPE_STRING or
                f.field_type_enum == .TYPE_BYTES)
            {
                try verkisto.print(
                    \\{s}        .{s} = try allocator.dupe(u8, {s}),
                    \\
                , .{ ind, f.name, def });
                // resto de tipos
            } else {
                try verkisto.print(
                    \\{s}        .{s} = {s},
                    \\
                , .{ ind, f.name, def });
            }
            continue;
        }

        // -------------------------
        // optional sin default
        // -------------------------
        if (f.label_enum == .LABEL_OPTIONAL) {
            try verkisto.print(
                \\{s}        .{s} = null,
                \\
                // , .{ indent, f.name });
            , .{ ind, f.name });
            continue;
        }

        if (f.field_type_enum == .TYPE_MESSAGE) {
            try verkisto.print(
                \\{s}        .{s} = try {s}.initDefault(allocator),
                \\
            , .{
                ind,
                f.name,
                auks.mapiProtoTiponAlZig(f.field_type),
            });

            continue;
        }

        // -------------------------
        // required sin default
        // -------------------------
        if (f.field_type_enum == .TYPE_STRING or
            f.field_type_enum == .TYPE_BYTES)
        {
            try verkisto.print(
                \\{s}        .{s} = try allocator.dupe(u8, ""),
                \\
            , .{ ind, f.name });
        } else {
            try verkisto.print(
                \\{s}        .{s} = 0,
                \\
                // , .{ indent, f.name });
            , .{ ind, f.name });
        }
    }

    // -----------------------------------------
    // OneOfs
    // -----------------------------------------
    // En protobuf, un oneof puede no tener ninguna alternativa activa.
    // La variante "none" no existe en el .proto, es una convencion interna
    // del codigo Zig generado para que initDefault() sea seguro y explicito.
    for (msg.oneofs) |oneof_decl| {
        try verkisto.print(
            \\{s}        .{s} = .{{ .none = {{}} }},
            \\
        , .{
            ind,
            oneof_decl.name,
        });
    }

    // -----------------------------------------
    // Cierre
    // -----------------------------------------
    try verkisto.print(
        \\{s}    }};
        \\{s}}}
        \\
        // , .{ indent, indent });
    , .{ ind, ind });

    try verkisto.print("\n", .{});
}

/////////////////////////////////////
/// Destruktoriloj
/////////////////////////////////////
///
fn skribiDeInit(msg: prs.Message, ind: []const u8) !void {
    try verkisto.print(
        \\{s}pub fn deinit(self: *const {s}, allocator: all.Allocator) void {{
        \\
    , .{ ind, msg.name });

    // -----------------------------------------
    // Detectar si se usa allocator
    // -----------------------------------------
    var uses_allocator = false;
    for (msg.fields) |f| {
        if (f.label_enum == .LABEL_REPEATED or
            f.field_type_enum == .TYPE_STRING or
            f.field_type_enum == .TYPE_BYTES or
            f.field_type_enum == .TYPE_MESSAGE)
        {
            uses_allocator = true;
            break;
        }
    }
    if (!uses_allocator) {
        try verkisto.print(
            \\{s}    _ = allocator;
            \\
        , .{ind});
    }

    // -----------------------------------------
    // Campos
    // -----------------------------------------
    for (msg.fields) |f| {
        // -------------------------
        // repeated
        // -------------------------
        if (f.label_enum == .LABEL_REPEATED) {
            switch (f.field_type_enum) {
                .TYPE_MESSAGE => {
                    try verkisto.print(
                        \\{s}    for (self.{s}) |item| {{
                        \\{s}        item.deinit(allocator);
                        \\{s}    }}
                        \\{s}    allocator.free(self.{s});
                        \\
                    , .{ ind, f.name, ind, ind, ind, f.name });
                },
                .TYPE_STRING, .TYPE_BYTES => {
                    try verkisto.print(
                        \\{s}    for (self.{s}) |item| {{
                        \\{s}        allocator.free(item);
                        \\{s}    }}
                        \\{s}    allocator.free(self.{s});
                        \\
                    , .{ ind, f.name, ind, ind, ind, f.name });
                },
                else => {
                    try verkisto.print(
                        \\{s}    allocator.free(self.{s});
                        \\
                    , .{ ind, f.name });
                },
            }
            continue;
        }

        if (f.label_enum == .LABEL_OPTIONAL and
            f.field_type_enum == .TYPE_MESSAGE)
        {
            try verkisto.print(
                \\{s}    if (self.{s}) |item| {{
                \\{s}        item.deinit(allocator);
                \\{s}    }}
                \\
            , .{
                ind,
                f.name,
                ind,
                ind,
            });

            continue;
        }

        if (f.label_enum == .LABEL_REQUIRED and
            f.field_type_enum == .TYPE_MESSAGE)
        {
            try verkisto.print(
                \\{s}    self.{s}.deinit(allocator);
                \\
            , .{
                ind,
                f.name,
            });

            continue;
        }

        if (f.field_type_enum == .TYPE_STRING or
            f.field_type_enum == .TYPE_BYTES)
        {
            if (f.label_enum == .LABEL_OPTIONAL) {
                try verkisto.print(
                    \\{s}    if( self.{s} ) |f| {{
                    \\{s}        allocator.free(f);
                    \\{s}    }}
                    \\
                , .{ ind, f.name, ind, ind });
            } else {
                try verkisto.print(
                    \\{s}    allocator.free(self.{s});
                    \\
                , .{ ind, f.name });
            }
        } else {
            // try verkisto.print(
            //     \\{s}    self.{s} = 0;
            //     \\
            // , .{ ind, f.name });
        }
    }

    // -----------------------------------------
    // OneOfs
    // -----------------------------------------
    for (msg.oneofs) |oneof_decl| {
        const union_name = auks.mapiOneOfNomonAlZigTipo(oneof_decl.name);

        try verkisto.print(
            \\{s}    self.deinit{s}(allocator);
            \\
        , .{
            ind,
            union_name,
        });
    }

    // -----------------------------------------
    // Cierre
    // -----------------------------------------
    try verkisto.print(
        \\{s}}}
        \\
    , .{
        ind,
    });

    try verkisto.print("\n", .{});
}
