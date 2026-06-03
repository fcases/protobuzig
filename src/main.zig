const std = @import("std");
const analizilo = @import("analizilo.zig");
const kgen = @import("kgeneratoro.zig");

const CliOptions = struct {
    proto_dir: []const u8 = ".",
    output_dir: []const u8 = ".",
    proto_file: ?[]const u8 = null,
    verbose: bool = false,
    help: bool = false,
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const opts = try parseArgs(args);

    // Sin parametros o con --help/-h: mostrar ayuda y salir sin error.
    if (args.len == 1 or opts.help) {
        printHelp();
        return;
    }

    const proto_file = opts.proto_file orelse {
        printHelp();
        return error.MissingProtoFile;
    };

    const proto_path = try std.fs.path.join(
        allocator,
        &.{ opts.proto_dir, proto_file },
    );
    defer allocator.free(proto_path);

    if (opts.verbose) {
        std.debug.print("... analizanta la dosieron: {s}\n", .{proto_path});
    }

    var ast_proto_dosiero = try analizilo.analiziDosieron(
        proto_path,
        opts.verbose,
    );
    defer analizilo.liberiProtoDosieron(&ast_proto_dosiero);

    try kgen.generiZigKodon(
        proto_path,
        opts.output_dir,
        &ast_proto_dosiero,
    );
}

fn parseArgs(args: []const []const u8) !CliOptions {
    var opts = CliOptions{};

    var i: usize = 1;
    while (i < args.len) {
        const arg = args[i];

        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            opts.help = true;
            i += 1;
            continue;
        }

        if (std.mem.eql(u8, arg, "--verbose") or std.mem.eql(u8, arg, "-v")) {
            opts.verbose = true;
            i += 1;
            continue;
        }

        if (std.mem.eql(u8, arg, "--proto_dir")) {
            i += 1;
            if (i >= args.len) return error.MissingProtoDirValue;
            opts.proto_dir = args[i];
            i += 1;
            continue;
        }

        if (std.mem.eql(u8, arg, "--output_dir")) {
            i += 1;
            if (i >= args.len) return error.MissingOutputDirValue;
            opts.output_dir = args[i];
            i += 1;
            continue;
        }

        if (std.mem.startsWith(u8, arg, "--")) {
            std.debug.print("Unknown option: {s}\n\n", .{arg});
            printHelp();
            return error.UnknownOption;
        }

        if (opts.proto_file != null) {
            printHelp();
            return error.TooManyProtoFiles;
        }

        opts.proto_file = arg;
        i += 1;
    }

    return opts;
}

fn printHelp() void {
    std.debug.print(
        \\Usage:
        \\  protobuzig [options] file.proto
        \\
        \\Options:
        \\  --proto_dir <dir>      Directory where input .proto is searched.
        \\                         Default: "."
        \\
        \\  --output_dir <dir>     Directory where generated .zig is written.
        \\                         Default: "."
        \\
        \\  --verbose, -v          Print parser/analyzer traces.
        \\
        \\  --help, -h             Show this help.
        \\
        \\Examples:
        \\  protobuzig Msg.proto
        \\  protobuzig --proto_dir protos/k6bus --output_dir generated/core Msg.proto
        \\  protobuzig --verbose --proto_dir protos/k6bus --output_dir generated/core Packet.proto
        \\
        ,
        .{},
    );
}
