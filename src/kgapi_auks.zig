const std = @import("std");

const prs = @import("mecha_prs.zig");

// ============================================================================
// kgapi_auks.zig
// ============================================================================
//
// Helpers auxiliares para kgenapi.zig.
//
// Este fichero contiene utilidades especificas de la API segura generada:
//
//   - deteccion de tipos de campo.
//   - nombres de metodos publicos.
//   - conversion snake_case -> PascalCase.
//   - helpers futuros para append/get/clear.
//
// No debe mezclarse con kgen_auks.zig, que pertenece al generador raw.
//
// ============================================================================

// ============================================================================
// CLASIFICACION DE CAMPOS
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
// NOMBRES DE METODOS
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

// ============================================================================
// UTILIDADES DE NOMBRE
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
