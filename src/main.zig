const std = @import("std");
const analizilo = @import("analizilo.zig");
const kgen = @import("kgeneratoro.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const dosiero = if (args.len > 1) args.ptr[1] else "proto/example.proto";
    std.debug.print("... analizanta la dosieron: {s}\n", .{dosiero});

    // Analizilo: krei ast-arbon
    var ast_proto_dosiero = try analizilo.analiziDosieron(dosiero, true);
    defer analizilo.liberiProtoDosieron(&ast_proto_dosiero);

    // Koda Generatoro: generi kodan dosieron
    try kgen.generiZigKodon(dosiero, &ast_proto_dosiero);
}
