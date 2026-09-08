const std = @import("std");
const t = std.testing;

// tests.zig: un test round-trip (Protobuf Text + binario) por mensaje
// externo del contrato. Generado por protobuzig --ws con el primer
// mensaje; anade aqui un test por cada mensaje nuevo.

const Base = @import("runtime/Ciudad.zig");

fn ronda(comptime T: type) !void {
    const a = t.allocator;

    var msg = try T.initDefault(a);
    defer msg.deinit(a);

    // Protobuf Text: escribir y releer.
    const teksto = try msg.skribiAlTeksto(a, .TF_PROTOBUF);
    defer a.free(teksto);
    var reteksto = try T.legiElTeksto(a, teksto, .TF_PROTOBUF);
    defer reteksto.deinit(a);

    // Binario Protocol Buffers: escribir y releer.
    const binara = try msg.seriigiAlBin(a, .BF_PROTOBUF);
    defer a.free(binara);
    var rebinara = try T.deseriigiElBin(a, binara, .BF_PROTOBUF);
    defer rebinara.deinit(a);
}

test "Estacion: round-trip texto + binario" {
    try ronda(Base.geo.Estacion);
}
