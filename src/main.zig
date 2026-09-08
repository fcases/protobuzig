const std = @import("std");
const analizilo = @import("analizilo.zig");
const kgen = @import("kgeneratoro.zig");
const kgapi = @import("kgenapi.zig");
const kgenws = @import("kgenws.zig");
const auks = @import("kgen_auks.zig");

const CliOptions = struct {
    proto_dir: []const u8 = ".",
    output_dir: []const u8 = ".",
    ws_dir: ?[]const u8 = null,
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

    // Con --ws <dir> el andamiaje dirige la generacion a <dir>/src/runtime
    // (ignora --output_dir); sin --ws se escribe en --output_dir.
    const output_dir = if (opts.ws_dir) |ws_dir|
        try std.fs.path.join(allocator, &.{ ws_dir, "src", "runtime" })
    else
        opts.output_dir;
    defer if (opts.ws_dir != null) allocator.free(output_dir);

    // L2: arena de generacion. shpa (kgen_auks) apunta a el durante la
    // generacion: reservar temporales es un bump (rapido) y arenoFini()
    // libera TODO de golpe al terminar (cero fugas). arenoReset() reutiliza
    // los buffers entre la fase raw y la fase API (retain_capacity).
    auks.arenoInici();
    defer auks.arenoFini();

    try kgen.generiZigKodon(
        proto_path,
        output_dir,
        &ast_proto_dosiero,
    );

    auks.arenoReset();

    try kgapi.generiZigAPI(
        proto_path,
        output_dir,
        &ast_proto_dosiero,
    );

    // Andamiaje de workspace: copia del .proto, encdec, main/root/tests de
    // ejemplo, build.zig y .vscode (los generados ya estan en src/runtime).
    if (opts.ws_dir) |ws_dir| {
        const nuda = std.fs.path.basename(proto_path);
        const punkta_indekso = std.mem.lastIndexOfScalar(u8, nuda, '.') orelse nuda.len;
        const basa_nomo = nuda[0..punkta_indekso];

        try kgenws.generiWorkshop(
            ws_dir,
            basa_nomo,
            proto_path,
            &ast_proto_dosiero,
        );
    }
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

        if (std.mem.eql(u8, arg, "--ws")) {
            i += 1;
            if (i >= args.len) return error.MissingWsDirValue;
            opts.ws_dir = args[i];
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
        \\  --ws <dir>             Create a self-contained workspace at <dir>
        \\                         (ignores --output_dir): copies the .proto to
        \\                         <dir>/protos, writes generated .zig + encdec
        \\                         to <dir>/src/runtime, and scaffolds
        \\                         main.zig/root.zig/tests.zig, build.zig and
        \\                         .vscode (settings/tasks/launch).
        \\
        \\  --verbose, -v          Print parser/analyzer traces.
        \\
        \\  --help, -h             Show this help.
        \\
        \\Examples:
        \\  protobuzig Msg.proto
        \\  protobuzig --proto_dir protos/k6bus --output_dir generated/core Msg.proto
        \\  protobuzig --verbose --proto_dir protos/k6bus --output_dir generated/core Packet.proto
        \\  protobuzig --ws miws --proto_dir protos Config.proto
        \\
    ,
        .{},
    );
}
