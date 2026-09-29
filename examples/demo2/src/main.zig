const std = @import("std");

// main.zig: kodo de UZANTO.
//
// Ekzemplo generita de protobuzig --ws. Modifu gxin libere por
// meti la logikon de via problemo: krei mesagxojn, plenigi kampojn,
// skribi al dosiero, sxangxi formaton, ktp.
//
// La generitajxo vivas en src/runtime:
//
//     r8.zig       RAW-implemento (interna uzo; ne importu gxin)
//     r8_api.zig   SEKURA API super la raw: uzu CXI TIU
//     encdec.zig         subteno de seriajxo
//
//     const r8 = @import("runtime/r8_api.zig");
//
// La nomspaco portas la nomon de la KONTRAKTO (tiun de la dosiero
// .proto) kaj la ekzempla mesagxo estas la UNUA difinita en gxi.
const r8 = @import("runtime/r8_api.zig");
const PackedMsg = r8.PackedMsg;   // la unua mesagxo de la kontrakto

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const a = gpa.allocator();

    // 1) Kreu objekton de la mesagxo de la kontrakto.
    var msg = try PackedMsg.initDefault(a);
    defer msg.deinit(a);

    // TODO: plenigu cxi tie viajn kampojn per la sekura API (X_api.zig
    // en src/runtime, ne la raw). Ekzemple:
    //     try msg.setMiString(a, "valor");     // []const u8: kopio
    //     msg.setMiNumero(7);                  // skalaroj
    //     try msg.appendMiLista(a, &elemento); // repeated


    // 2) Skribu gxin al dosiero kiel Protobuf Text kaj relegu gxin.
    try msg.writeToFile(a, "demo.txt", .TF_PROTOBUF);
    var desde_texto = try PackedMsg.readFromFile(a, "demo.txt", .TF_PROTOBUF);
    defer desde_texto.deinit(a);

    // 3) Sxangxu formaton: binara Protocol Buffers, kaj relegu gxin.
    try msg.serializeToFile(a, "demo.pb", .BF_PROTOBUF);
    var desde_binario = try PackedMsg.deserializeFromFile(a, "demo.pb", .BF_PROTOBUF);
    defer desde_binario.deinit(a);

    // 4) Montru la enhavon sur la konzolo.
    const texto = try msg.writeToText(a, .TF_PROTOBUF);
    defer a.free(texto);
    std.debug.print("{s}\n", .{texto});

    std.debug.print("Demo ok: revisa demo.txt y demo.pb en el directorio actual.\n", .{});
}
