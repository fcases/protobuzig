const std = @import("std");
const dbg = std.debug;
const all = std.mem;
const equal = std.mem.eql;
const  io = std.Io;

const encdec = @import("encdec.zig");
const EncodeBuffer = encdec.EncodeBuffer;
const DecodeBuffer = encdec.DecodeBuffer;

const TokenIterType = std.mem.TokenIterator(u8, .any);

pub const geo = struct {


pub const Estacion = struct {
    nombre: []const u8,
    id: ?u32 = null,

    pub fn initDefault(allocator: all.Allocator) !Estacion {
        return Estacion {
            .nombre = try allocator.dupe(u8, ""),
            .id = null,
        };
    }

    pub fn deinit(self: *const Estacion, allocator: all.Allocator) void {
        allocator.free(self.nombre);
    }

    pub fn setNombre(
        self: *Estacion,
        allocator: all.Allocator,
        value: []const u8,
    ) !void {
        allocator.free(self.nombre);
        self.nombre = try allocator.dupe(u8, value);
    }

    pub fn skribiAlTeksto(self: *Estacion, allocator: all.Allocator, t_formato: TekstaFormato) ![]const u8 {
        return try skribiTiponAlTeksto(allocator, Estacion, @as(*Estacion, self), t_formato);
    }

    pub fn skribiAlDosiero(self: *Estacion, allocator: all.Allocator, path: []const u8, t_formato: TekstaFormato) !void {
        try skribiTiponAlDosiero(allocator, Estacion, @as(*Estacion, self), path, t_formato);
    }

    pub fn legiElTeksto(allocator: all.Allocator, input: []const u8, t_formato: TekstaFormato) !Estacion {
        return try legiTiponElTeksto(allocator, Estacion, input, t_formato);
    }

    pub fn legiElDosiero(allocator: all.Allocator, path: []const u8, t_formato: TekstaFormato) !Estacion {
        return try legiTiponElDosiero(allocator, Estacion, path, t_formato);
    }

    fn skribiAlProtobufTeksto(self: *const Estacion, allocator: all.Allocator,ind: []const u8) ![]const u8 {
        var bufro:std.ArrayList(u8)= .empty;

        try bufro.print(allocator,"{s}nombre: \"{s}\"\n",.{ind, self.nombre });
        if( self.id ) |val|  
            try bufro.print(allocator,"{s}id: {any}\n",.{ ind, val });

        return bufro.toOwnedSlice(allocator);
    }

    fn legiElProtobufTeksto(allocator: all.Allocator, it: *TokenIterType) !Estacion {
        var mia_Mesagho = try Estacion.initDefault(allocator);
        errdefer mia_Mesagho.deinit(allocator);


        while (it.next()) |tok| {
            if( equal(u8, tok, "}" ) ) break;
            const val = it.next() orelse return error.InvalidFormat;

            if( equal(u8, tok, "nombre" ) ) { 
                allocator.free(mia_Mesagho.nombre);
                mia_Mesagho.nombre = try allocator.dupe(u8, val);
                continue;
            }
            if( equal(u8, tok, "id" ) ) { 
                mia_Mesagho.id =  std.fmt.parseInt(u32,val,10) catch 0;
                continue;
            }
        }

        return mia_Mesagho;
    }

    pub fn seriigiAlBin(self: *const Estacion, allocator: all.Allocator, b_formato: BinaraFormato) ![]const u8 {
        return try seriigiTiponAlBin(allocator, Estacion, self, b_formato);
    }

    pub fn seriigiAlDosiero(self: *const Estacion, allocator: all.Allocator, path: []const u8, b_formato: BinaraFormato) !void {
        return try seriigiTiponAlDosiero(allocator, Estacion, @as(*Estacion, self), path, b_formato);
    }

    fn seriigi(self: *const Estacion, allocator: all.Allocator, buffer: *EncodeBuffer) !usize {
 
        _ = allocator;
        var tuta_longo: usize = 0;
 
        if( self.id ) |val| {
            tuta_longo += try buffer.encodeUint32( val );
            tuta_longo += try buffer.encodeVarint(16);
        }   //1 opt - no def - no varlong

        const nombre_longa = try buffer.encodeString( self.nombre );
        tuta_longo += nombre_longa;
        tuta_longo += try buffer.encodeVarint(nombre_longa);
        tuta_longo += try buffer.encodeVarint(10);
        //7  req - no def - varlong

        return tuta_longo;
    }

    pub fn deseriigiElBin(allocator: all.Allocator,input: []const u8, b_formato: BinaraFormato) !Estacion {
        return try deseriigiTiponElBin(allocator, Estacion, input, b_formato);
    }

    pub fn deseriigiElDosiero(allocator: all.Allocator, path: [:0]const u8, b_formato: BinaraFormato) !Estacion {
        return try deseriigiTiponElDosiero(allocator, Estacion, path, b_formato);
    }

    fn deseriigi(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !Estacion {
        var mia_Mesagho = try Estacion.initDefault(allocator);
        errdefer mia_Mesagho.deinit(allocator);

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
            {
                const tmp_nombre = try buffer.decodeString(  try buffer.decodeVarint() );
                allocator.free(mia_Mesagho.nombre);
                mia_Mesagho.nombre = tmp_nombre;
            }
            else if ( field_number == 2 and wire_type == 0 ) 
                mia_Mesagho.id = try buffer.decodeUint32();
        }


        return mia_Mesagho;
    }
};    // Estacion

pub const Ciudad = struct {
    nombre: ?[]const u8 = null,
    estaciones: []Estacion,

    pub fn initDefault(allocator: all.Allocator) !Ciudad {
        return Ciudad {
            .nombre = null,
            .estaciones = try allocator.alloc(Estacion, 0),
        };
    }

    pub fn deinit(self: *const Ciudad, allocator: all.Allocator) void {
        if( self.nombre ) |f| {
            allocator.free(f);
        }
        for (self.estaciones) |item| {
            item.deinit(allocator);
        }
        allocator.free(self.estaciones);
    }

    pub fn skribiAlTeksto(self: *Ciudad, allocator: all.Allocator, t_formato: TekstaFormato) ![]const u8 {
        return try skribiTiponAlTeksto(allocator, Ciudad, @as(*Ciudad, self), t_formato);
    }

    pub fn skribiAlDosiero(self: *Ciudad, allocator: all.Allocator, path: []const u8, t_formato: TekstaFormato) !void {
        try skribiTiponAlDosiero(allocator, Ciudad, @as(*Ciudad, self), path, t_formato);
    }

    pub fn legiElTeksto(allocator: all.Allocator, input: []const u8, t_formato: TekstaFormato) !Ciudad {
        return try legiTiponElTeksto(allocator, Ciudad, input, t_formato);
    }

    pub fn legiElDosiero(allocator: all.Allocator, path: []const u8, t_formato: TekstaFormato) !Ciudad {
        return try legiTiponElDosiero(allocator, Ciudad, path, t_formato);
    }

    fn skribiAlProtobufTeksto(self: *const Ciudad, allocator: all.Allocator,ind: []const u8) ![]const u8 {
        var bufro:std.ArrayList(u8)= .empty;

        if( self.nombre ) |val|  
            try bufro.print(allocator,"{s}nombre: \"{s}\"\n",.{ ind, val });
        for(self.estaciones) |obj| {
            const indent = std.mem.concatWithSentinel(allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
            defer allocator.free(indent);
            const estaciones_text = try obj.skribiAlProtobufTeksto(allocator, indent);
            defer allocator.free(estaciones_text);

            try bufro.print(allocator, "{s}estaciones {{\n{s}{s}}}\n", .{ ind, estaciones_text, ind });
        }

        return bufro.toOwnedSlice(allocator);
    }

    fn legiElProtobufTeksto(allocator: all.Allocator, it: *TokenIterType) !Ciudad {
        var mia_Mesagho = try Ciudad.initDefault(allocator);
        errdefer mia_Mesagho.deinit(allocator);

        var estaciones_list: std.ArrayList(Estacion) = .empty; 
        while (it.next()) |tok| {
            if( equal(u8, tok, "}" ) ) break;
            const val = it.next() orelse return error.InvalidFormat;

            if( equal(u8, tok, "nombre" ) ) { 
                if (mia_Mesagho.nombre) |old| {
                    allocator.free(old);
                }
                mia_Mesagho.nombre = try allocator.dupe(u8, val);
                continue;
            }
            if( equal(u8, tok, "estaciones" ) ) { 
                const sub_msg = try Estacion.legiElProtobufTeksto(allocator, it); 
                try estaciones_list.append(allocator, sub_msg); 
                continue;
            }
        }
        for (mia_Mesagho.estaciones) |item| {
            item.deinit(allocator);
        }
        allocator.free(mia_Mesagho.estaciones);
        mia_Mesagho.estaciones = try estaciones_list.toOwnedSlice(allocator); 

        return mia_Mesagho;
    }

    pub fn seriigiAlBin(self: *const Ciudad, allocator: all.Allocator, b_formato: BinaraFormato) ![]const u8 {
        return try seriigiTiponAlBin(allocator, Ciudad, self, b_formato);
    }

    pub fn seriigiAlDosiero(self: *const Ciudad, allocator: all.Allocator, path: []const u8, b_formato: BinaraFormato) !void {
        return try seriigiTiponAlDosiero(allocator, Ciudad, @as(*Ciudad, self), path, b_formato);
    }

    fn seriigi(self: *const Ciudad, allocator: all.Allocator, buffer: *EncodeBuffer) !usize {
 
        var tuta_longo: usize = 0;
 
    for (self.estaciones) |item| {
        const estaciones_longa = try item.seriigi( allocator, buffer );
        tuta_longo += estaciones_longa;
        tuta_longo += try buffer.encodeVarint(estaciones_longa);
        tuta_longo += try buffer.encodeVarint(18);
    }  // 11  rept - no def - varlong 

    if ( self.nombre ) |val| {
        const st_longa = try buffer.encodeString( val );
        tuta_longo += st_longa;
        tuta_longo += try buffer.encodeVarint(st_longa);
        tuta_longo += try buffer.encodeVarint(10);
    }  //3  opt - no def - varlong

        return tuta_longo;
    }

    pub fn deseriigiElBin(allocator: all.Allocator,input: []const u8, b_formato: BinaraFormato) !Ciudad {
        return try deseriigiTiponElBin(allocator, Ciudad, input, b_formato);
    }

    pub fn deseriigiElDosiero(allocator: all.Allocator, path: [:0]const u8, b_formato: BinaraFormato) !Ciudad {
        return try deseriigiTiponElDosiero(allocator, Ciudad, path, b_formato);
    }

    fn deseriigi(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !Ciudad {
        var mia_Mesagho = try Ciudad.initDefault(allocator);
        errdefer mia_Mesagho.deinit(allocator);

        var end: usize = undefined;
        if (data_length) |val|
            end = buffer.read_index + val
        else
            end = buffer.buffer.len;

        var estaciones_list: std.ArrayList(Estacion) = .empty; 

        while (buffer.read_index < end) {
            const key: u64 = buffer.decodeVarint() catch 0 ;    
            const wire_type = key & 0x7;  
            const field_number = key >> 3;

            if ( field_number == 1 and wire_type == 2 ) 
            {
                const tmp_nombre = try buffer.decodeString(  try buffer.decodeVarint() );
                if (mia_Mesagho.nombre) |old| {
                    allocator.free(old);
                }
                mia_Mesagho.nombre = tmp_nombre;
            }
            else if ( field_number == 2 and wire_type == 2 ) 
                { try estaciones_list.append( allocator, try Estacion.deseriigi(allocator, buffer, try buffer.decodeVarint() ) ); }
        }

        const tmp_estaciones = try estaciones_list.toOwnedSlice(allocator);
        for (mia_Mesagho.estaciones) |*item| {
            item.deinit(allocator);
        }
        allocator.free(mia_Mesagho.estaciones);
        mia_Mesagho.estaciones = tmp_estaciones;

        return mia_Mesagho;
    }
};    // Ciudad

};   // geo

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
            const zon_input = try allocator.dupeZ(u8, input);
            defer allocator.free(zon_input);
            parsed = zon.parse.fromSlice(T, allocator, zon_input, null, .{}) catch |err| {
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
