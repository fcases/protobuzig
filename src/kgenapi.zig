const std = @import("std");

// Ajusta este import si en tu arbol el modulo del parser se llama de otra forma.
// La idea es usar el mismo alias/tipo que en kgeneratoro.zig.
const prs = @import("mecha_prs.zig");
const pf = prs.ProtoFile;

const kgen_auks = @import("kgen_auks.zig");
const api_auks = @import("kgapi_auks.zig");

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
        ast_proto_dosiero,
    );

    try skribiEnumAliases(
        allocator,
        &buf,
        proto_base_name,
        ast_proto_dosiero,
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

fn skribiRawNamespaceExpr(
    allocator: std.mem.Allocator,
    proto_base_name: []const u8,
    ast_proto_dosiero: *const pf,
) ![]const u8 {
    const package_name = ast_proto_dosiero.package_name orelse "";

    if (package_name.len == 0) {
        return try std.fmt.allocPrint(
            allocator,
            "RawFile.{s}",
            .{proto_base_name},
        );
    }

    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);

    try out.appendSlice(allocator, "RawFile");

    var it = std.mem.splitScalar(u8, package_name, '.');
    while (it.next()) |part| {
        if (part.len == 0) {
            continue;
        }

        try out.append(allocator, '.');
        try out.appendSlice(allocator, part);
    }

    return try out.toOwnedSlice(allocator);
}

// ============================================================================
// IMPORTS DEL FICHERO API
// ============================================================================
fn skribiRawImportojn(
    allocator: std.mem.Allocator,
    buf: *std.ArrayList(u8),
    proto_base_name: []const u8,
    raw_file_name: []const u8,
    ast_proto_dosiero: *const pf,
) !void {
    const raw_namespace_expr = try skribiRawNamespaceExpr(
        allocator,
        proto_base_name,
        ast_proto_dosiero,
    );
    defer allocator.free(raw_namespace_expr);

    try buf.print(allocator,
        \\const std = @import("std");
        \\
        \\const RawFile = @import("{s}");
        \\
        \\pub const TekstaFormato = RawFile.TekstaFormato;
        \\pub const BinaraFormato = RawFile.BinaraFormato;
        \\
        \\// Alias al namespace raw generado.
        \\// En fase intermedia apunta al package actual del fichero raw.
        \\const Raw = {s};
        \\
        \\// Alias intencionadamente llamado *_impl aunque en fase intermedia
        \\// apunte al namespace raw actual.
        \\//
        \\// Fase intermedia:
        \\//   const {s}_impl = Raw;
        \\//
        \\// Fase final:
        \\//   const {s}_impl = RawFile.<package>_impl;
        \\
        \\const {s}_impl = Raw;
        \\
        \\
    , .{
        raw_file_name,
        raw_namespace_expr,
        proto_base_name,
        proto_base_name,
        proto_base_name,
    });
}

fn skribiEnumAliases(
    allocator: std.mem.Allocator,
    buf: *std.ArrayList(u8),
    proto_base_name: []const u8,
    ast_proto_dosiero: *const pf,
) !void {
    if (ast_proto_dosiero.enums.len == 0) {
        return;
    }

    try buf.print(allocator,
        \\// ============================================================================
        \\// ALIASES PUBLICOS A ENUMS RAW / IMPL
        \\// ============================================================================
        \\//
        \\// Los enums no necesitan wrapper. Se reexportan desde el namespace raw/impl.
        \\//
        \\// En fase intermedia:
        \\//   pub const TipoPanel = cctrol_impl.TipoPanel;
        \\//
        \\// En fase final:
        \\//   pub const TipoPanel = cctrol_impl.TipoPanel;
        \\//
        \\
    , .{});

    for (ast_proto_dosiero.enums) |enu| {
        try buf.print(allocator,
            \\pub const {s} = {s}_impl.{s};
            \\
        , .{
            enu.name,
            proto_base_name,
            enu.name,
        });
    }

    try buf.print(allocator,
        \\
    , .{});
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
    try skribiWrapperStructKomenco(
        allocator,
        buf,
        msg,
    );

    try skribiRequiredScalarOrEnumAccessors(
        allocator,
        buf,
        msg,
    );

    try skribiOptionalScalarOrEnumAccessors(
        allocator,
        buf,
        msg,
    );

    try skribiRepeatedScalarOrEnumAccessors(
        allocator,
        buf,
        msg,
    );

    try skribiRequiredStringOrBytesAccessors(
        allocator,
        buf,
        msg,
    );

    try skribiWrapperStructFin(
        allocator,
        buf,
        msg,
    );
}

fn skribiWrapperStructKomenco(
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
        \\
    , .{
        msg.name,
        msg.name,
        msg.name,
    });
}

fn skribiWrapperStructFin(
    allocator: std.mem.Allocator,
    buf: *std.ArrayList(u8),
    msg: prs.Message,
) !void {
    try buf.print(allocator,
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
    });
}

fn skribiRequiredScalarOrEnumAccessors(
    allocator: std.mem.Allocator,
    buf: *std.ArrayList(u8),
    msg: prs.Message,
) !void {
    for (msg.fields) |field| {
        if (!api_auks.estasRequiredScalarOrEnum(field)) {
            continue;
        }

        const set_name = try api_auks.skribiSetNomon(
            allocator,
            field.name,
        );
        defer allocator.free(set_name);

        const get_name = try api_auks.skribiGetNomon(
            allocator,
            field.name,
        );
        defer allocator.free(get_name);

        const zig_type = kgen_auks.mapiProtoTiponAlZig(
            field.field_type,
        );

        try buf.print(allocator,
            \\    pub fn {s}(self: *Self, value: {s}) void {{
            \\        self.impl.{s} = value;
            \\    }}
            \\
            \\    pub fn {s}(self: *const Self) {s} {{
            \\        return self.impl.{s};
            \\    }}
            \\
            \\
        , .{
            set_name,
            zig_type,
            field.name,
            get_name,
            zig_type,
            field.name,
        });
    }
}

fn skribiOptionalScalarOrEnumAccessors(
    allocator: std.mem.Allocator,
    buf: *std.ArrayList(u8),
    msg: prs.Message,
) !void {
    for (msg.fields) |field| {
        if (!api_auks.estasOptionalScalarOrEnum(field)) {
            continue;
        }

        const set_name = try api_auks.skribiSetNomon(
            allocator,
            field.name,
        );
        defer allocator.free(set_name);

        const get_name = try api_auks.skribiGetNomon(
            allocator,
            field.name,
        );
        defer allocator.free(get_name);

        const has_name = try api_auks.skribiHasNomon(
            allocator,
            field.name,
        );
        defer allocator.free(has_name);

        const clear_name = try api_auks.skribiClearNomon(
            allocator,
            field.name,
        );
        defer allocator.free(clear_name);

        const zig_type = kgen_auks.mapiProtoTiponAlZig(
            field.field_type,
        );

        try buf.print(allocator,
            \\    pub fn {s}(self: *Self, value: {s}) void {{
            \\        self.impl.{s} = value;
            \\    }}
            \\
            \\    pub fn {s}(self: *const Self) ?{s} {{
            \\        return self.impl.{s};
            \\    }}
            \\
            \\    pub fn {s}(self: *const Self) bool {{
            \\        return self.impl.{s} != null;
            \\    }}
            \\
            \\    pub fn {s}(self: *Self) void {{
            \\        self.impl.{s} = null;
            \\    }}
            \\
            \\
        , .{
            set_name,
            zig_type,
            field.name,

            get_name,
            zig_type,
            field.name,

            has_name,
            field.name,

            clear_name,
            field.name,
        });
    }
}

fn skribiRepeatedScalarOrEnumAccessors(
    allocator: std.mem.Allocator,
    buf: *std.ArrayList(u8),
    msg: prs.Message,
) !void {
    for (msg.fields) |field| {
        if (!api_auks.estasRepeatedScalarOrEnum(field)) {
            continue;
        }

        const set_name = try api_auks.skribiSetNomon(
            allocator,
            field.name,
        );
        defer allocator.free(set_name);

        const append_name = try api_auks.skribiAppendNomon(
            allocator,
            field.name,
        );
        defer allocator.free(append_name);

        const clear_name = try api_auks.skribiClearNomon(
            allocator,
            field.name,
        );
        defer allocator.free(clear_name);

        const count_name = try api_auks.skribiCountNomon(
            allocator,
            field.name,
        );
        defer allocator.free(count_name);

        const at_name = try api_auks.skribiAtNomon(
            allocator,
            field.name,
        );
        defer allocator.free(at_name);

        const zig_type = kgen_auks.mapiProtoTiponAlZig(
            field.field_type,
        );

        try buf.print(allocator,
            \\    pub fn {s}(self: *const Self) usize {{
            \\        return self.impl.{s}.len;
            \\    }}
            \\
            \\    pub fn {s}(self: *const Self, index: usize) !{s} {{
            \\        if (index >= self.impl.{s}.len) {{
            \\            return error.IndexOutOfBounds;
            \\        }}
            \\
            \\        return self.impl.{s}[index];
            \\    }}
            \\
            \\    pub fn {s}(
            \\        self: *Self,
            \\        allocator: std.mem.Allocator,
            \\        value: {s},
            \\    ) !void {{
            \\        const old_len = self.impl.{s}.len;
            \\
            \\        self.impl.{s} = try allocator.realloc(
            \\            self.impl.{s},
            \\            old_len + 1,
            \\        );
            \\
            \\        self.impl.{s}[old_len] = value;
            \\    }}
            \\
            \\    pub fn {s}(
            \\        self: *Self,
            \\        allocator: std.mem.Allocator,
            \\        values: []const {s},
            \\    ) !void {{
            \\        const tmp = try allocator.dupe({s}, values);
            \\
            \\        allocator.free(self.impl.{s});
            \\        self.impl.{s} = tmp;
            \\    }}
            \\
            \\    pub fn {s}(
            \\        self: *Self,
            \\        allocator: std.mem.Allocator,
            \\    ) !void {{
            \\        allocator.free(self.impl.{s});
            \\        self.impl.{s} = try allocator.alloc({s}, 0);
            \\    }}
            \\
            \\
        , .{
            count_name,
            field.name,

            at_name,
            zig_type,
            field.name,
            field.name,

            append_name,
            zig_type,
            field.name,
            field.name,
            field.name,
            field.name,

            set_name,
            zig_type,
            zig_type,
            field.name,
            field.name,

            clear_name,
            field.name,
            field.name,
            zig_type,
        });
    }
}

fn skribiRequiredStringOrBytesAccessors(
    allocator: std.mem.Allocator,
    buf: *std.ArrayList(u8),
    msg: prs.Message,
) !void {
    for (msg.fields) |field| {
        if (!api_auks.estasRequiredStringOrBytes(field)) {
            continue;
        }

        const set_name = try api_auks.skribiSetNomon(
            allocator,
            field.name,
        );
        defer allocator.free(set_name);

        const get_name = try api_auks.skribiGetNomon(
            allocator,
            field.name,
        );
        defer allocator.free(get_name);

        try buf.print(allocator,
            \\    pub fn {s}(
            \\        self: *Self,
            \\        allocator: std.mem.Allocator,
            \\        value: []const u8,
            \\    ) !void {{
            \\        const tmp = try allocator.dupe(u8, value);
            \\        allocator.free(self.impl.{s});
            \\        self.impl.{s} = tmp;
            \\    }}
            \\
            \\    pub fn {s}(self: *const Self) []const u8 {{
            \\        return self.impl.{s};
            \\    }}
            \\
        , .{
            set_name,
            field.name,
            field.name,
            get_name,
            field.name,
        });
    }
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
