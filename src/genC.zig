const std = @import("std");
const shpa = std.heap.page_allocator;
const mpr = @import("mecha_prs.zig");

pub fn generateCBindings(proto_file: *mpr.ProtoFile, out_dir: []const u8) !void {
    var buffer: [256]u8 = .{0} ** 256;
    var buffer2: [256]u8 = .{0} ** 256;

    const punkta_indekso = std.mem.lastIndexOfScalar(u8, out_dir, '.') orelse out_dir.len;
    const basa_nomo = out_dir[0..punkta_indekso];

    const header_file_name = try std.fmt.bufPrint(&buffer, "src_test/generated/{s}.ifz.h", .{basa_nomo});
    var header_file = try std.fs.cwd().createFile(header_file_name, .{ .truncate = true });
    defer header_file.close();

    const zig_file_name = try std.fmt.bufPrint(&buffer2, "src_test/generated/{s}.ifz.zig", .{basa_nomo});
    var zig_file = try std.fs.cwd().createFile(zig_file_name, .{ .truncate = true });
    defer zig_file.close();

    try header_file.writeAll("/* Auto-generated C bindings */\n\n#include <stdint.h>\n#include <stddef.h>\n#include <stdbool.h>\n\n");

    try zig_file.writeAll("const std = @import(\"std\");\n\n");

    for (proto_file.enums) |e| try genEnum(zig_file, e);

    for (proto_file.messages) |m| try genStruct( zig_file, m);

    for (proto_file.messages) |m| try genArrayStruct(header_file, m.name);

    for (proto_file.enums) |e| try genArrayStruct(header_file, e.name);

    for (proto_file.messages) |m| try genArrayFunctions(zig_file, m.name);

    for (proto_file.enums) |e| try genArrayFunctions(zig_file, e.name);
}

// --- Generar enums ---
fn genEnum(header: anytype, e: mpr.Enum) !void {
    try header.writeAll("typedef enum {\n");
    for (e.values) |v| {
        try header.writeAll("    ");
        try header.writeAll(v.name);
        try header.writeAll(" = ");
        try header.writeAll(try std.fmt.allocPrint(shpa, "{d},\n", .{v.number}));
    }
    try header.writeAll("}} ");
    try header.writeAll(e.name);
    try header.writeAll(";\n\n");
}

// --- Generar structs ---
fn genStruct(header: anytype, m: mpr.Message) !void {
    try header.writeAll("typedef struct {\n");
    for (m.fields) |f| {
        const ctype: []const u8 = switch (f.field_type_enum) {
            else => "const char*",
        };
        try header.writeAll("    ");
        try header.writeAll(ctype);
        try header.writeAll(" ");
        try header.writeAll(f.name);
        try header.writeAll(";\n");
    }
    try header.writeAll("} ");
    try header.writeAll(m.name);
    try header.writeAll(";\n\n");
}

// --- Generar arrays ---
fn genArrayStruct(header: anytype, name: []const u8) !void {
    try header.writeAll(try std.fmt.allocPrint(shpa,"typedef struct {{ size_t len; {s}* items; }} {s}Array;\n\n", .{ name, name }));
}

// --- Funciones toC/fromC ---
fn genArrayFunctions(zigy: anytype, name: []const u8) !void {
    try zigy.writeAll(try std.fmt.allocPrint(shpa,"pub extern \"c\" fn {s}Array_toC(arr: []{s}) {s}Array {{\n    return {s}Array{{ .len = arr.len, .items = arr.ptr }};\n}}\n\n", .{ name, name, name, name }));
}
