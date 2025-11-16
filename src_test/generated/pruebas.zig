const std = @import("std");
const dbg = std.debug;
const zon = std.zon;
const all = std.mem;
const equal = std.mem.eql;
const  io = std.Io;
const encdec = @import("../encdec.zig");
const EncodeBuffer = encdec.EncodeBuffer;
const DecodeBuffer = encdec.DecodeBuffer;

const PepaCf = @import("PepaCfg.proto");
const Krma_Cf = @import("Krma_Cfg.proto");

pub const protocolBus = struct {

    pub const paparruchas = struct {


pub const Enum1 = enum(u32) {
    EAA_UNSPECIFIED = 0,
    EAA_STARTED = 1,
    EAA_RUNNING = 2,
    EAA_FINISHED = 3,
};

pub const AppConfig = struct {
    ActivateTrace: ?bool = false ,
    TraceLevel: ?i32 = 0 ,
    Domain: []DomainCfg,

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
 
        const key_Domain = 26;
        tuta_longo += try buffer.encodeVarint(key_Domain);
        var v_Domain_longo: usize = 0;
        { 
            var aux= try EncodeBuffer.init(std.heap.page_allocator,1024); 
            var mia_enc=&aux; 
            defer mia_enc.deinit(); 
            for (self.Domain) |item| { 
                v_Domain_longo += try item.encode( mia_enc );
            } 
        }
        tuta_longo += try buffer.encodeVarint(v_Domain_longo); 
        for (self.Domain) |item| { 
            tuta_longo += try item.encode( buffer );
        }

        if (self.TraceLevel != 0) {
            const key_TraceLevel = 16;
            tuta_longo += try buffer.encodeVarint(key_TraceLevel);
            if( self.TraceLevel ) |val| {
                tuta_longo += try buffer.encodeInt32( val );
            }
        }

        if (self.ActivateTrace != false) {
            const key_ActivateTrace = 8;
            tuta_longo += try buffer.encodeVarint(key_ActivateTrace);
            if( self.ActivateTrace ) |val| {
                tuta_longo += try buffer.encodeBool( val );
            }
        }

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
    Transport: []TransportDef,
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
 
        if (self.CrossConnector != null) {
            const key_CrossConnector = 48;
            tuta_longo += try buffer.encodeVarint(key_CrossConnector);
            if( self.CrossConnector ) |val| {
                tuta_longo += try buffer.encodeVarint( val );
            }
        }

        const key_Transport = 42;
        tuta_longo += try buffer.encodeVarint(key_Transport);
        var v_Transport_longo: usize = 0;
        { 
            var aux= try EncodeBuffer.init(std.heap.page_allocator,1024); 
            var mia_enc=&aux; 
            defer mia_enc.deinit(); 
            for (self.Transport) |item| { 
                v_Transport_longo += try mia_enc.encodeVarint( item );
            } 
        }
        tuta_longo += try buffer.encodeVarint(v_Transport_longo); 
        for (self.Transport) |item| { 
            tuta_longo += try buffer.encodeVarint( item );
        }

        if ( self.KeyFile != null ) {   
            const st= if ( self.KeyFile ) |val| val else "";
            if ( ! equal(u8, st, "null") ) { 
                const key_KeyFile = 34;
                tuta_longo += try buffer.encodeVarint(key_KeyFile);
                tuta_longo += try buffer.encodeString(st);
            }
        }

        if (self.DirectDispacthToSubs != false) {
            const key_DirectDispacthToSubs = 24;
            tuta_longo += try buffer.encodeVarint(key_DirectDispacthToSubs);
            if( self.DirectDispacthToSubs ) |val| {
                tuta_longo += try buffer.encodeBool( val );
            }
        }

        const key_ActivateDefaultTransport = 16;
        tuta_longo += try buffer.encodeVarint(key_ActivateDefaultTransport);
        tuta_longo += try buffer.encodeBool( self.ActivateDefaultTransport );

        const key_Id = 8;
        tuta_longo += try buffer.encodeVarint(key_Id);
        tuta_longo += try buffer.encodeInt32( self.Id );

        return tuta_longo;
    }

    pub fn decode(self: *const DomainCfg, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
       _=self;_=buffer;tuta_longo=3;
        return tuta_longo;
    }

};

    };   // paparruchas
};   // protocolBus

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

