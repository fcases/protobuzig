const std = @import("std");
const t = std.testing;

// tests.zig: po unu rondvoja testo (Protobuf Text + binara) por
// cxiu EKSTERA mesagxo de la kontrakto (2); la nestitaj ne
// testigxas cxi tie. Generita de protobuzig --ws: se vi aldonos
// mesagxojn al la .proto, regeneru la laborspacon.

// Sekura API generita (Ciudad_api.zig), ne la raw. La wrapper-oj vivas
// en la supra nivelo de la dosiero (sen la pakajxo de la proto) kaj
// la nomspaco portas la nomon de la KONTRAKTO (tiun de la .proto).
const Ciudad = @import("runtime/Ciudad_api.zig");

fn ronda(comptime T: type) !void {
    const a = t.allocator;

    var msg = try T.initDefault(a);
    defer msg.deinit(a);

    // Protobuf Text: skribi kaj relegi.
    const teksto = try msg.writeToText(a, .TF_PROTOBUF);
    defer a.free(teksto);
    var reteksto = try T.readFromText(a, teksto, .TF_PROTOBUF);
    defer reteksto.deinit(a);

    // Binara Protocol Buffers: skribi kaj relegi.
    const binara = try msg.serializeToBin(a, .BF_PROTOBUF);
    defer a.free(binara);
    var rebinara = try T.deserializeFromBin(a, binara, .BF_PROTOBUF);
    defer rebinara.deinit(a);
}

test "Estacion: round-trip texto + binario" {
    try ronda(Ciudad.Estacion);
}

test "Ciudad: round-trip texto + binario" {
    try ronda(Ciudad.Ciudad);
}
