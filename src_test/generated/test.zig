const std = @import("std");
const dbg = std.debug;
const zon = std.zon;
const all = std.mem;
const equal = std.mem.eql;
const  io = std.Io;
const encdec = @import("../encdec.zig");
const EncodeBuffer = encdec.EncodeBuffer;
const DecodeBuffer = encdec.DecodeBuffer;


pub const TestEnum = enum(u64) {
    ONE = 1,
    TWO = 2,
    THREE = 3,
};

pub const TestMessage = struct {
    value_int32: i32,
    value_uint32: u32,
    value_sint32: i32,
    value_fixed32: u32,
    value_sfixed32: i32,
    value_int64: i64,
    value_uint64: u64,
    value_sint64: i64,
    value_fixed64: u64,
    value_sfixed64: i64,
    value_bool: bool,
    value_enum: TestEnum,
    value_string: []const u8,
    value_bytes: []const u8,
    value_double: f64,
    value_float: f32,

    pub fn initDefault(allocator: all.Allocator) !TestMessage {
        const self = try allocator.create(TestMessage);
        self.* = TestMessage{
            .value_int32 = 0,
            .value_uint32 = 0,
            .value_sint32 = undefined, 
            .value_fixed32 = undefined, 
            .value_sfixed32 = undefined, 
            .value_int64 = 0,
            .value_uint64 = 0,
            .value_sint64 = undefined, 
            .value_fixed64 = undefined, 
            .value_sfixed64 = undefined, 
            .value_bool = false,
            .value_enum = undefined, 
            .value_string = "", 
            .value_bytes = undefined, 
            .value_double = undefined, 
            .value_float = undefined, 
        };
        return self.*;
    }

    pub fn skribiAlZonTeksto(self: *TestMessage, allocator: all.Allocator) ![]u8 {
        return skribiTiponAlZonTeksto(allocator, TestMessage, @as(*TestMessage,self));
    }

    pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !TestMessage {
        return legiTiponElZonTeksto(allocator, TestMessage, input);
    }

    pub fn skribiAlZonDosiero(self: *TestMessage, allocator: all.Allocator, path: []const u8) !void {
        try skribiTiponAlZonDosiero(allocator, TestMessage, @as(*TestMessage, self), path);
    }

    pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !TestMessage {
        return legiTiponElZonDosiero(allocator, TestMessage, path);
    }

    pub fn skribiAlProtobufTeksto(self: *const TestMessage, allocator: all.Allocator,ind: []const u8) ![]const u8 {
       const indent = std.mem.concatWithSentinel(std.heap.page_allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
       var bufro:std.ArrayList(u8)= .empty;
       if( equal(u8,indent,"") ) { {} } 

        try bufro.print(allocator,"{s}value_int32: {any}\n",.{ind, self.value_int32 });
        try bufro.print(allocator,"{s}value_uint32: {any}\n",.{ind, self.value_uint32 });
        try bufro.print(allocator,"{s}value_sint32: {any}\n",.{ind, self.value_sint32 });
        try bufro.print(allocator,"{s}value_fixed32: {any}\n",.{ind, self.value_fixed32 });
        try bufro.print(allocator,"{s}value_sfixed32: {any}\n",.{ind, self.value_sfixed32 });
        try bufro.print(allocator,"{s}value_int64: {any}\n",.{ind, self.value_int64 });
        try bufro.print(allocator,"{s}value_uint64: {any}\n",.{ind, self.value_uint64 });
        try bufro.print(allocator,"{s}value_sint64: {any}\n",.{ind, self.value_sint64 });
        try bufro.print(allocator,"{s}value_fixed64: {any}\n",.{ind, self.value_fixed64 });
        try bufro.print(allocator,"{s}value_sfixed64: {any}\n",.{ind, self.value_sfixed64 });
        try bufro.print(allocator,"{s}value_bool: {any}\n",.{ind, self.value_bool });
        try bufro.print(allocator,"{s}value_enum: {any}\n",.{ind, self.value_enum });
        try bufro.print(allocator,"{s}value_string: \"{s}\"\n",.{ind, self.value_string });
        try bufro.print(allocator,"{s}value_bytes: {any}\n",.{ind, self.value_bytes });
        try bufro.print(allocator,"{s}value_double: {any}\n",.{ind, self.value_double });
        try bufro.print(allocator,"{s}value_float: {any}\n",.{ind, self.value_float });

        return bufro.toOwnedSlice(allocator);
    }

    pub fn skribiAlJsonTeksto(self: *const TestMessage, allocator: all.Allocator) ![]const u8 {
        var skribila_asignilo = std.Io.Writer.Allocating.init(allocator);

        std.json.fmt(self,.{.whitespace=.indent_3}).format(&skribila_asignilo.writer) catch |err| {
            std.debug.print("eraro dum seriigo: {}\n", .{err});
            return err;
        };

    return skribila_asignilo.writer.buffered();
    }

    pub fn skribiAlPBDosiero(self: *TestMessage, allocator: all.Allocator) ![]u8 {
        _=self; _= allocator;
    }

    pub fn serialize(self: *TestMessage, allocator: all.Allocator) ![]u8 {
        return serializeTipon(allocator, TestMessage, @as(*TestMessage,self));
    }

    fn encode(self: *const TestMessage, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
 
        tuta_longo += try buffer.encodeFloat( self.value_float );
        tuta_longo += try buffer.encodeVarint(133);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeDouble( self.value_double );
        tuta_longo += try buffer.encodeVarint(121);
        //5 req - no def - no varlong

        const value_bytes_longa = try buffer.encodeBytes( self.value_bytes );
        tuta_longo += value_bytes_longa;
        tuta_longo += try buffer.encodeVarint(value_bytes_longa);
        tuta_longo += try buffer.encodeVarint(114);
        //7  req - no def - varlong

        const value_string_longa = try buffer.encodeString( self.value_string );
        tuta_longo += value_string_longa;
        tuta_longo += try buffer.encodeVarint(value_string_longa);
        tuta_longo += try buffer.encodeVarint(106);
        //7  req - no def - varlong

        tuta_longo += try buffer.encodeVarint( @intFromEnum(self.value_enum) );
        tuta_longo += try buffer.encodeVarint(96);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeBool( self.value_bool );
        tuta_longo += try buffer.encodeVarint(88);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeSfixed64( self.value_sfixed64 );
        tuta_longo += try buffer.encodeVarint(81);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeFixed64( self.value_fixed64 );
        tuta_longo += try buffer.encodeVarint(73);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeSint64( self.value_sint64 );
        tuta_longo += try buffer.encodeVarint(64);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint64( self.value_uint64 );
        tuta_longo += try buffer.encodeVarint(56);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeInt64( self.value_int64 );
        tuta_longo += try buffer.encodeVarint(48);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeSfixed32( self.value_sfixed32 );
        tuta_longo += try buffer.encodeVarint(45);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeFixed32( self.value_fixed32 );
        tuta_longo += try buffer.encodeVarint(37);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeSint32( self.value_sint32 );
        tuta_longo += try buffer.encodeVarint(24);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.value_uint32 );
        tuta_longo += try buffer.encodeVarint(16);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeInt32( self.value_int32 );
        tuta_longo += try buffer.encodeVarint(8);
        //5 req - no def - no varlong

        return tuta_longo;
    }

    pub fn deserialize(allocator: all.Allocator,input: []const u8) !TestMessage {
        return deserializeTipon(allocator, TestMessage, input);
    }

    fn decode(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !TestMessage {
        var mia_Mesagho= try TestMessage.initDefault(allocator);

        var end: usize = undefined;
        if (data_length) |val|
            end = buffer.read_index + val
        else
            end = buffer.buffer.len;


        while (buffer.read_index < end) {
            const key: u64 = buffer.decodeVarint() catch 0 ;    
            const wire_type = key & 0x7;  
            const field_number = key >> 3;

            if ( field_number == 1 and wire_type == 0 ) 
                mia_Mesagho.value_int32 = try buffer.decodeInt32()
            else if ( field_number == 2 and wire_type == 0 ) 
                mia_Mesagho.value_uint32 = try buffer.decodeUint32()
            else if ( field_number == 3 and wire_type == 0 ) 
                mia_Mesagho.value_sint32 = try buffer.decodeSint32()
            else if ( field_number == 4 and wire_type == 5 ) 
                mia_Mesagho.value_fixed32 = try buffer.decodeFixed32()
            else if ( field_number == 5 and wire_type == 5 ) 
                mia_Mesagho.value_sfixed32 = try buffer.edecodeSfixed32()
            else if ( field_number == 6 and wire_type == 0 ) 
                mia_Mesagho.value_int64 = try buffer.decodeInt64()
            else if ( field_number == 7 and wire_type == 0 ) 
                mia_Mesagho.value_uint64 = try buffer.decodeUint64()
            else if ( field_number == 8 and wire_type == 0 ) 
                mia_Mesagho.value_sint64 = try buffer.decodeSint64()
            else if ( field_number == 9 and wire_type == 1 ) 
                mia_Mesagho.value_fixed64 = try buffer.decodeFixed64()
            else if ( field_number == 10 and wire_type == 1 ) 
                mia_Mesagho.value_sfixed64 = try buffer.decodeSfixed64()
            else if ( field_number == 11 and wire_type == 0 ) 
                mia_Mesagho.value_bool = try buffer.decodeBool()
            else if ( field_number == 12 and wire_type == 0 ) 
                mia_Mesagho.value_enum = try std.meta.intToEnum(TestEnum, try buffer.decodeVarint() ) 
            else if ( field_number == 13 and wire_type == 2 ) 
                mia_Mesagho.value_string = try buffer.decodeString(  try buffer.decodeVarint() )
            else if ( field_number == 14 and wire_type == 2 ) 
                mia_Mesagho.value_bytes = try buffer.decodeBytes(  try buffer.decodeVarint() )
            else if ( field_number == 15 and wire_type == 1 ) 
                mia_Mesagho.value_double = try buffer.decodeDouble()
            else if ( field_number == 16 and wire_type == 5 ) 
                mia_Mesagho.value_float = try buffer.decodeFloat();
        }


        return mia_Mesagho;
    }
};

pub const TestRequiredMessage = struct {
    int_value: i32,
    string_value: []const u8,

    pub fn initDefault(allocator: all.Allocator) !TestRequiredMessage {
        const self = try allocator.create(TestRequiredMessage);
        self.* = TestRequiredMessage{
            .int_value = undefined, 
            .string_value = "", 
        };
        return self.*;
    }

    pub fn skribiAlZonTeksto(self: *TestRequiredMessage, allocator: all.Allocator) ![]u8 {
        return skribiTiponAlZonTeksto(allocator, TestRequiredMessage, @as(*TestRequiredMessage,self));
    }

    pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !TestRequiredMessage {
        return legiTiponElZonTeksto(allocator, TestRequiredMessage, input);
    }

    pub fn skribiAlZonDosiero(self: *TestRequiredMessage, allocator: all.Allocator, path: []const u8) !void {
        try skribiTiponAlZonDosiero(allocator, TestRequiredMessage, @as(*TestRequiredMessage, self), path);
    }

    pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !TestRequiredMessage {
        return legiTiponElZonDosiero(allocator, TestRequiredMessage, path);
    }

    pub fn skribiAlProtobufTeksto(self: *const TestRequiredMessage, allocator: all.Allocator,ind: []const u8) ![]const u8 {
       const indent = std.mem.concatWithSentinel(std.heap.page_allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
       var bufro:std.ArrayList(u8)= .empty;
       if( equal(u8,indent,"") ) { {} } 

        try bufro.print(allocator,"{s}int_value: {any}\n",.{ind, self.int_value });
        try bufro.print(allocator,"{s}string_value: \"{s}\"\n",.{ind, self.string_value });

        return bufro.toOwnedSlice(allocator);
    }

    pub fn skribiAlJsonTeksto(self: *const TestRequiredMessage, allocator: all.Allocator) ![]const u8 {
        var skribila_asignilo = std.Io.Writer.Allocating.init(allocator);

        std.json.fmt(self,.{.whitespace=.indent_3}).format(&skribila_asignilo.writer) catch |err| {
            std.debug.print("eraro dum seriigo: {}\n", .{err});
            return err;
        };

    return skribila_asignilo.writer.buffered();
    }

    pub fn skribiAlPBDosiero(self: *TestRequiredMessage, allocator: all.Allocator) ![]u8 {
        _=self; _= allocator;
    }

    pub fn serialize(self: *TestRequiredMessage, allocator: all.Allocator) ![]u8 {
        return serializeTipon(allocator, TestRequiredMessage, @as(*TestRequiredMessage,self));
    }

    fn encode(self: *const TestRequiredMessage, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
 
        const string_value_longa = try buffer.encodeString( self.string_value );
        tuta_longo += string_value_longa;
        tuta_longo += try buffer.encodeVarint(string_value_longa);
        tuta_longo += try buffer.encodeVarint(18);
        //7  req - no def - varlong

        tuta_longo += try buffer.encodeSint32( self.int_value );
        tuta_longo += try buffer.encodeVarint(8);
        //5 req - no def - no varlong

        return tuta_longo;
    }

    pub fn deserialize(allocator: all.Allocator,input: []const u8) !TestRequiredMessage {
        return deserializeTipon(allocator, TestRequiredMessage, input);
    }

    fn decode(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !TestRequiredMessage {
        var mia_Mesagho= try TestRequiredMessage.initDefault(allocator);

        var end: usize = undefined;
        if (data_length) |val|
            end = buffer.read_index + val
        else
            end = buffer.buffer.len;


        while (buffer.read_index < end) {
            const key: u64 = buffer.decodeVarint() catch 0 ;    
            const wire_type = key & 0x7;  
            const field_number = key >> 3;

            if ( field_number == 1 and wire_type == 0 ) 
                mia_Mesagho.int_value = try buffer.decodeSint32()
            else if ( field_number == 2 and wire_type == 2 ) 
                mia_Mesagho.string_value = try buffer.decodeString(  try buffer.decodeVarint() );
        }


        return mia_Mesagho;
    }
};

pub const TestOptionalMessage = struct {
    int_value: ?i32 = null,
    string_value: ?[]const u8 = null,

    pub fn initDefault(allocator: all.Allocator) !TestOptionalMessage {
        const self = try allocator.create(TestOptionalMessage);
        self.* = TestOptionalMessage{
            .int_value = null,
            .string_value = null,
        };
        return self.*;
    }

    pub fn skribiAlZonTeksto(self: *TestOptionalMessage, allocator: all.Allocator) ![]u8 {
        return skribiTiponAlZonTeksto(allocator, TestOptionalMessage, @as(*TestOptionalMessage,self));
    }

    pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !TestOptionalMessage {
        return legiTiponElZonTeksto(allocator, TestOptionalMessage, input);
    }

    pub fn skribiAlZonDosiero(self: *TestOptionalMessage, allocator: all.Allocator, path: []const u8) !void {
        try skribiTiponAlZonDosiero(allocator, TestOptionalMessage, @as(*TestOptionalMessage, self), path);
    }

    pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !TestOptionalMessage {
        return legiTiponElZonDosiero(allocator, TestOptionalMessage, path);
    }

    pub fn skribiAlProtobufTeksto(self: *const TestOptionalMessage, allocator: all.Allocator,ind: []const u8) ![]const u8 {
       const indent = std.mem.concatWithSentinel(std.heap.page_allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
       var bufro:std.ArrayList(u8)= .empty;
       if( equal(u8,indent,"") ) { {} } 

        if( self.int_value ) |val|  
            try bufro.print(allocator,"{s}int_value: {any}\n",.{ ind, val });
        if( self.string_value ) |val|  
            try bufro.print(allocator,"{s}string_value: \"{s}\"\n",.{ ind, val });

        return bufro.toOwnedSlice(allocator);
    }

    pub fn skribiAlJsonTeksto(self: *const TestOptionalMessage, allocator: all.Allocator) ![]const u8 {
        var skribila_asignilo = std.Io.Writer.Allocating.init(allocator);

        std.json.fmt(self,.{.whitespace=.indent_3}).format(&skribila_asignilo.writer) catch |err| {
            std.debug.print("eraro dum seriigo: {}\n", .{err});
            return err;
        };

    return skribila_asignilo.writer.buffered();
    }

    pub fn skribiAlPBDosiero(self: *TestOptionalMessage, allocator: all.Allocator) ![]u8 {
        _=self; _= allocator;
    }

    pub fn serialize(self: *TestOptionalMessage, allocator: all.Allocator) ![]u8 {
        return serializeTipon(allocator, TestOptionalMessage, @as(*TestOptionalMessage,self));
    }

    fn encode(self: *const TestOptionalMessage, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
 
        if ( self.string_value ) |val| {
            const st_longa = try buffer.encodeString( val );
            tuta_longo += st_longa;
            tuta_longo += try buffer.encodeVarint(st_longa);
            tuta_longo += try buffer.encodeVarint(18);
        }  //3  opt - no def - varlong

        if( self.int_value ) |val| {
            tuta_longo += try buffer.encodeSint32( val );
            tuta_longo += try buffer.encodeVarint(8);
        }   //1 opt - no def - no varlong

        return tuta_longo;
    }

    pub fn deserialize(allocator: all.Allocator,input: []const u8) !TestOptionalMessage {
        return deserializeTipon(allocator, TestOptionalMessage, input);
    }

    fn decode(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !TestOptionalMessage {
        var mia_Mesagho= try TestOptionalMessage.initDefault(allocator);

        var end: usize = undefined;
        if (data_length) |val|
            end = buffer.read_index + val
        else
            end = buffer.buffer.len;


        while (buffer.read_index < end) {
            const key: u64 = buffer.decodeVarint() catch 0 ;    
            const wire_type = key & 0x7;  
            const field_number = key >> 3;

            if ( field_number == 1 and wire_type == 0 ) 
                mia_Mesagho.int_value = try buffer.decodeSint32()
            else if ( field_number == 2 and wire_type == 2 ) 
                mia_Mesagho.string_value = try buffer.decodeString(  try buffer.decodeVarint() );
        }


        return mia_Mesagho;
    }
};

pub const TestOptionalDefaultsMessage = struct {
    int_value: ?i32 = 1 ,
    string_value: ?[]const u8 = "TEST" ,

    pub fn initDefault(allocator: all.Allocator) !TestOptionalDefaultsMessage {
        const self = try allocator.create(TestOptionalDefaultsMessage);
        self.* = TestOptionalDefaultsMessage{
            .int_value = 1,
            .string_value = "TEST",
        };
        return self.*;
    }

    pub fn skribiAlZonTeksto(self: *TestOptionalDefaultsMessage, allocator: all.Allocator) ![]u8 {
        return skribiTiponAlZonTeksto(allocator, TestOptionalDefaultsMessage, @as(*TestOptionalDefaultsMessage,self));
    }

    pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !TestOptionalDefaultsMessage {
        return legiTiponElZonTeksto(allocator, TestOptionalDefaultsMessage, input);
    }

    pub fn skribiAlZonDosiero(self: *TestOptionalDefaultsMessage, allocator: all.Allocator, path: []const u8) !void {
        try skribiTiponAlZonDosiero(allocator, TestOptionalDefaultsMessage, @as(*TestOptionalDefaultsMessage, self), path);
    }

    pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !TestOptionalDefaultsMessage {
        return legiTiponElZonDosiero(allocator, TestOptionalDefaultsMessage, path);
    }

    pub fn skribiAlProtobufTeksto(self: *const TestOptionalDefaultsMessage, allocator: all.Allocator,ind: []const u8) ![]const u8 {
       const indent = std.mem.concatWithSentinel(std.heap.page_allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
       var bufro:std.ArrayList(u8)= .empty;
       if( equal(u8,indent,"") ) { {} } 

        if( self.int_value ) |val|  
            try bufro.print(allocator,"{s}int_value: {any}\n",.{ ind, val });
        if( self.string_value ) |val|  
            try bufro.print(allocator,"{s}string_value: \"{s}\"\n",.{ ind, val });

        return bufro.toOwnedSlice(allocator);
    }

    pub fn skribiAlJsonTeksto(self: *const TestOptionalDefaultsMessage, allocator: all.Allocator) ![]const u8 {
        var skribila_asignilo = std.Io.Writer.Allocating.init(allocator);

        std.json.fmt(self,.{.whitespace=.indent_3}).format(&skribila_asignilo.writer) catch |err| {
            std.debug.print("eraro dum seriigo: {}\n", .{err});
            return err;
        };

    return skribila_asignilo.writer.buffered();
    }

    pub fn skribiAlPBDosiero(self: *TestOptionalDefaultsMessage, allocator: all.Allocator) ![]u8 {
        _=self; _= allocator;
    }

    pub fn serialize(self: *TestOptionalDefaultsMessage, allocator: all.Allocator) ![]u8 {
        return serializeTipon(allocator, TestOptionalDefaultsMessage, @as(*TestOptionalDefaultsMessage,self));
    }

    fn encode(self: *const TestOptionalDefaultsMessage, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
 
        if ( self.string_value ) |val| {
            if ( ! equal(u8, val, "TEST") ) {
                const st_longa = try buffer.encodeString( val );
                tuta_longo += st_longa;
                tuta_longo += try buffer.encodeVarint(st_longa);
                tuta_longo += try buffer.encodeVarint(18);
            }  
        }  //4  opt - def - varlong

        if( self.int_value ) |val| {
            if( val != 1 )  {
                tuta_longo += try buffer.encodeSint32( val );
                tuta_longo += try buffer.encodeVarint(8);
            }
        }  //2 opt - def - no varlong

        return tuta_longo;
    }

    pub fn deserialize(allocator: all.Allocator,input: []const u8) !TestOptionalDefaultsMessage {
        return deserializeTipon(allocator, TestOptionalDefaultsMessage, input);
    }

    fn decode(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !TestOptionalDefaultsMessage {
        var mia_Mesagho= try TestOptionalDefaultsMessage.initDefault(allocator);

        var end: usize = undefined;
        if (data_length) |val|
            end = buffer.read_index + val
        else
            end = buffer.buffer.len;


        while (buffer.read_index < end) {
            const key: u64 = buffer.decodeVarint() catch 0 ;    
            const wire_type = key & 0x7;  
            const field_number = key >> 3;

            if ( field_number == 1 and wire_type == 0 ) 
                mia_Mesagho.int_value = try buffer.decodeSint32()
            else if ( field_number == 2 and wire_type == 2 ) 
                mia_Mesagho.string_value = try buffer.decodeString(  try buffer.decodeVarint() );
        }


        return mia_Mesagho;
    }
};

pub const TestRepeatedMessage = struct {
    value: []u32,

    pub fn initDefault(allocator: all.Allocator) !TestRepeatedMessage {
        const self = try allocator.create(TestRepeatedMessage);
        self.* = TestRepeatedMessage{
            .value = try allocator.alloc(u32, 0),
        };
        return self.*;
    }

    pub fn skribiAlZonTeksto(self: *TestRepeatedMessage, allocator: all.Allocator) ![]u8 {
        return skribiTiponAlZonTeksto(allocator, TestRepeatedMessage, @as(*TestRepeatedMessage,self));
    }

    pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !TestRepeatedMessage {
        return legiTiponElZonTeksto(allocator, TestRepeatedMessage, input);
    }

    pub fn skribiAlZonDosiero(self: *TestRepeatedMessage, allocator: all.Allocator, path: []const u8) !void {
        try skribiTiponAlZonDosiero(allocator, TestRepeatedMessage, @as(*TestRepeatedMessage, self), path);
    }

    pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !TestRepeatedMessage {
        return legiTiponElZonDosiero(allocator, TestRepeatedMessage, path);
    }

    pub fn skribiAlProtobufTeksto(self: *const TestRepeatedMessage, allocator: all.Allocator,ind: []const u8) ![]const u8 {
       const indent = std.mem.concatWithSentinel(std.heap.page_allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
       var bufro:std.ArrayList(u8)= .empty;
       if( equal(u8,indent,"") ) { {} } 

        for(self.value) |obj| 
            try bufro.print(allocator,"{s}value: {any}\n",.{ind, obj });

        return bufro.toOwnedSlice(allocator);
    }

    pub fn skribiAlJsonTeksto(self: *const TestRepeatedMessage, allocator: all.Allocator) ![]const u8 {
        var skribila_asignilo = std.Io.Writer.Allocating.init(allocator);

        std.json.fmt(self,.{.whitespace=.indent_3}).format(&skribila_asignilo.writer) catch |err| {
            std.debug.print("eraro dum seriigo: {}\n", .{err});
            return err;
        };

    return skribila_asignilo.writer.buffered();
    }

    pub fn skribiAlPBDosiero(self: *TestRepeatedMessage, allocator: all.Allocator) ![]u8 {
        _=self; _= allocator;
    }

    pub fn serialize(self: *TestRepeatedMessage, allocator: all.Allocator) ![]u8 {
        return serializeTipon(allocator, TestRepeatedMessage, @as(*TestRepeatedMessage,self));
    }

    fn encode(self: *const TestRepeatedMessage, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
 
        for (self.value) |item| {
            tuta_longo += try buffer.encodeUint32( item );
            tuta_longo += try buffer.encodeVarint(10);
        }  // 9 rept - no def - no varlong 

        return tuta_longo;
    }

    pub fn deserialize(allocator: all.Allocator,input: []const u8) !TestRepeatedMessage {
        return deserializeTipon(allocator, TestRepeatedMessage, input);
    }

    fn decode(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !TestRepeatedMessage {
        var mia_Mesagho= try TestRepeatedMessage.initDefault(allocator);

        var end: usize = undefined;
        if (data_length) |val|
            end = buffer.read_index + val
        else
            end = buffer.buffer.len;

        var value_list: std.ArrayList(u32) = .empty; 

        while (buffer.read_index < end) {
            const key: u64 = buffer.decodeVarint() catch 0 ;    
            const wire_type = key & 0x7;  
            const field_number = key >> 3;

            if ( field_number == 1 and wire_type == 2 ) 
                { try value_list.append( allocator, try buffer.decodeUint32() ); }
        }

        mia_Mesagho.value = try value_list.toOwnedSlice(allocator); 

        return mia_Mesagho;
    }
};

pub const TestRepeatedPackedMessage = struct {
    value: []u32,

    pub fn initDefault(allocator: all.Allocator) !TestRepeatedPackedMessage {
        const self = try allocator.create(TestRepeatedPackedMessage);
        self.* = TestRepeatedPackedMessage{
            .value = try allocator.alloc(u32, 0),
        };
        return self.*;
    }

    pub fn skribiAlZonTeksto(self: *TestRepeatedPackedMessage, allocator: all.Allocator) ![]u8 {
        return skribiTiponAlZonTeksto(allocator, TestRepeatedPackedMessage, @as(*TestRepeatedPackedMessage,self));
    }

    pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !TestRepeatedPackedMessage {
        return legiTiponElZonTeksto(allocator, TestRepeatedPackedMessage, input);
    }

    pub fn skribiAlZonDosiero(self: *TestRepeatedPackedMessage, allocator: all.Allocator, path: []const u8) !void {
        try skribiTiponAlZonDosiero(allocator, TestRepeatedPackedMessage, @as(*TestRepeatedPackedMessage, self), path);
    }

    pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !TestRepeatedPackedMessage {
        return legiTiponElZonDosiero(allocator, TestRepeatedPackedMessage, path);
    }

    pub fn skribiAlProtobufTeksto(self: *const TestRepeatedPackedMessage, allocator: all.Allocator,ind: []const u8) ![]const u8 {
       const indent = std.mem.concatWithSentinel(std.heap.page_allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
       var bufro:std.ArrayList(u8)= .empty;
       if( equal(u8,indent,"") ) { {} } 

        for(self.value) |obj| 
            try bufro.print(allocator,"{s}value: {any}\n",.{ind, obj });

        return bufro.toOwnedSlice(allocator);
    }

    pub fn skribiAlJsonTeksto(self: *const TestRepeatedPackedMessage, allocator: all.Allocator) ![]const u8 {
        var skribila_asignilo = std.Io.Writer.Allocating.init(allocator);

        std.json.fmt(self,.{.whitespace=.indent_3}).format(&skribila_asignilo.writer) catch |err| {
            std.debug.print("eraro dum seriigo: {}\n", .{err});
            return err;
        };

    return skribila_asignilo.writer.buffered();
    }

    pub fn skribiAlPBDosiero(self: *TestRepeatedPackedMessage, allocator: all.Allocator) ![]u8 {
        _=self; _= allocator;
    }

    pub fn serialize(self: *TestRepeatedPackedMessage, allocator: all.Allocator) ![]u8 {
        return serializeTipon(allocator, TestRepeatedPackedMessage, @as(*TestRepeatedPackedMessage,self));
    }

    fn encode(self: *const TestRepeatedPackedMessage, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
 
        var value_longa: usize = 0; 
        for (self.value) |item| 
            value_longa += try buffer.encodeUint32( item );
        tuta_longo += value_longa;
        tuta_longo += try buffer.encodeVarint(value_longa);
        tuta_longo += try buffer.encodeVarint(10);
        // 9 rept - no def - no varlong  PACKED

        return tuta_longo;
    }

    pub fn deserialize(allocator: all.Allocator,input: []const u8) !TestRepeatedPackedMessage {
        return deserializeTipon(allocator, TestRepeatedPackedMessage, input);
    }

    fn decode(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !TestRepeatedPackedMessage {
        var mia_Mesagho= try TestRepeatedPackedMessage.initDefault(allocator);

        var end: usize = undefined;
        if (data_length) |val|
            end = buffer.read_index + val
        else
            end = buffer.buffer.len;

        var value_list: std.ArrayList(u32) = .empty; 

        while (buffer.read_index < end) {
            const key: u64 = buffer.decodeVarint() catch 0 ;    
            const wire_type = key & 0x7;  
            const field_number = key >> 3;

            if ( field_number == 1 and wire_type == 2 ) 
            {
                const value_len = try buffer.decodeVarint();
                const value_end = buffer.read_index + value_len;
                while (buffer.read_index < value_end)
                    try value_list.append( allocator, try  buffer.decodeUint32() );
                if (buffer.read_index != value_end) return error.AllocationFailed;
            }
        }

        mia_Mesagho.value = try value_list.toOwnedSlice(allocator); 

        return mia_Mesagho;
    }
};

pub const TestEnumMessage = struct {
    enum_value: TestEnum,
    enum_value_o: ?TestEnum = null,
    enum_value_od: ?TestEnum = .TWO ,
    enum_value_r: []TestEnum,

    pub fn initDefault(allocator: all.Allocator) !TestEnumMessage {
        const self = try allocator.create(TestEnumMessage);
        self.* = TestEnumMessage{
            .enum_value = undefined, 
            .enum_value_o = null,
            .enum_value_od = .TWO,
            .enum_value_r = try allocator.alloc(TestEnum, 0),
        };
        return self.*;
    }

    pub fn skribiAlZonTeksto(self: *TestEnumMessage, allocator: all.Allocator) ![]u8 {
        return skribiTiponAlZonTeksto(allocator, TestEnumMessage, @as(*TestEnumMessage,self));
    }

    pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !TestEnumMessage {
        return legiTiponElZonTeksto(allocator, TestEnumMessage, input);
    }

    pub fn skribiAlZonDosiero(self: *TestEnumMessage, allocator: all.Allocator, path: []const u8) !void {
        try skribiTiponAlZonDosiero(allocator, TestEnumMessage, @as(*TestEnumMessage, self), path);
    }

    pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !TestEnumMessage {
        return legiTiponElZonDosiero(allocator, TestEnumMessage, path);
    }

    pub fn skribiAlProtobufTeksto(self: *const TestEnumMessage, allocator: all.Allocator,ind: []const u8) ![]const u8 {
       const indent = std.mem.concatWithSentinel(std.heap.page_allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
       var bufro:std.ArrayList(u8)= .empty;
       if( equal(u8,indent,"") ) { {} } 

        try bufro.print(allocator,"{s}enum_value: {any}\n",.{ind, self.enum_value });
        if( self.enum_value_o ) |val|  
            try bufro.print(allocator,"{s}enum_value_o: {any}\n",.{ ind, val });
        if( self.enum_value_od ) |val|  
            try bufro.print(allocator,"{s}enum_value_od: {any}\n",.{ ind, val });
        for(self.enum_value_r) |obj| 
            try bufro.print(allocator,"{s}enum_value_r: {any}\n",.{ind, obj });

        return bufro.toOwnedSlice(allocator);
    }

    pub fn skribiAlJsonTeksto(self: *const TestEnumMessage, allocator: all.Allocator) ![]const u8 {
        var skribila_asignilo = std.Io.Writer.Allocating.init(allocator);

        std.json.fmt(self,.{.whitespace=.indent_3}).format(&skribila_asignilo.writer) catch |err| {
            std.debug.print("eraro dum seriigo: {}\n", .{err});
            return err;
        };

    return skribila_asignilo.writer.buffered();
    }

    pub fn skribiAlPBDosiero(self: *TestEnumMessage, allocator: all.Allocator) ![]u8 {
        _=self; _= allocator;
    }

    pub fn serialize(self: *TestEnumMessage, allocator: all.Allocator) ![]u8 {
        return serializeTipon(allocator, TestEnumMessage, @as(*TestEnumMessage,self));
    }

    fn encode(self: *const TestEnumMessage, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
 
        for (self.enum_value_r) |item| {
            tuta_longo += try buffer.encodeVarint( @intFromEnum(item) );
            tuta_longo += try buffer.encodeVarint(34);
        }  // 9 rept - no def - no varlong 

        if( self.enum_value_od ) |val| {
            if( val != .TWO )  {
                tuta_longo += try buffer.encodeVarint( @intFromEnum(val) );
                tuta_longo += try buffer.encodeVarint(24);
            }
        }  //2 opt - def - no varlong

        if( self.enum_value_o ) |val| {
            tuta_longo += try buffer.encodeVarint( @intFromEnum(val) );
            tuta_longo += try buffer.encodeVarint(16);
        }   //1 opt - no def - no varlong

        tuta_longo += try buffer.encodeVarint( @intFromEnum(self.enum_value) );
        tuta_longo += try buffer.encodeVarint(8);
        //5 req - no def - no varlong

        return tuta_longo;
    }

    pub fn deserialize(allocator: all.Allocator,input: []const u8) !TestEnumMessage {
        return deserializeTipon(allocator, TestEnumMessage, input);
    }

    fn decode(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !TestEnumMessage {
        var mia_Mesagho= try TestEnumMessage.initDefault(allocator);

        var end: usize = undefined;
        if (data_length) |val|
            end = buffer.read_index + val
        else
            end = buffer.buffer.len;

        var enum_value_r_list: std.ArrayList(TestEnum) = .empty; 

        while (buffer.read_index < end) {
            const key: u64 = buffer.decodeVarint() catch 0 ;    
            const wire_type = key & 0x7;  
            const field_number = key >> 3;

            if ( field_number == 1 and wire_type == 0 ) 
                mia_Mesagho.enum_value = try std.meta.intToEnum(TestEnum, try buffer.decodeVarint() ) 
            else if ( field_number == 2 and wire_type == 0 ) 
                mia_Mesagho.enum_value_o = try std.meta.intToEnum(TestEnum, try buffer.decodeVarint() ) 
            else if ( field_number == 3 and wire_type == 0 ) 
                mia_Mesagho.enum_value_od = try std.meta.intToEnum(TestEnum, try buffer.decodeVarint() ) 
            else if ( field_number == 4 and wire_type == 2 ) 
                { try enum_value_r_list.append( allocator, try std.meta.intToEnum(TestEnum, try buffer.decodeVarint() )  ); }
        }

        mia_Mesagho.enum_value_r = try enum_value_r_list.toOwnedSlice(allocator); 

        return mia_Mesagho;
    }
};

pub const TestReservedMessage = struct {
    abstract: u32,
    as: u32,
    async: u32,
    base: u32,
    case: u32,
    class: u32,
    construct: u32,
    default: u32,
    delegate: u32,
    delete: u32,
    do: u32,
    dynamic: u32,
    ensures: u32,
    errordomain: u32,
    finally: u32,
    foreach: u32,
    get: u32,
    global: u32,
    in: u32,
    interface: u32,
    internal: u32,
    is: u32,
    lock: u32,
    namespace: u32,
    new: u32,
    null: u32,
    out: u32,
    owned: u32,
    override: u32,
    public: u32,
    private: u32,
    protected: u32,
    ref: u32,
    requires: u32,
    set: u32,
    signal: u32,
    sizeof: u32,
    static: u32,
    this: u32,
    throw: u32,
    throws: u32,
    true: u32,
    typeof: u32,
    unowned: u32,
    using: u32,
    value: u32,
    void: u32,
    virtual: u32,
    weak: u32,
    yield: u32,

    pub fn initDefault(allocator: all.Allocator) !TestReservedMessage {
        const self = try allocator.create(TestReservedMessage);
        self.* = TestReservedMessage{
            .abstract = 0,
            .as = 0,
            .async = 0,
            .base = 0,
            .case = 0,
            .class = 0,
            .construct = 0,
            .default = 0,
            .delegate = 0,
            .delete = 0,
            .do = 0,
            .dynamic = 0,
            .ensures = 0,
            .errordomain = 0,
            .finally = 0,
            .foreach = 0,
            .get = 0,
            .global = 0,
            .in = 0,
            .interface = 0,
            .internal = 0,
            .is = 0,
            .lock = 0,
            .namespace = 0,
            .new = 0,
            .null = 0,
            .out = 0,
            .owned = 0,
            .override = 0,
            .public = 0,
            .private = 0,
            .protected = 0,
            .ref = 0,
            .requires = 0,
            .set = 0,
            .signal = 0,
            .sizeof = 0,
            .static = 0,
            .this = 0,
            .throw = 0,
            .throws = 0,
            .true = 0,
            .typeof = 0,
            .unowned = 0,
            .using = 0,
            .value = 0,
            .void = 0,
            .virtual = 0,
            .weak = 0,
            .yield = 0,
        };
        return self.*;
    }

    pub fn skribiAlZonTeksto(self: *TestReservedMessage, allocator: all.Allocator) ![]u8 {
        return skribiTiponAlZonTeksto(allocator, TestReservedMessage, @as(*TestReservedMessage,self));
    }

    pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !TestReservedMessage {
        return legiTiponElZonTeksto(allocator, TestReservedMessage, input);
    }

    pub fn skribiAlZonDosiero(self: *TestReservedMessage, allocator: all.Allocator, path: []const u8) !void {
        try skribiTiponAlZonDosiero(allocator, TestReservedMessage, @as(*TestReservedMessage, self), path);
    }

    pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !TestReservedMessage {
        return legiTiponElZonDosiero(allocator, TestReservedMessage, path);
    }

    pub fn skribiAlProtobufTeksto(self: *const TestReservedMessage, allocator: all.Allocator,ind: []const u8) ![]const u8 {
       const indent = std.mem.concatWithSentinel(std.heap.page_allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
       var bufro:std.ArrayList(u8)= .empty;
       if( equal(u8,indent,"") ) { {} } 

        try bufro.print(allocator,"{s}abstract: {any}\n",.{ind, self.abstract });
        try bufro.print(allocator,"{s}as: {any}\n",.{ind, self.as });
        try bufro.print(allocator,"{s}async: {any}\n",.{ind, self.async });
        try bufro.print(allocator,"{s}base: {any}\n",.{ind, self.base });
        try bufro.print(allocator,"{s}case: {any}\n",.{ind, self.case });
        try bufro.print(allocator,"{s}class: {any}\n",.{ind, self.class });
        try bufro.print(allocator,"{s}construct: {any}\n",.{ind, self.construct });
        try bufro.print(allocator,"{s}default: {any}\n",.{ind, self.default });
        try bufro.print(allocator,"{s}delegate: {any}\n",.{ind, self.delegate });
        try bufro.print(allocator,"{s}delete: {any}\n",.{ind, self.delete });
        try bufro.print(allocator,"{s}do: {any}\n",.{ind, self.do });
        try bufro.print(allocator,"{s}dynamic: {any}\n",.{ind, self.dynamic });
        try bufro.print(allocator,"{s}ensures: {any}\n",.{ind, self.ensures });
        try bufro.print(allocator,"{s}errordomain: {any}\n",.{ind, self.errordomain });
        try bufro.print(allocator,"{s}finally: {any}\n",.{ind, self.finally });
        try bufro.print(allocator,"{s}foreach: {any}\n",.{ind, self.foreach });
        try bufro.print(allocator,"{s}get: {any}\n",.{ind, self.get });
        try bufro.print(allocator,"{s}global: {any}\n",.{ind, self.global });
        try bufro.print(allocator,"{s}in: {any}\n",.{ind, self.in });
        try bufro.print(allocator,"{s}interface: {any}\n",.{ind, self.interface });
        try bufro.print(allocator,"{s}internal: {any}\n",.{ind, self.internal });
        try bufro.print(allocator,"{s}is: {any}\n",.{ind, self.is });
        try bufro.print(allocator,"{s}lock: {any}\n",.{ind, self.lock });
        try bufro.print(allocator,"{s}namespace: {any}\n",.{ind, self.namespace });
        try bufro.print(allocator,"{s}new: {any}\n",.{ind, self.new });
        try bufro.print(allocator,"{s}null: {any}\n",.{ind, self.null });
        try bufro.print(allocator,"{s}out: {any}\n",.{ind, self.out });
        try bufro.print(allocator,"{s}owned: {any}\n",.{ind, self.owned });
        try bufro.print(allocator,"{s}override: {any}\n",.{ind, self.override });
        try bufro.print(allocator,"{s}public: {any}\n",.{ind, self.public });
        try bufro.print(allocator,"{s}private: {any}\n",.{ind, self.private });
        try bufro.print(allocator,"{s}protected: {any}\n",.{ind, self.protected });
        try bufro.print(allocator,"{s}ref: {any}\n",.{ind, self.ref });
        try bufro.print(allocator,"{s}requires: {any}\n",.{ind, self.requires });
        try bufro.print(allocator,"{s}set: {any}\n",.{ind, self.set });
        try bufro.print(allocator,"{s}signal: {any}\n",.{ind, self.signal });
        try bufro.print(allocator,"{s}sizeof: {any}\n",.{ind, self.sizeof });
        try bufro.print(allocator,"{s}static: {any}\n",.{ind, self.static });
        try bufro.print(allocator,"{s}this: {any}\n",.{ind, self.this });
        try bufro.print(allocator,"{s}throw: {any}\n",.{ind, self.throw });
        try bufro.print(allocator,"{s}throws: {any}\n",.{ind, self.throws });
        try bufro.print(allocator,"{s}true: {any}\n",.{ind, self.true });
        try bufro.print(allocator,"{s}typeof: {any}\n",.{ind, self.typeof });
        try bufro.print(allocator,"{s}unowned: {any}\n",.{ind, self.unowned });
        try bufro.print(allocator,"{s}using: {any}\n",.{ind, self.using });
        try bufro.print(allocator,"{s}value: {any}\n",.{ind, self.value });
        try bufro.print(allocator,"{s}void: {any}\n",.{ind, self.void });
        try bufro.print(allocator,"{s}virtual: {any}\n",.{ind, self.virtual });
        try bufro.print(allocator,"{s}weak: {any}\n",.{ind, self.weak });
        try bufro.print(allocator,"{s}yield: {any}\n",.{ind, self.yield });

        return bufro.toOwnedSlice(allocator);
    }

    pub fn skribiAlJsonTeksto(self: *const TestReservedMessage, allocator: all.Allocator) ![]const u8 {
        var skribila_asignilo = std.Io.Writer.Allocating.init(allocator);

        std.json.fmt(self,.{.whitespace=.indent_3}).format(&skribila_asignilo.writer) catch |err| {
            std.debug.print("eraro dum seriigo: {}\n", .{err});
            return err;
        };

    return skribila_asignilo.writer.buffered();
    }

    pub fn skribiAlPBDosiero(self: *TestReservedMessage, allocator: all.Allocator) ![]u8 {
        _=self; _= allocator;
    }

    pub fn serialize(self: *TestReservedMessage, allocator: all.Allocator) ![]u8 {
        return serializeTipon(allocator, TestReservedMessage, @as(*TestReservedMessage,self));
    }

    fn encode(self: *const TestReservedMessage, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
 
        tuta_longo += try buffer.encodeUint32( self.yield );
        tuta_longo += try buffer.encodeVarint(536);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.weak );
        tuta_longo += try buffer.encodeVarint(520);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.virtual );
        tuta_longo += try buffer.encodeVarint(512);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.void );
        tuta_longo += try buffer.encodeVarint(504);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.value );
        tuta_longo += try buffer.encodeVarint(488);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.using );
        tuta_longo += try buffer.encodeVarint(480);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.unowned );
        tuta_longo += try buffer.encodeVarint(472);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.typeof );
        tuta_longo += try buffer.encodeVarint(464);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.true );
        tuta_longo += try buffer.encodeVarint(448);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.throws );
        tuta_longo += try buffer.encodeVarint(440);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.throw );
        tuta_longo += try buffer.encodeVarint(432);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.this );
        tuta_longo += try buffer.encodeVarint(424);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.static );
        tuta_longo += try buffer.encodeVarint(400);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.sizeof );
        tuta_longo += try buffer.encodeVarint(392);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.signal );
        tuta_longo += try buffer.encodeVarint(384);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.set );
        tuta_longo += try buffer.encodeVarint(376);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.requires );
        tuta_longo += try buffer.encodeVarint(360);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.ref );
        tuta_longo += try buffer.encodeVarint(352);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.protected );
        tuta_longo += try buffer.encodeVarint(344);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.private );
        tuta_longo += try buffer.encodeVarint(336);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.public );
        tuta_longo += try buffer.encodeVarint(328);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.override );
        tuta_longo += try buffer.encodeVarint(320);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.owned );
        tuta_longo += try buffer.encodeVarint(312);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.out );
        tuta_longo += try buffer.encodeVarint(304);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.null );
        tuta_longo += try buffer.encodeVarint(296);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.new );
        tuta_longo += try buffer.encodeVarint(288);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.namespace );
        tuta_longo += try buffer.encodeVarint(280);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.lock );
        tuta_longo += try buffer.encodeVarint(272);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.is );
        tuta_longo += try buffer.encodeVarint(264);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.internal );
        tuta_longo += try buffer.encodeVarint(256);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.interface );
        tuta_longo += try buffer.encodeVarint(248);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.in );
        tuta_longo += try buffer.encodeVarint(232);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.global );
        tuta_longo += try buffer.encodeVarint(216);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.get );
        tuta_longo += try buffer.encodeVarint(208);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.foreach );
        tuta_longo += try buffer.encodeVarint(200);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.finally );
        tuta_longo += try buffer.encodeVarint(184);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.errordomain );
        tuta_longo += try buffer.encodeVarint(160);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.ensures );
        tuta_longo += try buffer.encodeVarint(152);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.dynamic );
        tuta_longo += try buffer.encodeVarint(128);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.do );
        tuta_longo += try buffer.encodeVarint(120);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.delete );
        tuta_longo += try buffer.encodeVarint(112);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.delegate );
        tuta_longo += try buffer.encodeVarint(104);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.default );
        tuta_longo += try buffer.encodeVarint(96);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.construct );
        tuta_longo += try buffer.encodeVarint(80);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.class );
        tuta_longo += try buffer.encodeVarint(64);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.case );
        tuta_longo += try buffer.encodeVarint(48);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.base );
        tuta_longo += try buffer.encodeVarint(32);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.async );
        tuta_longo += try buffer.encodeVarint(24);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.as );
        tuta_longo += try buffer.encodeVarint(16);
        //5 req - no def - no varlong

        tuta_longo += try buffer.encodeUint32( self.abstract );
        tuta_longo += try buffer.encodeVarint(8);
        //5 req - no def - no varlong

        return tuta_longo;
    }

    pub fn deserialize(allocator: all.Allocator,input: []const u8) !TestReservedMessage {
        return deserializeTipon(allocator, TestReservedMessage, input);
    }

    fn decode(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !TestReservedMessage {
        var mia_Mesagho= try TestReservedMessage.initDefault(allocator);

        var end: usize = undefined;
        if (data_length) |val|
            end = buffer.read_index + val
        else
            end = buffer.buffer.len;


        while (buffer.read_index < end) {
            const key: u64 = buffer.decodeVarint() catch 0 ;    
            const wire_type = key & 0x7;  
            const field_number = key >> 3;

            if ( field_number == 1 and wire_type == 0 ) 
                mia_Mesagho.abstract = try buffer.decodeUint32()
            else if ( field_number == 2 and wire_type == 0 ) 
                mia_Mesagho.as = try buffer.decodeUint32()
            else if ( field_number == 3 and wire_type == 0 ) 
                mia_Mesagho.async = try buffer.decodeUint32()
            else if ( field_number == 4 and wire_type == 0 ) 
                mia_Mesagho.base = try buffer.decodeUint32()
            else if ( field_number == 6 and wire_type == 0 ) 
                mia_Mesagho.case = try buffer.decodeUint32()
            else if ( field_number == 8 and wire_type == 0 ) 
                mia_Mesagho.class = try buffer.decodeUint32()
            else if ( field_number == 10 and wire_type == 0 ) 
                mia_Mesagho.construct = try buffer.decodeUint32()
            else if ( field_number == 12 and wire_type == 0 ) 
                mia_Mesagho.default = try buffer.decodeUint32()
            else if ( field_number == 13 and wire_type == 0 ) 
                mia_Mesagho.delegate = try buffer.decodeUint32()
            else if ( field_number == 14 and wire_type == 0 ) 
                mia_Mesagho.delete = try buffer.decodeUint32()
            else if ( field_number == 15 and wire_type == 0 ) 
                mia_Mesagho.do = try buffer.decodeUint32()
            else if ( field_number == 16 and wire_type == 0 ) 
                mia_Mesagho.dynamic = try buffer.decodeUint32()
            else if ( field_number == 19 and wire_type == 0 ) 
                mia_Mesagho.ensures = try buffer.decodeUint32()
            else if ( field_number == 20 and wire_type == 0 ) 
                mia_Mesagho.errordomain = try buffer.decodeUint32()
            else if ( field_number == 23 and wire_type == 0 ) 
                mia_Mesagho.finally = try buffer.decodeUint32()
            else if ( field_number == 25 and wire_type == 0 ) 
                mia_Mesagho.foreach = try buffer.decodeUint32()
            else if ( field_number == 26 and wire_type == 0 ) 
                mia_Mesagho.get = try buffer.decodeUint32()
            else if ( field_number == 27 and wire_type == 0 ) 
                mia_Mesagho.global = try buffer.decodeUint32()
            else if ( field_number == 29 and wire_type == 0 ) 
                mia_Mesagho.in = try buffer.decodeUint32()
            else if ( field_number == 31 and wire_type == 0 ) 
                mia_Mesagho.interface = try buffer.decodeUint32()
            else if ( field_number == 32 and wire_type == 0 ) 
                mia_Mesagho.internal = try buffer.decodeUint32()
            else if ( field_number == 33 and wire_type == 0 ) 
                mia_Mesagho.is = try buffer.decodeUint32()
            else if ( field_number == 34 and wire_type == 0 ) 
                mia_Mesagho.lock = try buffer.decodeUint32()
            else if ( field_number == 35 and wire_type == 0 ) 
                mia_Mesagho.namespace = try buffer.decodeUint32()
            else if ( field_number == 36 and wire_type == 0 ) 
                mia_Mesagho.new = try buffer.decodeUint32()
            else if ( field_number == 37 and wire_type == 0 ) 
                mia_Mesagho.null = try buffer.decodeUint32()
            else if ( field_number == 38 and wire_type == 0 ) 
                mia_Mesagho.out = try buffer.decodeUint32()
            else if ( field_number == 39 and wire_type == 0 ) 
                mia_Mesagho.owned = try buffer.decodeUint32()
            else if ( field_number == 40 and wire_type == 0 ) 
                mia_Mesagho.override = try buffer.decodeUint32()
            else if ( field_number == 41 and wire_type == 0 ) 
                mia_Mesagho.public = try buffer.decodeUint32()
            else if ( field_number == 42 and wire_type == 0 ) 
                mia_Mesagho.private = try buffer.decodeUint32()
            else if ( field_number == 43 and wire_type == 0 ) 
                mia_Mesagho.protected = try buffer.decodeUint32()
            else if ( field_number == 44 and wire_type == 0 ) 
                mia_Mesagho.ref = try buffer.decodeUint32()
            else if ( field_number == 45 and wire_type == 0 ) 
                mia_Mesagho.requires = try buffer.decodeUint32()
            else if ( field_number == 47 and wire_type == 0 ) 
                mia_Mesagho.set = try buffer.decodeUint32()
            else if ( field_number == 48 and wire_type == 0 ) 
                mia_Mesagho.signal = try buffer.decodeUint32()
            else if ( field_number == 49 and wire_type == 0 ) 
                mia_Mesagho.sizeof = try buffer.decodeUint32()
            else if ( field_number == 50 and wire_type == 0 ) 
                mia_Mesagho.static = try buffer.decodeUint32()
            else if ( field_number == 53 and wire_type == 0 ) 
                mia_Mesagho.this = try buffer.decodeUint32()
            else if ( field_number == 54 and wire_type == 0 ) 
                mia_Mesagho.throw = try buffer.decodeUint32()
            else if ( field_number == 55 and wire_type == 0 ) 
                mia_Mesagho.throws = try buffer.decodeUint32()
            else if ( field_number == 56 and wire_type == 0 ) 
                mia_Mesagho.true = try buffer.decodeUint32()
            else if ( field_number == 58 and wire_type == 0 ) 
                mia_Mesagho.typeof = try buffer.decodeUint32()
            else if ( field_number == 59 and wire_type == 0 ) 
                mia_Mesagho.unowned = try buffer.decodeUint32()
            else if ( field_number == 60 and wire_type == 0 ) 
                mia_Mesagho.using = try buffer.decodeUint32()
            else if ( field_number == 61 and wire_type == 0 ) 
                mia_Mesagho.value = try buffer.decodeUint32()
            else if ( field_number == 63 and wire_type == 0 ) 
                mia_Mesagho.void = try buffer.decodeUint32()
            else if ( field_number == 64 and wire_type == 0 ) 
                mia_Mesagho.virtual = try buffer.decodeUint32()
            else if ( field_number == 65 and wire_type == 0 ) 
                mia_Mesagho.weak = try buffer.decodeUint32()
            else if ( field_number == 67 and wire_type == 0 ) 
                mia_Mesagho.yield = try buffer.decodeUint32();
        }


        return mia_Mesagho;
    }
};

pub const TestRequiredNestedMessage = struct {
    child: TestChildMessage,

    pub fn initDefault(allocator: all.Allocator) !TestRequiredNestedMessage {
        const self = try allocator.create(TestRequiredNestedMessage);
        self.* = TestRequiredNestedMessage{
            .child = undefined, 
        };
        return self.*;
    }

    pub fn skribiAlZonTeksto(self: *TestRequiredNestedMessage, allocator: all.Allocator) ![]u8 {
        return skribiTiponAlZonTeksto(allocator, TestRequiredNestedMessage, @as(*TestRequiredNestedMessage,self));
    }

    pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !TestRequiredNestedMessage {
        return legiTiponElZonTeksto(allocator, TestRequiredNestedMessage, input);
    }

    pub fn skribiAlZonDosiero(self: *TestRequiredNestedMessage, allocator: all.Allocator, path: []const u8) !void {
        try skribiTiponAlZonDosiero(allocator, TestRequiredNestedMessage, @as(*TestRequiredNestedMessage, self), path);
    }

    pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !TestRequiredNestedMessage {
        return legiTiponElZonDosiero(allocator, TestRequiredNestedMessage, path);
    }

    pub fn skribiAlProtobufTeksto(self: *const TestRequiredNestedMessage, allocator: all.Allocator,ind: []const u8) ![]const u8 {
       const indent = std.mem.concatWithSentinel(std.heap.page_allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
       var bufro:std.ArrayList(u8)= .empty;
       if( equal(u8,indent,"") ) { {} } 

        try bufro.print(allocator, "{s}child {{\n{s}{s}}}\n", .{ind, try self.child.skribiAlProtobufTeksto(allocator,indent),ind });

        return bufro.toOwnedSlice(allocator);
    }

    pub fn skribiAlJsonTeksto(self: *const TestRequiredNestedMessage, allocator: all.Allocator) ![]const u8 {
        var skribila_asignilo = std.Io.Writer.Allocating.init(allocator);

        std.json.fmt(self,.{.whitespace=.indent_3}).format(&skribila_asignilo.writer) catch |err| {
            std.debug.print("eraro dum seriigo: {}\n", .{err});
            return err;
        };

    return skribila_asignilo.writer.buffered();
    }

    pub fn skribiAlPBDosiero(self: *TestRequiredNestedMessage, allocator: all.Allocator) ![]u8 {
        _=self; _= allocator;
    }

    pub fn serialize(self: *TestRequiredNestedMessage, allocator: all.Allocator) ![]u8 {
        return serializeTipon(allocator, TestRequiredNestedMessage, @as(*TestRequiredNestedMessage,self));
    }

    fn encode(self: *const TestRequiredNestedMessage, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
 
        const child_longa = try self.child.encode( buffer );
        tuta_longo += child_longa;
        tuta_longo += try buffer.encodeVarint(child_longa);
        tuta_longo += try buffer.encodeVarint(10);
        //7  req - no def - varlong

        return tuta_longo;
    }

    pub fn deserialize(allocator: all.Allocator,input: []const u8) !TestRequiredNestedMessage {
        return deserializeTipon(allocator, TestRequiredNestedMessage, input);
    }

    fn decode(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !TestRequiredNestedMessage {
        var mia_Mesagho= try TestRequiredNestedMessage.initDefault(allocator);

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
                mia_Mesagho.child = try TestChildMessage.decode(allocator, buffer, try buffer.decodeVarint() );
        }


        return mia_Mesagho;
    }
};

pub const TestOptionalNestedMessage = struct {
    child: ?TestChildMessage = null,

    pub fn initDefault(allocator: all.Allocator) !TestOptionalNestedMessage {
        const self = try allocator.create(TestOptionalNestedMessage);
        self.* = TestOptionalNestedMessage{
            .child = null,
        };
        return self.*;
    }

    pub fn skribiAlZonTeksto(self: *TestOptionalNestedMessage, allocator: all.Allocator) ![]u8 {
        return skribiTiponAlZonTeksto(allocator, TestOptionalNestedMessage, @as(*TestOptionalNestedMessage,self));
    }

    pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !TestOptionalNestedMessage {
        return legiTiponElZonTeksto(allocator, TestOptionalNestedMessage, input);
    }

    pub fn skribiAlZonDosiero(self: *TestOptionalNestedMessage, allocator: all.Allocator, path: []const u8) !void {
        try skribiTiponAlZonDosiero(allocator, TestOptionalNestedMessage, @as(*TestOptionalNestedMessage, self), path);
    }

    pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !TestOptionalNestedMessage {
        return legiTiponElZonDosiero(allocator, TestOptionalNestedMessage, path);
    }

    pub fn skribiAlProtobufTeksto(self: *const TestOptionalNestedMessage, allocator: all.Allocator,ind: []const u8) ![]const u8 {
       const indent = std.mem.concatWithSentinel(std.heap.page_allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
       var bufro:std.ArrayList(u8)= .empty;
       if( equal(u8,indent,"") ) { {} } 

        if( self.child ) |val|  
            try bufro.print(allocator, "{s}child {{\n{s}{s}}}\n", .{ind, try val.skribiAlProtobufTeksto(allocator,indent),ind });

        return bufro.toOwnedSlice(allocator);
    }

    pub fn skribiAlJsonTeksto(self: *const TestOptionalNestedMessage, allocator: all.Allocator) ![]const u8 {
        var skribila_asignilo = std.Io.Writer.Allocating.init(allocator);

        std.json.fmt(self,.{.whitespace=.indent_3}).format(&skribila_asignilo.writer) catch |err| {
            std.debug.print("eraro dum seriigo: {}\n", .{err});
            return err;
        };

    return skribila_asignilo.writer.buffered();
    }

    pub fn skribiAlPBDosiero(self: *TestOptionalNestedMessage, allocator: all.Allocator) ![]u8 {
        _=self; _= allocator;
    }

    pub fn serialize(self: *TestOptionalNestedMessage, allocator: all.Allocator) ![]u8 {
        return serializeTipon(allocator, TestOptionalNestedMessage, @as(*TestOptionalNestedMessage,self));
    }

    fn encode(self: *const TestOptionalNestedMessage, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
 
        if ( self.child ) |val| {
            const st_longa = try val.encode( buffer );
            tuta_longo += st_longa;
            tuta_longo += try buffer.encodeVarint(st_longa);
            tuta_longo += try buffer.encodeVarint(10);
        }  //3  opt - no def - varlong

        return tuta_longo;
    }

    pub fn deserialize(allocator: all.Allocator,input: []const u8) !TestOptionalNestedMessage {
        return deserializeTipon(allocator, TestOptionalNestedMessage, input);
    }

    fn decode(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !TestOptionalNestedMessage {
        var mia_Mesagho= try TestOptionalNestedMessage.initDefault(allocator);

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
                mia_Mesagho.child = try TestChildMessage.decode(allocator, buffer, try buffer.decodeVarint() );
        }


        return mia_Mesagho;
    }
};

pub const TestRepeatedNestedMessage = struct {
    children: []TestChildMessage,

    pub fn initDefault(allocator: all.Allocator) !TestRepeatedNestedMessage {
        const self = try allocator.create(TestRepeatedNestedMessage);
        self.* = TestRepeatedNestedMessage{
            .children = try allocator.alloc(TestChildMessage, 0),
        };
        return self.*;
    }

    pub fn skribiAlZonTeksto(self: *TestRepeatedNestedMessage, allocator: all.Allocator) ![]u8 {
        return skribiTiponAlZonTeksto(allocator, TestRepeatedNestedMessage, @as(*TestRepeatedNestedMessage,self));
    }

    pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !TestRepeatedNestedMessage {
        return legiTiponElZonTeksto(allocator, TestRepeatedNestedMessage, input);
    }

    pub fn skribiAlZonDosiero(self: *TestRepeatedNestedMessage, allocator: all.Allocator, path: []const u8) !void {
        try skribiTiponAlZonDosiero(allocator, TestRepeatedNestedMessage, @as(*TestRepeatedNestedMessage, self), path);
    }

    pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !TestRepeatedNestedMessage {
        return legiTiponElZonDosiero(allocator, TestRepeatedNestedMessage, path);
    }

    pub fn skribiAlProtobufTeksto(self: *const TestRepeatedNestedMessage, allocator: all.Allocator,ind: []const u8) ![]const u8 {
       const indent = std.mem.concatWithSentinel(std.heap.page_allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
       var bufro:std.ArrayList(u8)= .empty;
       if( equal(u8,indent,"") ) { {} } 

        for(self.children) |obj| 
            try bufro.print(allocator, "{s}children {{\n{s}{s}}}\n", .{ind, try obj.skribiAlProtobufTeksto(allocator,indent),ind });

        return bufro.toOwnedSlice(allocator);
    }

    pub fn skribiAlJsonTeksto(self: *const TestRepeatedNestedMessage, allocator: all.Allocator) ![]const u8 {
        var skribila_asignilo = std.Io.Writer.Allocating.init(allocator);

        std.json.fmt(self,.{.whitespace=.indent_3}).format(&skribila_asignilo.writer) catch |err| {
            std.debug.print("eraro dum seriigo: {}\n", .{err});
            return err;
        };

    return skribila_asignilo.writer.buffered();
    }

    pub fn skribiAlPBDosiero(self: *TestRepeatedNestedMessage, allocator: all.Allocator) ![]u8 {
        _=self; _= allocator;
    }

    pub fn serialize(self: *TestRepeatedNestedMessage, allocator: all.Allocator) ![]u8 {
        return serializeTipon(allocator, TestRepeatedNestedMessage, @as(*TestRepeatedNestedMessage,self));
    }

    fn encode(self: *const TestRepeatedNestedMessage, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
 
        for (self.children) |item| {
            const children_longa = try item.encode( buffer );
            tuta_longo += children_longa;
            tuta_longo += try buffer.encodeVarint(children_longa);
            tuta_longo += try buffer.encodeVarint(10);
        }  // 11  rept - no def - varlong 

        return tuta_longo;
    }

    pub fn deserialize(allocator: all.Allocator,input: []const u8) !TestRepeatedNestedMessage {
        return deserializeTipon(allocator, TestRepeatedNestedMessage, input);
    }

    fn decode(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !TestRepeatedNestedMessage {
        var mia_Mesagho= try TestRepeatedNestedMessage.initDefault(allocator);

        var end: usize = undefined;
        if (data_length) |val|
            end = buffer.read_index + val
        else
            end = buffer.buffer.len;

        var children_list: std.ArrayList(TestChildMessage) = .empty; 

        while (buffer.read_index < end) {
            const key: u64 = buffer.decodeVarint() catch 0 ;    
            const wire_type = key & 0x7;  
            const field_number = key >> 3;

            if ( field_number == 1 and wire_type == 2 ) 
                { try children_list.append( allocator, try TestChildMessage.decode(allocator, buffer, try buffer.decodeVarint() ) ); }
        }

        mia_Mesagho.children = try children_list.toOwnedSlice(allocator); 

        return mia_Mesagho;
    }
};

pub const TestChildMessage = struct {
    value: u32,

    pub fn initDefault(allocator: all.Allocator) !TestChildMessage {
        const self = try allocator.create(TestChildMessage);
        self.* = TestChildMessage{
            .value = 0,
        };
        return self.*;
    }

    pub fn skribiAlZonTeksto(self: *TestChildMessage, allocator: all.Allocator) ![]u8 {
        return skribiTiponAlZonTeksto(allocator, TestChildMessage, @as(*TestChildMessage,self));
    }

    pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !TestChildMessage {
        return legiTiponElZonTeksto(allocator, TestChildMessage, input);
    }

    pub fn skribiAlZonDosiero(self: *TestChildMessage, allocator: all.Allocator, path: []const u8) !void {
        try skribiTiponAlZonDosiero(allocator, TestChildMessage, @as(*TestChildMessage, self), path);
    }

    pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !TestChildMessage {
        return legiTiponElZonDosiero(allocator, TestChildMessage, path);
    }

    pub fn skribiAlProtobufTeksto(self: *const TestChildMessage, allocator: all.Allocator,ind: []const u8) ![]const u8 {
       const indent = std.mem.concatWithSentinel(std.heap.page_allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
       var bufro:std.ArrayList(u8)= .empty;
       if( equal(u8,indent,"") ) { {} } 

        try bufro.print(allocator,"{s}value: {any}\n",.{ind, self.value });

        return bufro.toOwnedSlice(allocator);
    }

    pub fn skribiAlJsonTeksto(self: *const TestChildMessage, allocator: all.Allocator) ![]const u8 {
        var skribila_asignilo = std.Io.Writer.Allocating.init(allocator);

        std.json.fmt(self,.{.whitespace=.indent_3}).format(&skribila_asignilo.writer) catch |err| {
            std.debug.print("eraro dum seriigo: {}\n", .{err});
            return err;
        };

    return skribila_asignilo.writer.buffered();
    }

    pub fn skribiAlPBDosiero(self: *TestChildMessage, allocator: all.Allocator) ![]u8 {
        _=self; _= allocator;
    }

    pub fn serialize(self: *TestChildMessage, allocator: all.Allocator) ![]u8 {
        return serializeTipon(allocator, TestChildMessage, @as(*TestChildMessage,self));
    }

    fn encode(self: *const TestChildMessage, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
 
        tuta_longo += try buffer.encodeUint32( self.value );
        tuta_longo += try buffer.encodeVarint(8);
        //5 req - no def - no varlong

        return tuta_longo;
    }

    pub fn deserialize(allocator: all.Allocator,input: []const u8) !TestChildMessage {
        return deserializeTipon(allocator, TestChildMessage, input);
    }

    fn decode(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !TestChildMessage {
        var mia_Mesagho= try TestChildMessage.initDefault(allocator);

        var end: usize = undefined;
        if (data_length) |val|
            end = buffer.read_index + val
        else
            end = buffer.buffer.len;


        while (buffer.read_index < end) {
            const key: u64 = buffer.decodeVarint() catch 0 ;    
            const wire_type = key & 0x7;  
            const field_number = key >> 3;

            if ( field_number == 1 and wire_type == 0 ) 
                mia_Mesagho.value = try buffer.decodeUint32();
        }


        return mia_Mesagho;
    }
};

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


