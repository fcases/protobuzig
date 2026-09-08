const std = @import("std");
const dbg = std.debug.print;

// -------------------------
// IMPORTS GENERADOS
// -------------------------

const Geo = @import("generated/Ciudad.zig").geo;
const Est = Geo.Estacion;
const Ciu = Geo.Ciudad;

const MsgMod = @import("generated/Msg.zig").k6bus.msg;
const Msg = MsgMod.Msg;

const Pkg = @import("generated/Packet.zig").k6bus.pkgpb;
const Packet = Pkg.Packet;

// -------------------------
// ALLOCATORS
// -------------------------

var buffer: [512 * 1024]u8 = undefined;
var fba = std.heap.FixedBufferAllocator.init(&buffer);
const fba_allocator = fba.allocator();
var arena = std.heap.ArenaAllocator.init(fba_allocator);

// -------------------------
// HASH CANAL
// -------------------------

fn hashCanal(txt: []const u8) u32 {
    var h: u32 = 2166136261;
    for (txt) |c| {
        h ^= c;
        h *%= 16777619;
    }
    return h;
}

// -------------------------
// MAIN
// -------------------------

pub fn main() !void {
    dbg("=== Test completa K6Bus mock ===\n", .{});
    try testPayloadCompleto();
    dbg("\n=== FIN OK ===\n", .{});
}

// -------------------------
// TEST COMPLETO
// -------------------------

fn testPayloadCompleto() !void {
    defer _ = arena.reset(.free_all);
    const al = arena.allocator();

    // -------------------------
    // 1. Canal + MsgType
    // -------------------------

    const canal_txt = "mteos";
    const canal_hash = hashCanal(canal_txt);

    const MSG_CIUDAD: u32 = 1;

    dbg("Canal '{s}' → hash = {d}\n", .{ canal_txt, canal_hash });

    // -------------------------
    // 2. Estaciones
    // -------------------------

    var ests = try al.alloc(Est, 3);

    ests[0] = .{ .nombre = "Central", .id = 1 };
    ests[1] = .{ .nombre = "Norte",   .id = 2 };
    ests[2] = .{ .nombre = "Sur",     .id = 3 };

    // -------------------------
    // 3. Ciudad
    // -------------------------

    var ciudad = Ciu{
        .nombre = "Madrid",
        .estaciones = ests,
    };

    // -------------------------
    // 4. Serialize Ciudad → payload
    // -------------------------

    const payload = try ciudad.seriigiAlBin(al, .BF_PROTOBUF);

    dbg("\nPayload ciudad:\n{any}\n", .{payload});

    // -------------------------
    // Canal (array, repeated)
    // -------------------------

    var chs = try al.alloc(u32, 1);
    chs[0] = canal_hash;

    // -------------------------
    // Msg (envelope)
    // -------------------------

    const msg = Msg{
        .channels = chs,
        .msgType = MSG_CIUDAD,
        .payLoad = payload,
    };

    // -------------------------
    // 6. Packet (repeated Msg)
    // -------------------------

    var msgs = try al.alloc(Msg, 2);
    msgs[0] = msg;
    msgs[1] = msg;

    var packet = Packet{
        .messages = msgs,
        .OutOfBand = 77,
    };

    // -------------------------
    // 7. SERIALIZAR PACKET
    // -------------------------

    const bin = try packet.seriigiAlBin(al, .BF_PROTOBUF);

    dbg("\n--- BIN PACKET ---\n{any}\n", .{bin});

    // -------------------------
    // 8. DESERIALIZAR PACKET
    // -------------------------

    var packet2 = try Packet.deseriigiElBin(al, bin, .BF_PROTOBUF);

    const msg2 = packet2.messages[0];

    // -------------------------
    // 9. VALIDACIONES
    // -------------------------
    if (msg2.channels.len == 0 or msg2.channels[0] != canal_hash) {
        dbg("ERROR canal\n", .{});
        return error.BadChannel;
    }

    if (msg2.msgType != MSG_CIUDAD) {
        dbg("ERROR msgType\n", .{});
        return error.BadMsgType;
    }

    // -------------------------
    // 10. Decode payload → Ciudad
    // -------------------------

    var ciudad2 = try Ciu.deseriigiElBin(
        al,
        msg2.payLoad,
        .BF_PROTOBUF,
    );

    // -------------------------
    // 11. OUTPUTS
    // -------------------------

    const txt_packet = try packet2.skribiAlTeksto(al, .TF_PROTOBUF);
    dbg("\n--- PB PACKET ---\n{s}\n", .{txt_packet});

    const txt_ciudad = try ciudad2.skribiAlTeksto(al, .TF_PROTOBUF);
    dbg("\n--- PB CIUDAD ---\n{s}\n", .{txt_ciudad});

    const json = try packet2.skribiAlTeksto(al, .TF_JSON);
    dbg("\n--- JSON PACKET ---\n{s}\n", .{json});

    const zon = try packet2.skribiAlTeksto(al, .TF_ZIG_ZON);
    dbg("\n--- ZON PACKET ---\n{s}\n", .{zon});

    var est = try Est.deseriigiElBin( al, packet2.messages[0].payLoad,.BF_PROTOBUF);
    const txt_est = try (&est).skribiAlTeksto(al, .TF_ZIG_ZON);    
    dbg("\n--- ZON ESTACION ---\n{s}\n", .{txt_est});
}
