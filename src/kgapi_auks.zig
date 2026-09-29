const std = @import("std");

const prs = @import("mecha_prs.zig");

// ============================================================================
// kgapi_auks.zig
// ============================================================================
//
// Auksiliaj helpiloj por kgenapi.zig.
//
// Cxi tiu dosiero enhavas utilajojn specifajn al la generita sekura API:
//
//   - detekto de kampaj tipoj.
//   - nomoj de publikaj metodoj.
//   - konverto snake_case -> PascalCase.
//   - estontaj helpiloj por append/get/clear.
//
// Gxi ne miksu kun kgen_auks.zig, kiu apartenas al la kruda generatoro.
//
// ============================================================================

// ============================================================================
// KLASIFIKADO DE KAMPOJ
// ============================================================================

pub fn estasRequiredScalarOrEnum(field: prs.Field) bool {
    if (field.label_enum != .LABEL_REQUIRED) {
        return false;
    }

    return estasScalarOrEnum(field.field_type_enum);
}

pub fn estasOptionalScalarOrEnum(field: prs.Field) bool {
    if (field.label_enum != .LABEL_OPTIONAL) {
        return false;
    }

    return estasScalarOrEnum(field.field_type_enum);
}

pub fn estasRepeatedScalarOrEnum(field: prs.Field) bool {
    if (field.label_enum != .LABEL_REPEATED) {
        return false;
    }

    return estasScalarOrEnum(field.field_type_enum);
}

pub fn estasScalarOrEnum(field_type_enum: prs.Tipoj) bool {
    return switch (field_type_enum) {
        .TYPE_DOUBLE,
        .TYPE_FLOAT,
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
        .TYPE_BOOL,
        .TYPE_ENUM,
        => true,

        else => false,
    };
}

pub fn estasStringOrBytes(field_type_enum: prs.Tipoj) bool {
    return switch (field_type_enum) {
        .TYPE_STRING,
        .TYPE_BYTES,
        => true,

        else => false,
    };
}

pub fn estasRequiredStringOrBytes(field: prs.Field) bool {
    if (field.label_enum != .LABEL_REQUIRED) {
        return false;
    }

    return estasStringOrBytes(field.field_type_enum);
}

pub fn estasOptionalStringOrBytes(field: prs.Field) bool {
    if (field.label_enum != .LABEL_OPTIONAL) {
        return false;
    }

    return estasStringOrBytes(field.field_type_enum);
}

pub fn estasRepeatedStringOrBytes(field: prs.Field) bool {
    if (field.label_enum != .LABEL_REPEATED) {
        return false;
    }

    return estasStringOrBytes(field.field_type_enum);
}

pub fn estasMessage(field_type_enum: prs.Tipoj) bool {
    return field_type_enum == .TYPE_MESSAGE;
}

pub fn estasRequiredMessage(field: prs.Field) bool {
    if (field.label_enum != .LABEL_REQUIRED) {
        return false;
    }
    return estasMessage(field.field_type_enum);
}

pub fn estasOptionalMessage(field: prs.Field) bool {
    if (field.label_enum != .LABEL_OPTIONAL) {
        return false;
    }

    return estasMessage(field.field_type_enum);
}

pub fn estasRepeatedMessage(field: prs.Field) bool {
    if (field.label_enum != .LABEL_REPEATED) {
        return false;
    }

    return estasMessage(field.field_type_enum);
}

// ============================================================================
// NOMOJ DE METODOJ
// ============================================================================
pub fn skribiSetNomon(
    allocator: std.mem.Allocator,
    field_name: []const u8,
) ![]const u8 {
    return try skribiMetodoNomon(
        allocator,
        "set",
        field_name,
    );
}

pub fn skribiGetNomon(
    allocator: std.mem.Allocator,
    field_name: []const u8,
) ![]const u8 {
    return try skribiMetodoNomon(
        allocator,
        "get",
        field_name,
    );
}

pub fn skribiHasNomon(
    allocator: std.mem.Allocator,
    field_name: []const u8,
) ![]const u8 {
    return try skribiMetodoNomon(
        allocator,
        "has",
        field_name,
    );
}

pub fn skribiClearNomon(
    allocator: std.mem.Allocator,
    field_name: []const u8,
) ![]const u8 {
    return try skribiMetodoNomon(
        allocator,
        "clear",
        field_name,
    );
}

pub fn skribiAppendNomon(
    allocator: std.mem.Allocator,
    field_name: []const u8,
) ![]const u8 {
    return try skribiMetodoNomon(
        allocator,
        "append",
        field_name,
    );
}

pub fn skribiCountNomon(
    allocator: std.mem.Allocator,
    field_name: []const u8,
) ![]const u8 {
    const pascal = try skribiPascalNomon(
        allocator,
        field_name,
    );
    defer allocator.free(pascal);

    return try std.fmt.allocPrint(
        allocator,
        "get{s}Count",
        .{pascal},
    );
}

pub fn skribiAtNomon(
    allocator: std.mem.Allocator,
    field_name: []const u8,
) ![]const u8 {
    const pascal = try skribiPascalNomon(
        allocator,
        field_name,
    );
    defer allocator.free(pascal);

    return try std.fmt.allocPrint(
        allocator,
        "get{s}At",
        .{pascal},
    );
}

pub fn skribiOneofClearNomon(allocator: std.mem.Allocator, oneof_name: []const u8) ![]const u8 {
    return try skribiMetodoNomon(allocator, "clear", oneof_name);
}

pub fn skribiOneofHasNomon(allocator: std.mem.Allocator, oneof_name: []const u8) ![]const u8 {
    return try skribiMetodoNomon(allocator, "has", oneof_name);
}

pub fn skribiOneofFieldSetNomon(allocator: std.mem.Allocator, oneof_name: []const u8, field_name: []const u8) ![]const u8 {
    const oneof_pascal = try skribiPascalNomon(allocator, oneof_name);
    defer allocator.free(oneof_pascal);

    const field_pascal = try skribiPascalNomon(allocator, field_name);
    defer allocator.free(field_pascal);

    return try std.fmt.allocPrint(
        allocator,
        "set{s}{s}",
        .{
            oneof_pascal,
            field_pascal,
        },
    );
}

pub fn skribiOneofFieldGetNomon(allocator: std.mem.Allocator, oneof_name: []const u8, field_name: []const u8) ![]const u8 {
    const oneof_pascal = try skribiPascalNomon(allocator, oneof_name);
    defer allocator.free(oneof_pascal);

    const field_pascal = try skribiPascalNomon(allocator, field_name);
    defer allocator.free(field_pascal);

    return try std.fmt.allocPrint(
        allocator,
        "get{s}{s}",
        .{
            oneof_pascal,
            field_pascal,
        },
    );
}

pub fn skribiOneofFieldHasNomon(allocator: std.mem.Allocator, oneof_name: []const u8, field_name: []const u8) ![]const u8 {
    const oneof_pascal = try skribiPascalNomon(allocator, oneof_name);
    defer allocator.free(oneof_pascal);

    const field_pascal = try skribiPascalNomon(allocator, field_name);
    defer allocator.free(field_pascal);

    return try std.fmt.allocPrint(
        allocator,
        "has{s}{s}",
        .{
            oneof_pascal,
            field_pascal,
        },
    );
}

// ============================================================================
// UTILAJOJ PRI NOMOJ
// ============================================================================
pub fn skribiMetodoNomon(
    allocator: std.mem.Allocator,
    prefix: []const u8,
    field_name: []const u8,
) ![]const u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);

    try out.appendSlice(allocator, prefix);

    var capitalize_next = true;

    for (field_name) |c| {
        if (c == '_') {
            capitalize_next = true;
            continue;
        }

        if (capitalize_next) {
            try out.append(allocator, std.ascii.toUpper(c));
            capitalize_next = false;
        } else {
            try out.append(allocator, c);
        }
    }

    return try out.toOwnedSlice(allocator);
}

pub fn skribiPascalNomon(
    allocator: std.mem.Allocator,
    field_name: []const u8,
) ![]const u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);

    var capitalize_next = true;

    for (field_name) |c| {
        if (c == '_') {
            capitalize_next = true;
            continue;
        }

        if (capitalize_next) {
            try out.append(allocator, std.ascii.toUpper(c));
            capitalize_next = false;
        } else {
            try out.append(allocator, c);
        }
    }

    return try out.toOwnedSlice(allocator);
}

// ============================================================================
// IDENTIGILOJ DERIVITAJ DE LA NOMO DE LA DOSIERO .proto (F9)
// ============================================================================
//
// La baza nomo de la .proto-dosiero ne cxiam validas kiel Zig-identigilo:
// "my-proto" (streko), "2fa" (komencigxas per cifero) aux "test"/"error"
// (rezervita vorto) generis kodon, kiu ne kompilas (const my-proto_impl =
// Raw;). Cxi tiuj funkcioj sanigas la nomon por uzi gxin kiel identigilon,
// kaj en la sekura API (*_impl) kaj en la skafaldo --ws (nomspaco).

/// Vortoj, kiuj ne servas kiel deklaracia nomo en Zig: rezervitaj vortoj de
/// la lingvo kaj nomoj de primitivaj tipoj (kiujn oni ne povas ombri). La
/// listo estas pli ol suficxa: se iu eskapas, la generitajxo malsukcesas per
/// klara Zig-eraro kaj oni aldonas gxin cxi tie.
const REZERVITAJ = [_][]const u8{
    "addrspace",      "align",       "allowzero", "and",      "anyframe",
    "anytype",        "asm",         "async",     "await",    "break",
    "callconv",       "catch",       "comptime",  "const",    "continue",
    "defer",          "else",        "enum",      "errdefer", "error",
    "export",         "extern",      "fn",        "for",      "if",
    "inline",         "linksection", "noalias",   "noinline", "nosuspend",
    "opaque",         "or",          "orelse",    "packed",   "pub",
    "resume",         "return",      "struct",    "suspend",  "switch",
    "test",           "threadlocal", "try",       "union",    "unreachable",
    "usingnamespace", "var",         "volatile",  "while",    "bool",
    "void",           "noreturn",    "type",      "anyerror", "undefined",
    "null",           "true",        "false",     "self",     "isize",
    "usize",
};

pub fn estasRezervita(nomo: []const u8) bool {
    for (REZERVITAJ) |rezervita| {
        if (std.mem.eql(u8, nomo, rezervita)) return true;
    }

    // Primitivaj tipoj kun grando (u8, i32, f64...).
    if (nomo.len >= 2 and (nomo[0] == 'u' or nomo[0] == 'i' or nomo[0] == 'f')) {
        var nur_ciferoj = true;
        for (nomo[1..]) |c| {
            if (!std.ascii.isDigit(c)) nur_ciferoj = false;
        }
        if (nur_ciferoj) return true;
    }

    return false;
}

/// CXu oni povas uzi `nomo` rekte kiel deklaracian nomon en Zig?
pub fn uzeblaKielIdent(nomo: []const u8) bool {
    if (nomo.len == 0) return false;
    if (std.ascii.isDigit(nomo[0])) return false;

    for (nomo) |c| {
        if (!std.ascii.isAlphanumeric(c) and c != '_') return false;
    }

    return !estasRezervita(nomo);
}

/// Nomo derivita de la baza nomo de la .proto, kiu JES validas kiel Zig-
/// identigilo: nevalidaj signoj farigxas '_', gxi ne povas komencigxi per
/// cifero kaj ne povas esti rezervita vorto (oni aldonas sufikson "_proto").
pub fn nomoIdentebla(
    allocator: std.mem.Allocator,
    basa: []const u8,
) ![]const u8 {
    var bufro: std.ArrayList(u8) = .empty;
    errdefer bufro.deinit(allocator);

    for (basa, 0..) |c, i| {
        if (std.ascii.isAlphanumeric(c) or c == '_') {
            if (i == 0 and std.ascii.isDigit(c)) try bufro.append(allocator, '_');
            try bufro.append(allocator, c);
        } else {
            try bufro.append(allocator, '_');
        }
    }

    if (bufro.items.len == 0) try bufro.appendSlice(allocator, "proto");
    if (estasRezervita(bufro.items)) try bufro.appendSlice(allocator, "_proto");

    return try bufro.toOwnedSlice(allocator);
}

/// Nomo de la interna aliaso al la krudaj tipoj: `<purigita bazo>_impl` (F9).
pub fn implNomon(
    allocator: std.mem.Allocator,
    basa: []const u8,
) ![]const u8 {
    const sana = try nomoIdentebla(allocator, basa);
    defer allocator.free(sana);

    return try std.fmt.allocPrint(allocator, "{s}_impl", .{sana});
}
