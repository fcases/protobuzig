const std = @import("std");
const dbgPrint = std.debug.print;
const shpa = std.heap.page_allocator;
const prs = @import("mecha_prs.zig");

///////////////////////////////////////////////////////
///////////////////////////////////////////////////////

pub fn analiziDosieron(dosieroaNomo: []const u8, presi: bool) !prs.ProtoFile {
    // Conecta tambien las trazas internas de mecha_prs.zig al flag presi/verbose.
    prs.setVerbose(presi);

    const dosiero = try std.fs.cwd().openFile(dosieroaNomo, .{});
    defer dosiero.close();

    const dosiera_long = try dosiero.getEndPos();
    var enhavo = shpa.alloc(u8, dosiera_long + 1) catch return error.OutOfMemory;
    defer shpa.free(enhavo);
    _ = try dosiero.readAll(enhavo[0..dosiera_long]);
    enhavo[dosiera_long] = 0;

    const nuda_enhavo = nudiKomentaijnLinojn(enhavo);
    defer shpa.free(nuda_enhavo);

    const prt_p = prs.protofile_parser;
    const rezulto = try prt_p.parse(shpa, nuda_enhavo);

    var pf: *const prs.ProtoFile = undefined;
    switch (rezulto.value) {
        .ok => |la_pf| {
            pf = &la_pf;
        },
        .err => return error.ParseError,
    }
    if (presi) presiProtoDosieron(pf.*);

    return pf.*;
}
// Me faltan   extensions,

pub fn liberiProtoDosieron(pf: *prs.ProtoFile) void {
    for (pf.messages) |*msg| {
        for (msg.fields) |field| {
            shpa.free(field.label);
            shpa.free(field.field_type);
            shpa.free(field.name);
            if (field.default_value) |d| shpa.free(d);
        }
        shpa.free(msg.fields);
        shpa.free(msg.name);
    }
    shpa.free(pf.messages);

    for (pf.options) |*opt| {
        shpa.free(opt.name);
        shpa.free(opt.value);
    }
    shpa.free(pf.options);
}

fn nudiKomentaijnLinojn(input: []const u8) []const u8 {
    var out = std.ArrayList(u8).empty;

    var i: usize = 0;
    while (i < input.len) : (i += 1) {
        if (i + 1 < input.len and input[i] == '/' and input[i + 1] == '/') {
            // saltar hasta el final de la línea
            while (i < input.len and input[i] != '\n') : (i += 1) {}
        } else {
            out.append(shpa, input[i]) catch {};
        }
    }
    return out.toOwnedSlice(shpa) catch input;
}

fn presiProtoDosieron(ast: prs.ProtoFile) void {
    dbgPrint("\n\n=========\n", .{});
    dbgPrint("Syntax: {s}\n\n", .{ast.syntax});

    dbgPrint("Imports:\n", .{});
    for (ast.imports) |imp| {
        dbgPrint("  {s}\n", .{imp});
    }
    dbgPrint("\n", .{});

    dbgPrint("Package: {s}\n\n", .{ast.package_name orelse "none"});

    dbgPrint("Options:\n", .{});
    for (ast.options) |opt| {
        dbgPrint("  {s} = {s}\n", .{ opt.name, opt.value });
    }
    dbgPrint("\n", .{});

    // Enums fuera de mensajes
    dbgPrint("Enums:\n", .{});
    for (ast.enums) |en| {
        dbgPrint("  Enum: {s}\n", .{en.name});
        for (en.values) |v| {
            dbgPrint("    {s} = {d}\n", .{ v.name, v.number });
        }
    }
    dbgPrint("\n", .{});

    dbgPrint("Messages:\n", .{});
    for (ast.messages) |msg| {
        dbgPrint("  Message: {s}\n", .{msg.name});
        for (msg.fields) |field| {
            const def_value: []const u8 = field.default_value orelse "void";
            const pck_value: []const u8 = if (field.label_enum == .LABEL_REPEATED and field.packed_value) ", packed" else "";
            dbgPrint("    {d}: {s} := {s} ( {s} , [{s}{s}] )\n", .{ field.number, field.name, field.field_type, field.label, def_value, pck_value });
        }

        // Enums dentro de mensaje
        for (msg.internal_enums) |en| {
            dbgPrint("    - Enum: {s}\n", .{en.name});
            for (en.values) |v| {
                dbgPrint("        {s} = {d}\n", .{ v.name, v.number });
            }
        }

        // Mensajes dentro de mensaje
        for (msg.internal_msgs) |imsg| {
            dbgPrint("    - Message: {s}\n", .{imsg.name});
            for (imsg.fields) |field| {
                const def_value: []const u8 = field.default_value orelse "void";
                const pck_value: []const u8 = if (field.label_enum == .LABEL_REPEATED and field.packed_value) ", packed" else "";
                dbgPrint("        {d}: {s} := {s} ( {s} , [{s}{s}] )\n", .{ field.number, field.name, field.field_type, field.label, def_value, pck_value });
            }
        }

        dbgPrint("\n", .{});
    }
}
