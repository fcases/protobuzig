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

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const result = gpa.deinit();
        if (result == .leak) {
            std.debug.print("etst3: GPA detected leaks\n", .{});
        }
    }

    const allocator = gpa.allocator();

    try testEstMeteoRoundTripBinario(allocator);
    try testEstMeteoRoundTripTexto(allocator);

    std.debug.print("etst3: OK\n", .{});
}

fn testEstMeteoRoundTripBinario(
    allocator: std.mem.Allocator,
) !void {
    var meteo = try Api.EstMeteo.initDefault(allocator);
    defer meteo.deinit(allocator);

    // Temporal hasta generar setters en cctrol_api.zig.
    allocator.free(meteo.impl.nombre);
    meteo.impl.nombre = try allocator.dupe(u8, "meteo-api-1");
    meteo.impl.temp = 23;
    meteo.impl.v_viento = 12.5;
    meteo.impl.dir_viento = 270.0;

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
        12.5,
        270.0,
    );

    std.debug.print(
        "etst3: bin roundtrip EstMeteo OK nombre={s} temp={d} viento={d:.2} dir={d:.2}\n",
        .{
            meteo2.impl.nombre,
            meteo2.impl.temp,
            meteo2.impl.v_viento,
            meteo2.impl.dir_viento,
        },
    );
}

fn testEstMeteoRoundTripTexto(
    allocator: std.mem.Allocator,
) !void {
    var meteo = try Api.EstMeteo.initDefault(allocator);
    defer meteo.deinit(allocator);

    // Temporal hasta generar setters en cctrol_api.zig.
    allocator.free(meteo.impl.nombre);
    meteo.impl.nombre = try allocator.dupe(u8, "meteo-api-texto-1");
    meteo.impl.temp = 24;
    meteo.impl.v_viento = 13.5;
    meteo.impl.dir_viento = 180.0;

    const text = try meteo.writeToText(
        allocator,
        .TF_ZIG_ZON,
    );
    defer allocator.free(text);
    std.debug.print("{s}", .{text});

    var meteo2 = try Api.EstMeteo.readFromText(
        allocator,
        text,
        .TF_ZIG_ZON,
    );
    defer meteo2.deinit(allocator);

    try expectEstMeteo(
        meteo2,
        "meteo-api-texto-1",
        24,
        13.5,
        180.0,
    );

    std.debug.print(
        "etst3: text roundtrip EstMeteo OK nombre={s} temp={d} viento={d:.2} dir={d:.2}\n",
        .{
            meteo2.impl.nombre,
            meteo2.impl.temp,
            meteo2.impl.v_viento,
            meteo2.impl.dir_viento,
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

    if (meteo.impl.temp != expected_temp) {
        return error.BadTemp;
    }

    if (!approxEqAbs(f32, meteo.impl.v_viento, expected_v_viento, 0.001)) {
        return error.BadVViento;
    }

    if (!approxEqAbs(f32, meteo.impl.dir_viento, expected_dir_viento, 0.001)) {
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
