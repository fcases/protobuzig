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

    const nuda_enhavo = nudiKomentaijnLinojn(enhavo[0..dosiera_long]);
    defer shpa.free(nuda_enhavo);

    try kontroliNesubtenatajnKonstruojn(nuda_enhavo);

    const prt_p = prs.protofile_parser;
    const rezulto = try prt_p.parse(shpa, nuda_enhavo);

    var pf: *const prs.ProtoFile = undefined;
    switch (rezulto.value) {
        .ok => |la_pf| {
            pf = &la_pf;
        },
        .err => {
            // F5: error de gramatica con posicion (linea:columna) en vez de
            // un ParseError mudo.
            const idx = @min(rezulto.index, nuda_enhavo.len);
            var linio: usize = 1;
            var kolumno: usize = 1;
            for (nuda_enhavo[0..idx]) |c| {
                if (c == '\n') {
                    linio += 1;
                    kolumno = 1;
                } else {
                    kolumno += 1;
                }
            }
            std.debug.print(
                "protobuzig: error de parseo en {s} (linea {d}, columna {d}). Usa --verbose para trazas del parser.\n",
                .{ dosieroaNomo, linio, kolumno },
            );
            return error.ParseError;
        },
    }
    if (presi) presiProtoDosieron(pf.*);

    try avertiIgnoratajnLinojn(pf.*, nuda_enhavo);

    try validiNedifinitajnTipojn(pf.*, dosieroaNomo);

    return pf.*;
}
// Me faltan   extensions,

/// F5: aviso (no error) por cada linea de nivel fichero que el parser no
/// reconocio y descarto (other_line). El usuario del proto decide que hacer:
/// modificarlo o asumirlo. Se calcula el numero de linea buscando el texto
/// en el contenido (tras quitar comentarios) de forma secuencial.
fn avertiIgnoratajnLinojn(pf: prs.ProtoFile, enhavo: []const u8) !void {
    var cursor: usize = 0;
    for (pf.ignorataj) |linio| {
        if (linio.len == 0) continue;

        const encontrada = std.mem.indexOf(u8, enhavo[cursor..], linio) orelse {
            std.debug.print(
                "protobuzig: aviso: linea ignorada: '{s}' (constructo no soportado o sintaxis desconocida).\n",
                .{linio},
            );
            continue;
        };
        const pos = cursor + encontrada;
        cursor = pos + linio.len;

        var numero_linio: usize = 1;
        for (enhavo[0..pos]) |c| {
            if (c == '\n') numero_linio += 1;
        }

        const fragmento = if (linio.len > 70) linio[0..70] else linio;
        std.debug.print(
            "protobuzig: aviso: linea {d}: '{s}' (constructo no soportado o sintaxis desconocida; ignorada).\n",
            .{ numero_linio, fragmento },
        );
    }
}

/// F5: errores limpios para tipos no definidos. Tras la resolucion por
/// nombre, cualquier campo cuyo tipo siga contando como "message asumido
/// externo" (no definido localmente) es un typo o una referencia a otro
/// fichero; sin imports en el proto no puede ser una referencia externa
/// legitima -> error con contexto.
fn validiNedifinitajnTipojn(pf: prs.ProtoFile, dosieroaNomo: []const u8) !void {
    if (pf.imports.len > 0) return; // referencias cross-file: territorio R7

    const esLocal = struct {
        fn aplicar(la_pf: prs.ProtoFile, tipo: []const u8) bool {
            for (la_pf.messages) |mm| {
                if (std.mem.eql(u8, mm.name, tipo)) return true;
            }
            for (la_pf.enums) |en| {
                if (std.mem.eql(u8, en.name, tipo)) return true;
            }
            return false;
        }
    }.aplicar;

    for (pf.messages) |msg| {
        for (msg.fields) |field| {
            if (field.field_type_enum == .TYPE_MESSAGE and !esLocal(pf, field.field_type)) {
                std.debug.print(
                    "protobuzig: error: tipo no definido '{s}' en el campo '{s}' del mensaje '{s}' ({s}).\n",
                    .{ field.field_type, field.name, msg.name, dosieroaNomo },
                );
                return error.UndefinedProtoType;
            }
        }
        for (msg.oneofs) |oneof_decl| {
            for (oneof_decl.fields) |field| {
                if (field.field_type_enum == .TYPE_MESSAGE and !esLocal(pf, field.field_type)) {
                    std.debug.print(
                        "protobuzig: error: tipo no definido '{s}' en la alternativa '{s}' del oneof '{s}' del mensaje '{s}' ({s}).\n",
                        .{ field.field_type, field.name, oneof_decl.name, msg.name, dosieroaNomo },
                    );
                    return error.UndefinedProtoType;
                }
            }
        }
    }
}

/// Diagnostico limpio de constructos que el generador NO soporta y que antes
/// se descartaban en silencio (F5, parte):
/// - syntax = "proto3"  -> error (el generador produce codigo proto2).
/// - service / rpc / extend (nivel top) -> error.
/// Los 'extensions 1000 to max;' DENTRO de mensajes (proto2, p. ej. los
/// fixtures descriptor*.proto) se siguen ignorando: no afectan al wire de
/// los campos propios del mensaje.
fn kontroliNesubtenatajnKonstruojn(enhavo: []const u8) !void {
    var linio: usize = 1;
    var linioj = std.mem.splitScalar(u8, enhavo, '\n');
    while (linioj.next()) |linio_enhavo| : (linio += 1) {
        const nuda = std.mem.trimLeft(u8, linio_enhavo, " \t\r");

        if (std.mem.startsWith(u8, nuda, "syntax")) {
            if (std.mem.indexOf(u8, linio_enhavo, "proto3") != null) {
                std.debug.print(
                    "protobuzig: error: syntax = \"proto3\" no soportado (linea {d}); el generador produce codigo proto2.\n",
                    .{linio},
                );
                return error.UnsupportedProto3Syntax;
            }
            continue;
        }

        for ([_][]const u8{ "service", "rpc", "extend" }) |konstruo| {
            if (komencePerVorto(nuda, konstruo)) {
                std.debug.print(
                    "protobuzig: error: constructo '{s}' no soportado (linea {d}).\n",
                    .{ konstruo, linio },
                );
                return error.UnsupportedProtoConstruct;
            }
        }
    }
}

/// True si 'teksto' empieza por la palabra 'vorto' (seguida de fin de linea o
/// de un caracter no-identificador).
fn komencePerVorto(teksto: []const u8, vorto: []const u8) bool {
    if (!std.mem.startsWith(u8, teksto, vorto)) return false;
    if (teksto.len == vorto.len) return true;
    const sekva = teksto[vorto.len];
    return !std.ascii.isAlphanumeric(sekva) and sekva != '_';
}

pub fn liberiProtoDosieron(pf: *prs.ProtoFile) void {
    for (pf.messages) |*msg| {
        for (msg.fields) |field| {
            shpa.free(field.label);
            shpa.free(field.field_type);
            shpa.free(field.name);
            if (field.default_value) |d| shpa.free(d);
        }
        shpa.free(msg.fields);

        for (msg.oneofs) |oneof_decl| {
            shpa.free(oneof_decl.name);
            for (oneof_decl.fields) |field| {
                shpa.free(field.field_type);
                shpa.free(field.name);
                if (field.default_value) |d| shpa.free(d);
            }
            shpa.free(oneof_decl.fields);
        }
        shpa.free(msg.oneofs);

        shpa.free(msg.name);
    }
    shpa.free(pf.messages);

    for (pf.options) |*opt| {
        shpa.free(opt.name);
        shpa.free(opt.value);
    }
    shpa.free(pf.options);

    for (pf.ignorataj) |linio| {
        shpa.free(linio);
    }
    shpa.free(pf.ignorataj);
}

fn nudiKomentaijnLinojn(input: []const u8) []const u8 {
    var out = std.ArrayList(u8).empty;

    var i: usize = 0;
    while (i < input.len) {
        if (i + 1 < input.len and input[i] == '/' and input[i + 1] == '/') {
            // comentario de linea: descartar hasta '\n' (el '\n' se copia
            // en la siguiente iteracion: las lineas no se fusionan).
            while (i < input.len and input[i] != '\n') : (i += 1) {}
            continue;
        }
        if (i + 1 < input.len and input[i] == '/' and input[i + 1] == '*') {
            // comentario de bloque (F5, parte): descartar hasta '*''/',
            // conservando los '\n' para no descuadrar los numeros de linea
            // de los diagnosticos posteriores.
            i += 2;
            while (i + 1 < input.len and !(input[i] == '*' and input[i + 1] == '/')) {
                if (input[i] == '\n') out.append(shpa, '\n') catch {};
                i += 1;
            }
            i += 2; // consumir '*' '/' (si no cerro, termina el bucle)
            continue;
        }
        out.append(shpa, input[i]) catch {};
        i += 1;
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

        for (msg.oneofs) |oneof_decl| {
            dbgPrint("    - OneOf: {s}\n", .{oneof_decl.name});
            for (oneof_decl.fields) |field| {
                const def_value: []const u8 = field.default_value orelse "void";
                const pck_value: []const u8 = if (field.packed_value) ", packed" else "";
                dbgPrint(
                    "        {d}: {s} := {s} ( [ {s}{s} ] )\n",
                    .{ field.number, field.name, field.field_type, def_value, pck_value },
                );
            }
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
