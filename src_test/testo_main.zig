const std = @import("std");
const dbgPresi = std.debug.print;
const zon = @import("std").zon;

const EncodeBuffer = @import("encdec.zig").EncodeBuffer;
const DecodeBuffer = @import("encdec.zig").DecodeBuffer;
const pbz = @import("generated/example.zig").ProtocolBus;

var buffer: [512 * 1024]u8 = undefined;
var fba = std.heap.FixedBufferAllocator.init(&buffer);
const fba_allocator = fba.allocator();
var arena = std.heap.ArenaAllocator.init(fba_allocator);

pub fn main() !void {
    dbgPresi("Proto Main/Ĉefo\n", .{});
    try fariChiujnTestojn();
    dbgPresi("skribu amkaŭ \'zig test  proto/main.zig\' por testi ĉiujn testojn\n", .{});
}

fn fariChiujnTestojn() !void {
    try fariTeston1();
    try fariTeston2();
    try fariTeston3();
    try fariTeston4();
    try fariTeston5();
}

fn fariTeston1() !void {
    // // var arena = std.heap.ArenaAllocator.init(fba_allocator);
    // defer arena.deinit();
    defer _ = arena.reset(.free_all);

    const mia_asignilo = arena.allocator();

    /////////////////
    // Unua testo
    /////////////////

    // Alia ekzemplo de kreo de AppConfig objekto:
    // var mia_transp = [_]pbz.TransportDef{.{ .ReceiveOwnMsgs = true, .MCastParams = .{ .Port = 40000 } }};
    // var mia_transp = [_]pbz.TransportDef{};
    // var mia_transp = [_]pbz.TransportDef{.{ .MCastParams = .{ .MCastAddress = "239.255.0.7", .Port = 40000 } }};

    // var mia_dom = [_]pbz.DomainCfg{.{
    //     .Id = 0,
    //     .ActivateDefaultTransport = true,
    //     .Transports = mia_transp[0..],
    // }};
    // var app_config = pbz.AppConfig{
    //     .Domains = mia_dom[0..],
    // };

    var mia_dom = [_]pbz.DomainCfg{.{
        .Id = 0,
        .ActivateDefaultTransport = true,
        .Transports = ([_]pbz.TransportDef{})[0..],
    }};
    var app_config = pbz.AppConfig{
        .Domains = mia_dom[0..],
        // .a = .EAA_RUNNING,
    };

    const mia_appcfg_txt1 = try app_config.skribiAlTeksto(mia_asignilo, .TF_ZIG_ZON);
    presiMesagho("Testo 1.1:");
    dbgPresi("{s}\n", .{mia_appcfg_txt1});

    const mia_appcfg_txt2 = try app_config.skribiAlTeksto(mia_asignilo, .TF_JSON);
    presiMesagho("Testo 1.2:");
    dbgPresi("{s}\n", .{mia_appcfg_txt2});

    const mia_appcfg_txt3 = try app_config.skribiAlTeksto(mia_asignilo, .TF_PROTOBUF);
    presiMesagho("Testo 1.3:");
    dbgPresi("{s}\n", .{mia_appcfg_txt3});

    presiMesagho("Fino de Testo 1");
}

fn fariTeston2() !void {
    // var arena = std.heap.ArenaAllocator.init(fba_allocator);
    // defer arena.deinit();
    defer _ = arena.reset(.free_all);

    const mia_asignilo = arena.allocator();

    /////////////////
    // Dua testo
    /////////////////

    const teksto =
        \\.{
        \\      .ActivateTrace = false,
        \\      .TraceLevel = 0,
        \\      .Domains = .{.{
        \\          .Id = 0,
        \\          .ActivateDefaultTransport = false,
        \\          .DirectDispacthToSubs = false,
        \\          .KeyFile = null,
        \\          .Transports = .{.{
        \\              .TransportName = "MCastDefault007",
        \\              .DllImport = "Default",
        \\              .TransportClass = "Default",
        \\              .ReceiveOwnMsgs = true,
        \\              .MCastParams = .{
        \\                  .LocalAddress = "Any",
        \\                  .MCastAddress = "239.255.0.7",
        \\                  .Port = 40007,
        \\                  .TTL = 1,
        \\                  .ReceiveBuffer = 134217727,
        \\                  .SendBuffer = 134217727,
        \\              },
        \\          .BCastParams = null,
        \\          .UDPStarParams = null,
        \\          }},
        \\          .CrossConnector = null,
        \\      }},
        // \\      .a = .EAA_STARTED,
        \\}
    ;
    var app_config = pbz.AppConfig.legiElTeksto(mia_asignilo, teksto, .TF_ZIG_ZON) catch unreachable;
    var aux: std.ArrayList([]const u8) = .empty;
    defer aux.deinit(mia_asignilo);

    aux.append(mia_asignilo, "hola") catch unreachable;
    aux.append(mia_asignilo, "nulla") catch unreachable;
    const cross = pbz.CrossConnectorDef{
        .Transports = try aux.toOwnedSlice(mia_asignilo),
    };
    app_config.Domains[0].CrossConnector = cross;

    const skribilo = try app_config.skribiAlTeksto(mia_asignilo, .TF_PROTOBUF);
    presiMesagho("Testo 2.1:");
    dbgPresi("{s}\n", .{skribilo});

    const skribilo2 = try app_config.skribiAlTeksto(mia_asignilo, .TF_JSON);
    presiMesagho("Testo 2.2:");
    dbgPresi("{s}\n", .{skribilo2});

    const skribilo3 = try app_config.skribiAlTeksto(mia_asignilo, .TF_ZIG_ZON);
    presiMesagho("Testo 2.3:");
    dbgPresi("{s}\n", .{skribilo3});

    presiMesagho("Fino de Testo 2");
}

fn fariTeston3() !void {
    // var arena = std.heap.ArenaAllocator.init(fba_allocator);
    // defer arena.deinit();
    defer _ = arena.reset(.free_all);

    const mia_asignilo = arena.allocator();

    /////////////////
    // Tria testo
    /////////////////

    var app_config: pbz.AppConfig = undefined;
    var skribilo: []const u8 = undefined;

    const teksto =
        \\.{
        \\  .Domains = .{.{
        \\          .Id = 0,
        \\          .ActivateDefaultTransport = true,
        \\          .Transports = .{},
        \\  }},
        \\}
    ;

    app_config = pbz.AppConfig.legiElTeksto(mia_asignilo, teksto, .TF_ZIG_ZON) catch unreachable;
    skribilo = try app_config.skribiAlTeksto(mia_asignilo, .TF_PROTOBUF);

    presiMesagho("Testo 3.1:");
    dbgPresi("{s}\n", .{skribilo});

    presiMesagho("Fino de Testo 3");
}

fn fariTeston4() !void {
    // var arena = std.heap.ArenaAllocator.init(fba_allocator);
    // defer arena.deinit();
    defer _ = arena.reset(.free_all);

    const mia_asignilo = arena.allocator();

    /////////////////
    // Kvara testo
    /////////////////

    var app_config = pbz.AppConfig.legiElDosiero(mia_asignilo, "cfg/App.cfg", .TF_ZIG_ZON) catch unreachable;

    const skribilo1 = try app_config.seriigiAlBin(mia_asignilo, .BF_BIN2TEKSTO);
    presiMesagho("Testo 4.1:");
    dbgPresi("{s}\n", .{skribilo1});

    const skribilo2 = try app_config.seriigiAlBin(mia_asignilo, .BF_BASE64);
    presiMesagho("Testo 4.2:");
    dbgPresi("{s}\n", .{skribilo2});

    const skribilo3 = try app_config.seriigiAlBin(mia_asignilo, .BF_PROTOBUF);
    presiMesagho("Testo 4.3:");
    dbgPresi("{any}\n", .{skribilo3});

    presiMesagho("Fino de Testo 4");
}

fn fariTeston5() !void {
    defer _ = arena.reset(.free_all);

    const mia_asignilo = arena.allocator();

    /////////////////
    // Kvina  testo
    /////////////////

    var app_config = pbz.AppConfig.legiElDosiero(mia_asignilo, "cfg/App.cfg", .TF_ZIG_ZON) catch unreachable;
    // nun, app_config1 enhavas la legitan objekton.

    const skribilo = try app_config.skribiAlTeksto(mia_asignilo, .TF_ZIG_ZON);
    presiMesagho("Testo 5.1:");
    dbgPresi("\n{s}\n{d}\n\n", .{ skribilo, skribilo.len });
    const la_biteoj = try app_config.seriigiAlBin(mia_asignilo, .BF_PROTOBUF);
    dbgPresi("{any}\n", .{la_biteoj});

    /////////////////

    var app_config2 = try pbz.AppConfig.deseriigiElBin(mia_asignilo, la_biteoj, .BF_PROTOBUF);
    // nun, app_config2 enhavas la app_config1 objekton de serializita el la_biteoj.
    app_config2.Hola = 3;
    const skribilo2 = try app_config2.skribiAlTeksto(mia_asignilo, .TF_ZIG_ZON);

    presiMesagho("Testo 5.2:");
    dbgPresi("\n{s}\n{d}\n\n", .{ skribilo2, skribilo2.len });

    /////////////////
}

test "Unua testo: skribi objekton al zon formato" {
    try fariTeston1();
}

test "Dua testo: legi zon tekston al objekto" {
    try fariTeston2();
}

test "Tria testo: legi kaj skribi al kaj el Zon formata teksto" {
    try fariTeston3();
}

test "Kvara testo: legi kaj skribi al kaj el Zon formata dosiero" {
    try fariTeston4();
}

test "Kvina testo: Serializo protobuf" {
    try fariTeston5();
}

fn presiMesagho(msg: []const u8) void {
    dbgPresi("\n======\n", .{});
    dbgPresi("{s}\n", .{msg});
    dbgPresi("======\n", .{});
}
