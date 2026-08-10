const std = @import("std");
const dbg = std.debug;
const all = std.mem;
const equal = std.mem.eql;
const  io = std.Io;

const encdec = @import("encdec.zig");
const EncodeBuffer = encdec.EncodeBuffer;
const DecodeBuffer = encdec.DecodeBuffer;

const TokenIterType = std.mem.TokenIterator(u8, .any);

pub const k6bus = struct {

    pub const security = struct {


pub const CryptoMode = enum(u64) {
   CRYPTO_NONE = 0,
   CRYPTO_AES_256_CBC = 1,
   CRYPTO_AES_256_GCM = 2,
   CRYPTO_CHACHA20_POLY1305 = 3,
};

pub const KeyRegistry = struct {
    Version: ?u32 = 1 ,
    Date: []const u8,
    Time: []const u8,
    Sender: []const u8,
    Phrase: ?[]const u8 = null,
    Salt: ?[]const u8 = null,
    Mode: ?CryptoMode = .CRYPTO_AES_256_GCM ,
    KeyId: ?u32 = 0 ,
    Key: []const u8,
    LegacyIV: ?[]const u8 = null,

    pub fn initDefault(allocator: all.Allocator) !KeyRegistry {
        return KeyRegistry {
            .Version = 1,
            .Date = try allocator.dupe(u8, ""),
            .Time = try allocator.dupe(u8, ""),
            .Sender = try allocator.dupe(u8, ""),
            .Phrase = null,
            .Salt = null,
            .Mode = .CRYPTO_AES_256_GCM,
            .KeyId = 0,
            .Key = try allocator.dupe(u8, ""),
            .LegacyIV = null,
        };
    }

    pub fn deinit(self: *const KeyRegistry, allocator: all.Allocator) void {
        allocator.free(self.Date);
        allocator.free(self.Time);
        allocator.free(self.Sender);
        if( self.Phrase ) |f| {
            allocator.free(f);
        }
        if( self.Salt ) |f| {
            allocator.free(f);
        }
        allocator.free(self.Key);
        if( self.LegacyIV ) |f| {
            allocator.free(f);
        }
    }

    pub fn skribiAlTeksto(self: *KeyRegistry, allocator: all.Allocator, t_formato: TekstaFormato) ![]const u8 {
        return try skribiTiponAlTeksto(allocator, KeyRegistry, @as(*KeyRegistry, self), t_formato);
    }

    pub fn skribiAlDosiero(self: *KeyRegistry, allocator: all.Allocator, path: []const u8, t_formato: TekstaFormato) !void {
        try skribiTiponAlDosiero(allocator, KeyRegistry, @as(*KeyRegistry, self), path, t_formato);
    }

    pub fn legiElTeksto(allocator: all.Allocator, input: []const u8, t_formato: TekstaFormato) !KeyRegistry {
        return try legiTiponElTeksto(allocator, KeyRegistry, input, t_formato);
    }

    pub fn legiElDosiero(allocator: all.Allocator, path: []const u8, t_formato: TekstaFormato) !KeyRegistry {
        return try legiTiponElDosiero(allocator, KeyRegistry, path, t_formato);
    }

    fn skribiAlProtobufTeksto(self: *const KeyRegistry, allocator: all.Allocator,ind: []const u8) ![]const u8 {
        var bufro:std.ArrayList(u8)= .empty;

        if( self.Version ) |val|  
            try bufro.print(allocator,"{s}Version: {any}\n",.{ ind, val });
        try bufro.print(allocator,"{s}Date: \"{s}\"\n",.{ind, self.Date });
        try bufro.print(allocator,"{s}Time: \"{s}\"\n",.{ind, self.Time });
        try bufro.print(allocator,"{s}Sender: \"{s}\"\n",.{ind, self.Sender });
        if( self.Phrase ) |val|  
            try bufro.print(allocator,"{s}Phrase: \"{s}\"\n",.{ ind, val });
        if( self.Salt ) |val|  
            try bufro.print(allocator,"{s}Salt: \"{s}\"\n",.{ ind, val });
        if( self.Mode ) |val|  
            try bufro.print(allocator, "{s}Mode: {s}\n", .{ ind, @tagName(val) });
        if( self.KeyId ) |val|  
            try bufro.print(allocator,"{s}KeyId: {any}\n",.{ ind, val });
        try bufro.print(allocator,"{s}Key: {any}\n",.{ind, self.Key });
        if( self.LegacyIV ) |val|  
            try bufro.print(allocator,"{s}LegacyIV: {any}\n",.{ ind, val });

        return bufro.toOwnedSlice(allocator);
    }

    fn legiElProtobufTeksto(allocator: all.Allocator, it: *TokenIterType) !KeyRegistry {
        var mia_Mesagho= try KeyRegistry.initDefault(allocator); 


        while (it.next()) |tok| {
            if( equal(u8, tok, "}" ) ) break;
            const val = it.next() orelse return error.InvalidFormat;

            if( equal(u8, tok, "Version" ) ) { 
                mia_Mesagho.Version =  std.fmt.parseInt(u32,val,10) catch 0;
                continue;
            }
            if( equal(u8, tok, "Date" ) ) { 
                mia_Mesagho.Date =  allocator.dupe(u8, val) catch "";
                continue;
            }
            if( equal(u8, tok, "Time" ) ) { 
                mia_Mesagho.Time =  allocator.dupe(u8, val) catch "";
                continue;
            }
            if( equal(u8, tok, "Sender" ) ) { 
                mia_Mesagho.Sender =  allocator.dupe(u8, val) catch "";
                continue;
            }
            if( equal(u8, tok, "Phrase" ) ) { 
                mia_Mesagho.Phrase =  allocator.dupe(u8, val) catch "";
                continue;
            }
            if( equal(u8, tok, "Salt" ) ) { 
                mia_Mesagho.Salt =  allocator.dupe(u8, val) catch "";
                continue;
            }
            if( equal(u8, tok, "Mode" ) ) { 
                mia_Mesagho.Mode = parseEnumValue(CryptoMode, val) catch (std.meta.intToEnum(CryptoMode, 0) catch unreachable);
                continue;
            }
            if( equal(u8, tok, "KeyId" ) ) { 
                mia_Mesagho.KeyId =  std.fmt.parseInt(u32,val,10) catch 0;
                continue;
            }
            if( equal(u8, tok, "Key" ) ) { 
                mia_Mesagho.Key =  allocator.dupe(u8, val) catch "";
                continue;
            }
            if( equal(u8, tok, "LegacyIV" ) ) { 
                mia_Mesagho.LegacyIV =  allocator.dupe(u8, val) catch "";
                continue;
            }
        }

        return mia_Mesagho;
    }

    pub fn seriigiAlBin(self: *const KeyRegistry, allocator: all.Allocator, b_formato: BinaraFormato) ![]const u8 {
        return try seriigiTiponAlBin(allocator, KeyRegistry, self, b_formato);
    }

    pub fn seriigiAlDosiero(self: *const KeyRegistry, allocator: all.Allocator, path: []const u8, b_formato: BinaraFormato) !void {
        return try seriigiTiponAlDosiero(allocator, KeyRegistry, @as(*KeyRegistry, self), path, b_formato);
    }

    fn seriigi(self: *const KeyRegistry, allocator: all.Allocator, buffer: *EncodeBuffer) !usize {
 
        _ = allocator;
        var tuta_longo: usize = 0;
 
    if ( self.LegacyIV ) |val| {
        const st_longa = try buffer.encodeBytes( val );
        tuta_longo += st_longa;
        tuta_longo += try buffer.encodeVarint(st_longa);
        tuta_longo += try buffer.encodeVarint(82);
    }  //3  opt - no def - varlong

        const Key_longa = try buffer.encodeBytes( self.Key );
        tuta_longo += Key_longa;
        tuta_longo += try buffer.encodeVarint(Key_longa);
        tuta_longo += try buffer.encodeVarint(74);
        //7  req - no def - varlong

    if( self.KeyId ) |val| {
        if( val != 0 )  {
            tuta_longo += try buffer.encodeUint32( val );
            tuta_longo += try buffer.encodeVarint(64);
        }
    }  //2 opt - def - no varlong

    if( self.Mode ) |val| {
        if( val != .CRYPTO_AES_256_GCM )  {
            tuta_longo += try buffer.encodeVarint( @intFromEnum(val) );
            tuta_longo += try buffer.encodeVarint(56);
        }
    }  //2 opt - def - no varlong

    if ( self.Salt ) |val| {
        const st_longa = try buffer.encodeString( val );
        tuta_longo += st_longa;
        tuta_longo += try buffer.encodeVarint(st_longa);
        tuta_longo += try buffer.encodeVarint(50);
    }  //3  opt - no def - varlong

    if ( self.Phrase ) |val| {
        const st_longa = try buffer.encodeString( val );
        tuta_longo += st_longa;
        tuta_longo += try buffer.encodeVarint(st_longa);
        tuta_longo += try buffer.encodeVarint(42);
    }  //3  opt - no def - varlong

        const Sender_longa = try buffer.encodeString( self.Sender );
        tuta_longo += Sender_longa;
        tuta_longo += try buffer.encodeVarint(Sender_longa);
        tuta_longo += try buffer.encodeVarint(34);
        //7  req - no def - varlong

        const Time_longa = try buffer.encodeString( self.Time );
        tuta_longo += Time_longa;
        tuta_longo += try buffer.encodeVarint(Time_longa);
        tuta_longo += try buffer.encodeVarint(26);
        //7  req - no def - varlong

        const Date_longa = try buffer.encodeString( self.Date );
        tuta_longo += Date_longa;
        tuta_longo += try buffer.encodeVarint(Date_longa);
        tuta_longo += try buffer.encodeVarint(18);
        //7  req - no def - varlong

    if( self.Version ) |val| {
        if( val != 1 )  {
            tuta_longo += try buffer.encodeUint32( val );
            tuta_longo += try buffer.encodeVarint(8);
        }
    }  //2 opt - def - no varlong

        return tuta_longo;
    }

    pub fn deseriigiElBin(allocator: all.Allocator,input: []const u8, b_formato: BinaraFormato) !KeyRegistry {
        return try deseriigiTiponElBin(allocator, KeyRegistry, input, b_formato);
    }

    pub fn deseriigiElDosiero(allocator: all.Allocator, path: [:0]const u8, b_formato: BinaraFormato) !KeyRegistry {
        return try deseriigiTiponElDosiero(allocator, KeyRegistry, path, b_formato);
    }

    fn deseriigi(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !KeyRegistry {
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

            if ( field_number == 1 and wire_type == 0 ) 
                mia_Mesagho.Version = try buffer.decodeUint32()
            else if ( field_number == 2 and wire_type == 2 ) 
                mia_Mesagho.Date = try buffer.decodeString(  try buffer.decodeVarint() )
            else if ( field_number == 3 and wire_type == 2 ) 
                mia_Mesagho.Time = try buffer.decodeString(  try buffer.decodeVarint() )
            else if ( field_number == 4 and wire_type == 2 ) 
                mia_Mesagho.Sender = try buffer.decodeString(  try buffer.decodeVarint() )
            else if ( field_number == 5 and wire_type == 2 ) 
                mia_Mesagho.Phrase = try buffer.decodeString(  try buffer.decodeVarint() )
            else if ( field_number == 6 and wire_type == 2 ) 
                mia_Mesagho.Salt = try buffer.decodeString(  try buffer.decodeVarint() )
            else if ( field_number == 7 and wire_type == 0 ) 
                mia_Mesagho.Mode = try std.meta.intToEnum(CryptoMode, try buffer.decodeVarint() ) 
            else if ( field_number == 8 and wire_type == 0 ) 
                mia_Mesagho.KeyId = try buffer.decodeUint32()
            else if ( field_number == 9 and wire_type == 2 ) 
                mia_Mesagho.Key = try buffer.decodeBytes(  try buffer.decodeVarint() )
            else if ( field_number == 10 and wire_type == 2 ) 
                mia_Mesagho.LegacyIV = try buffer.decodeBytes(  try buffer.decodeVarint() );
        }


        return mia_Mesagho;
    }
};    // KeyRegistry

    };   // security
};   // k6bus

//////////////////////////////////////////////
/// //////////////////////////////////////////
/// //////////////////////////////////////////
//////////////////////////////////////////////

//////////////////////////////////////////////
/// Seriigi Binaran Tipon
/// //////////////////////////////////////////

pub const BinaraFormato = enum(u32) {
    BF_PROTOBUF = 0,
    BF_OMG_CDR = 1,
    BF_ASN1_BER = 2,
    BF_ASN1_DER = 3,
    BF_BASE64 = 10,
    BF_BINPB2TEKSTO_HEX = 11,
    BF_BINPB2TEKSTO_DEC = 12,
};

fn seriigiTipon(allocator: all.Allocator, comptime T: type, value: * const T) ![]const u8 {
    var mia_enc = try EncodeBuffer.init(allocator, 48 * 1024);
    defer mia_enc.deinit();

    const longo = try value.seriigi(allocator, &mia_enc);
    const bytes = try allocator.alloc(u8, longo);
    std.mem.copyForwards(u8, bytes, mia_enc.data());
    return bytes;
}

fn seriigiTiponAlBin(allocator: all.Allocator, comptime T: type, value: * const T, b_formato: BinaraFormato) ![]const u8 {
    var parsed: []const u8 = undefined;
    switch (b_formato) {
        .BF_PROTOBUF => {
            parsed = try seriigiTipon(allocator, T, value);
        },
        .BF_BASE64 => {
            const binaraj_bitoj = try seriigiTipon(allocator, T, value);
            defer allocator.free(binaraj_bitoj);

            const enc=std.base64.standard.Encoder;
            const base64_longo = enc.calcSize(binaraj_bitoj.len);
            const base64_bitoj = try allocator.alloc(u8, base64_longo);
            parsed = enc.encode(base64_bitoj, binaraj_bitoj);
        },
        .BF_BINPB2TEKSTO_HEX => {
            const binaraj_bitoj = try seriigiTipon(allocator, T, value);
            defer allocator.free(binaraj_bitoj);

            var bin2teksto_bitoj:std.ArrayList(u8)= .empty;
            const hex = "0123456789ABCDEF";
            try bin2teksto_bitoj.print(allocator,"{{ ", .{});
            for (binaraj_bitoj, 0..) |val, i| {
                const hi: u8 = @intCast((val >> 4) & 0xF);
                const lo: u8 = @intCast(val & 0xF);
                try bin2teksto_bitoj.print(allocator,"0x{c}{c}{s} ", .{ hex[hi], hex[lo], if (i!=binaraj_bitoj.len-1) "," else ""});

                if ((i + 1) % 20 == 0) try bin2teksto_bitoj.print(allocator,"\n", .{});
            }
            try bin2teksto_bitoj.print(allocator,"}}", .{});
            parsed = try bin2teksto_bitoj.toOwnedSlice(allocator);
        },
        .BF_BINPB2TEKSTO_DEC => {
            const binaraj_bitoj = try seriigiTipon(allocator, T, value);
            defer allocator.free(binaraj_bitoj);

            var bin2teksto_bitoj:std.ArrayList(u8)= .empty;
            bin2teksto_bitoj.print(allocator,"{any}",.{binaraj_bitoj}) catch |err| {
                std.debug.print("eraro dum bin2teksto: {}\n", .{err});
                return err;
            };
            parsed = try bin2teksto_bitoj.toOwnedSlice(allocator);
        },    
        else => {
            return error.UnsupportedFormat;
        },
    }

    return parsed;
}

fn seriigiTiponAlDosiero(allocator: all.Allocator, comptime T: type, value: * const T, b_formato: BinaraFormato, path: []const u8) !void {
    const teksto = try seriigiTiponAlBin(allocator, T, value, b_formato);
    defer allocator.free(teksto);

    var dosiero = try std.fs.cwd().createFile(path, .{ .truncate = true });
    defer dosiero.close();
    try dosiero.writeAll(teksto);
}

//////////////////////////////////////////////
//// Deseriigi Binaran Tipon
//////////////////////////////////////////////

fn deseriigiTipon(allocator: all.Allocator, comptime T: type, input: []const u8) !T {
    var mia_dec = DecodeBuffer.init(allocator, input, 0, -1);
    defer mia_dec.deinit();

    const obj = try T.deseriigi(allocator, &mia_dec, null);
    return obj;
}

fn deseriigiTiponElBin(allocator: all.Allocator, comptime T: type, input: []const u8, b_formato: BinaraFormato) !T {
    var parsed: []const u8 = undefined;
    switch (b_formato) {
        .BF_PROTOBUF => {
            parsed = input;
        },
        .BF_BASE64 => {
            const dec=std.base64.standard.Decoder;
            const base64_decoded_longo = try dec.calcSizeForSlice(input);
            const base64_decoded = try allocator.alloc(u8, base64_decoded_longo);

            dec.decode(base64_decoded,input) catch |err| {
                std.debug.print("eraro dum deseriigo: {}\n", .{err});
                return err;
            };
            parsed = base64_decoded;
        },
        .BF_BINPB2TEKSTO_HEX, .BF_BINPB2TEKSTO_DEC => {
            var it = std.mem.tokenizeAny(u8, input, "{}, \n\r\t");
            var bytes: std.ArrayList(u8) = .empty;
            while (it.next()) |tok| {
                const val = std.fmt.parseUnsigned(u8, tok, 0) catch |err| {
                    std.debug.print("eraro dum parseInt dec: {}\n", .{err});
                    return err;
                };
                bytes.append(allocator, val) catch |err| {
                    std.debug.print("eraro dum append dec: {}\n", .{err});
                    return err;
                };
            }
            parsed = try bytes.toOwnedSlice(allocator);
        },
        else => {
            return error.UnsupportedFormat;
        },
    }

    return deseriigiTipon(allocator, T, parsed);
}

fn deseriigiTiponElDosiero(allocator: all.Allocator, comptime T: type, path: []const u8, b_formato: BinaraFormato) !T {
    var dosiero = try std.fs.cwd().openFile(path, .{});
    defer dosiero.close();

    const dosiera_long = try dosiero.getEndPos();
    var enhavo = allocator.alloc(u8, dosiera_long + 1) catch return error.OutOfMemory;
    defer allocator.free(enhavo);

    _ = try dosiero.readAll(enhavo[0..dosiera_long]);
    enhavo[dosiera_long] = 0;

    return deseriigiTiponElBin(allocator, T, enhavo[0..dosiera_long :0], b_formato);
}

//////////////////////////////////////////////
/// //////////////////////////////////////////
/// //////////////////////////////////////////
//////////////////////////////////////////////

const zon = std.zon;

fn parseEnumValue(comptime E: type, tok: []const u8) !E {
    if (std.meta.stringToEnum(E, tok)) |v| return v;
    const n = try std.fmt.parseInt(u64, tok, 10);
    return try std.meta.intToEnum(E, n);
}

fn legiSubProtobufTeksto(allocator: all.Allocator, it: *TokenIterType) ![]const u8 {
    var bufro: std.ArrayList(u8) = .empty;
    var depth: usize = 1;

    while (it.next()) |tok| {
        if (equal(u8, tok, "{")) {
            depth += 1;
            try bufro.print(allocator, "{ ", .{});
            continue;
        }

        if (equal(u8, tok, "}")) {
            depth -= 1;
            if (depth == 0) break;
            try bufro.print(allocator, "} ", .{});
            continue;
        }

        try bufro.print(allocator, "{s} ", .{tok});
    }

    if (depth != 0) return error.InvalidFormat;
    return try bufro.toOwnedSlice(allocator);
}

pub const TekstaFormato = enum(u32) {
    TF_ZIG_ZON,
    TF_PROTOBUF,
    TF_JSON,
    TF_ASN1,
};

//////////////////////////////////////////////
//// Skribi Tipon Al Teksto
//////////////////////////////////////////////

pub fn skribiTiponAlTeksto(allocator: all.Allocator, comptime T: type, value: *T, t_formato: TekstaFormato) ![]const u8 {
    var skribila_asignilo = std.Io.Writer.Allocating.init(allocator);

    const self = @as(T, value.*);
    var bytes: []const u8 = undefined;
    switch (t_formato) {
        .TF_ZIG_ZON => {
            zon.stringify.serialize(self, .{}, &skribila_asignilo.writer) catch |err| {
                std.debug.print("eraro dum seriigo: {}\n", .{err});
                return err;
            };
            bytes = skribila_asignilo.toOwnedSlice() catch |err| {
                std.debug.print("eraro dum seriigo: {}\n", .{err});
               return err;
            };
        },
        .TF_JSON => {
            std.json.fmt(self, .{ .whitespace = .indent_3 }).format(&skribila_asignilo.writer) catch |err| {
                std.debug.print("eraro dum seriigo: {}\n", .{err});
                return err;
            };
            bytes = skribila_asignilo.toOwnedSlice() catch |err| {
                std.debug.print("eraro dum seriigo: {}\n", .{err});
               return err;
            };
        },
        .TF_PROTOBUF => {
            bytes = self.skribiAlProtobufTeksto(allocator, "") catch |err| {
                std.debug.print("eraro dum seriigo: {}\n", .{err});
                return err;
            };
        },
        else => {
            return error.UnsupportedFormat;
        },
    }

    return bytes;
}

fn skribiTiponAlDosiero(allocator: all.Allocator, comptime T: type, value: *T, path: []const u8, t_formato: TekstaFormato) !void {
    const teksto = try skribiTiponAlTeksto(allocator, T, value, t_formato);
    defer allocator.free(teksto);

    var dosiero = try std.fs.cwd().createFile(path, .{ .truncate = true });
    defer dosiero.close();
    try dosiero.writeAll(teksto);
}

//////////////////////////////////////////////
//// Legi Tipon El Teksto
//////////////////////////////////////////////

pub fn legiTiponElTeksto(allocator: all.Allocator, comptime T: type, input: []const u8, t_formato: TekstaFormato) !T {
    var parsed: T = undefined;
    switch (t_formato) {
        .TF_ZIG_ZON => {
            parsed = zon.parse.fromSlice(T, allocator, @ptrCast(input), null, .{}) catch |err| {
                std.debug.print("eraro dun deseriigo: {}\n", .{err});
                return err;
            };
        },
        .TF_JSON => {
            parsed = std.json.parseFromSliceLeaky(T, allocator, input, .{ .ignore_unknown_fields = false, .allocate = .alloc_always }) catch |err| {
                std.debug.print("eraro dun deseriigo: {}\n", .{err});
                return err;
            };
        },
        .TF_PROTOBUF => {
            var it: TokenIterType = std.mem.tokenizeAny(u8, input, ":\", \n\r\t");
            parsed = T.legiElProtobufTeksto(allocator, &it) catch |err| {
                std.debug.print("eraro dun deseriigo: {}\n", .{err});
                return err;
            };
            _=it.peek();
        },
        else => {
            return error.UnsupportedFormat;
        },
    }

    return parsed;
}

pub fn legiTiponElDosiero(allocator: all.Allocator, comptime T: type, path: []const u8, t_formato: TekstaFormato) !T {
    var dosiero = try std.fs.cwd().openFile(path, .{});
    defer dosiero.close();

    const dosiera_long = try dosiero.getEndPos();
    var enhavo = allocator.alloc(u8, dosiera_long + 1) catch return error.OutOfMemory;
    defer allocator.free(enhavo);

    _ = try dosiero.readAll(enhavo[0..dosiera_long]);
    enhavo[dosiera_long] = 0;

    return legiTiponElTeksto(allocator, T, enhavo[0..dosiera_long :0], t_formato);
}
