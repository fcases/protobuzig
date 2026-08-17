const std = @import("std");

// -----------------------------------------------------------------------------
// testo3.zig
// -----------------------------------------------------------------------------
//
// Test minimo para validar la primera capa API generada por kgenapi.zig.
//
// Suposicion de directorio:
//
//   testo3.zig
//   generated/cctrol.zig
//   generated/cctrol_api.zig
//   generated/encdec.zig
//
// Es decir, todos los ficheros necesarios estan en el mismo directorio.
//
// Compilacion manual desde ese directorio:
//
//   zig build-exe testo3.zig
//   ./testo3
//
// O con salida explicita:
//
//   zig build-exe testo3.zig -femit-bin=testo3
//   ./testo3
//
// Objetivo:
//
//   - Crear un EstMeteo usando cctrol_api.zig.
//   - Serializarlo a binario protobuf.
//   - Deserializarlo de vuelta.
//   - Escribirlo a Protobuf Text.
//   - Leerlo de vuelta desde Protobuf Text.
//   - Cerrar todo sin leaks.
//
// De momento NO se usan setters de campo en la API, porque todavia no los hemos
// generado en cctrol_api.zig. Para rellenar campos se toca api.impl directamente.
// Esto es temporal y justamente es lo que eliminaremos cuando generemos setters.
//
// -----------------------------------------------------------------------------

const Api = @import("generated/cctrol_api.zig");
const ConfigApi = @import("generated/Config_api.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const result = gpa.deinit();
        if (result == .leak) {
            std.debug.print("testo3: GPA detected leaks\n", .{});
        }
    }

    const allocator = gpa.allocator();

    try testEstMeteoRoundTripBinario(allocator);
    try testEstMeteoRoundTripTexto(allocator);

    try testOptionales(allocator);
    try testRepeatedScalar(allocator);
    try testRepeatedString(allocator);
    try testOptionalDefaultPresencia(allocator);

    std.debug.print("testo3: OK\n", .{});
}

fn testOptionalDefaultPresencia(
    allocator: std.mem.Allocator,
) !void {
    var cfg = try ConfigApi.AppConfig.initDefault(allocator);
    defer cfg.deinit(allocator);

    // optional con default explicito:
    // initDefault() materializa el default como valor presente.
    try std.testing.expect(cfg.hasActivateTrace());
    try std.testing.expectEqual(
        @as(?bool, false),
        cfg.getActivateTrace(),
    );

    // Lo seteamos de nuevo al mismo valor default para validar que
    // optional presente con valor default se serializa igualmente.
    cfg.setActivateTrace(false);

    try std.testing.expect(cfg.hasActivateTrace());
    try std.testing.expectEqual(
        @as(?bool, false),
        cfg.getActivateTrace(),
    );

    const bin = try cfg.serializeToBin(
        allocator,
        .BF_PROTOBUF,
    );
    defer allocator.free(bin);

    var cfg2 = try ConfigApi.AppConfig.deserializeFromBin(
        allocator,
        bin,
        .BF_PROTOBUF,
    );
    defer cfg2.deinit(allocator);

    try std.testing.expect(cfg2.hasActivateTrace());
    try std.testing.expectEqual(
        @as(?bool, false),
        cfg2.getActivateTrace(),
    );

    const bin_b64 = try cfg.serializeToBin(
        allocator,
        .BF_BASE64,
    );
    defer allocator.free(bin_b64);

    std.debug.print(
        "testo3: AppConfig activate_trace=false BF_BASE64 = {s}\n",
        .{bin_b64},
    );

    var cfg3 = try ConfigApi.AppConfig.deserializeFromBin(
        allocator,
        bin_b64,
        .BF_BASE64,
    );
    defer cfg3.deinit(allocator);

    try std.testing.expect(cfg3.hasActivateTrace());
    try std.testing.expectEqual(
        @as(?bool, false),
        cfg3.getActivateTrace(),
    );

    // clearX() si debe llevarlo a null.
    cfg3.clearActivateTrace();

    try std.testing.expect(!cfg3.hasActivateTrace());
    try std.testing.expectEqual(
        @as(?bool, null),
        cfg3.getActivateTrace(),
    );

    std.debug.print(
        "testo3: optional default AppConfig.activate_trace OK\n",
        .{},
    );
}

fn testRepeatedString(allocator: std.mem.Allocator) !void {
    var cfg = try ConfigApi.UnixSocketStarConfig.initDefault(allocator);
    defer cfg.deinit(allocator);

    try cfg.setLocalSocketPath(allocator, "/tmp/local.sock");

    try cfg.appendRemoteSocketPaths(allocator, "/tmp/remote-a.sock");
    try cfg.appendRemoteSocketPaths(allocator, "/tmp/remote-b.sock");

    try std.testing.expectEqual(
        @as(usize, 2),
        cfg.getRemoteSocketPathsCount(),
    );

    try std.testing.expect(
        std.mem.eql(
            u8,
            try cfg.getRemoteSocketPathsAt(0),
            "/tmp/remote-a.sock",
        ),
    );

    try std.testing.expect(
        std.mem.eql(
            u8,
            try cfg.getRemoteSocketPathsAt(1),
            "/tmp/remote-b.sock",
        ),
    );

    const bin = try cfg.serializeToBin(
        allocator,
        .BF_PROTOBUF,
    );
    defer allocator.free(bin);

    var cfg2 = try ConfigApi.UnixSocketStarConfig.deserializeFromBin(
        allocator,
        bin,
        .BF_PROTOBUF,
    );
    defer cfg2.deinit(allocator);

    try std.testing.expectEqual(
        @as(usize, 2),
        cfg2.getRemoteSocketPathsCount(),
    );

    try std.testing.expect(
        std.mem.eql(
            u8,
            try cfg2.getRemoteSocketPathsAt(0),
            "/tmp/remote-a.sock",
        ),
    );

    try std.testing.expect(
        std.mem.eql(
            u8,
            try cfg2.getRemoteSocketPathsAt(1),
            "/tmp/remote-b.sock",
        ),
    );

    try cfg2.setRemoteSocketPaths(
        allocator,
        &[_][]const u8{
            "/tmp/set-a.sock",
            "/tmp/set-b.sock",
        },
    );

    try std.testing.expectEqual(
        @as(usize, 2),
        cfg2.getRemoteSocketPathsCount(),
    );

    try std.testing.expect(
        std.mem.eql(
            u8,
            try cfg2.getRemoteSocketPathsAt(0),
            "/tmp/set-a.sock",
        ),
    );

    try std.testing.expect(
        std.mem.eql(
            u8,
            try cfg2.getRemoteSocketPathsAt(1),
            "/tmp/set-b.sock",
        ),
    );

    try cfg2.clearRemoteSocketPaths(allocator);

    try std.testing.expectEqual(
        @as(usize, 0),
        cfg2.getRemoteSocketPathsCount(),
    );

    std.debug.print(
        "testo3: repeated string UnixSocketStarConfig.remote_socket_paths OK\n",
        .{},
    );
}

fn testRepeatedScalar(allocator: std.mem.Allocator) !void {
    var trafico = try Api.SnrTrafico.initDefault(allocator);
    defer trafico.deinit(allocator);

    try trafico.setSeccion(allocator, "A-23/KM-12");
    trafico.setCarriles(2);

    try trafico.appendVelMedia(allocator, 82.5);
    try trafico.appendVelMedia(allocator, 79.2);

    try trafico.appendVehiculosMin(allocator, 24.0);
    try trafico.appendVehiculosMin(allocator, 21.0);

    try std.testing.expectEqual(
        @as(usize, 2),
        trafico.getVelMediaCount(),
    );

    try std.testing.expectEqual(
        @as(usize, 2),
        trafico.getVehiculosMinCount(),
    );

    try std.testing.expect(
        approxEqAbs(
            f32,
            try trafico.getVelMediaAt(0),
            82.5,
            0.001,
        ),
    );

    try std.testing.expect(
        approxEqAbs(
            f32,
            try trafico.getVelMediaAt(1),
            79.2,
            0.001,
        ),
    );

    try std.testing.expect(
        approxEqAbs(
            f32,
            try trafico.getVehiculosMinAt(0),
            24.0,
            0.001,
        ),
    );

    try std.testing.expect(
        approxEqAbs(
            f32,
            try trafico.getVehiculosMinAt(1),
            21.0,
            0.001,
        ),
    );

    const bin = try trafico.serializeToBin(
        allocator,
        .BF_PROTOBUF,
    );
    defer allocator.free(bin);

    var trafico2 = try Api.SnrTrafico.deserializeFromBin(
        allocator,
        bin,
        .BF_PROTOBUF,
    );
    defer trafico2.deinit(allocator);

    const text = try trafico2.writeToText(allocator, .TF_JSON);
    defer allocator.free(text);
    std.debug.print("testo3: trafico2 = \n {s}\n", .{text});

    try std.testing.expectEqual(
        @as(usize, 2),
        trafico2.getVelMediaCount(),
    );

    try std.testing.expectEqual(
        @as(usize, 2),
        trafico2.getVehiculosMinCount(),
    );

    try std.testing.expect(
        approxEqAbs(
            f32,
            try trafico2.getVelMediaAt(0),
            82.5,
            0.001,
        ),
    );

    try std.testing.expect(
        approxEqAbs(
            f32,
            try trafico2.getVelMediaAt(1),
            79.2,
            0.001,
        ),
    );

    try std.testing.expect(
        approxEqAbs(
            f32,
            try trafico2.getVehiculosMinAt(0),
            24.0,
            0.001,
        ),
    );

    try std.testing.expect(
        approxEqAbs(
            f32,
            try trafico2.getVehiculosMinAt(1),
            21.0,
            0.001,
        ),
    );

    try trafico2.clearVelMedia(allocator);

    try std.testing.expectEqual(
        @as(usize, 0),
        trafico2.getVelMediaCount(),
    );

    try trafico2.setVelMedia(
        allocator,
        &[_]f32{
            90.0,
            91.5,
        },
    );

    try std.testing.expectEqual(
        @as(usize, 2),
        trafico2.getVelMediaCount(),
    );

    try std.testing.expect(
        approxEqAbs(
            f32,
            try trafico2.getVelMediaAt(0),
            90.0,
            0.001,
        ),
    );

    try std.testing.expect(
        approxEqAbs(
            f32,
            try trafico2.getVelMediaAt(1),
            91.5,
            0.001,
        ),
    );

    try trafico2.clearVehiculosMin(allocator);

    try std.testing.expectEqual(
        @as(usize, 0),
        trafico2.getVehiculosMinCount(),
    );

    try trafico2.setVehiculosMin(
        allocator,
        &[_]f32{
            30.0,
            31.5,
        },
    );

    try std.testing.expectEqual(
        @as(usize, 2),
        trafico2.getVehiculosMinCount(),
    );

    try std.testing.expect(
        approxEqAbs(
            f32,
            try trafico2.getVehiculosMinAt(0),
            30.0,
            0.001,
        ),
    );

    try std.testing.expect(
        approxEqAbs(
            f32,
            try trafico2.getVehiculosMinAt(1),
            31.5,
            0.001,
        ),
    );

    std.debug.print(
        "testo3: repeated scalar SnrTrafico OK seccion={s} carriles={d} vel_count={d} veh_count={d}\n",
        .{
            trafico2.getSeccion(),
            trafico2.getCarriles(),
            trafico2.getVelMediaCount(),
            trafico2.getVehiculosMinCount(),
        },
    );
}

fn testOptionales(allocator: std.mem.Allocator) !void {
    var cfg = try ConfigApi.AppConfig.initDefault(allocator);
    defer cfg.deinit(allocator);

    cfg.setVersion(1);
    try std.testing.expect(cfg.hasVersion());
    try std.testing.expectEqual(@as(?u32, 1), cfg.getVersion());
    cfg.clearVersion();
    try std.testing.expect(!cfg.hasVersion());
    try std.testing.expectEqual(@as(?u32, null), cfg.getVersion());
}

fn testEstMeteoRoundTripBinario(allocator: std.mem.Allocator) !void {
    var meteo = try Api.EstMeteo.initDefault(allocator);
    defer meteo.deinit(allocator);

    try meteo.setNombre(allocator, "meteo-api-1");
    meteo.setTemp(23);
    meteo.setVViento(14.5);
    meteo.setDirViento(270.0);

    const bin = try meteo.serializeToBin(
        allocator,
        .BF_PROTOBUF,
    );
    defer allocator.free(bin);

    var meteo2 = try Api.EstMeteo.deserializeFromBin(
        allocator,
        bin,
        .BF_PROTOBUF,
    );
    defer meteo2.deinit(allocator);

    try expectEstMeteo(
        meteo2,
        "meteo-api-1",
        23,
        14.5,
        270.0,
    );

    std.debug.print(
        "testo3: bin roundtrip EstMeteo OK nombre={s} temp={d} viento={d:.2} dir={d:.2}\n",
        .{
            meteo2.getNombre(),
            meteo2.getTemp(),
            meteo2.getVViento(),
            meteo2.getDirViento(),
        },
    );
}

fn testEstMeteoRoundTripTexto(allocator: std.mem.Allocator) !void {
    var meteo = try Api.EstMeteo.initDefault(allocator);
    defer meteo.deinit(allocator);

    try meteo.setNombre(allocator, "meteo-api-1");
    meteo.setTemp(24);
    meteo.setVViento(13.5);
    meteo.setDirViento(180.1);

    const text = try meteo.writeToText(
        allocator,
        .TF_ZIG_ZON,
    );
    defer allocator.free(text);
    std.debug.print("{s}\n", .{text});

    var meteo2 = try Api.EstMeteo.readFromText(
        allocator,
        text,
        .TF_ZIG_ZON,
    );
    defer meteo2.deinit(allocator);

    try expectEstMeteo(
        meteo2,
        "meteo-api-1",
        24,
        13.5,
        180.1,
    );

    std.debug.print(
        "testo3: text roundtrip EstMeteo OK nombre={s} temp={d} viento={d:.2} dir={d:.2}\n",
        .{
            meteo2.getNombre(),
            meteo2.getTemp(),
            meteo2.getVViento(),
            meteo2.getDirViento(),
        },
    );
}

fn expectEstMeteo(
    meteo: Api.EstMeteo,
    expected_nombre: []const u8,
    expected_temp: u32,
    expected_v_viento: f32,
    expected_dir_viento: f32,
) !void {
    if (!std.mem.eql(u8, meteo.impl.nombre, expected_nombre)) {
        return error.BadNombre;
    }

    if (meteo.getTemp() != expected_temp) {
        return error.BadTemp;
    }

    if (!approxEqAbs(f32, meteo.getVViento(), expected_v_viento, 0.001)) {
        return error.BadVViento;
    }

    if (!approxEqAbs(f32, meteo.getDirViento(), expected_dir_viento, 0.001)) {
        return error.BadDirViento;
    }
}

fn approxEqAbs(
    comptime T: type,
    a: T,
    b: T,
    tolerance: T,
) bool {
    const diff = if (a > b) a - b else b - a;
    return diff <= tolerance;
}
