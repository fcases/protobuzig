const std = @import("std");

// Ajusta este import si en tu arbol el modulo del parser se llama de otra forma.
// La idea es usar el mismo alias/tipo que en kgeneratoro.zig.
const prs = @import("mecha_prs.zig");
const pf = prs.ProtoFile;

// ============================================================================
// kgenapi.zig
// ============================================================================
//
// Generador de API segura para tipos generados por ProtobuZig.
//
// Fase intermedia prevista:
//
//   cctrol.zig
//       Tipos raw actuales generados por kgeneratoro.zig.
//
//   cctrol_api.zig
//       Wrappers seguros sobre los tipos raw actuales.
//
// Fase final posible:
//
//   cctrol_impl.zig
//       Tipos raw renombrados a *_impl.
//
//   cctrol.zig
//       Wrappers publicos definitivos.
//
// Este modulo NO debe sustituir a kgeneratoro.zig.
// Este modulo genera una capa adicional.
//
// ============================================================================

const ApiGenError = error{
    InvalidProtoPath,
};

// ============================================================================
// API PUBLICA DEL MODULO
// ============================================================================

pub fn generiZigAPI(
    proto_path: []const u8,
    output_dir: []const u8,
    ast_proto_dosiero: *const pf,
) !void {
    const allocator = std.heap.page_allocator;

    const proto_base_name = try akiriProtoBaseName(
        allocator,
        proto_path,
    );
    defer allocator.free(proto_base_name);

    const raw_file_name = try akiriRawFileName(
        allocator,
        proto_base_name,
    );
    defer allocator.free(raw_file_name);

    const api_file_name = try akiriApiFileName(
        allocator,
        proto_base_name,
    );
    defer allocator.free(api_file_name);

    const api_path = try std.fs.path.join(
        allocator,
        &[_][]const u8{
            output_dir,
            api_file_name,
        },
    );
    defer allocator.free(api_path);

    var file = try std.fs.cwd().createFile(
        api_path,
        .{ .truncate = true },
    );
    defer file.close();

    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(allocator);

    try skribiDosieranKaplinion(
        allocator,
        &buf,
        proto_base_name,
        raw_file_name,
        api_file_name,
    );

    try skribiRawImportojn(
        allocator,
        &buf,
        proto_base_name,
        raw_file_name,
    );

    try skribiApiKomencanSekcion(
        allocator,
        &buf,
        ast_proto_dosiero,
    );

    try skribiApiWrappers(
        allocator,
        &buf,
        proto_base_name,
        ast_proto_dosiero,
    );

    try skribiApiFinon(
        allocator,
        &buf,
    );

    try file.writeAll(buf.items);
}

// ============================================================================
// NOMBRES DE FICHEROS
// ============================================================================

fn akiriProtoBaseName(
    allocator: std.mem.Allocator,
    proto_path: []const u8,
) ![]const u8 {
    const base = std.fs.path.basename(proto_path);

    if (!std.mem.endsWith(u8, base, ".proto")) {
        return ApiGenError.InvalidProtoPath;
    }

    const stem = std.fs.path.stem(base);
    return try allocator.dupe(u8, stem);
}

fn akiriRawFileName(
    allocator: std.mem.Allocator,
    proto_base_name: []const u8,
) ![]const u8 {
    return try std.fmt.allocPrint(
        allocator,
        "{s}.zig",
        .{proto_base_name},
    );
}

fn akiriApiFileName(
    allocator: std.mem.Allocator,
    proto_base_name: []const u8,
) ![]const u8 {
    return try std.fmt.allocPrint(
        allocator,
        "{s}_api.zig",
        .{proto_base_name},
    );
}

// ============================================================================
// CABECERA DEL FICHERO API
// ============================================================================

fn skribiDosieranKaplinion(
    allocator: std.mem.Allocator,
    buf: *std.ArrayList(u8),
    proto_base_name: []const u8,
    raw_file_name: []const u8,
    api_file_name: []const u8,
) !void {
    try buf.print(allocator,
        \\// ============================================================================
        \\// {s}
        \\// ============================================================================
        \\//
        \\// Fichero generado por ProtobuZig / kgenapi.zig.
        \\//
        \\// Proto base:
        \\//   {s}
        \\//
        \\// Raw generado:
        \\//   {s}
        \\//
        \\// Este fichero contiene wrappers/API segura sobre el raw generado.
        \\//
        \\// Fase intermedia:
        \\//   - el fichero raw mantiene los tipos actuales.
        \\//   - este fichero genera wrappers seguros encima.
        \\//
        \\// Fase final posible:
        \\//   - el fichero raw pasara a *_impl.zig.
        \\//   - este fichero o su equivalente pasara a ser la API publica principal.
        \\//
        \\// No editar a mano salvo para depuracion.
        \\// ============================================================================
        \\
        \\
    , .{
        api_file_name,
        proto_base_name,
        raw_file_name,
    });
}

// ============================================================================
// IMPORTS DEL FICHERO API
// ============================================================================
fn skribiRawImportojn(
    allocator: std.mem.Allocator,
    buf: *std.ArrayList(u8),
    proto_base_name: []const u8,
    raw_file_name: []const u8,
) !void {
    try buf.print(allocator,
        \\const std = @import("std");
        \\
        \\const RawFile = @import("{s}");
        \\
        \\pub const TekstaFormato = RawFile.TekstaFormato;
        \\pub const BinaraFormato = RawFile.BinaraFormato;
        \\
        \\// Alias intencionadamente llamado *_impl aunque en fase intermedia
        \\// apunte al namespace raw actual.
        \\//
        \\// Fase intermedia:
        \\//   const {s}_impl = RawFile.{s};
        \\//
        \\// Fase final:
        \\//   const {s}_impl = RawFile.{s}_impl;
        \\
        \\const {s}_impl = RawFile.{s};
        \\
        \\
    , .{
        raw_file_name,
        proto_base_name,
        proto_base_name,
        proto_base_name,
        proto_base_name,
        proto_base_name,
        proto_base_name,
    });
}

// ============================================================================
// SECCION INICIAL DEL API
// ============================================================================

fn skribiApiKomencanSekcion(
    allocator: std.mem.Allocator,
    buf: *std.ArrayList(u8),
    ast_proto_dosiero: *const pf,
) !void {
    _ = ast_proto_dosiero;

    try buf.print(allocator,
        \\// ============================================================================
        \\// API SEGURA
        \\// ============================================================================
        \\//
        \\// Objetivo:
        \\//
        \\//   - ocultar el acceso directo a campos owned siempre que sea posible.
        \\//   - exponer setters/builders/getters controlados.
        \\//   - ofrecer nombres publicos en ingles para operaciones generales:
        \\//       serializeToBin
        \\//       deserializeFromBin
        \\//       writeToText
        \\//       readFromText
        \\//
        \\// Reglas previstas:
        \\//
        \\//   - append de repeated message hace copia profunda.
        \\//   - no se expone appendOwned como API publica inicial.
        \\//   - getXAt(index) devuelve copia owned.
        \\//   - el usuario debe llamar deinit() sobre copias devueltas.
        \\//   - no se exponen slices repeated internos como API principal.
        \\//
        \\
        \\
    , .{});
}

// ============================================================================
// WRAPPERS DE MENSAJE
// ============================================================================
//
// Esta funcion sera el punto principal del generador API.
//
// Primera version prevista:
//   - recorrer mensajes top-level.
//   - generar un wrapper por mensaje.
//   - cada wrapper contendra:
//       impl: Raw.<Message>
//
//   - funciones iniciales:
//       initDefault()
//       deinit()
//       serializeToBin()
//       deserializeFromBin()
//       writeToText()
//       readFromText()
//
// Despues:
//   - setters para required string/bytes.
//   - set/clear para optional string/bytes.
//   - append para repeated.
//   - getCount/getAt para repeated.
//
// De momento se deja una salida estructural para que el fichero generado compile
// y para fijar el punto de extension.
//

fn skribiApiWrappers(
    allocator: std.mem.Allocator,
    buf: *std.ArrayList(u8),
    proto_base_name: []const u8,
    ast_proto_dosiero: *const pf,
) !void {
    try skribiImplAliases(
        allocator,
        buf,
        proto_base_name,
        ast_proto_dosiero,
    );

    try skribiWrapperStructs(
        allocator,
        buf,
        ast_proto_dosiero,
    );
}

fn skribiImplAliases(
    allocator: std.mem.Allocator,
    buf: *std.ArrayList(u8),
    proto_base_name: []const u8,
    ast_proto_dosiero: *const pf,
) !void {
    try buf.print(allocator,
        \\// ============================================================================
        \\// ALIASES INTERNOS A TIPOS RAW / IMPL
        \\// ============================================================================
        \\//
        \\// Estos aliases permiten que el cuerpo de los wrappers no dependa de si
        \\// estamos en fase intermedia o fase final.
        \\//
        \\// Fase intermedia:
        \\//   EstMeteoImpl = cctrol_impl.EstMeteo
        \\//
        \\// Fase final:
        \\//   EstMeteoImpl = cctrol_impl.EstMeteo_impl
        \\//
        \\
    , .{});

    for (ast_proto_dosiero.messages) |msg| {
        try buf.print(allocator,
            \\const {s}Impl = {s}_impl.{s};
            \\
        , .{
            msg.name,
            proto_base_name,
            msg.name,
        });
    }

    try buf.print(allocator,
        \\
        \\
    , .{});
}

fn skribiWrapperStructs(
    allocator: std.mem.Allocator,
    buf: *std.ArrayList(u8),
    ast_proto_dosiero: *const pf,
) !void {
    try buf.print(allocator,
        \\// ============================================================================
        \\// WRAPPERS PUBLICOS
        \\// ============================================================================
        \\//
        \\// De momento cada wrapper solo contiene:
        \\//
        \\//   impl: TipoImpl
        \\//
        \\// En los siguientes pasos se generaran:
        \\//
        \\//   - initDefault()
        \\//   - deinit()
        \\//   - serializeToBin()
        \\//   - deserializeFromBin()
        \\//   - writeToText()
        \\//   - readFromText()
        \\//   - setters/getters/builders seguros
        \\//
        \\
    , .{});

    for (ast_proto_dosiero.messages) |msg| {
        try skribiUnuWrapperStruct(
            allocator,
            buf,
            msg,
        );
    }

    try buf.print(allocator,
        \\
    , .{});
}

fn skribiUnuWrapperStruct(
    allocator: std.mem.Allocator,
    buf: *std.ArrayList(u8),
    msg: prs.Message,
) !void {
    try buf.print(allocator,
        \\pub const {s} = struct {{
        \\    impl: {s}Impl,
        \\
        \\    const Self = @This();
        \\
        \\    pub fn initDefault(allocator: std.mem.Allocator) !Self {{
        \\        return .{{
        \\            .impl = try {s}Impl.initDefault(allocator),
        \\        }};
        \\    }}
        \\
        \\    pub fn deinit(self: *const Self, allocator: std.mem.Allocator) void {{
        \\        self.impl.deinit(allocator);
        \\    }}
        \\
        \\    pub fn writeToText(
        \\        self: *Self,
        \\        allocator: std.mem.Allocator,
        \\        format: TekstaFormato,
        \\    ) ![]const u8 {{
        \\        return try self.impl.skribiAlTeksto(
        \\            allocator,
        \\            format,
        \\        );
        \\    }}
        \\
        \\    pub fn writeToFile(
        \\        self: *Self,
        \\        allocator: std.mem.Allocator,
        \\        path: []const u8,
        \\        format: TekstaFormato,
        \\    ) !void {{
        \\        try self.impl.skribiAlDosiero(
        \\            allocator,
        \\            path,
        \\            format,
        \\        );
        \\    }}
        \\
        \\    pub fn readFromText(
        \\        allocator: std.mem.Allocator,
        \\        input: []const u8,
        \\        format: TekstaFormato,
        \\    ) !Self {{
        \\        return .{{
        \\            .impl = try {s}Impl.legiElTeksto(
        \\                allocator,
        \\                input,
        \\                format,
        \\            ),
        \\        }};
        \\    }}
        \\
        \\    pub fn readFromFile(
        \\        allocator: std.mem.Allocator,
        \\        path: []const u8,
        \\        format: TekstaFormato,
        \\    ) !Self {{
        \\        return .{{
        \\            .impl = try {s}Impl.legiElDosiero(
        \\                allocator,
        \\                path,
        \\                format,
        \\            ),
        \\        }};
        \\    }}
        \\
        \\    pub fn serializeToBin(
        \\        self: *const Self,
        \\        allocator: std.mem.Allocator,
        \\        format: BinaraFormato,
        \\    ) ![]const u8 {{
        \\        return try self.impl.seriigiAlBin(
        \\            allocator,
        \\            format,
        \\        );
        \\    }}
        \\
        \\    pub fn serializeToFile(
        \\        self: *const Self,
        \\        allocator: std.mem.Allocator,
        \\        path: []const u8,
        \\        format: BinaraFormato,
        \\    ) !void {{
        \\        try self.impl.seriigiAlDosiero(
        \\            allocator,
        \\            path,
        \\            format,
        \\        );
        \\    }}
        \\
        \\    pub fn deserializeFromBin(
        \\        allocator: std.mem.Allocator,
        \\        input: []const u8,
        \\        format: BinaraFormato,
        \\    ) !Self {{
        \\        return .{{
        \\            .impl = try {s}Impl.deseriigiElBin(
        \\                allocator,
        \\                input,
        \\                format,
        \\            ),
        \\        }};
        \\    }}
        \\
        \\    pub fn deserializeFromFile(
        \\        allocator: std.mem.Allocator,
        \\        path: [:0]const u8,
        \\        format: BinaraFormato,
        \\    ) !Self {{
        \\        return .{{
        \\            .impl = try {s}Impl.deseriigiElDosiero(
        \\                allocator,
        \\                path,
        \\                format,
        \\            ),
        \\        }};
        \\    }}
        \\}};
        \\
        \\
    , .{
        msg.name,
        msg.name,
        msg.name,
        msg.name,
        msg.name,
        msg.name,
        msg.name,
    });
}

// ============================================================================
// CIERRE DEL FICHERO API
// ============================================================================

fn skribiApiFinon(
    allocator: std.mem.Allocator,
    buf: *std.ArrayList(u8),
) !void {
    try buf.print(allocator,
        \\// ============================================================================
        \\// FIN API SEGURA
        \\// ============================================================================
        \\
    , .{});
}
