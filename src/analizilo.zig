const std = @import("std");
const dbgPrint = std.debug.print;
const shpa = std.heap.page_allocator;
const prs = @import("mecha_prs.zig");

/// Maksimuma numero de kampo laux la protobuf-speco (2^29 - 1). Pli granda
/// numero trunkas la sxlosilon kaj la kampo neniam malcxifrigxos.
const MAKSIMUMA_KAMPO: u32 = 536870911;

///////////////////////////////////////////////////////
///////////////////////////////////////////////////////

/// Legas kaj analizas la .proto-dosieron. `malstrikta` (--lenient) elektas
/// la malnovan konduton "averto kaj dauxrigi" por la linioj, kiujn la sintaksa
/// analizilo ne rekonis; sen gxi tiuj linioj estas ERARO (vidu
/// kontroliIgnoratajnLinojn).
pub fn analiziDosieron(dosieroaNomo: []const u8, presi: bool, malstrikta: bool) !prs.ProtoFile {
    // Konektas ankaux la internajn spurojn de mecha_prs.zig al la flagilo presi.
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
            // gramatika eraro kun pozicio (linio:kolumno) anstataux muta
            // ParseError.
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
                "protobuzig: parse error in {s} (line {d}, column {d}). Use --verbose for parser traces.\n",
                .{ dosieroaNomo, linio, kolumno },
            );
            return error.ParseError;
        },
    }
    if (presi) presiProtoDosieron(pf.*);

    // la sinsekvo gravas - unue la linioj forjxetitaj de la sintaksa
    // analizilo (povas esti tuta mesagxo), poste la AST-kontroloj.
    try kontroliIgnoratajnLinojn(pf.*, nuda_enhavo, malstrikta, dosieroaNomo);

    try validiNedifinitajnTipojn(pf.*, dosieroaNomo);

    try validiKampojn(pf.*, dosieroaNomo);

    return pf.*;
}
// Ankoraux mankas   extensions,

/// linioj de nivelo de dosiero, kiujn la sintaksa analizilo ne rekonis kaj
/// forjxetis (other_line). Antauxe oni nur averis pri ili kaj dauxrigis, sed
/// tia linio povas esti MESAGXO tuta (eraro de sintakso, kampo sen nomo): la
/// kontrakto restus malplena kaj la generita kodo mensogus pri la datumoj.
/// Nun: ERARO (eliro != 0, nenio generita) montrante CXIUJN koncernatajn
/// liniojn; --lenient (malstrikta) reakiras la malnovan averton por kiu scias,
/// kion gxi faras. La numero de linio estas kalkulita sercxante la tekston
/// sinsekve en la enhavo (post forigo de komentoj).
fn kontroliIgnoratajnLinojn(
    pf: prs.ProtoFile,
    enhavo: []const u8,
    malstrikta: bool,
    dosieroaNomo: []const u8,
) !void {
    var cursor: usize = 0;
    var eraro = false;

    for (pf.ignorataj) |linio| {
        if (linio.len == 0) continue;

        var numero_linio: usize = 0;
        if (std.mem.indexOf(u8, enhavo[cursor..], linio)) |encontrada| {
            const pos = cursor + encontrada;
            cursor = pos + linio.len;
            numero_linio = 1;
            for (enhavo[0..pos]) |c| {
                if (c == '\n') numero_linio += 1;
            }
        }

        const fragmento = if (linio.len > 70) linio[0..70] else linio;

        if (malstrikta) {
            std.debug.print(
                "protobuzig: warning: line ignored: '{s}' (unsupported construct or unknown syntax).\n",
                .{fragmento},
            );
            continue;
        }

        eraro = true;
        if (numero_linio > 0) {
            std.debug.print(
                "protobuzig: error: {s}: line {d}: '{s}' was not understood and would be discarded (a dropped message would leave an empty contract). Use --lenient to ignore it as before.\n",
                .{ dosieroaNomo, numero_linio, fragmento },
            );
        } else {
            std.debug.print(
                "protobuzig: error: {s}: '{s}' was not understood and would be discarded . Use --lenient to ignore it as before.\n",
                .{ dosieroaNomo, fragmento },
            );
        }
    }

    if (eraro) return error.IgnoredProtoLine;
}

/// kontrolo de la kampoj de la AST, antaux ol skribi ion ajn:
///   - numero ekster 1..536870911 (la sintaksa analizilo faras 0 el '= -1' kaj
///     el nelegeblaj numeroj, kaj 0 aux tro granda numero perdigxas la kampon
///     en la drato: la malcxifrilo neniam trovos gxin);
///   - duobla numero aux duobla nomo en la sama mesagxo (unu kampo kasxas la
///     alian kaj la dua brancxo de la malcxifrilo estas morta kodo);
///   - kampo sen nomo ('repeated Cia = 4;').
/// Oni kontrolas ankaux la alternativojn de oneof (sama nomspaco kaj sama
/// numero-spaco kiel la ordinaraj kampoj) kaj la internajn mesagxojn.
fn validiKampojn(pf: prs.ProtoFile, dosieroaNomo: []const u8) !void {
    for (pf.messages) |msg| {
        try validiMesagxon(msg, dosieroaNomo);
    }
}

/// Referenco al unu kampo de mesagxo (ordinara aux de oneof), por kontroli
/// numerojn kaj nomojn en unu sola listo.
const KampoRef = struct {
    numero: u32,
    nomo: []const u8,
    tipo: []const u8,
    oneof: ?[]const u8,
};

fn validiMesagxon(msg: prs.Message, dosieroaNomo: []const u8) !void {
    var kampoj = std.ArrayList(KampoRef).empty;
    defer kampoj.deinit(shpa);

    for (msg.fields) |k| {
        kampoj.append(shpa, .{
            .numero = k.number,
            .nomo = k.name,
            .tipo = k.field_type,
            .oneof = null,
        }) catch return error.OutOfMemory;
    }
    for (msg.oneofs) |oneof_decl| {
        for (oneof_decl.fields) |k| {
            kampoj.append(shpa, .{
                .numero = k.number,
                .nomo = k.name,
                .tipo = k.field_type,
                .oneof = oneof_decl.name,
            }) catch return error.OutOfMemory;
        }
    }

    for (kampoj.items) |k| {
        // Por la diagnozo: kie gxi precize estas (oneof aux ne).
        const loko = if (k.oneof) |oo|
            std.fmt.allocPrint(shpa, "in oneof '{s}'", .{oo}) catch return error.OutOfMemory
        else
            shpa.dupe(u8, "not in a oneof") catch return error.OutOfMemory;
        defer shpa.free(loko);

        if (k.numero == 0) {
            std.debug.print(
                "protobuzig: error: {s}: field '{s}' of message '{s}' has number 0 ({s}). Valid numbers are 1..{d}; the wire tag 0 is invalid and 'field = -1' is read as 0.\n",
                .{ dosieroaNomo, k.nomo, msg.name, loko, MAKSIMUMA_KAMPO },
            );
            return error.InvalidFieldNumber;
        }
        if (k.numero > MAKSIMUMA_KAMPO) {
            std.debug.print(
                "protobuzig: error: {s}: field '{s}' of message '{s}' has number {d} ({s}); the maximum is {d} (a larger key is truncated and the field is never decoded).\n",
                .{ dosieroaNomo, k.nomo, msg.name, k.numero, loko, MAKSIMUMA_KAMPO },
            );
            return error.InvalidFieldNumber;
        }
        if (k.nomo.len == 0) {
            std.debug.print(
                "protobuzig: error: {s}: a field of message '{s}' has no name (number {d}, {s}).\n",
                .{ dosieroaNomo, msg.name, k.numero, loko },
            );
            return error.MissingFieldName;
        }
    }

    for (kampoj.items, 0..) |a, i| {
        for (kampoj.items[i + 1 ..]) |b| {
            if (a.numero == b.numero) {
                std.debug.print(
                    "protobuzig: error: {s}: message '{s}' uses number {d} twice: field '{s}' and field '{s}'.\n",
                    .{ dosieroaNomo, msg.name, a.numero, a.nomo, b.nomo },
                );
                return error.DuplicateFieldNumber;
            }
            if (std.mem.eql(u8, a.nomo, b.nomo)) {
                std.debug.print(
                    "protobuzig: error: {s}: message '{s}' uses the name '{s}' twice (numbers {d} and {d}).\n",
                    .{ dosieroaNomo, msg.name, a.nomo, a.numero, b.numero },
                );
                return error.DuplicateFieldName;
            }
        }
    }

    for (msg.internal_msgs) |interna| {
        try validiMesagxon(interna, dosieroaNomo);
    }
}

/// klaraj eraroj por ne difinitaj tipoj. Post la rekonado laux nomo, cxiu
/// kampo, kiu ankoraux estas "ekstera mesagxo supozita" (ne difinita loke), es
/// tajperaro aux referenco al alia dosiero; sen import en la .proto gxi ne
/// povas esti legxosxata ekstera referenco -> eraro kun kunteksto.
fn validiNedifinitajnTipojn(pf: prs.ProtoFile, dosieroaNomo: []const u8) !void {
    if (pf.imports.len > 0) return; // importitaj tipoj: eblas eksteraj referencoj

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
                    "protobuzig: error: undefined type '{s}' in field '{s}' of message '{s}' ({s}).\n",
                    .{ field.field_type, field.name, msg.name, dosieroaNomo },
                );
                return error.UndefinedProtoType;
            }
        }
        for (msg.oneofs) |oneof_decl| {
            for (oneof_decl.fields) |field| {
                if (field.field_type_enum == .TYPE_MESSAGE and !esLocal(pf, field.field_type)) {
                    std.debug.print(
                        "protobuzig: error: undefined type '{s}' in alternative '{s}' of oneof '{s}' of message '{s}' ({s}).\n",
                        .{ field.field_type, field.name, oneof_decl.name, msg.name, dosieroaNomo },
                    );
                    return error.UndefinedProtoType;
                }
            }
        }
    }
}

/// Klara diagnozo de konstruoj, kiujn la generatoro NE subtenas:
/// - syntax = "proto3"  -> eraro (la generatoro produktas proto2-kodon).
/// - service / rpc / extend (nivelo de dosiero) -> eraro.
/// La 'extensions 1000 to max;' EN mesagxoj (proto2, ekz. la fixtures
/// descriptor*.proto) plu ignorigxas: ili ne tusxas la draton de la propraj
/// kampoj de la mesagxo.
fn kontroliNesubtenatajnKonstruojn(enhavo: []const u8) !void {
    var linio: usize = 1;
    var linioj = std.mem.splitScalar(u8, enhavo, '\n');
    while (linioj.next()) |linio_enhavo| : (linio += 1) {
        const nuda = std.mem.trimLeft(u8, linio_enhavo, " \t\r");

        if (std.mem.startsWith(u8, nuda, "syntax")) {
            if (std.mem.indexOf(u8, linio_enhavo, "proto3") != null) {
                std.debug.print(
                    "protobuzig: error: syntax = \"proto3\" is not supported (line {d}); the generator emits proto2 code.\n",
                    .{linio},
                );
                return error.UnsupportedProto3Syntax;
            }
            continue;
        }

        for ([_][]const u8{ "service", "rpc", "extend" }) |konstruo| {
            if (komencePerVorto(nuda, konstruo)) {
                std.debug.print(
                    "protobuzig: error: construct '{s}' is not supported (line {d}).\n",
                    .{ konstruo, linio },
                );
                return error.UnsupportedProtoConstruct;
            }
        }
    }
}

/// True se 'teksto' komencigxas per la vorto 'vorto' (sekvata de fino de linio
/// aux de ne-identiga signo).
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
            // Kommento de linio: forjxeti gxis '\n' (la '\n' kopiigxas en la
            // sekva iteracio: la linioj ne kungluigxas).
            while (i < input.len and input[i] != '\n') : (i += 1) {}
            continue;
        }
        if (i + 1 < input.len and input[i] == '/' and input[i + 1] == '*') {
            // Bloka komento: forjxeti gxis '*''/', konservante la
            // '\n'-ojn por ne mislokigi la linio-numerojn de la diagnozoj.
            i += 2;
            while (i + 1 < input.len and !(input[i] == '*' and input[i + 1] == '/')) {
                if (input[i] == '\n') out.append(shpa, '\n') catch {};
                i += 1;
            }
            i += 2; // konsumi '*' '/' (se ne fermigxis, la buklo finigxas)
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

    // Enumoj ekster mesagxoj
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

        // Enumoj en mesagxo
        for (msg.internal_enums) |en| {
            dbgPrint("    - Enum: {s}\n", .{en.name});
            for (en.values) |v| {
                dbgPrint("        {s} = {d}\n", .{ v.name, v.number });
            }
        }

        // Mesagxoj en mesagxo
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
