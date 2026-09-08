const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Sin libreria ni modulo raiz en el supuesto solo-Zig: main y tests
    // importan src/runtime por ruta relativa. Un root.zig/paquete (y la
    // libreria .a) se reintroducira cuando exista un consumidor externo
    // (escenario C: fachada sobre la API segura generada).

    // Ejecutable de ejemplo (src/main.zig): codigo de usuario.
    const main_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "prueba1",
        .root_module = main_mod,
        .use_llvm = true,
    });
    b.installArtifact(exe);

    // Run: ejecuta el ejemplo.
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);

    const run_step = b.step("run", "Ejecuta el ejemplo de src/main.zig");
    run_step.dependOn(&run_cmd.step);

    // Check: compila el exe sin ejecutar.
    const check_step = b.step("check", "Compila sin ejecutar");
    check_step.dependOn(&exe.step);

    // Test: round-trip por mensaje (src/tests.zig).
    const tests_mod = b.createModule(.{
        .root_source_file = b.path("src/tests.zig"),
        .target = target,
        .optimize = optimize,
    });

    const unit_tests = b.addTest(.{ .root_module = tests_mod });
    const run_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Ejecuta los tests de src/tests.zig");
    test_step.dependOn(&run_tests.step);
}
