const std = @import("std");

// main.zig: codigo de USUARIO.
//
// Ejemplo generado por protobuzig --ws. Modificalo libremente para
// poner la logica de tu problema: crear mensajes, rellenar campos,
// escribir a fichero, cambiar de formato, etc.
//
// Lo generado vive en src/runtime:
//
//     r8.zig       implementacion RAW (uso interno; no la importes)
//     r8_api.zig   API SEGURA sobre el raw: usa ESTA
//     encdec.zig         soporte de serializacion
//
//     const r8 = @import("runtime/r8_api.zig");
//
// El namespace lleva el nombre del CONTRATO (el del fichero .proto) y el
// mensaje de ejemplo es el PRIMER mensaje definido en el.
const r8 = @import("runtime/r8_api.zig");
const PackedMsg = r8.PackedMsg;   // el primer mensaje del contrato

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const a = gpa.allocator();

    // 1) Crea un objeto del mensaje del contrato.
    var msg = try PackedMsg.initDefault(a);
    defer msg.deinit(a);

    // TODO: rellena aqui tus campos con la API segura (X_api.zig en
    // src/runtime, no el raw). Por ejemplo:
    //     try msg.setMiString(a, "valor");     // []const u8: copia
    //     msg.setMiNumero(7);                  // escalares
    //     try msg.appendMiLista(a, &elemento); // repeated


    // 2) Escribelo a fichero como Protobuf Text y leelo de vuelta.
    try msg.writeToFile(a, "demo.txt", .TF_PROTOBUF);
    var desde_texto = try PackedMsg.readFromFile(a, "demo.txt", .TF_PROTOBUF);
    defer desde_texto.deinit(a);

    // 3) Cambia de formato: binario Protocol Buffers, y leelo de vuelta.
    try msg.serializeToFile(a, "demo.pb", .BF_PROTOBUF);
    var desde_binario = try PackedMsg.deserializeFromFile(a, "demo.pb", .BF_PROTOBUF);
    defer desde_binario.deinit(a);

    // 4) Muestra el contenido por consola.
    const texto = try msg.writeToText(a, .TF_PROTOBUF);
    defer a.free(texto);
    std.debug.print("{s}\n", .{texto});

    std.debug.print("Demo ok: revisa demo.txt y demo.pb en el directorio actual.\n", .{});
}
