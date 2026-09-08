// ============================================================================
// kgenws.zig
//
// Andamiaje de workspace para protobuzig --ws <dir>.
//
// Dado un .proto, crea un proyecto autocontenido:
//
//   <ws>/
//     protos/            copia del .proto de entrada
//     src/
//       main.zig         codigo de usuario: ejemplo modificable
//       tests.zig        un test round-trip por mensaje del contrato
//       runtime/         TODO lo generado: X.zig + X_api.zig + encdec.zig
//     build.zig          exe demo + pasos check/run/test
//     .vscode/           settings/tasks/launch
//     .gitignore
//
// Supuesto solo-Zig: sin libreria ni modulo raiz (root.zig). main y tests
// importan src/runtime por ruta relativa. Un root.zig/paquete y la libreria
// .a se reintroduciran cuando exista un consumidor externo (escenario C:
// fachada sobre la API segura generada X_api.zig).
//
// protobuzig vive independiente de K6Bus: el workspace no referencia ningun
// runtime externo; encdec.zig se incrusta en el binario (@embedFile) y se
// escribe en src/runtime como parte del andamiaje.
// ============================================================================

const std = @import("std");
const prs = @import("mecha_prs.zig");

const asignilo = std.heap.page_allocator;

// encdec.zig vive junto a este modulo (src/encdec.zig) y se incrusta en el
// binario de protobuzig: el workspace queda autocontenido.
const encdec_enhavo = @embedFile("encdec.zig");

const PLANTILO_BUILD = 
    \\const std = @import("std");
    \\
    \\pub fn build(b: *std.Build) void {
    \\    const target = b.standardTargetOptions(.{});
    \\    const optimize = b.standardOptimizeOption(.{});
    \\
    \\    // Sin libreria ni modulo raiz en el supuesto solo-Zig: main y tests
    \\    // importan src/runtime por ruta relativa. Un root.zig/paquete (y la
    \\    // libreria .a) se reintroducira cuando exista un consumidor externo
    \\    // (escenario C: fachada sobre la API segura generada).
    \\
    \\    // Ejecutable de ejemplo (src/main.zig): codigo de usuario.
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
    \\    // Run: ejecuta el ejemplo.
    \\    const run_cmd = b.addRunArtifact(exe);
    \\    run_cmd.step.dependOn(b.getInstallStep());
    \\    if (b.args) |args| run_cmd.addArgs(args);
    \\
    \\    const run_step = b.step("run", "Ejecuta el ejemplo de src/main.zig");
    \\    run_step.dependOn(&run_cmd.step);
    \\
    \\    // Check: compila el exe sin ejecutar.
    \\    const check_step = b.step("check", "Compila sin ejecutar");
    \\    check_step.dependOn(&exe.step);
    \\
    \\    // Test: round-trip por mensaje (src/tests.zig).
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
    \\// main.zig: codigo de USUARIO.
    \\//
    \\// Ejemplo generado por protobuzig --ws. Modificalo libremente para
    \\// poner la logica de tu problema: crear mensajes, rellenar campos,
    \\// escribir a fichero, cambiar de formato, etc.
    \\//
    \\// Lo generado vive en src/runtime (X.zig + X_api.zig + encdec.zig);
    \\// importalo desde aqui:
    \\//
    \\//     const Base = @import("runtime/%%BASE%%.zig");
    \\//
    \\const Base = @import("runtime/%%BASE%%.zig");
    \\const Ejemplo = Base.%%MSG%%;
    \\
    \\pub fn main() !void {
    \\    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    \\    defer _ = gpa.deinit();
    \\    const a = gpa.allocator();
    \\
    \\    // 1) Crea un objeto del mensaje del contrato.
    \\    var msg = try Ejemplo.initDefault(a);
    \\    defer msg.deinit(a);
    \\
    \\%%KAMPO%%
    \\
    \\    // 2) Escribelo a fichero como Protobuf Text y leelo de vuelta.
    \\    try msg.skribiAlDosiero(a, "demo.txt", .TF_PROTOBUF);
    \\    var desde_texto = try Ejemplo.legiElDosiero(a, "demo.txt", .TF_PROTOBUF);
    \\    defer desde_texto.deinit(a);
    \\
    \\    // 3) Cambia de formato: binario Protocol Buffers, y leelo de vuelta.
    \\    try msg.seriigiAlDosiero(a, "demo.pb", .BF_PROTOBUF);
    \\    var desde_binario = try Ejemplo.deseriigiElDosiero(a, "demo.pb", .BF_PROTOBUF);
    \\    defer desde_binario.deinit(a);
    \\
    \\    // 4) Muestra el contenido por consola.
    \\    const texto = try msg.skribiAlTeksto(a, .TF_PROTOBUF);
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
    \\// main.zig: codigo de USUARIO.
    \\//
    \\// El contrato %%BASE%%.proto no define mensajes (solo enums/opciones),
    \\// asi que no hay objeto de ejemplo que crear. Importa lo generado
    \\// desde src/runtime cuando anadas mensajes al contrato.
    \\
    \\pub fn main() !void {
    \\    std.debug.print("El contrato %%BASE%%.proto no define mensajes.\n", .{});
    \\}
    \\
;

const PLANTILO_TESTS =
    \\const std = @import("std");
    \\const t = std.testing;
    \\
    \\// tests.zig: un test round-trip (Protobuf Text + binario) por mensaje
    \\// externo del contrato. Generado por protobuzig --ws con el primer
    \\// mensaje; anade aqui un test por cada mensaje nuevo.
    \\
    \\const Base = @import("runtime/%%BASE%%.zig");
    \\
    \\fn ronda(comptime T: type) !void {
    \\    const a = t.allocator;
    \\
    \\    var msg = try T.initDefault(a);
    \\    defer msg.deinit(a);
    \\
    \\    // Protobuf Text: escribir y releer.
    \\    const teksto = try msg.skribiAlTeksto(a, .TF_PROTOBUF);
    \\    defer a.free(teksto);
    \\    var reteksto = try T.legiElTeksto(a, teksto, .TF_PROTOBUF);
    \\    defer reteksto.deinit(a);
    \\
    \\    // Binario Protocol Buffers: escribir y releer.
    \\    const binara = try msg.seriigiAlBin(a, .BF_PROTOBUF);
    \\    defer a.free(binara);
    \\    var rebinara = try T.deseriigiElBin(a, binara, .BF_PROTOBUF);
    \\    defer rebinara.deinit(a);
    \\}
    \\
    \\test "%%MSG_NOMO%%: round-trip texto + binario" {
    \\    try ronda(Base.%%MSG%%);
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

/// Sustituye %%TOKEN%% y escribe el fichero.
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

/// Referencia Zig al primer mensaje del contrato, con su paquete si existe.
fn referencoUnuaMensagho(proto: *const prs.ProtoFile) ?[2][]const u8 {
    if (proto.messages.len == 0) return null;

    const unua = proto.messages[0].name;
    if (proto.package_name) |pkg| {
        if (pkg.len > 0) {
            const tuta = std.fmt.allocPrint(asignilo, "{s}.{s}", .{ pkg, unua }) catch return null;
            return .{ unua, tuta };
        }
    }
    return .{ unua, unua };
}

/// Bloque de ejemplo para el main: rellena el primer campo del primer
/// mensaje con un valor de muestra (demuestra el ciclo completo). Si el
/// primer campo no es asignable con un literal simple (message, enum,
/// repeated), devuelve un comentario TODO guia.
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
        .TYPE_INT32, .TYPE_INT64, .TYPE_SINT32, .TYPE_SINT64,
        .TYPE_SFIXED32, .TYPE_SFIXED64,
        .TYPE_UINT32, .TYPE_UINT64, .TYPE_FIXED32, .TYPE_FIXED64,
        .TYPE_FLOAT, .TYPE_DOUBLE,
        => true,
        else => false,
    };

    if (!es_literal_simple) {
        try bufro.appendSlice(asignilo,
            \\    // TODO: rellena aqui tus campos (consulta los generados en
            \\    // src/runtime). Por ejemplo:
            \\    //     a.free(msg.mi_string);              // libera el default ""
            \\    //     msg.mi_string = try a.dupe(u8, "valor");
            \\    //     msg.mi_numero = 7;
            \\
        );
        return try bufro.toOwnedSlice(asignilo);
    }

    try bufro.print(asignilo,
        \\    // Muestra en el primer campo ("{s}"): quita esto y pon tu logica.
        \\
    , .{nomo});

    switch (f.field_type_enum) {
        .TYPE_STRING, .TYPE_BYTES => {
            if (f.label_enum == .LABEL_REQUIRED) {
                try bufro.print(asignilo, "    a.free(msg.{s});\n", .{nomo});
            } else {
                try bufro.print(asignilo, "    if (msg.{s}) |v| a.free(v);\n", .{nomo});
            }
            try bufro.print(asignilo,
                "    msg.{s} = try a.dupe(u8, \"valor de ejemplo\");\n",
                .{nomo},
            );
        },
        .TYPE_BOOL => {
            try bufro.print(asignilo, "    msg.{s} = true;\n", .{nomo});
        },
        .TYPE_FLOAT, .TYPE_DOUBLE => {
            try bufro.print(asignilo, "    msg.{s} = 3.5;\n", .{nomo});
        },
        else => {
            try bufro.print(asignilo, "    msg.{s} = 42;\n", .{nomo});
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

    // Directorios del workspace.
    try std.fs.cwd().makePath(ws);
    try std.fs.cwd().makePath(try std.fs.path.join(asignilo, &.{ ws, "protos" }));
    try std.fs.cwd().makePath(try std.fs.path.join(asignilo, &.{ ws, "src", "runtime" }));
    try std.fs.cwd().makePath(try std.fs.path.join(asignilo, &.{ ws, ".vscode" }));

    // 1) Copia del .proto de entrada a protos/.
    const proto_nuda = std.fs.path.basename(proto_path);
    const proto_celo = try std.fs.path.join(asignilo, &.{ ws, "protos", proto_nuda });
    defer asignilo.free(proto_celo);
    try kopiuDosieron(proto_path, proto_celo);

    // 2) Soporte de serializacion: encdec.zig en src/runtime.
    const encdec_celo = try std.fs.path.join(asignilo, &.{ ws, "src", "runtime", "encdec.zig" });
    defer asignilo.free(encdec_celo);
    try skribiEnhavon(encdec_celo, encdec_enhavo);

    // 3) Ficheros de usuario y build (los generados X.zig/X_api.zig ya los
    //    escribio el pipeline de generacion en ws/src/runtime).
    const paroj_base = [_][2][]const u8{
        .{ "%%WS%%", ws_nomo },
        .{ "%%BASE%%", basa },
    };

    try skribiPlantilon(
        try std.fs.path.join(asignilo, &.{ ws, "build.zig" }),
        PLANTILO_BUILD,
        &paroj_base,
    );

    // Main y tests: referencian el primer mensaje del contrato.
    if (referencoUnuaMensagho(proto)) |ref| {
        const msg_nomo = ref[0];
        const msg_ref = ref[1];

        const kampo_montro = try konstruiKampanMontron(proto);
        defer asignilo.free(kampo_montro);

        const paroj_msg = [_][2][]const u8{
            .{ "%%WS%%", ws_nomo },
            .{ "%%BASE%%", basa },
            .{ "%%MSG%%", msg_ref },
            .{ "%%MSG_NOMO%%", msg_nomo },
            .{ "%%KAMPO%%", kampo_montro },
        };

        try skribiPlantilon(
            try std.fs.path.join(asignilo, &.{ ws, "src", "main.zig" }),
            PLANTILO_MAIN_CON_MENSAJES,
            &paroj_msg,
        );

        try skribiPlantilon(
            try std.fs.path.join(asignilo, &.{ ws, "src", "tests.zig" }),
            PLANTILO_TESTS,
            &paroj_msg,
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

        // tests.zig sin mensajes: comentario de guia.
        const tests_vacio =
            \\const std = @import("std");
            \\
            \\// El contrato %%BASE%%.proto no define mensajes: sin tests.
            \\// Anade mensajes al contrato y regenera con protobuzig --ws.
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
