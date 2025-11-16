const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    //const optimize = b.standardOptimizeOption(.{});
    const optimize: std.builtin.OptimizeMode = .Debug; // It's also possible to define more custom flags to toggle optional features

    const mecha = b.dependency("mecha", .{});

    // const mod = b.addModule("zk6bus_p3", .{
    //     // The root source file is the "entry point" of this module. Users of
    //     // this module will only be able to access public declarations contained
    //     // in this file, which means that if you have declarations that you
    //     // intend to expose to consumers that were defined in other files part
    //     // of this module, you will have to make sure to re-export them from
    //     // the root file.
    //     .root_source_file = b.path("src/root.zig"),
    //     // Later on we'll use this module as the root module of a test executable
    //     // which requires us to specify a target.
    //     .target = target,
    // });

    const exe = b.addExecutable(.{
        .name = "protobuzig",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "mecha", .module = mecha.module("mecha") },
                // .{ .name = "zk6bus_p4", .module = mod },
            },
        }),
    });

    exe.use_llvm = true;

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
}
