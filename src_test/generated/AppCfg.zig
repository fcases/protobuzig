const std = @import("std");
const dbg = std.debug;
const zon = std.zon;
const all = std.mem;
const equal = std.mem.eql;
const  io = std.Io;
const encdec = @import("../encdec.zig");
const EncodeBuffer = encdec.EncodeBuffer;
const DecodeBuffer = encdec.DecodeBuffer;


pub const ProtocolBus = struct {

    pub const Config = struct {


pub const AppConfig = struct {
    ActivateTrace: ?bool = false ,
    TraceLevel: ?i32 = 0 ,
    Domains: []DomainCfg,

    pub fn skribiAlZonTeksto(self: *AppConfig, allocator: all.Allocator) ![]u8 {
        return skribiTiponAlZonTeksto(allocator, AppConfig, @as(*AppConfig,self));
    }

    pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !AppConfig {
        return legiTiponElZonTeksto(allocator, AppConfig, input);
    }

    pub fn skribiAlZonDosiero(self: *AppConfig, allocator: all.Allocator, path: []const u8) !void {
        try skribiTiponAlZonDosiero(allocator, AppConfig, @as(*AppConfig, self), path);
    }

    pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !AppConfig {
        return legiTiponElZonDosiero(allocator, AppConfig, path);
    }

    pub fn encode(self: *const AppConfig, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
 
        for (self.Domains) |item| {
            const Domains_longa = try item.encode( buffer );
            tuta_longo += Domains_longa;
            tuta_longo += try buffer.encodeVarint(Domains_longa);
            tuta_longo += try buffer.encodeVarint(26);
        }  // 11  rept - no def - varlong 

        if( self.TraceLevel ) |val| {
            if( val != 0 )  {
                tuta_longo += try buffer.encodeInt32( val );
                tuta_longo += try buffer.encodeVarint(16);
            }
        }  //2 opt - def - no varlong

        if( self.ActivateTrace ) |val| {
            if( val != false )  {
                tuta_longo += try buffer.encodeBool( val );
                tuta_longo += try buffer.encodeVarint(8);
            }
        }  //2 opt - def - no varlong

        return tuta_longo;
    }

    pub fn decode(self: *const AppConfig, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
       _=self;_=buffer;tuta_longo=3;
        return tuta_longo;
    }

};

pub const DomainCfg = struct {
    Id: i32,
    ActivateDefaultTransport: bool = false ,
    DirectDispacthToSubs: ?bool = false ,
    KeyFile: ?[]const u8 = null,
    Transports: []TransportDef,
    CrossConnector: ?CrossConnectorDef = null,

    pub fn skribiAlZonTeksto(self: *DomainCfg, allocator: all.Allocator) ![]u8 {
        return skribiTiponAlZonTeksto(allocator, DomainCfg, @as(*DomainCfg,self));
    }

    pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !DomainCfg {
        return legiTiponElZonTeksto(allocator, DomainCfg, input);
    }

    pub fn skribiAlZonDosiero(self: *DomainCfg, allocator: all.Allocator, path: []const u8) !void {
        try skribiTiponAlZonDosiero(allocator, DomainCfg, @as(*DomainCfg, self), path);
    }

    pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !DomainCfg {
        return legiTiponElZonDosiero(allocator, DomainCfg, path);
    }

    pub fn encode(self: *const DomainCfg, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
 
        if ( self.CrossConnector ) |val| {
            const st_longa = try val.encode( buffer );
            tuta_longo += st_longa;
            tuta_longo += try buffer.encodeVarint(st_longa);
            tuta_longo += try buffer.encodeVarint(50);
        }  //3  opt - no def - varlong

        for (self.Transports) |item| {
            const Transports_longa = try item.encode( buffer );
            tuta_longo += Transports_longa;
            tuta_longo += try buffer.encodeVarint(Transports_longa);
            tuta_longo += try buffer.encodeVarint(42);
        }  // 11  rept - no def - varlong 

        if ( self.KeyFile ) |val| {
            const st_longa = try buffer.encodeString( val );
            tuta_longo += st_longa;
            tuta_longo += try buffer.encodeVarint(st_longa);
            tuta_longo += try buffer.encodeVarint(34);
        }  //3  opt - no def - varlong

        if( self.DirectDispacthToSubs ) |val| {
            if( val != false )  {
                tuta_longo += try buffer.encodeBool( val );
                tuta_longo += try buffer.encodeVarint(24);
            }
        }  //2 opt - def - no varlong

        if( self.ActivateDefaultTransport != false )  {
            tuta_longo += try buffer.encodeBool( self.ActivateDefaultTransport );
            tuta_longo += try buffer.encodeVarint(16);
        }  //6  req - def - no varlong

        tuta_longo += try buffer.encodeInt32( self.Id );
        tuta_longo += try buffer.encodeVarint(8);
        //5 req - no def - no varlong

        return tuta_longo;
    }

    pub fn decode(self: *const DomainCfg, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
       _=self;_=buffer;tuta_longo=3;
        return tuta_longo;
    }

};

pub const TransportDef = struct {
    TransportName: []const u8 = "MCastDefault0" ,
    DllImport: []const u8 = "Default" ,
    TransportClass: []const u8 = "Default" ,
    ReceiveOwnMsgs: ?bool = false ,
    MCastParams: ?MCastDefConfig = null,
    BCastParams: ?BCastDefConfig = null,
    UDPStarParams: ?UDPStarDefConfig = null,

    pub fn skribiAlZonTeksto(self: *TransportDef, allocator: all.Allocator) ![]u8 {
        return skribiTiponAlZonTeksto(allocator, TransportDef, @as(*TransportDef,self));
    }

    pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !TransportDef {
        return legiTiponElZonTeksto(allocator, TransportDef, input);
    }

    pub fn skribiAlZonDosiero(self: *TransportDef, allocator: all.Allocator, path: []const u8) !void {
        try skribiTiponAlZonDosiero(allocator, TransportDef, @as(*TransportDef, self), path);
    }

    pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !TransportDef {
        return legiTiponElZonDosiero(allocator, TransportDef, path);
    }

    pub fn encode(self: *const TransportDef, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
 
        if ( self.UDPStarParams ) |val| {
            const st_longa = try val.encode( buffer );
            tuta_longo += st_longa;
            tuta_longo += try buffer.encodeVarint(st_longa);
            tuta_longo += try buffer.encodeVarint(58);
        }  //3  opt - no def - varlong

        if ( self.BCastParams ) |val| {
            const st_longa = try val.encode( buffer );
            tuta_longo += st_longa;
            tuta_longo += try buffer.encodeVarint(st_longa);
            tuta_longo += try buffer.encodeVarint(50);
        }  //3  opt - no def - varlong

        if ( self.MCastParams ) |val| {
            const st_longa = try val.encode( buffer );
            tuta_longo += st_longa;
            tuta_longo += try buffer.encodeVarint(st_longa);
            tuta_longo += try buffer.encodeVarint(42);
        }  //3  opt - no def - varlong

        if( self.ReceiveOwnMsgs ) |val| {
            if( val != false )  {
                tuta_longo += try buffer.encodeBool( val );
                tuta_longo += try buffer.encodeVarint(32);
            }
        }  //2 opt - def - no varlong

        if ( ! equal(u8, self.TransportClass, "Default") ) {
            const st_longa = try buffer.encodeString( self.TransportClass );
            tuta_longo += st_longa;
            tuta_longo += try buffer.encodeVarint(st_longa);
            tuta_longo += try buffer.encodeVarint(26);
        }  //8 req - def - varlong

        if ( ! equal(u8, self.DllImport, "Default") ) {
            const st_longa = try buffer.encodeString( self.DllImport );
            tuta_longo += st_longa;
            tuta_longo += try buffer.encodeVarint(st_longa);
            tuta_longo += try buffer.encodeVarint(18);
        }  //8 req - def - varlong

        if ( ! equal(u8, self.TransportName, "MCastDefault0") ) {
            const st_longa = try buffer.encodeString( self.TransportName );
            tuta_longo += st_longa;
            tuta_longo += try buffer.encodeVarint(st_longa);
            tuta_longo += try buffer.encodeVarint(10);
        }  //8 req - def - varlong

        return tuta_longo;
    }

    pub fn decode(self: *const TransportDef, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
       _=self;_=buffer;tuta_longo=3;
        return tuta_longo;
    }

};

pub const MCastDefConfig = struct {
    LocalAddress: []const u8 = "Any" ,
    MCastAddress: []const u8 = "239.255.0.1" ,
    Port: i32 = 40069 ,
    TTL: ?i32 = 1 ,
    ReceiveBuffer: ?i32 = 134217727 ,
    SendBuffer: ?i32 = 134217727 ,

    pub fn skribiAlZonTeksto(self: *MCastDefConfig, allocator: all.Allocator) ![]u8 {
        return skribiTiponAlZonTeksto(allocator, MCastDefConfig, @as(*MCastDefConfig,self));
    }

    pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !MCastDefConfig {
        return legiTiponElZonTeksto(allocator, MCastDefConfig, input);
    }

    pub fn skribiAlZonDosiero(self: *MCastDefConfig, allocator: all.Allocator, path: []const u8) !void {
        try skribiTiponAlZonDosiero(allocator, MCastDefConfig, @as(*MCastDefConfig, self), path);
    }

    pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !MCastDefConfig {
        return legiTiponElZonDosiero(allocator, MCastDefConfig, path);
    }

    pub fn encode(self: *const MCastDefConfig, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
 
        if( self.SendBuffer ) |val| {
            if( val != 134217727 )  {
                tuta_longo += try buffer.encodeInt32( val );
                tuta_longo += try buffer.encodeVarint(48);
            }
        }  //2 opt - def - no varlong

        if( self.ReceiveBuffer ) |val| {
            if( val != 134217727 )  {
                tuta_longo += try buffer.encodeInt32( val );
                tuta_longo += try buffer.encodeVarint(40);
            }
        }  //2 opt - def - no varlong

        if( self.TTL ) |val| {
            if( val != 1 )  {
                tuta_longo += try buffer.encodeInt32( val );
                tuta_longo += try buffer.encodeVarint(32);
            }
        }  //2 opt - def - no varlong

        if( self.Port != 40069 )  {
            tuta_longo += try buffer.encodeInt32( self.Port );
            tuta_longo += try buffer.encodeVarint(24);
        }  //6  req - def - no varlong

        if ( ! equal(u8, self.MCastAddress, "239.255.0.1") ) {
            const st_longa = try buffer.encodeString( self.MCastAddress );
            tuta_longo += st_longa;
            tuta_longo += try buffer.encodeVarint(st_longa);
            tuta_longo += try buffer.encodeVarint(18);
        }  //8 req - def - varlong

        if ( ! equal(u8, self.LocalAddress, "Any") ) {
            const st_longa = try buffer.encodeString( self.LocalAddress );
            tuta_longo += st_longa;
            tuta_longo += try buffer.encodeVarint(st_longa);
            tuta_longo += try buffer.encodeVarint(10);
        }  //8 req - def - varlong

        return tuta_longo;
    }

    pub fn decode(self: *const MCastDefConfig, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
       _=self;_=buffer;tuta_longo=3;
        return tuta_longo;
    }

};

pub const BCastDefConfig = struct {
    LocalAddress: []const u8 = "Any" ,
    BCastAddress: []const u8 = "192.168.2.255" ,
    Port: i32 = 40069 ,
    ReceiveBuffer: ?i32 = 134217727 ,
    SendBuffer: ?i32 = 134217727 ,

    pub fn skribiAlZonTeksto(self: *BCastDefConfig, allocator: all.Allocator) ![]u8 {
        return skribiTiponAlZonTeksto(allocator, BCastDefConfig, @as(*BCastDefConfig,self));
    }

    pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !BCastDefConfig {
        return legiTiponElZonTeksto(allocator, BCastDefConfig, input);
    }

    pub fn skribiAlZonDosiero(self: *BCastDefConfig, allocator: all.Allocator, path: []const u8) !void {
        try skribiTiponAlZonDosiero(allocator, BCastDefConfig, @as(*BCastDefConfig, self), path);
    }

    pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !BCastDefConfig {
        return legiTiponElZonDosiero(allocator, BCastDefConfig, path);
    }

    pub fn encode(self: *const BCastDefConfig, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
 
        if( self.SendBuffer ) |val| {
            if( val != 134217727 )  {
                tuta_longo += try buffer.encodeInt32( val );
                tuta_longo += try buffer.encodeVarint(40);
            }
        }  //2 opt - def - no varlong

        if( self.ReceiveBuffer ) |val| {
            if( val != 134217727 )  {
                tuta_longo += try buffer.encodeInt32( val );
                tuta_longo += try buffer.encodeVarint(32);
            }
        }  //2 opt - def - no varlong

        if( self.Port != 40069 )  {
            tuta_longo += try buffer.encodeInt32( self.Port );
            tuta_longo += try buffer.encodeVarint(24);
        }  //6  req - def - no varlong

        if ( ! equal(u8, self.BCastAddress, "192.168.2.255") ) {
            const st_longa = try buffer.encodeString( self.BCastAddress );
            tuta_longo += st_longa;
            tuta_longo += try buffer.encodeVarint(st_longa);
            tuta_longo += try buffer.encodeVarint(18);
        }  //8 req - def - varlong

        if ( ! equal(u8, self.LocalAddress, "Any") ) {
            const st_longa = try buffer.encodeString( self.LocalAddress );
            tuta_longo += st_longa;
            tuta_longo += try buffer.encodeVarint(st_longa);
            tuta_longo += try buffer.encodeVarint(10);
        }  //8 req - def - varlong

        return tuta_longo;
    }

    pub fn decode(self: *const BCastDefConfig, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
       _=self;_=buffer;tuta_longo=3;
        return tuta_longo;
    }

};

pub const UDPStarDefConfig = struct {
    LocalAddress: []const u8 = "Any" ,
    Port: i32 = 40069 ,
    EndPoint: []EndPointDef,
    ReceiveBuffer: ?i32 = 134217727 ,
    SendBuffer: ?i32 = 134217727 ,

    pub fn skribiAlZonTeksto(self: *UDPStarDefConfig, allocator: all.Allocator) ![]u8 {
        return skribiTiponAlZonTeksto(allocator, UDPStarDefConfig, @as(*UDPStarDefConfig,self));
    }

    pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !UDPStarDefConfig {
        return legiTiponElZonTeksto(allocator, UDPStarDefConfig, input);
    }

    pub fn skribiAlZonDosiero(self: *UDPStarDefConfig, allocator: all.Allocator, path: []const u8) !void {
        try skribiTiponAlZonDosiero(allocator, UDPStarDefConfig, @as(*UDPStarDefConfig, self), path);
    }

    pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !UDPStarDefConfig {
        return legiTiponElZonDosiero(allocator, UDPStarDefConfig, path);
    }

    pub fn encode(self: *const UDPStarDefConfig, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
 
        if( self.SendBuffer ) |val| {
            if( val != 134217727 )  {
                tuta_longo += try buffer.encodeInt32( val );
                tuta_longo += try buffer.encodeVarint(40);
            }
        }  //2 opt - def - no varlong

        if( self.ReceiveBuffer ) |val| {
            if( val != 134217727 )  {
                tuta_longo += try buffer.encodeInt32( val );
                tuta_longo += try buffer.encodeVarint(32);
            }
        }  //2 opt - def - no varlong

        for (self.EndPoint) |item| {
            const EndPoint_longa = try item.encode( buffer );
            tuta_longo += EndPoint_longa;
            tuta_longo += try buffer.encodeVarint(EndPoint_longa);
            tuta_longo += try buffer.encodeVarint(26);
        }  // 11  rept - no def - varlong 

        if( self.Port != 40069 )  {
            tuta_longo += try buffer.encodeInt32( self.Port );
            tuta_longo += try buffer.encodeVarint(16);
        }  //6  req - def - no varlong

        if ( ! equal(u8, self.LocalAddress, "Any") ) {
            const st_longa = try buffer.encodeString( self.LocalAddress );
            tuta_longo += st_longa;
            tuta_longo += try buffer.encodeVarint(st_longa);
            tuta_longo += try buffer.encodeVarint(10);
        }  //8 req - def - varlong

        return tuta_longo;
    }

    pub fn decode(self: *const UDPStarDefConfig, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
       _=self;_=buffer;tuta_longo=3;
        return tuta_longo;
    }

};

pub const EndPointDef = struct {
    Host: []const u8,
    Port: i32 = 40069 ,

    pub fn skribiAlZonTeksto(self: *EndPointDef, allocator: all.Allocator) ![]u8 {
        return skribiTiponAlZonTeksto(allocator, EndPointDef, @as(*EndPointDef,self));
    }

    pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !EndPointDef {
        return legiTiponElZonTeksto(allocator, EndPointDef, input);
    }

    pub fn skribiAlZonDosiero(self: *EndPointDef, allocator: all.Allocator, path: []const u8) !void {
        try skribiTiponAlZonDosiero(allocator, EndPointDef, @as(*EndPointDef, self), path);
    }

    pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !EndPointDef {
        return legiTiponElZonDosiero(allocator, EndPointDef, path);
    }

    pub fn encode(self: *const EndPointDef, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
 
        if( self.Port != 40069 )  {
            tuta_longo += try buffer.encodeInt32( self.Port );
            tuta_longo += try buffer.encodeVarint(16);
        }  //6  req - def - no varlong

        const Host_longa = try buffer.encodeString( self.Host );
        tuta_longo += Host_longa;
        tuta_longo += try buffer.encodeVarint(Host_longa);
        tuta_longo += try buffer.encodeVarint(10);
        //7  req - no def - varlong

        return tuta_longo;
    }

    pub fn decode(self: *const EndPointDef, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
       _=self;_=buffer;tuta_longo=3;
        return tuta_longo;
    }

};

pub const CrossConnectorDef = struct {
    Transports: [][]const u8,

    pub fn skribiAlZonTeksto(self: *CrossConnectorDef, allocator: all.Allocator) ![]u8 {
        return skribiTiponAlZonTeksto(allocator, CrossConnectorDef, @as(*CrossConnectorDef,self));
    }

    pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !CrossConnectorDef {
        return legiTiponElZonTeksto(allocator, CrossConnectorDef, input);
    }

    pub fn skribiAlZonDosiero(self: *CrossConnectorDef, allocator: all.Allocator, path: []const u8) !void {
        try skribiTiponAlZonDosiero(allocator, CrossConnectorDef, @as(*CrossConnectorDef, self), path);
    }

    pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !CrossConnectorDef {
        return legiTiponElZonDosiero(allocator, CrossConnectorDef, path);
    }

    pub fn encode(self: *const CrossConnectorDef, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
 
        for (self.Transports) |item| {
            const Transports_longa = try buffer.encodeString( item );
            tuta_longo += Transports_longa;
            tuta_longo += try buffer.encodeVarint(Transports_longa);
            tuta_longo += try buffer.encodeVarint(10);
        }  // 11  rept - no def - varlong 

        return tuta_longo;
    }

    pub fn decode(self: *const CrossConnectorDef, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
       _=self;_=buffer;tuta_longo=3;
        return tuta_longo;
    }

};

    };   // Config
};   // ProtocolBus

//////////////////////////////////////////////
/// //////////////////////////////////////////
/// //////////////////////////////////////////
//////////////////////////////////////////////

fn skribiTiponAlZonTeksto(allocator: all.Allocator, comptime T: type, value: *T) ![]u8 {
    var skribila_asignilo = std.Io.Writer.Allocating.init(allocator);
    // defer skribila_asignilo.deinit();

    const self = @as(T, value.*);
    zon.stringify.serialize(self, .{}, &skribila_asignilo.writer) catch |err| {
        std.debug.print("eraro dum seriigo: {}\n", .{err});
        return err;
    };

    return skribila_asignilo.writer.buffered();
}

fn skribiTiponAlZonDosiero(allocator: all.Allocator, comptime T: type, value: *T, path: []const u8) !void {
    const teksto = try skribiTiponAlZonTeksto(allocator,T, value);

    var dosiero = try std.fs.cwd().createFile(path, .{ .truncate = true });
    defer dosiero.close();
    try dosiero.writeAll(teksto);
}

fn legiTiponElZonTeksto(allocator: all.Allocator, comptime T: type, input: [:0]const u8) !T {
    const parsed = zon.parse.fromSlice(T, allocator, input, null, .{}) catch |err| {
        std.debug.print("eraro dun deseriigo: {}\n", .{err});
        return err;
    };

    return parsed;
}

fn legiTiponElZonDosiero(allocator: all.Allocator, comptime T: type, path: []const u8) !T {
    var dosiero = try std.fs.cwd().openFile(path, .{});
    defer dosiero.close();

    const dosiera_long = try dosiero.getEndPos();
    var enhavo = allocator.alloc(u8, dosiera_long + 1) catch return error.OutOfMemory;
    defer allocator.free(enhavo);

    _ = try dosiero.readAll(enhavo[0..dosiera_long]);
    enhavo[dosiera_long] = 0;

    return legiTiponElZonTeksto(allocator, T, enhavo[0..dosiera_long :0]);
}

