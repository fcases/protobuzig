// ============================================================================
// kgenws.zig
//
// Skafaldo de laborspaco por protobuzig --ws <dir>.
//
// Donite .proto-dosieron, gxi kreas memstaran projekton:
//
//   <ws>/
//     protos/            kopio de la eniga .proto
//     src/
//       main.zig         uzanta kodo: sxangxebla ekzemplo
//       tests.zig        unu rondvoja testo por cxiu kontrakta mesagxo
//       runtime/         CXIO generita: X.zig + X_api.zig + encdec.zig
//     build.zig          demo-exe + pasxoj check/run/test
//     .vscode/           settings/tasks/launch
//     .gitignore
//
// Supozo nur-Zig: sen biblioteko nek radika modulo (root.zig). main kaj
// tests importas src/runtime per relativa vojo. Unu root.zig/pakajxo kaj
// la .a-biblioteko revenos kiam ekzistos ekstera konsumanto (scenaro C:
// fasado super la generita sekura API X_api.zig).
//
// protobuzig vivas sendepende de K6Bus: la laborspaco ne referencas iun
// eksteran runtime; encdec.zig enkorpigxas en la binaron (@embedFile) kaj
// skribigxas en src/runtime kiel parto de la skafaldo.
// ============================================================================

const std = @import("std");
const prs = @import("mecha_prs.zig");

// Nomoj de la metodoj de la sekura API (setXxx/getXxx/appendXxx), por ke
// la ekzemplo de main.zig voku gxuste tion, kion generas kgenapi.
const api_auks = @import("kgapi_auks.zig");

const asignilo = std.heap.page_allocator;

// encdec.zig vivas apud cxi tiu modulo (src/encdec.zig) kaj enkorpigxas
// en la binaron de protobuzig: la laborspaco restas memstara.
const encdec_enhavo = @embedFile("encdec.zig");

const PLANTILO_BUILD =
    \\const std = @import("std");
    \\
    \\pub fn build(b: *std.Build) void {
    \\    const target = b.standardTargetOptions(.{});
    \\    const optimize = b.standardOptimizeOption(.{});
    \\
    \\    // Sen biblioteko nek radika modulo en la supozo nur-Zig: main
    \\    // kaj tests importas src/runtime per relativa vojo. root.zig/pakajxo
    \\    // (kaj la .a-biblioteko) revenos kiam ekzistos ekstera konsumanto
    \\    // (scenaro C: fasado super la generita sekura API).
    \\
    \\    // Ekzempla plenumeblo (src/main.zig): uzanta kodo.
    \\    const main_mod = b.createModule(.{
    \\        .root_source_file = b.path("src/main.zig"),
    \\        .target = target,
    \\        .optimize = optimize,
    \\    });
    \\
    \\    const exe = b.addExecutable(.{
    \\        .name = "%%WS%%",
    \\        .root_module = main_mod,
    \\        .use_llvm = true,
    \\    });
    \\    b.installArtifact(exe);
    \\
    \\    // Run: plenumas la ekzemplon.
    \\    const run_cmd = b.addRunArtifact(exe);
    \\    run_cmd.step.dependOn(b.getInstallStep());
    \\    if (b.args) |args| run_cmd.addArgs(args);
    \\
    \\    const run_step = b.step("run", "Ejecuta el ejemplo de src/main.zig");
    \\    run_step.dependOn(&run_cmd.step);
    \\
    \\    // Check: kompilas la exe sen plenumi.
    \\    const check_step = b.step("check", "Compila sin ejecutar");
    \\    check_step.dependOn(&exe.step);
    \\
    \\    // Test: rondvoja testo por cxiu mesagxo (src/tests.zig).
    \\    const tests_mod = b.createModule(.{
    \\        .root_source_file = b.path("src/tests.zig"),
    \\        .target = target,
    \\        .optimize = optimize,
    \\    });
    \\
    \\    const unit_tests = b.addTest(.{ .root_module = tests_mod });
    \\    const run_tests = b.addRunArtifact(unit_tests);
    \\
    \\    const test_step = b.step("test", "Ejecuta los tests de src/tests.zig");
    \\    test_step.dependOn(&run_tests.step);
    \\}
    \\
;

const PLANTILO_MAIN_CON_MENSAJES =
    \\const std = @import("std");
    \\
    \\// main.zig: kodo de UZANTO.
    \\//
    \\// Ekzemplo generita de protobuzig --ws. Modifu gxin libere por
    \\// meti la logikon de via problemo: krei mesagxojn, plenigi kampojn,
    \\// skribi al dosiero, sxangxi formaton, ktp.
    \\//
    \\// La generitajxo vivas en src/runtime:
    \\//
    \\//     %%BASE%%.zig       RAW-implemento (interna uzo; ne importu gxin)
    \\//     %%BASE%%_api.zig   SEKURA API super la raw: uzu CXI TIU
    \\//     encdec.zig         subteno de seriajxo
    \\//
    \\//     const %%NS%% = @import("runtime/%%BASE%%_api.zig");
    \\//
    \\// La nomspaco portas la nomon de la KONTRAKTO (tiun de la dosiero
    \\// .proto) kaj la ekzempla mesagxo estas la UNUA difinita en gxi.
    \\const %%NS%% = @import("runtime/%%BASE%%_api.zig");
    \\%%ALIAS_LINIO%%
    \\
    \\pub fn main() !void {
    \\    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    \\    defer _ = gpa.deinit();
    \\    const a = gpa.allocator();
    \\
    \\    // 1) Kreu objekton de la mesagxo de la kontrakto.
    \\    var msg = try %%MSG%%.initDefault(a);
    \\    defer msg.deinit(a);
    \\
    \\%%KAMPO%%
    \\
    \\    // 2) Skribu gxin al dosiero kiel Protobuf Text kaj relegu gxin.
    \\    try msg.writeToFile(a, "demo.txt", .TF_PROTOBUF);
    \\    var desde_texto = try %%MSG%%.readFromFile(a, "demo.txt", .TF_PROTOBUF);
    \\    defer desde_texto.deinit(a);
    \\
    \\    // 3) Sxangxu formaton: binara Protocol Buffers, kaj relegu gxin.
    \\    try msg.serializeToFile(a, "demo.pb", .BF_PROTOBUF);
    \\    var desde_binario = try %%MSG%%.deserializeFromFile(a, "demo.pb", .BF_PROTOBUF);
    \\    defer desde_binario.deinit(a);
    \\
    \\    // 4) Montru la enhavon sur la konzolo.
    \\    const texto = try msg.writeToText(a, .TF_PROTOBUF);
    \\    defer a.free(texto);
    \\    std.debug.print("{s}\n", .{texto});
    \\
    \\    std.debug.print("Demo ok: revisa demo.txt y demo.pb en el directorio actual.\n", .{});
    \\}
    \\
;

const PLANTILO_MAIN_SIN_MENSAJES =
    \\const std = @import("std");
    \\
    \\// main.zig: kodo de UZANTO.
    \\//
    \\// La kontrakto %%BASE%%.proto ne difinas mesagxojn (nur enum-ojn kaj
    \\// opciojn), do ne ekzistas ekzempla objekto por krei. Importu la
    \\// generitajxon el src/runtime kiam vi aldonos mesagxojn al la kontrakto.
    \\
    \\pub fn main() !void {
    \\    std.debug.print("El contrato %%BASE%%.proto no define mensajes.\n", .{});
    \\}
    \\
;

/// Komuna korpo de la testoj de la laborspaco: helpilo por rondvojo
/// (Protobuf Text + binara). La tutan dosieron tests.zig konstruas
/// konstruiTestsTekson(): po unu testo por cxiu EKSTERA mesagxo de la
/// kontrakto. Uzas la generitan sekuran API (X_api.zig), ne la raw.
const TESTS_RONDA =
    \\fn ronda(comptime T: type) !void {
    \\    const a = t.allocator;
    \\
    \\    var msg = try T.initDefault(a);
    \\    defer msg.deinit(a);
    \\
    \\    // Protobuf Text: skribi kaj relegi.
    \\    const teksto = try msg.writeToText(a, .TF_PROTOBUF);
    \\    defer a.free(teksto);
    \\    var reteksto = try T.readFromText(a, teksto, .TF_PROTOBUF);
    \\    defer reteksto.deinit(a);
    \\
    \\    // Binara Protocol Buffers: skribi kaj relegi.
    \\    const binara = try msg.serializeToBin(a, .BF_PROTOBUF);
    \\    defer a.free(binara);
    \\    var rebinara = try T.deserializeFromBin(a, binara, .BF_PROTOBUF);
    \\    defer rebinara.deinit(a);
    \\}
    \\
;

const PLANTILO_GITIGNORE =
    \\.zig-cache/
    \\zig-out/
    \\demo.txt
    \\demo.pb
    \\
;

const PLANTILO_SETTINGS =
    \\{
    \\    "zig.zigPath": "/opt/Zig/zig/zig",
    \\    "zig.path": "/opt/Zig/zig/zig",
    \\    "zig.zls.path": "/opt/Zig/zls/zls",
    \\    "zig.libPath": "/opt/Zig/zig/lib",
    \\    "lldb.launch.terminal": "integrated"
    \\}
    \\
;

const PLANTILO_TASKS =
    \\{
    \\    // See https://go.microsoft.com/fwlink/?LinkId=733558
    \\    "version": "2.0.0",
    \\    "tasks": [
    \\        {
    \\            "label": "build %%WS%%",
    \\            "type": "shell",
    \\            "command": "zig build",
    \\            "problemMatcher": [],
    \\            "group": {
    \\                "kind": "build",
    \\                "isDefault": true
    \\            }
    \\        },
    \\        {
    \\            "label": "check %%WS%%",
    \\            "type": "shell",
    \\            "command": "zig build check",
    \\            "problemMatcher": [],
    \\            "group": "build"
    \\        },
    \\        {
    \\            "label": "run %%WS%%",
    \\            "type": "shell",
    \\            "command": "zig build run",
    \\            "problemMatcher": [],
    \\            "group": "build"
    \\        },
    \\        {
    \\            "label": "test %%WS%%",
    \\            "type": "shell",
    \\            "command": "zig build test",
    \\            "problemMatcher": [],
    \\            "group": "build"
    \\        }
    \\    ]
    \\}
    \\
;

const PLANTILO_LAUNCH =
    \\{
    \\    "version": "0.2.0",
    \\    "configurations": [
    \\        {
    \\            "name": "Debug %%WS%%",
    \\            "type": "lldb",
    \\            "request": "launch",
    \\            "program": "${workspaceFolder}/zig-out/bin/%%WS%%",
    \\            "args": [],
    \\            "cwd": "${workspaceFolder}",
    \\            "env": {},
    \\            "console": "integratedTerminal",
    \\            "preLaunchTask": "build %%WS%%"
    \\        }
    \\    ]
    \\}
    \\
;

fn skribiEnhavon(dosiero_nomo: []const u8, enhavo: []const u8) !void {
    var dosiero = try std.fs.cwd().createFile(dosiero_nomo, .{ .truncate = true });
    defer dosiero.close();
    try dosiero.writeAll(enhavo);
}

/// Anstatauxas %%TOKEN%% kaj skribas la dosieron.
fn skribiPlantilon(dosiero_nomo: []const u8, plantilo: []const u8, paroj: []const [2][]const u8) !void {
    var enhavo = try asignilo.dupe(u8, plantilo);

    for (paroj) |paro| {
        const nova = try std.mem.replaceOwned(u8, asignilo, enhavo, paro[0], paro[1]);
        asignilo.free(enhavo);
        enhavo = nova;
    }
    defer asignilo.free(enhavo);

    try skribiEnhavon(dosiero_nomo, enhavo);
}

fn kopiuDosieron(fonto: []const u8, celo: []const u8) !void {
    var en_dosiero = try std.fs.cwd().openFile(fonto, .{});
    defer en_dosiero.close();

    const longo = try en_dosiero.getEndPos();
    const enhavo = try asignilo.alloc(u8, longo);
    defer asignilo.free(enhavo);

    _ = try en_dosiero.readAll(enhavo);
    try skribiEnhavon(celo, enhavo);
}

/// Nomo de la unua mesagxo de la kontrakto. Oni uzas la SIMPLAN nomon
/// (sen la pakajxo de la proto) cxar la skafaldo importas la sekuran API
/// X_api.zig, kies wrapper-oj vivas en la supra nivelo de la dosiero; la
/// pakajxo aperas nur en la raw X.zig (Base.<pakajxo>.<Mesagxo>).
fn unuaMensaghoNomo(proto: *const prs.ProtoFile) ?[]const u8 {
    if (proto.messages.len == 0) return null;

    return proto.messages[0].name;
}

/// Enhavo de src/tests.zig: kapo + ronda() + po UNU rondvoja testo por
/// cxiu EKSTERA (top-level) mesagxo de la kontrakto. La nestitaj mesagxoj
/// ne estas testataj cxi tie (ili vivas ene de sia entena mesagxo).
fn konstruiTestsTekson(proto: *const prs.ProtoFile, basa: []const u8, ns_nomo: []const u8) ![]const u8 {
    var bufro: std.ArrayList(u8) = .empty;
    errdefer bufro.deinit(asignilo);

    try bufro.print(asignilo,
        \\const std = @import("std");
        \\const t = std.testing;
        \\
        \\// tests.zig: po unu rondvoja testo (Protobuf Text + binara) por
        \\// cxiu EKSTERA mesagxo de la kontrakto ({d}); la nestitaj ne
        \\// testigxas cxi tie. Generita de protobuzig --ws: se vi aldonos
        \\// mesagxojn al la .proto, regeneru la laborspacon.
        \\
        \\// Sekura API generita ({s}_api.zig), ne la raw. La wrapper-oj vivas
        \\// en la supra nivelo de la dosiero (sen la pakajxo de la proto) kaj
        \\// la nomspaco portas la nomon de la KONTRAKTO (tiun de la .proto).
        \\const {s} = @import("runtime/{s}_api.zig");
        \\
        \\
    , .{ proto.messages.len, basa, ns_nomo, basa });

    try bufro.appendSlice(asignilo, TESTS_RONDA);

    for (proto.messages) |msg| {
        try bufro.print(asignilo,
            \\
            \\test "{s}: round-trip texto + binario" {{
            \\    try ronda({s}.{s});
            \\}}
            \\
        , .{ msg.name, ns_nomo, msg.name });
    }

    return try bufro.toOwnedSlice(asignilo);
}

/// Ekzempla bloko por la main: plenigas la unuan kampon de la unua
/// mesagxo per montra valoro (montras la tutan ciklon). Se la unua
/// kampo ne estas asignebla per simpla literalo (message, enum,
/// repeated), gxi redonas gvidan komenton TODO.
fn konstruiKampanMontron(proto: *const prs.ProtoFile) ![]const u8 {
    var bufro: std.ArrayList(u8) = .empty;
    errdefer bufro.deinit(asignilo);

    const msg = proto.messages[0];
    if (msg.fields.len == 0) return try bufro.toOwnedSlice(asignilo);

    const f = msg.fields[0];
    const nomo = f.name;

    const es_literal_simple = f.label_enum != .LABEL_REPEATED and switch (f.field_type_enum) {
        .TYPE_BOOL,
        .TYPE_STRING,
        .TYPE_BYTES,
        .TYPE_INT32,
        .TYPE_INT64,
        .TYPE_SINT32,
        .TYPE_SINT64,
        .TYPE_SFIXED32,
        .TYPE_SFIXED64,
        .TYPE_UINT32,
        .TYPE_UINT64,
        .TYPE_FIXED32,
        .TYPE_FIXED64,
        .TYPE_FLOAT,
        .TYPE_DOUBLE,
        => true,
        else => false,
    };

    if (!es_literal_simple) {
        try bufro.appendSlice(asignilo,
            \\    // TODO: plenigu cxi tie viajn kampojn per la sekura API
            \\    // (X_api.zig en src/runtime, ne la raw). Ekzemple:
            \\    //     try msg.setMiString(a, "valor");     // []const u8: kopio
            \\    //     msg.setMiNumero(7);                  // skalaroj
            \\    //     try msg.appendMiLista(a, &elemento); // repeated
            \\
        );
        return try bufro.toOwnedSlice(asignilo);
    }

    // Sama setter-nomo kiel generas kgenapi (set + PascalCase de la kampo).
    const metodo_nomo = try api_auks.skribiSetNomon(asignilo, nomo);
    defer asignilo.free(metodo_nomo);

    try bufro.print(asignilo,
        \\    // Montro en la unua kampo ("{s}") per la sekura API: forigu
        \\    // tion kaj metu vian logikon.
        \\
    , .{nomo});

    switch (f.field_type_enum) {
        .TYPE_STRING, .TYPE_BYTES => {
            try bufro.print(
                asignilo,
                "    try msg.{s}(a, \"valor de ejemplo\");\n",
                .{metodo_nomo},
            );
        },
        .TYPE_BOOL => {
            try bufro.print(asignilo, "    msg.{s}(true);\n", .{metodo_nomo});
        },
        .TYPE_FLOAT, .TYPE_DOUBLE => {
            try bufro.print(asignilo, "    msg.{s}(3.5);\n", .{metodo_nomo});
        },
        else => {
            try bufro.print(asignilo, "    msg.{s}(42);\n", .{metodo_nomo});
        },
    }

    return try bufro.toOwnedSlice(asignilo);
}

pub fn generiWorkshop(
    ws: []const u8,
    basa: []const u8,
    proto_path: []const u8,
    proto: *const prs.ProtoFile,
) !void {
    const ws_nomo = std.fs.path.basename(ws);

    // Dosierujoj de la laborspaco.
    try std.fs.cwd().makePath(ws);
    try std.fs.cwd().makePath(try std.fs.path.join(asignilo, &.{ ws, "protos" }));
    try std.fs.cwd().makePath(try std.fs.path.join(asignilo, &.{ ws, "src", "runtime" }));
    try std.fs.cwd().makePath(try std.fs.path.join(asignilo, &.{ ws, ".vscode" }));

    // 1) Kopio de la eniga .proto en protos/.
    const proto_nuda = std.fs.path.basename(proto_path);
    const proto_celo = try std.fs.path.join(asignilo, &.{ ws, "protos", proto_nuda });
    defer asignilo.free(proto_celo);
    try kopiuDosieron(proto_path, proto_celo);

    // 2) Subteno de seriajxo: encdec.zig en src/runtime.
    const encdec_celo = try std.fs.path.join(asignilo, &.{ ws, "src", "runtime", "encdec.zig" });
    defer asignilo.free(encdec_celo);
    try skribiEnhavon(encdec_celo, encdec_enhavo);

    // 3) Uzantaj dosieroj kaj build (X.zig/X_api.zig jam estis generitaj
    //    fare de la generilo en ws/src/runtime).
    const paroj_base = [_][2][]const u8{
        .{ "%%WS%%", ws_nomo },
        .{ "%%BASE%%", basa },
    };

    try skribiPlantilon(
        try std.fs.path.join(asignilo, &.{ ws, "build.zig" }),
        PLANTILO_BUILD,
        &paroj_base,
    );

    // Main kaj tests: main referencas la unuan mesagxon; tests generas UNU
    // rondvojan teston por cxiu EKSTERA mesagxo de la kontrakto.
    // Ambaux uzas la sekuran API (X_api.zig) kaj kiel nomspacon la nomon de
    // la KONTRAKTO (tiun de la .proto-dosiero, saneigitan al Zig-identigilo):
    //   const r8 = @import("runtime/r8_api.zig");
    //   const PackedMsg = r8.PackedMsg;      // aliaso de la unua mesagxo
    const ns_nomo = try api_auks.nomoIdentebla(asignilo, basa);
    defer asignilo.free(ns_nomo);

    if (unuaMensaghoNomo(proto)) |msg_nomo| {
        const kampo_montro = try konstruiKampanMontron(proto);
        defer asignilo.free(kampo_montro);

        // Komforta aliaso por la ekzempla mesagxo de la main: gxi estas
        // deklarita nur se gxia nomo validas kiel identigilo kaj ne kolizias
        // kun la nomspaco. Se ne, la korpo uzas la kvalifikitan referencon.
        const kun_alias = api_auks.uzeblaKielIdent(msg_nomo) and !std.mem.eql(u8, msg_nomo, ns_nomo);

        const alias_linio = if (kun_alias)
            try std.fmt.allocPrint(
                asignilo,
                "const {s} = {s}.{s};   // la unua mesagxo de la kontrakto",
                .{ msg_nomo, ns_nomo, msg_nomo },
            )
        else
            try asignilo.dupe(u8, "");
        defer asignilo.free(alias_linio);

        const msg_expr = if (kun_alias)
            try asignilo.dupe(u8, msg_nomo)
        else
            try std.fmt.allocPrint(asignilo, "{s}.{s}", .{ ns_nomo, msg_nomo });
        defer asignilo.free(msg_expr);

        const paroj_msg = [_][2][]const u8{
            .{ "%%WS%%", ws_nomo },
            .{ "%%BASE%%", basa },
            .{ "%%NS%%", ns_nomo },
            .{ "%%MSG%%", msg_expr },
            .{ "%%ALIAS_LINIO%%", alias_linio },
            .{ "%%KAMPO%%", kampo_montro },
        };

        try skribiPlantilon(
            try std.fs.path.join(asignilo, &.{ ws, "src", "main.zig" }),
            PLANTILO_MAIN_CON_MENSAJES,
            &paroj_msg,
        );

        const tests_enhavo = try konstruiTestsTekson(proto, basa, ns_nomo);
        defer asignilo.free(tests_enhavo);

        try skribiEnhavon(
            try std.fs.path.join(asignilo, &.{ ws, "src", "tests.zig" }),
            tests_enhavo,
        );
    } else {
        const paroj_msg = [_][2][]const u8{
            .{ "%%WS%%", ws_nomo },
            .{ "%%BASE%%", basa },
        };

        try skribiPlantilon(
            try std.fs.path.join(asignilo, &.{ ws, "src", "main.zig" }),
            PLANTILO_MAIN_SIN_MENSAJES,
            &paroj_msg,
        );

        // tests.zig sen mesagxoj: gvida komento.
        const tests_vacio =
            \\const std = @import("std");
            \\
            \\// La kontrakto %%BASE%%.proto ne difinas mesagxojn: sen testoj.
            \\// Aldonu mesagxojn kaj regeneru per protobuzig --ws.
            \\
        ;
        try skribiPlantilon(
            try std.fs.path.join(asignilo, &.{ ws, "src", "tests.zig" }),
            tests_vacio,
            &paroj_msg,
        );
    }

    // 4) .vscode: settings/tasks/launch.
    try skribiPlantilon(
        try std.fs.path.join(asignilo, &.{ ws, ".vscode", "settings.json" }),
        PLANTILO_SETTINGS,
        &.{},
    );

    try skribiPlantilon(
        try std.fs.path.join(asignilo, &.{ ws, ".gitignore" }),
        PLANTILO_GITIGNORE,
        &.{},
    );

    try skribiPlantilon(
        try std.fs.path.join(asignilo, &.{ ws, ".vscode", "tasks.json" }),
        PLANTILO_TASKS,
        &paroj_base,
    );

    try skribiPlantilon(
        try std.fs.path.join(asignilo, &.{ ws, ".vscode", "launch.json" }),
        PLANTILO_LAUNCH,
        &paroj_base,
    );
}
