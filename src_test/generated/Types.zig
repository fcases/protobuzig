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


pub const Msg = struct {
    channels: [][]const u8,
    msgType: u64,
    payLoad: []const u8,

    pub fn initDefault(allocator: all.Allocator) !Msg {
        const self = try allocator.create(Msg);
        self.* = Msg{
            .channels = try allocator.alloc([]const u8, 0),
            .msgType = undefined, 
            .payLoad = undefined, 
        };
        return self.*;
    }

    pub fn skribiAlZonTeksto(self: *Msg, allocator: all.Allocator) ![]u8 {
        return skribiTiponAlZonTeksto(allocator, Msg, @as(*Msg,self));
    }

    pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !Msg {
        return legiTiponElZonTeksto(allocator, Msg, input);
    }

    pub fn skribiAlZonDosiero(self: *Msg, allocator: all.Allocator, path: []const u8) !void {
        try skribiTiponAlZonDosiero(allocator, Msg, @as(*Msg, self), path);
    }

    pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !Msg {
        return legiTiponElZonDosiero(allocator, Msg, path);
    }

    pub fn skribiAlProtobufTeksto(self: *const Msg, allocator: all.Allocator,ind: []const u8) ![]const u8 {
       const indent = std.mem.concatWithSentinel(std.heap.page_allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
       var bufro:std.ArrayList(u8)= .empty;
       if( equal(u8,indent,"") ) { {} } 

        for(self.channels) |obj| 
            try bufro.print(allocator,"{s}channels: \"{s}\"\n",.{ind, obj });
        try bufro.print(allocator,"{s}msgType: {any}\n",.{ind, self.msgType });
        try bufro.print(allocator,"{s}payLoad: {any}\n",.{ind, self.payLoad });

        return bufro.toOwnedSlice(allocator);
    }

    pub fn skribiAlJsonTeksto(self: *const Msg, allocator: all.Allocator) ![]const u8 {
        var skribila_asignilo = std.Io.Writer.Allocating.init(allocator);

        std.json.fmt(self,.{.whitespace=.indent_3}).format(&skribila_asignilo.writer) catch |err| {
            std.debug.print("eraro dum seriigo: {}\n", .{err});
            return err;
        };

    return skribila_asignilo.writer.buffered();
    }

    pub fn skribiAlPBDosiero(self: *Msg, allocator: all.Allocator) ![]u8 {
        _=self; _= allocator;
    }

    pub fn serialize(self: *Msg, allocator: all.Allocator) ![]u8 {
        return serializeTipon(allocator, Msg, @as(*Msg,self));
    }

    fn encode(self: *const Msg, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
 
        const payLoad_longa = try buffer.encodeBytes( self.payLoad );
        tuta_longo += payLoad_longa;
        tuta_longo += try buffer.encodeVarint(payLoad_longa);
        tuta_longo += try buffer.encodeVarint(26);
        //7  req - no def - varlong

        tuta_longo += try buffer.encodeFixed64( self.msgType );
        tuta_longo += try buffer.encodeVarint(17);
        //5 req - no def - no varlong

        for (self.channels) |item| {
            const channels_longa = try buffer.encodeString( item );
            tuta_longo += channels_longa;
            tuta_longo += try buffer.encodeVarint(channels_longa);
            tuta_longo += try buffer.encodeVarint(10);
        }  // 11  rept - no def - varlong 

        return tuta_longo;
    }

    pub fn deserialize(allocator: all.Allocator,input: []const u8) !Msg {
        return deserializeTipon(allocator, Msg, input);
    }

    fn decode(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !Msg {
        var mia_Mesagho= try Msg.initDefault(allocator);

        var end: usize = undefined;
        if (data_length) |val|
            end = buffer.read_index + val
        else
            end = buffer.buffer.len;

        var channels_list: std.ArrayList([]const u8) = .empty; 

        while (buffer.read_index < end) {
            const key: u64 = buffer.decodeVarint() catch 0 ;    
            const wire_type = key & 0x7;  
            const field_number = key >> 3;

            if ( field_number == 1 and wire_type == 2 ) 
                { try channels_list.append( allocator, try buffer.decodeString(  try buffer.decodeVarint() ) ); }
            else if ( field_number == 2 and wire_type == 1 ) 
                mia_Mesagho.msgType = try buffer.decodeFixed64()
            else if ( field_number == 3 and wire_type == 2 ) 
                mia_Mesagho.payLoad = try buffer.decodeBytes(  try buffer.decodeVarint() );
        }

        mia_Mesagho.channels = try channels_list.toOwnedSlice(allocator); 

        return mia_Mesagho;
    }
};

pub const Packet = struct {
    messages: []Msg,
    OutOfBand: ?u64 = null,

    pub fn initDefault(allocator: all.Allocator) !Packet {
        const self = try allocator.create(Packet);
        self.* = Packet{
            .messages = try allocator.alloc(Msg, 0),
            .OutOfBand = null,
        };
        return self.*;
    }

    pub fn skribiAlZonTeksto(self: *Packet, allocator: all.Allocator) ![]u8 {
        return skribiTiponAlZonTeksto(allocator, Packet, @as(*Packet,self));
    }

    pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !Packet {
        return legiTiponElZonTeksto(allocator, Packet, input);
    }

    pub fn skribiAlZonDosiero(self: *Packet, allocator: all.Allocator, path: []const u8) !void {
        try skribiTiponAlZonDosiero(allocator, Packet, @as(*Packet, self), path);
    }

    pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !Packet {
        return legiTiponElZonDosiero(allocator, Packet, path);
    }

    pub fn skribiAlProtobufTeksto(self: *const Packet, allocator: all.Allocator,ind: []const u8) ![]const u8 {
       const indent = std.mem.concatWithSentinel(std.heap.page_allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
       var bufro:std.ArrayList(u8)= .empty;
       if( equal(u8,indent,"") ) { {} } 

        for(self.messages) |obj| 
            try bufro.print(allocator, "{s}messages {{\n{s}{s}}}\n", .{ind, try obj.skribiAlProtobufTeksto(allocator,indent),ind });
        if( self.OutOfBand ) |val|  
            try bufro.print(allocator,"{s}OutOfBand: {any}\n",.{ ind, val });

        return bufro.toOwnedSlice(allocator);
    }

    pub fn skribiAlJsonTeksto(self: *const Packet, allocator: all.Allocator) ![]const u8 {
        var skribila_asignilo = std.Io.Writer.Allocating.init(allocator);

        std.json.fmt(self,.{.whitespace=.indent_3}).format(&skribila_asignilo.writer) catch |err| {
            std.debug.print("eraro dum seriigo: {}\n", .{err});
            return err;
        };

    return skribila_asignilo.writer.buffered();
    }

    pub fn skribiAlPBDosiero(self: *Packet, allocator: all.Allocator) ![]u8 {
        _=self; _= allocator;
    }

    pub fn serialize(self: *Packet, allocator: all.Allocator) ![]u8 {
        return serializeTipon(allocator, Packet, @as(*Packet,self));
    }

    fn encode(self: *const Packet, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
 
        if( self.OutOfBand ) |val| {
            tuta_longo += try buffer.encodeUint64( val );
            tuta_longo += try buffer.encodeVarint(16);
        }   //1 opt - no def - no varlong

        for (self.messages) |item| {
            const messages_longa = try item.encode( buffer );
            tuta_longo += messages_longa;
            tuta_longo += try buffer.encodeVarint(messages_longa);
            tuta_longo += try buffer.encodeVarint(10);
        }  // 11  rept - no def - varlong 

        return tuta_longo;
    }

    pub fn deserialize(allocator: all.Allocator,input: []const u8) !Packet {
        return deserializeTipon(allocator, Packet, input);
    }

    fn decode(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !Packet {
        var mia_Mesagho= try Packet.initDefault(allocator);

        var end: usize = undefined;
        if (data_length) |val|
            end = buffer.read_index + val
        else
            end = buffer.buffer.len;

        var messages_list: std.ArrayList(Msg) = .empty; 

        while (buffer.read_index < end) {
            const key: u64 = buffer.decodeVarint() catch 0 ;    
            const wire_type = key & 0x7;  
            const field_number = key >> 3;

            if ( field_number == 1 and wire_type == 2 ) 
                { try messages_list.append( allocator, try Msg.decode(allocator, buffer, try buffer.decodeVarint() ) ); }
            else if ( field_number == 2 and wire_type == 0 ) 
                mia_Mesagho.OutOfBand = try buffer.decodeUint64();
        }

        mia_Mesagho.messages = try messages_list.toOwnedSlice(allocator); 

        return mia_Mesagho;
    }
};

pub const KeyRegistry = struct {
    Date: []const u8,
    Time: []const u8,
    Sender: []const u8,
    Phrase: []const u8,
    Salt: []const u8,
    AESKey: []const u8,
    AESIV: []const u8,

    pub fn initDefault(allocator: all.Allocator) !KeyRegistry {
        const self = try allocator.create(KeyRegistry);
        self.* = KeyRegistry{
            .Date = "", 
            .Time = "", 
            .Sender = "", 
            .Phrase = "", 
            .Salt = "", 
            .AESKey = undefined, 
            .AESIV = undefined, 
        };
        return self.*;
    }

    pub fn skribiAlZonTeksto(self: *KeyRegistry, allocator: all.Allocator) ![]u8 {
        return skribiTiponAlZonTeksto(allocator, KeyRegistry, @as(*KeyRegistry,self));
    }

    pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !KeyRegistry {
        return legiTiponElZonTeksto(allocator, KeyRegistry, input);
    }

    pub fn skribiAlZonDosiero(self: *KeyRegistry, allocator: all.Allocator, path: []const u8) !void {
        try skribiTiponAlZonDosiero(allocator, KeyRegistry, @as(*KeyRegistry, self), path);
    }

    pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !KeyRegistry {
        return legiTiponElZonDosiero(allocator, KeyRegistry, path);
    }

    pub fn skribiAlProtobufTeksto(self: *const KeyRegistry, allocator: all.Allocator,ind: []const u8) ![]const u8 {
       const indent = std.mem.concatWithSentinel(std.heap.page_allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
       var bufro:std.ArrayList(u8)= .empty;
       if( equal(u8,indent,"") ) { {} } 

        try bufro.print(allocator,"{s}Date: \"{s}\"\n",.{ind, self.Date });
        try bufro.print(allocator,"{s}Time: \"{s}\"\n",.{ind, self.Time });
        try bufro.print(allocator,"{s}Sender: \"{s}\"\n",.{ind, self.Sender });
        try bufro.print(allocator,"{s}Phrase: \"{s}\"\n",.{ind, self.Phrase });
        try bufro.print(allocator,"{s}Salt: \"{s}\"\n",.{ind, self.Salt });
        try bufro.print(allocator,"{s}AESKey: {any}\n",.{ind, self.AESKey });
        try bufro.print(allocator,"{s}AESIV: {any}\n",.{ind, self.AESIV });

        return bufro.toOwnedSlice(allocator);
    }

    pub fn skribiAlJsonTeksto(self: *const KeyRegistry, allocator: all.Allocator) ![]const u8 {
        var skribila_asignilo = std.Io.Writer.Allocating.init(allocator);

        std.json.fmt(self,.{.whitespace=.indent_3}).format(&skribila_asignilo.writer) catch |err| {
            std.debug.print("eraro dum seriigo: {}\n", .{err});
            return err;
        };

    return skribila_asignilo.writer.buffered();
    }

    pub fn skribiAlPBDosiero(self: *KeyRegistry, allocator: all.Allocator) ![]u8 {
        _=self; _= allocator;
    }

    pub fn serialize(self: *KeyRegistry, allocator: all.Allocator) ![]u8 {
        return serializeTipon(allocator, KeyRegistry, @as(*KeyRegistry,self));
    }

    fn encode(self: *const KeyRegistry, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
 
        const AESIV_longa = try buffer.encodeBytes( self.AESIV );
        tuta_longo += AESIV_longa;
        tuta_longo += try buffer.encodeVarint(AESIV_longa);
        tuta_longo += try buffer.encodeVarint(58);
        //7  req - no def - varlong

        const AESKey_longa = try buffer.encodeBytes( self.AESKey );
        tuta_longo += AESKey_longa;
        tuta_longo += try buffer.encodeVarint(AESKey_longa);
        tuta_longo += try buffer.encodeVarint(50);
        //7  req - no def - varlong

        const Salt_longa = try buffer.encodeString( self.Salt );
        tuta_longo += Salt_longa;
        tuta_longo += try buffer.encodeVarint(Salt_longa);
        tuta_longo += try buffer.encodeVarint(42);
        //7  req - no def - varlong

        const Phrase_longa = try buffer.encodeString( self.Phrase );
        tuta_longo += Phrase_longa;
        tuta_longo += try buffer.encodeVarint(Phrase_longa);
        tuta_longo += try buffer.encodeVarint(34);
        //7  req - no def - varlong

        const Sender_longa = try buffer.encodeString( self.Sender );
        tuta_longo += Sender_longa;
        tuta_longo += try buffer.encodeVarint(Sender_longa);
        tuta_longo += try buffer.encodeVarint(26);
        //7  req - no def - varlong

        const Time_longa = try buffer.encodeString( self.Time );
        tuta_longo += Time_longa;
        tuta_longo += try buffer.encodeVarint(Time_longa);
        tuta_longo += try buffer.encodeVarint(18);
        //7  req - no def - varlong

        const Date_longa = try buffer.encodeString( self.Date );
        tuta_longo += Date_longa;
        tuta_longo += try buffer.encodeVarint(Date_longa);
        tuta_longo += try buffer.encodeVarint(10);
        //7  req - no def - varlong

        return tuta_longo;
    }

    pub fn deserialize(allocator: all.Allocator,input: []const u8) !KeyRegistry {
        return deserializeTipon(allocator, KeyRegistry, input);
    }

    fn decode(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !KeyRegistry {
        var mia_Mesagho= try KeyRegistry.initDefault(allocator);

        var end: usize = undefined;
        if (data_length) |val|
            end = buffer.read_index + val
        else
            end = buffer.buffer.len;


        while (buffer.read_index < end) {
            const key: u64 = buffer.decodeVarint() catch 0 ;    
            const wire_type = key & 0x7;  
            const field_number = key >> 3;

            if ( field_number == 1 and wire_type == 2 ) 
                mia_Mesagho.Date = try buffer.decodeString(  try buffer.decodeVarint() )
            else if ( field_number == 2 and wire_type == 2 ) 
                mia_Mesagho.Time = try buffer.decodeString(  try buffer.decodeVarint() )
            else if ( field_number == 3 and wire_type == 2 ) 
                mia_Mesagho.Sender = try buffer.decodeString(  try buffer.decodeVarint() )
            else if ( field_number == 4 and wire_type == 2 ) 
                mia_Mesagho.Phrase = try buffer.decodeString(  try buffer.decodeVarint() )
            else if ( field_number == 5 and wire_type == 2 ) 
                mia_Mesagho.Salt = try buffer.decodeString(  try buffer.decodeVarint() )
            else if ( field_number == 6 and wire_type == 2 ) 
                mia_Mesagho.AESKey = try buffer.decodeBytes(  try buffer.decodeVarint() )
            else if ( field_number == 7 and wire_type == 2 ) 
                mia_Mesagho.AESIV = try buffer.decodeBytes(  try buffer.decodeVarint() );
        }


        return mia_Mesagho;
    }
};

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

fn serializeTipon(allocator: all.Allocator, comptime T: type, value: *T) ![]u8 {
    var mia_enc = try EncodeBuffer.init(allocator, 48 * 1024);
    defer mia_enc.deinit();

    const longo = try value.encode(&mia_enc);
    const bytes = try allocator.alloc(u8, longo);
    std.mem.copyForwards(u8, bytes, mia_enc.data());
    return bytes;
}


fn deserializeTipon(allocator: all.Allocator, comptime T: type, input: []const u8) !T {
    var mia_dec = DecodeBuffer.init(allocator, input, 0, -1);
    defer mia_dec.deinit();

    const obj = try T.decode(allocator, &mia_dec, null);
    return obj;
}


