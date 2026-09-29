const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Sen biblioteko nek radika modulo en la supozo nur-Zig: main
    // kaj tests importas src/runtime per relativa vojo. root.zig/pakajxo
    // (kaj la .a-biblioteko) revenos kiam ekzistos ekstera konsumanto
    // (scenaro C: fasado super la generita sekura API).

    // Ekzempla plenumeblo (src/main.zig): uzanta kodo.
    const main_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "demo2",
        .root_module = main_mod,
        .use_llvm = true,
    });
    b.installArtifact(exe);

    // Run: plenumas la ekzemplon.
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);

    const run_step = b.step("run", "Ejecuta el ejemplo de src/main.zig");
    run_step.dependOn(&run_cmd.step);

    // Check: kompilas la exe sen plenumi.
    const check_step = b.step("check", "Compila sin ejecutar");
    check_step.dependOn(&exe.step);

    // Test: rondvoja testo por cxiu mesagxo (src/tests.zig).
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
