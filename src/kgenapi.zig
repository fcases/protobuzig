const std = @import("std");

// Adaptu cxi tiun importon se en via arbo la parser-modulo nomigxas alie.
// La ideo estas uzi la saman aliason/tipon kiel en kgeneratoro.zig.
const prs = @import("mecha_prs.zig");
const pf = prs.ProtoFile;

const kgen_auks = @import("kgen_auks.zig");
const api_auks = @import("kgapi_auks.zig");

// ============================================================================
// kgenapi.zig
// ============================================================================
//
// Generilo de sekura API por tipoj generitaj de ProtobuZig.
//
// Antauxvidita meza fazo:
//
//   cctrol.zig
//       Nunaj raw-tipoj generitaj de kgeneratoro.zig.
//
//   cctrol_api.zig
//       Sekuraj wrapper-oj super la nunaj raw-tipoj.
//
// Ebla fina fazo:
//
//   cctrol_impl.zig
//       Raw-tipoj renomitaj al *_impl.
//
//   cctrol.zig
//       Difinitivaj publikaj wrapper-oj.
//
// Cxi tiu modulo NE devas anstatauxi kgeneratoro.zig.
// Cxi tiu modulo generas plian tavolon.
//
// ============================================================================

const ApiGenError = error{
    InvalidProtoPath,
};

// ============================================================================
// PUBLIKA API DE LA MODULO
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
// NOMOJ DE DOSIEROJ
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
// KAPLINIO DE LA API-DOSIERO
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
        \\// Dosiero generita de ProtobuZig / kgenapi.zig.
        \\//
        \\// Baza proto:
        \\//   {s}
        \\//
        \\// Generita raw:
        \\//   {s}
        \\//
        \\// Cxi tiu dosiero enhavas wrapper-ojn (sekura API) super la raw.
        \\//
        \\// Meza fazo:
        \\//   - la raw-dosiero konservas la nunajn tipojn.
        \\//   - cxi tiu dosiero generas sekurajn wrapper-ojn supre.
        \\//
        \\// Ebla fina fazo:
        \\//   - la raw-dosiero pasos al *_impl.zig.
        \\//   - cxi tiu dosiero aux gia ekvivalento farigxos cefa publika API.
        \\//
        \\// Ne redaktu mane krom por sencimigado.
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
    ast_proto_dosiero: *const pf,
) ![]const u8 {
    const package_name = ast_proto_dosiero.package_name orelse "";

    if (package_name.len == 0) {
        // Sen package la raw NE malfermas nomspacon: gxiaj tipoj vivas en la
        // supra nivelo de la raw-dosiero (ne en nomspaco kun la nomo de la
        // dosiero). Referenci RawFile.<dosiero> generis api-on kiu ne
        // kompilis ("has no member named 'r8'"), kaj tio vidigxis nur per
        // proto sen package (F8, detektita per internaltests/protos/r8.proto).
        return try allocator.dupe(u8, "RawFile");
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
// IMPORTOJ DE LA API-DOSIERO
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
        ast_proto_dosiero,
    );
    defer allocator.free(raw_namespace_expr);

    // La baza nomo de la .proto-dosiero povas ne validi kiel Zig-identigilo
    // ("my-proto", "2fa", "test"...): la aliaso *_impl uzas la saneigitan
    // nomon, aux la generita api-dosiero ne kompilas (F9).
    const impl_nomo = try api_auks.implNomon(allocator, proto_base_name);
    defer allocator.free(impl_nomo);

    try buf.print(allocator,
        \\const std = @import("std");
        \\
        \\const RawFile = @import("{s}");
        \\
        \\pub const TekstaFormato = RawFile.TekstaFormato;
        \\pub const BinaraFormato = RawFile.BinaraFormato;
        \\
        \\// Aliaso al la generita raw-nomspaco.
        \\// En la meza fazo gxi montras al la nuna package de la raw-dosiero.
        \\const Raw = {s};
        \\
        \\// Aliaso intence nomita *_impl, kvankam en la meza fazo gxi
        \\// montras al la nuna raw-nomspaco.
        \\//
        \\// Meza fazo:
        \\//   const {s} = Raw;
        \\//
        \\// Fina fazo:
        \\//   const {s} = RawFile.<package>_impl;
        \\
        \\const {s} = Raw;
        \\
        \\
    , .{
        raw_file_name,
        raw_namespace_expr,
        impl_nomo,
        impl_nomo,
        impl_nomo,
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
        \\// PUBLIKAJ ALIASOJ AL RAW / IMPL-ENUMOJ
        \\// ============================================================================
        \\//
        \\// Enum-oj ne bezonas wrapper-on. Ili reeksportigxas el raw/impl.
        \\//
        \\// En la meza fazo:
        \\//   pub const TipoPanel = cctrol_impl.TipoPanel;
        \\//
        \\// En la fina fazo:
        \\//   pub const TipoPanel = cctrol_impl.TipoPanel;
        \\//
        \\
    , .{});

    const impl_nomo = try api_auks.implNomon(allocator, proto_base_name);
    defer allocator.free(impl_nomo);

    for (ast_proto_dosiero.enums) |enu| {
        try buf.print(allocator,
            \\pub const {s} = {s}.{s};
            \\
        , .{
            enu.name,
            impl_nomo,
            enu.name,
        });
    }

    try buf.print(allocator,
        \\
    , .{});
}

// ============================================================================
// KOMENCA SEKCIO DE LA API
// ============================================================================

fn skribiApiKomencanSekcion(
    allocator: std.mem.Allocator,
    buf: *std.ArrayList(u8),
    ast_proto_dosiero: *const pf,
) !void {
    _ = ast_proto_dosiero;

    try buf.print(allocator,
        \\// ============================================================================
        \\// SEKURA API
        \\// ============================================================================
        \\//
        \\// Celo:
        \\//
        \\//   - kasxi la rektan aliron al owned-kampoj kiam eble.
        \\//   - montri kontrolitajn setter-ojn/builder-ojn/getter-ojn.
        \\//   - proponi publikajn nomojn en la angla por generalaj operacioj:
        \\//       serializeToBin
        \\//       deserializeFromBin
        \\//       writeToText
        \\//       readFromText
        \\//
        \\// Antauxviditaj reguloj:
        \\//
        \\//   - append de repeated message faras profundan kopion.
        \\//   - appendOwned ne estas montrata kiel komenca publika API.
        \\//   - getXAt(index) redonas owned-kopion.
        \\//   - la uzanto devas voki deinit() sur redonitajn kopiojn.
        \\//   - internaj repeated slices ne estas montrataj kiel cefa API.
        \\//
        \\
        \\
    , .{});
}

// ============================================================================
// WRAPPER-OJ DE MESAGXO
// ============================================================================
//
// Cxi tiu funkcio estos la cefa punkto de la API-generilo.
//
// Antauxvidita unua versio:
//   - trakuri supranivelajn mesagxojn.
//   - generi unu wrapper-on por mesagxo.
//   - cxiu wrapper enhavos:
//       impl: Raw.<Message>
//
//   - komencajn funkciojn:
//       initDefault()
//       deinit()
//       serializeToBin()
//       deserializeFromBin()
//       writeToText()
//       readFromText()
//
// Poste:
//   - setter-ojn por required string/bytes.
//   - set/clear por optional string/bytes.
//   - append por repeated.
//   - getCount/getAt por repeated.
//
// Provizore oni lasas strukturan eliron por ke la generita dosiero kompilu
// kaj por fiksi la etendopunkton.
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

    try skribiCloneImplHelper(
        allocator,
        buf,
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
        \\// INTERNAJ ALIASOJ AL RAW / IMPL-TIPOJ
        \\// ============================================================================
        \\//
        \\// Cxi tiuj aliasoj ebligas, ke la korpo de la wrapper-oj ne dependu
        \\// de tio, cxu ni estas en la meza aux fina fazo.
        \\//
        \\// Meza fazo:
        \\//   EstMeteoImpl = cctrol_impl.EstMeteo
        \\//
        \\// Fina fazo:
        \\//   EstMeteoImpl = cctrol_impl.EstMeteo_impl
        \\//
        \\
    , .{});

    const impl_nomo = try api_auks.implNomon(allocator, proto_base_name);
    defer allocator.free(impl_nomo);

    for (ast_proto_dosiero.messages) |msg| {
        try buf.print(allocator,
            \\const {s}Impl = {s}.{s};
            \\
        , .{
            msg.name,
            impl_nomo,
            msg.name,
        });
    }

    try buf.print(allocator,
        \\
        \\
    , .{});
}

fn skribiCloneImplHelper(allocator: std.mem.Allocator, buf: *std.ArrayList(u8)) !void {
    try buf.print(allocator,
        \\// ============================================================================
        \\// PRIVATAJ HELPILOJ DE PROFUNDA KOPIO
        \\// ============================================================================
        \\//
        \\// cloneImpl() faras profundan kopion per la generita binara vojo.
        \\//
        \\// Komenca strategio:
        \\//
        \\//   clone = seriigiAlBin(.BF_PROTOBUF) + deseriigiElBin(.BF_PROTOBUF)
        \\//
        \\// Cxi tiu versio prioritatas simplecon kaj sekurecon de ownership.
        \\// Se seriigi/deseriigi havas cimon, gxi riparigxu en ProtobuZig,
        \\// cxar gxi trafas ankaux la normalan uzon de mesagxoj en K6Bus.
        \\//
        \\
        \\fn cloneImpl(comptime T: type, allocator: std.mem.Allocator, src: *const T) !T {{
        \\    const bytes = try src.seriigiAlBin(allocator, .BF_PROTOBUF);
        \\    defer allocator.free(bytes);
        \\
        \\    return try T.deseriigiElBin(allocator, bytes, .BF_PROTOBUF);
        \\}}
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
        \\// PUBLIKAJ WRAPPER-OJ
        \\// ============================================================================
        \\//
        \\// Provizore cxiu wrapper enhavas nur:
        \\//
        \\//   impl: TipoImpl
        \\//
        \\// En la sekvaj pasxoj generigxos:
        \\//
        \\//   - initDefault()
        \\//   - deinit()
        \\//   - serializeToBin()
        \\//   - deserializeFromBin()
        \\//   - writeToText()
        \\//   - readFromText()
        \\//   - sekuraj setter-oj/getter-oj/builder-oj
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

fn skribiUnuWrapperStruct(allocator: std.mem.Allocator, buf: *std.ArrayList(u8), msg: prs.Message) !void {
    try skribiWrapperStructKomenco(allocator, buf, msg);

    try skribiRequiredScalarOrEnumAccessors(allocator, buf, msg);
    try skribiOptionalScalarOrEnumAccessors(allocator, buf, msg);
    try skribiRepeatedScalarOrEnumAccessors(allocator, buf, msg);

    try skribiRequiredStringOrBytesAccessors(allocator, buf, msg);
    try skribiOptionalStringOrBytesAccessors(allocator, buf, msg);
    try skribiRepeatedStringOrBytesAccessors(allocator, buf, msg);

    try skribiRequiredMessageAccessors(allocator, buf, msg);
    try skribiOptionalMessageAccessors(allocator, buf, msg);
    try skribiRepeatedMessageAccessors(allocator, buf, msg);

    try skribiOneofClearAndHasAccessors(allocator, buf, msg);
    try skribiOneofMessageFieldAccessors(allocator, buf, msg);
    try skribiOneofScalarOrEnumFieldAccessors(allocator, buf, msg);
    try skribiOneofStringOrBytesFieldAccessors(allocator, buf, msg);

    try skribiWrapperStructFin(allocator, buf, msg);
}

fn skribiWrapperStructKomenco(allocator: std.mem.Allocator, buf: *std.ArrayList(u8), msg: prs.Message) !void {
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
        \\    pub fn clone(self: *const Self, allocator: std.mem.Allocator) !Self {{
        \\        return .{{
        \\            .impl = try cloneImpl(
        \\                {s}Impl,
        \\                allocator,
        \\                &self.impl,
        \\            ),
        \\        }};
        \\    }}
        \\
        \\
    , .{
        msg.name,
        msg.name,
        msg.name,
        msg.name,
    });
}

fn skribiWrapperStructFin(allocator: std.mem.Allocator, buf: *std.ArrayList(u8), msg: prs.Message) !void {
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

fn skribiOptionalStringOrBytesAccessors(
    allocator: std.mem.Allocator,
    buf: *std.ArrayList(u8),
    msg: prs.Message,
) !void {
    for (msg.fields) |field| {
        if (!api_auks.estasOptionalStringOrBytes(field)) {
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

        try buf.print(allocator,
            \\    pub fn {s}(self: *Self, allocator: std.mem.Allocator, value: []const u8) !void {{
            \\        const tmp = try allocator.dupe(u8, value);
            \\
            \\        if (self.impl.{s}) |old| {{
            \\            allocator.free(old);
            \\        }}
            \\
            \\        self.impl.{s} = tmp;
            \\    }}
            \\
            \\    pub fn {s}(self: *const Self) ?[]const u8 {{
            \\        return self.impl.{s};
            \\    }}
            \\
            \\    pub fn {s}(self: *const Self) bool {{
            \\        return self.impl.{s} != null;
            \\    }}
            \\
            \\    pub fn {s}(self: *Self, allocator: std.mem.Allocator) void {{
            \\        if (self.impl.{s}) |old| {{
            \\            allocator.free(old);
            \\        }}
            \\
            \\        self.impl.{s} = null;
            \\    }}
            \\
            \\
        , .{
            set_name,
            field.name,
            field.name,

            get_name,
            field.name,

            has_name,
            field.name,

            clear_name,
            field.name,
            field.name,
        });
    }
}

fn skribiRepeatedStringOrBytesAccessors(
    allocator: std.mem.Allocator,
    buf: *std.ArrayList(u8),
    msg: prs.Message,
) !void {
    for (msg.fields) |field| {
        if (!api_auks.estasRepeatedStringOrBytes(field)) {
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

        try buf.print(allocator,
            \\    pub fn {s}(self: *const Self) usize {{
            \\        return self.impl.{s}.len;
            \\    }}
            \\
            \\    pub fn {s}(self: *const Self, index: usize) ![]const u8 {{
            \\        if (index >= self.impl.{s}.len) {{
            \\            return error.IndexOutOfBounds;
            \\        }}
            \\
            \\        return self.impl.{s}[index];
            \\    }}
            \\
            \\    pub fn {s}(self: *Self, allocator: std.mem.Allocator, value: []const u8) !void {{
            \\        const tmp_item = try allocator.dupe(u8, value);
            \\        errdefer allocator.free(tmp_item);
            \\
            \\        const old_len = self.impl.{s}.len;
            \\        self.impl.{s} = try allocator.realloc(
            \\            self.impl.{s},
            \\            old_len + 1,
            \\        );
            \\
            \\        self.impl.{s}[old_len] = tmp_item;
            \\    }}
            \\
            \\    pub fn {s}(self: *Self, allocator: std.mem.Allocator, values: []const []const u8) !void {{
            \\        var tmp_list: std.ArrayList([]const u8) = .empty;
            \\        errdefer {{
            \\            for (tmp_list.items) |item| {{
            \\                allocator.free(item);
            \\            }}
            \\            tmp_list.deinit(allocator);
            \\        }}
            \\
            \\        for (values) |value| {{
            \\            const tmp_item = try allocator.dupe(u8, value);
            \\            errdefer allocator.free(tmp_item);
            \\            try tmp_list.append(allocator, tmp_item);
            \\        }}
            \\
            \\        const tmp = try tmp_list.toOwnedSlice(allocator);
            \\
            \\        for (self.impl.{s}) |item| {{
            \\            allocator.free(item);
            \\        }}
            \\        allocator.free(self.impl.{s});
            \\
            \\        self.impl.{s} = tmp;
            \\    }}
            \\
            \\    pub fn {s}(self: *Self, allocator: std.mem.Allocator) !void {{
            \\        for (self.impl.{s}) |item| {{
            \\            allocator.free(item);
            \\        }}
            \\        allocator.free(self.impl.{s});
            \\        self.impl.{s} = try allocator.alloc([]const u8, 0);
            \\    }}
            \\
            \\
        , .{
            count_name,
            field.name,

            at_name,
            field.name,
            field.name,

            append_name,
            field.name,
            field.name,
            field.name,
            field.name,

            set_name,
            field.name,
            field.name,
            field.name,

            clear_name,
            field.name,
            field.name,
            field.name,
        });
    }
}

fn skribiRequiredMessageAccessors(allocator: std.mem.Allocator, buf: *std.ArrayList(u8), msg: prs.Message) !void {
    for (msg.fields) |field| {
        if (!api_auks.estasRequiredMessage(field)) {
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

        const wrapper_type_name = field.field_type;

        const impl_type_name = try std.fmt.allocPrint(
            allocator,
            "{s}Impl",
            .{field.field_type},
        );
        defer allocator.free(impl_type_name);

        try buf.print(allocator,
            \\    pub fn {s}(self: *Self, allocator: std.mem.Allocator, value: *const {s}) !void {{
            \\        const tmp = try cloneImpl({s}, allocator, &value.impl);
            \\
            \\        self.impl.{s}.deinit(allocator);
            \\        self.impl.{s} = tmp;
            \\    }}
            \\
            \\    pub fn {s}(self: *const Self, allocator: std.mem.Allocator) !{s} {{
            \\        return .{{
            \\            .impl = try cloneImpl({s}, allocator, &self.impl.{s}),
            \\        }};
            \\    }}
            \\
            \\
        , .{
            set_name,
            wrapper_type_name,
            impl_type_name,
            field.name,
            field.name,

            get_name,
            wrapper_type_name,
            impl_type_name,
            field.name,
        });
    }
}

fn skribiOptionalMessageAccessors(
    allocator: std.mem.Allocator,
    buf: *std.ArrayList(u8),
    msg: prs.Message,
) !void {
    for (msg.fields) |field| {
        if (!api_auks.estasOptionalMessage(field)) {
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

        const wrapper_type_name = field.field_type;

        const impl_type_name = try std.fmt.allocPrint(
            allocator,
            "{s}Impl",
            .{field.field_type},
        );
        defer allocator.free(impl_type_name);

        try buf.print(allocator,
            \\    pub fn {s}(self: *Self, allocator: std.mem.Allocator, value: *const {s}) !void {{
            \\        const tmp = try cloneImpl({s}, allocator, &value.impl);
            \\
            \\        if (self.impl.{s}) |*old| {{
            \\            old.deinit(allocator);
            \\        }}
            \\
            \\        self.impl.{s} = tmp;
            \\    }}
            \\
            \\    pub fn {s}(self: *const Self) bool {{
            \\        return self.impl.{s} != null;
            \\    }}
            \\
            \\    pub fn {s}(self: *const Self, allocator: std.mem.Allocator) !{s} {{
            \\        if (self.impl.{s}) |*value| {{
            \\            return .{{
            \\                .impl = try cloneImpl(
            \\                    {s},
            \\                    allocator,
            \\                    value,
            \\                ),
            \\            }};
            \\        }}
            \\
            \\        return error.MissingField;
            \\    }}
            \\
            \\    pub fn {s}(self: *Self, allocator: std.mem.Allocator) void {{
            \\        if (self.impl.{s}) |*old| {{
            \\            old.deinit(allocator);
            \\        }}
            \\
            \\        self.impl.{s} = null;
            \\    }}
            \\
            \\
        , .{
            set_name,
            wrapper_type_name,
            impl_type_name,
            field.name,
            field.name,

            has_name,
            field.name,

            get_name,
            wrapper_type_name,
            field.name,
            impl_type_name,

            clear_name,
            field.name,
            field.name,
        });
    }
}

fn skribiRepeatedMessageAccessors(
    allocator: std.mem.Allocator,
    buf: *std.ArrayList(u8),
    msg: prs.Message,
) !void {
    for (msg.fields) |field| {
        if (!api_auks.estasRepeatedMessage(field)) {
            continue;
        }

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

        const wrapper_type_name = field.field_type;

        const impl_type_name = try std.fmt.allocPrint(
            allocator,
            "{s}Impl",
            .{field.field_type},
        );
        defer allocator.free(impl_type_name);

        try buf.print(allocator,
            \\    pub fn {s}(self: *const Self) usize {{
            \\        return self.impl.{s}.len;
            \\    }}
            \\
            \\    pub fn {s}(self: *const Self, allocator: std.mem.Allocator, index: usize) !{s} {{
            \\        if (index >= self.impl.{s}.len) {{
            \\            return error.IndexOutOfBounds;
            \\        }}
            \\
            \\        return .{{
            \\            .impl = try cloneImpl(
            \\                {s},
            \\                allocator,
            \\                &self.impl.{s}[index],
            \\            ),
            \\        }};
            \\    }}
            \\
            \\    pub fn {s}(self: *Self, allocator: std.mem.Allocator, value: *const {s}) !void {{
            \\        const tmp_item = try cloneImpl(
            \\            {s},
            \\            allocator,
            \\            &value.impl,
            \\        );
            \\        errdefer tmp_item.deinit(allocator);
            \\
            \\        const old_len = self.impl.{s}.len;
            \\        self.impl.{s} = try allocator.realloc(
            \\            self.impl.{s},
            \\            old_len + 1,
            \\        );
            \\
            \\        self.impl.{s}[old_len] = tmp_item;
            \\    }}
            \\
            \\    pub fn {s}(self: *Self, allocator: std.mem.Allocator) !void {{
            \\        for (self.impl.{s}) |*item| {{
            \\            item.deinit(allocator);
            \\        }}
            \\        allocator.free(self.impl.{s});
            \\        self.impl.{s} = try allocator.alloc({s}, 0);
            \\    }}
            \\
            \\
        , .{
            count_name,
            field.name,

            at_name,
            wrapper_type_name,
            field.name,
            impl_type_name,
            field.name,

            append_name,
            wrapper_type_name,
            impl_type_name,
            field.name,
            field.name,
            field.name,
            field.name,

            clear_name,
            field.name,
            field.name,
            field.name,
            impl_type_name,
        });
    }
}

fn skribiOneofClearAndHasAccessors(
    allocator: std.mem.Allocator,
    buf: *std.ArrayList(u8),
    msg: prs.Message,
) !void {
    for (msg.oneofs) |oneof_decl| {
        const clear_name = try api_auks.skribiOneofClearNomon(
            allocator,
            oneof_decl.name,
        );
        defer allocator.free(clear_name);

        const has_name = try api_auks.skribiOneofHasNomon(
            allocator,
            oneof_decl.name,
        );
        defer allocator.free(has_name);

        try buf.print(allocator,
            \\    pub fn {s}(self: *const Self) bool {{
            \\        return switch (self.impl.{s}) {{
            \\            .none => false,
            \\            else => true,
            \\        }};
            \\    }}
            \\
            \\    pub fn {s}(self: *Self, allocator: std.mem.Allocator) void {{
            \\        switch (self.impl.{s}) {{
            \\            .none => {{}},
            \\
        , .{
            has_name,
            oneof_decl.name,
            clear_name,
            oneof_decl.name,
        });

        for (oneof_decl.fields) |field| {
            switch (field.field_type_enum) {
                .TYPE_MESSAGE => {
                    try buf.print(allocator,
                        \\            .{s} => |*value| {{
                        \\                value.deinit(allocator);
                        \\            }},
                        \\
                    , .{
                        field.name,
                    });
                },

                .TYPE_STRING,
                .TYPE_BYTES,
                => {
                    try buf.print(allocator,
                        \\            .{s} => |value| {{
                        \\                allocator.free(value);
                        \\            }},
                        \\
                    , .{
                        field.name,
                    });
                },

                else => {
                    try buf.print(allocator,
                        \\            .{s} => {{}},
                        \\
                    , .{
                        field.name,
                    });
                },
            }
        }

        try buf.print(allocator,
            \\        }}
            \\
            \\        self.impl.{s} = .none;
            \\    }}
            \\
            \\
        , .{
            oneof_decl.name,
        });
    }
}

fn skribiOneofMessageFieldAccessors(
    allocator: std.mem.Allocator,
    buf: *std.ArrayList(u8),
    msg: prs.Message,
) !void {
    for (msg.oneofs) |oneof_decl| {
        const clear_name = try api_auks.skribiOneofClearNomon(
            allocator,
            oneof_decl.name,
        );
        defer allocator.free(clear_name);

        for (oneof_decl.fields) |field| {
            if (field.field_type_enum != .TYPE_MESSAGE) {
                continue;
            }

            const set_name = try api_auks.skribiOneofFieldSetNomon(
                allocator,
                oneof_decl.name,
                field.name,
            );
            defer allocator.free(set_name);

            const get_name = try api_auks.skribiOneofFieldGetNomon(
                allocator,
                oneof_decl.name,
                field.name,
            );
            defer allocator.free(get_name);

            const has_name = try api_auks.skribiOneofFieldHasNomon(
                allocator,
                oneof_decl.name,
                field.name,
            );
            defer allocator.free(has_name);

            const wrapper_type_name = field.field_type;

            const impl_type_name = try std.fmt.allocPrint(
                allocator,
                "{s}Impl",
                .{field.field_type},
            );
            defer allocator.free(impl_type_name);

            try buf.print(allocator,
                \\    pub fn {s}(self: *Self, allocator: std.mem.Allocator, value: *const {s}) !void {{
                \\        const tmp = try cloneImpl(
                \\            {s},
                \\            allocator,
                \\            &value.impl,
                \\        );
                \\
                \\        self.{s}(allocator);
                \\        self.impl.{s} = .{{ .{s} = tmp }};
                \\    }}
                \\
                \\    pub fn {s}(self: *const Self) bool {{
                \\        return switch (self.impl.{s}) {{
                \\            .{s} => true,
                \\            else => false,
                \\        }};
                \\    }}
                \\
                \\    pub fn {s}(self: *const Self, allocator: std.mem.Allocator) !{s} {{
                \\        return switch (self.impl.{s}) {{
                \\            .{s} => |*value| .{{
                \\                .impl = try cloneImpl(
                \\                    {s},
                \\                    allocator,
                \\                    value,
                \\                ),
                \\            }},
                \\            else => error.WrongOneofField,
                \\        }};
                \\    }}
                \\
                \\
            , .{
                set_name,
                wrapper_type_name,
                impl_type_name,
                clear_name,
                oneof_decl.name,
                field.name,

                has_name,
                oneof_decl.name,
                field.name,

                get_name,
                wrapper_type_name,
                oneof_decl.name,
                field.name,
                impl_type_name,
            });
        }
    }
}

fn skribiOneofScalarOrEnumFieldAccessors(
    allocator: std.mem.Allocator,
    buf: *std.ArrayList(u8),
    msg: prs.Message,
) !void {
    for (msg.oneofs) |oneof_decl| {
        const clear_name = try api_auks.skribiOneofClearNomon(
            allocator,
            oneof_decl.name,
        );
        defer allocator.free(clear_name);

        for (oneof_decl.fields) |field| {
            if (!api_auks.estasScalarOrEnum(field.field_type_enum)) {
                continue;
            }

            const set_name = try api_auks.skribiOneofFieldSetNomon(
                allocator,
                oneof_decl.name,
                field.name,
            );
            defer allocator.free(set_name);

            const get_name = try api_auks.skribiOneofFieldGetNomon(
                allocator,
                oneof_decl.name,
                field.name,
            );
            defer allocator.free(get_name);

            const has_name = try api_auks.skribiOneofFieldHasNomon(
                allocator,
                oneof_decl.name,
                field.name,
            );
            defer allocator.free(has_name);

            const zig_type = kgen_auks.mapiProtoTiponAlZig(
                field.field_type,
            );

            try buf.print(allocator,
                \\    pub fn {s}(self: *Self, allocator: std.mem.Allocator, value: {s}) void {{
                \\        self.{s}(allocator);
                \\        self.impl.{s} = .{{ .{s} = value }};
                \\    }}
                \\
                \\    pub fn {s}(self: *const Self) bool {{
                \\        return switch (self.impl.{s}) {{
                \\            .{s} => true,
                \\            else => false,
                \\        }};
                \\    }}
                \\
                \\    pub fn {s}(self: *const Self) !{s} {{
                \\        return switch (self.impl.{s}) {{
                \\            .{s} => |value| value,
                \\            else => error.WrongOneofField,
                \\        }};
                \\    }}
                \\
                \\
            , .{
                set_name,
                zig_type,
                clear_name,
                oneof_decl.name,
                field.name,

                has_name,
                oneof_decl.name,
                field.name,

                get_name,
                zig_type,
                oneof_decl.name,
                field.name,
            });
        }
    }
}

fn skribiOneofStringOrBytesFieldAccessors(allocator: std.mem.Allocator, buf: *std.ArrayList(u8), msg: prs.Message) !void {
    for (msg.oneofs) |oneof_decl| {
        const clear_name = try api_auks.skribiOneofClearNomon(
            allocator,
            oneof_decl.name,
        );
        defer allocator.free(clear_name);

        for (oneof_decl.fields) |field| {
            if (!api_auks.estasStringOrBytes(field.field_type_enum)) {
                continue;
            }

            const set_name = try api_auks.skribiOneofFieldSetNomon(
                allocator,
                oneof_decl.name,
                field.name,
            );
            defer allocator.free(set_name);

            const get_name = try api_auks.skribiOneofFieldGetNomon(
                allocator,
                oneof_decl.name,
                field.name,
            );
            defer allocator.free(get_name);

            const has_name = try api_auks.skribiOneofFieldHasNomon(
                allocator,
                oneof_decl.name,
                field.name,
            );
            defer allocator.free(has_name);

            try buf.print(allocator,
                \\    pub fn {s}(self: *Self, allocator: std.mem.Allocator, value: []const u8) !void {{
                \\        const tmp = try allocator.dupe(u8, value);
                \\
                \\        self.{s}(allocator);
                \\        self.impl.{s} = .{{ .{s} = tmp }};
                \\    }}
                \\
                \\    pub fn {s}(self: *const Self) bool {{
                \\        return switch (self.impl.{s}) {{
                \\            .{s} => true,
                \\            else => false,
                \\        }};
                \\    }}
                \\
                \\    pub fn {s}(self: *const Self) ![]const u8 {{
                \\        return switch (self.impl.{s}) {{
                \\            .{s} => |value| value,
                \\            else => error.WrongOneofField,
                \\        }};
                \\    }}
                \\
                \\
            , .{
                set_name,
                clear_name,
                oneof_decl.name,
                field.name,

                has_name,
                oneof_decl.name,
                field.name,

                get_name,
                oneof_decl.name,
                field.name,
            });
        }
    }
}

// ============================================================================
// FERMO DE LA API-DOSIERO
// ============================================================================

fn skribiApiFinon(
    allocator: std.mem.Allocator,
    buf: *std.ArrayList(u8),
) !void {
    try buf.print(allocator,
        \\// ============================================================================
        \\// FINO DE LA SEKURA API
        \\// ============================================================================
        \\
    , .{});
}
