const std = @import("std");
const dbg = std.debug;
const all = std.mem;
const equal = std.mem.eql;
const  io = std.Io;

const encdec = @import("encdec.zig");
const EncodeBuffer = encdec.EncodeBuffer;
const DecodeBuffer = encdec.DecodeBuffer;

const TokenIterType = std.mem.TokenIterator(u8, .any);
const AppCfg = @import("AppCfg.zig");

pub const ProtocolBus = struct {

    pub const Transports = struct {

        pub const CentralServer = struct {


pub const XMPPDefConfig = struct {
    SendingUser: []const u8,
    SendingPssw: []const u8,
    TopicUser: []const u8,
    TopicPssw: []const u8,
    Server: ?[]const u8 = "gmail.com" ,
    ConnectServer: ?[]const u8 = "talk.google.com" ,
    Proxy: ?ProxyDefConfig = null,

    pub fn initDefault(allocator: all.Allocator) !XMPPDefConfig {
        return XMPPDefConfig {
            .SendingUser = try allocator.dupe(u8, ""),
            .SendingPssw = try allocator.dupe(u8, ""),
            .TopicUser = try allocator.dupe(u8, ""),
            .TopicPssw = try allocator.dupe(u8, ""),
            .Server = try allocator.dupe(u8, "gmail.com"),
            .ConnectServer = try allocator.dupe(u8, "talk.google.com"),
            .Proxy = null,
        };
    }

    pub fn deinit(self: *const XMPPDefConfig, allocator: all.Allocator) void {
        allocator.free(self.SendingUser);
        allocator.free(self.SendingPssw);
        allocator.free(self.TopicUser);
        allocator.free(self.TopicPssw);
        if( self.Server ) |f| {
            allocator.free(f);
        }
        if( self.ConnectServer ) |f| {
            allocator.free(f);
        }
        if (self.Proxy) |item| {
            item.deinit(allocator);
        }
    }

    pub fn skribiAlTeksto(self: *XMPPDefConfig, allocator: all.Allocator, t_formato: TekstaFormato) ![]const u8 {
        return try skribiTiponAlTeksto(allocator, XMPPDefConfig, @as(*XMPPDefConfig, self), t_formato);
    }

    pub fn skribiAlDosiero(self: *XMPPDefConfig, allocator: all.Allocator, path: []const u8, t_formato: TekstaFormato) !void {
        try skribiTiponAlDosiero(allocator, XMPPDefConfig, @as(*XMPPDefConfig, self), path, t_formato);
    }

    pub fn legiElTeksto(allocator: all.Allocator, input: []const u8, t_formato: TekstaFormato) !XMPPDefConfig {
        return try legiTiponElTeksto(allocator, XMPPDefConfig, input, t_formato);
    }

    pub fn legiElDosiero(allocator: all.Allocator, path: []const u8, t_formato: TekstaFormato) !XMPPDefConfig {
        return try legiTiponElDosiero(allocator, XMPPDefConfig, path, t_formato);
    }

    fn skribiAlProtobufTeksto(self: *const XMPPDefConfig, allocator: all.Allocator,ind: []const u8) ![]const u8 {
        var bufro:std.ArrayList(u8)= .empty;

        try bufro.print(allocator,"{s}SendingUser: \"{s}\"\n",.{ind, self.SendingUser });
        try bufro.print(allocator,"{s}SendingPssw: \"{s}\"\n",.{ind, self.SendingPssw });
        try bufro.print(allocator,"{s}TopicUser: \"{s}\"\n",.{ind, self.TopicUser });
        try bufro.print(allocator,"{s}TopicPssw: \"{s}\"\n",.{ind, self.TopicPssw });
        if( self.Server ) |val|  
            try bufro.print(allocator,"{s}Server: \"{s}\"\n",.{ ind, val });
        if( self.ConnectServer ) |val|  
            try bufro.print(allocator,"{s}ConnectServer: \"{s}\"\n",.{ ind, val });
        if( self.Proxy ) |val|  {
            const indent = std.mem.concatWithSentinel(allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
            defer allocator.free(indent);
            const Proxy_text = try val.skribiAlProtobufTeksto(allocator, indent);
            defer allocator.free(Proxy_text);

            try bufro.print(allocator, "{s}Proxy {{\n{s}{s}}}\n", .{ ind, Proxy_text, ind });
        }

        return bufro.toOwnedSlice(allocator);
    }

    fn legiElProtobufTeksto(allocator: all.Allocator, it: *TokenIterType) !XMPPDefConfig {
        var mia_Mesagho= try XMPPDefConfig.initDefault(allocator); 


        while (it.next()) |tok| {
            if( equal(u8, tok, "}" ) ) break;
            const val = it.next() orelse return error.InvalidFormat;

            if( equal(u8, tok, "SendingUser" ) ) { 
                mia_Mesagho.SendingUser =  allocator.dupe(u8, val) catch "";
                continue;
            }
            if( equal(u8, tok, "SendingPssw" ) ) { 
                mia_Mesagho.SendingPssw =  allocator.dupe(u8, val) catch "";
                continue;
            }
            if( equal(u8, tok, "TopicUser" ) ) { 
                mia_Mesagho.TopicUser =  allocator.dupe(u8, val) catch "";
                continue;
            }
            if( equal(u8, tok, "TopicPssw" ) ) { 
                mia_Mesagho.TopicPssw =  allocator.dupe(u8, val) catch "";
                continue;
            }
            if( equal(u8, tok, "Server" ) ) { 
                mia_Mesagho.Server =  allocator.dupe(u8, val) catch "";
                continue;
            }
            if( equal(u8, tok, "ConnectServer" ) ) { 
                mia_Mesagho.ConnectServer =  allocator.dupe(u8, val) catch "";
                continue;
            }
            if( equal(u8, tok, "Proxy" ) ) { 
                const sub_msg = try ProxyDefConfig.legiElProtobufTeksto(allocator, it); 
                mia_Mesagho.Proxy = sub_msg; 
                continue;
            }
        }

        return mia_Mesagho;
    }

    pub fn seriigiAlBin(self: *const XMPPDefConfig, allocator: all.Allocator, b_formato: BinaraFormato) ![]const u8 {
        return try seriigiTiponAlBin(allocator, XMPPDefConfig, self, b_formato);
    }

    pub fn seriigiAlDosiero(self: *const XMPPDefConfig, allocator: all.Allocator, path: []const u8, b_formato: BinaraFormato) !void {
        return try seriigiTiponAlDosiero(allocator, XMPPDefConfig, @as(*XMPPDefConfig, self), path, b_formato);
    }

    fn seriigi(self: *const XMPPDefConfig, allocator: all.Allocator, buffer: *EncodeBuffer) !usize {
 
        var tuta_longo: usize = 0;
 
    if ( self.Proxy ) |val| {
        const st_longa = try val.seriigi( allocator, buffer );
        tuta_longo += st_longa;
        tuta_longo += try buffer.encodeVarint(st_longa);
        tuta_longo += try buffer.encodeVarint(58);
    }  //3  opt - no def - varlong

    if ( self.ConnectServer ) |val| {
        if ( ! equal(u8, val, "talk.google.com") ) {
            const st_longa = try buffer.encodeString( val );
            tuta_longo += st_longa;
            tuta_longo += try buffer.encodeVarint(st_longa);
            tuta_longo += try buffer.encodeVarint(50);
        }  
    }  //4  opt - def - varlong

    if ( self.Server ) |val| {
        if ( ! equal(u8, val, "gmail.com") ) {
            const st_longa = try buffer.encodeString( val );
            tuta_longo += st_longa;
            tuta_longo += try buffer.encodeVarint(st_longa);
            tuta_longo += try buffer.encodeVarint(42);
        }  
    }  //4  opt - def - varlong

        const TopicPssw_longa = try buffer.encodeString( self.TopicPssw );
        tuta_longo += TopicPssw_longa;
        tuta_longo += try buffer.encodeVarint(TopicPssw_longa);
        tuta_longo += try buffer.encodeVarint(34);
        //7  req - no def - varlong

        const TopicUser_longa = try buffer.encodeString( self.TopicUser );
        tuta_longo += TopicUser_longa;
        tuta_longo += try buffer.encodeVarint(TopicUser_longa);
        tuta_longo += try buffer.encodeVarint(26);
        //7  req - no def - varlong

        const SendingPssw_longa = try buffer.encodeString( self.SendingPssw );
        tuta_longo += SendingPssw_longa;
        tuta_longo += try buffer.encodeVarint(SendingPssw_longa);
        tuta_longo += try buffer.encodeVarint(18);
        //7  req - no def - varlong

        const SendingUser_longa = try buffer.encodeString( self.SendingUser );
        tuta_longo += SendingUser_longa;
        tuta_longo += try buffer.encodeVarint(SendingUser_longa);
        tuta_longo += try buffer.encodeVarint(10);
        //7  req - no def - varlong

        return tuta_longo;
    }

    pub fn deseriigiElBin(allocator: all.Allocator,input: []const u8, b_formato: BinaraFormato) !XMPPDefConfig {
        return try deseriigiTiponElBin(allocator, XMPPDefConfig, input, b_formato);
    }

    pub fn deseriigiElDosiero(allocator: all.Allocator, path: [:0]const u8, b_formato: BinaraFormato) !XMPPDefConfig {
        return try deseriigiTiponElDosiero(allocator, XMPPDefConfig, path, b_formato);
    }

    fn deseriigi(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !XMPPDefConfig {
        var mia_Mesagho= try XMPPDefConfig.initDefault(allocator);

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
                mia_Mesagho.SendingUser = try buffer.decodeString(  try buffer.decodeVarint() )
            else if ( field_number == 2 and wire_type == 2 ) 
                mia_Mesagho.SendingPssw = try buffer.decodeString(  try buffer.decodeVarint() )
            else if ( field_number == 3 and wire_type == 2 ) 
                mia_Mesagho.TopicUser = try buffer.decodeString(  try buffer.decodeVarint() )
            else if ( field_number == 4 and wire_type == 2 ) 
                mia_Mesagho.TopicPssw = try buffer.decodeString(  try buffer.decodeVarint() )
            else if ( field_number == 5 and wire_type == 2 ) 
                mia_Mesagho.Server = try buffer.decodeString(  try buffer.decodeVarint() )
            else if ( field_number == 6 and wire_type == 2 ) 
                mia_Mesagho.ConnectServer = try buffer.decodeString(  try buffer.decodeVarint() )
            else if ( field_number == 7 and wire_type == 2 ) 
                mia_Mesagho.Proxy = try ProxyDefConfig.deseriigi(allocator, buffer, try buffer.decodeVarint() );
        }


        return mia_Mesagho;
    }
};    // XMPPDefConfig

pub const K6ServerDefConfig = struct {
    K6Server: EndPointDef.ProtocolBus.Config.EndPointDef,
    Service: []const u8,
    Password: []const u8,
    Proxy: ?ProxyDefConfig = null,

    pub fn initDefault(allocator: all.Allocator) !K6ServerDefConfig {
        return K6ServerDefConfig {
            .K6Server = try EndPointDef.ProtocolBus.Config.EndPointDef.initDefault(allocator),
            .Service = try allocator.dupe(u8, ""),
            .Password = try allocator.dupe(u8, ""),
            .Proxy = null,
        };
    }

    pub fn deinit(self: *const K6ServerDefConfig, allocator: all.Allocator) void {
        self.K6Server.deinit(allocator);
        allocator.free(self.Service);
        allocator.free(self.Password);
        if (self.Proxy) |item| {
            item.deinit(allocator);
        }
    }

    pub fn skribiAlTeksto(self: *K6ServerDefConfig, allocator: all.Allocator, t_formato: TekstaFormato) ![]const u8 {
        return try skribiTiponAlTeksto(allocator, K6ServerDefConfig, @as(*K6ServerDefConfig, self), t_formato);
    }

    pub fn skribiAlDosiero(self: *K6ServerDefConfig, allocator: all.Allocator, path: []const u8, t_formato: TekstaFormato) !void {
        try skribiTiponAlDosiero(allocator, K6ServerDefConfig, @as(*K6ServerDefConfig, self), path, t_formato);
    }

    pub fn legiElTeksto(allocator: all.Allocator, input: []const u8, t_formato: TekstaFormato) !K6ServerDefConfig {
        return try legiTiponElTeksto(allocator, K6ServerDefConfig, input, t_formato);
    }

    pub fn legiElDosiero(allocator: all.Allocator, path: []const u8, t_formato: TekstaFormato) !K6ServerDefConfig {
        return try legiTiponElDosiero(allocator, K6ServerDefConfig, path, t_formato);
    }

    fn skribiAlProtobufTeksto(self: *const K6ServerDefConfig, allocator: all.Allocator,ind: []const u8) ![]const u8 {
        var bufro:std.ArrayList(u8)= .empty;

        var K6Server_item = self.K6Server;
        const K6Server_text = try K6Server_item.skribiAlTeksto(allocator, .TF_PROTOBUF);
        defer allocator.free(K6Server_text);
        try bufro.print(allocator, "{s}K6Server {{\n{s}{s}}}\n", .{ ind, K6Server_text, ind });
        try bufro.print(allocator,"{s}Service: \"{s}\"\n",.{ind, self.Service });
        try bufro.print(allocator,"{s}Password: \"{s}\"\n",.{ind, self.Password });
        if( self.Proxy ) |val|  {
            const indent = std.mem.concatWithSentinel(allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
            defer allocator.free(indent);
            const Proxy_text = try val.skribiAlProtobufTeksto(allocator, indent);
            defer allocator.free(Proxy_text);

            try bufro.print(allocator, "{s}Proxy {{\n{s}{s}}}\n", .{ ind, Proxy_text, ind });
        }

        return bufro.toOwnedSlice(allocator);
    }

    fn legiElProtobufTeksto(allocator: all.Allocator, it: *TokenIterType) !K6ServerDefConfig {
        var mia_Mesagho= try K6ServerDefConfig.initDefault(allocator); 


        while (it.next()) |tok| {
            if( equal(u8, tok, "}" ) ) break;
            const val = it.next() orelse return error.InvalidFormat;

            if( equal(u8, tok, "K6Server" ) ) { 
                const sub_text = try legiSubProtobufTeksto(allocator, it);
                const sub_msg = try EndPointDef.ProtocolBus.Config.EndPointDef.legiElTeksto(allocator, sub_text, .TF_PROTOBUF);
                mia_Mesagho.K6Server = sub_msg; 
                continue;
            }
            if( equal(u8, tok, "Service" ) ) { 
                mia_Mesagho.Service =  allocator.dupe(u8, val) catch "";
                continue;
            }
            if( equal(u8, tok, "Password" ) ) { 
                mia_Mesagho.Password =  allocator.dupe(u8, val) catch "";
                continue;
            }
            if( equal(u8, tok, "Proxy" ) ) { 
                const sub_msg = try ProxyDefConfig.legiElProtobufTeksto(allocator, it); 
                mia_Mesagho.Proxy = sub_msg; 
                continue;
            }
        }

        return mia_Mesagho;
    }

    pub fn seriigiAlBin(self: *const K6ServerDefConfig, allocator: all.Allocator, b_formato: BinaraFormato) ![]const u8 {
        return try seriigiTiponAlBin(allocator, K6ServerDefConfig, self, b_formato);
    }

    pub fn seriigiAlDosiero(self: *const K6ServerDefConfig, allocator: all.Allocator, path: []const u8, b_formato: BinaraFormato) !void {
        return try seriigiTiponAlDosiero(allocator, K6ServerDefConfig, @as(*K6ServerDefConfig, self), path, b_formato);
    }

    fn seriigi(self: *const K6ServerDefConfig, allocator: all.Allocator, buffer: *EncodeBuffer) !usize {
 
        var tuta_longo: usize = 0;
 
    if ( self.Proxy ) |val| {
        const st_longa = try val.seriigi( allocator, buffer );
        tuta_longo += st_longa;
        tuta_longo += try buffer.encodeVarint(st_longa);
        tuta_longo += try buffer.encodeVarint(34);
    }  //3  opt - no def - varlong

        const Password_longa = try buffer.encodeString( self.Password );
        tuta_longo += Password_longa;
        tuta_longo += try buffer.encodeVarint(Password_longa);
        tuta_longo += try buffer.encodeVarint(26);
        //7  req - no def - varlong

        const Service_longa = try buffer.encodeString( self.Service );
        tuta_longo += Service_longa;
        tuta_longo += try buffer.encodeVarint(Service_longa);
        tuta_longo += try buffer.encodeVarint(18);
        //7  req - no def - varlong

        const K6Server_longa = try self.K6Server.seriigi( allocator, buffer );
        tuta_longo += K6Server_longa;
        tuta_longo += try buffer.encodeVarint(K6Server_longa);
        tuta_longo += try buffer.encodeVarint(10);
        //7  req - no def - varlong

        return tuta_longo;
    }

    pub fn deseriigiElBin(allocator: all.Allocator,input: []const u8, b_formato: BinaraFormato) !K6ServerDefConfig {
        return try deseriigiTiponElBin(allocator, K6ServerDefConfig, input, b_formato);
    }

    pub fn deseriigiElDosiero(allocator: all.Allocator, path: [:0]const u8, b_formato: BinaraFormato) !K6ServerDefConfig {
        return try deseriigiTiponElDosiero(allocator, K6ServerDefConfig, path, b_formato);
    }

    fn deseriigi(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !K6ServerDefConfig {
        var mia_Mesagho= try K6ServerDefConfig.initDefault(allocator);

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
                const raw = try buffer.decodeBytes(try buffer.decodeVarint());
                defer allocator.free(raw);
    
                mia_Mesagho.K6Server =
                    try EndPointDef.ProtocolBus.Config.EndPointDef.deseriigiElBin(
                        allocator,
                        raw,
                        .BF_PROTOBUF,
                    );
            }
            else if ( field_number == 2 and wire_type == 2 ) 
                mia_Mesagho.Service = try buffer.decodeString(  try buffer.decodeVarint() )
            else if ( field_number == 3 and wire_type == 2 ) 
                mia_Mesagho.Password = try buffer.decodeString(  try buffer.decodeVarint() )
            else if ( field_number == 4 and wire_type == 2 ) 
                mia_Mesagho.Proxy = try ProxyDefConfig.deseriigi(allocator, buffer, try buffer.decodeVarint() );
        }


        return mia_Mesagho;
    }
};    // K6ServerDefConfig

pub const ProxyDefConfig = struct {
    Server: EndPointDef.ProtocolBus.Config.EndPointDef,
    User: ?[]const u8 = null,
    Password: ?[]const u8 = null,

    pub fn initDefault(allocator: all.Allocator) !ProxyDefConfig {
        return ProxyDefConfig {
            .Server = try EndPointDef.ProtocolBus.Config.EndPointDef.initDefault(allocator),
            .User = null,
            .Password = null,
        };
    }

    pub fn deinit(self: *const ProxyDefConfig, allocator: all.Allocator) void {
        self.Server.deinit(allocator);
        if( self.User ) |f| {
            allocator.free(f);
        }
        if( self.Password ) |f| {
            allocator.free(f);
        }
    }

    pub fn skribiAlTeksto(self: *ProxyDefConfig, allocator: all.Allocator, t_formato: TekstaFormato) ![]const u8 {
        return try skribiTiponAlTeksto(allocator, ProxyDefConfig, @as(*ProxyDefConfig, self), t_formato);
    }

    pub fn skribiAlDosiero(self: *ProxyDefConfig, allocator: all.Allocator, path: []const u8, t_formato: TekstaFormato) !void {
        try skribiTiponAlDosiero(allocator, ProxyDefConfig, @as(*ProxyDefConfig, self), path, t_formato);
    }

    pub fn legiElTeksto(allocator: all.Allocator, input: []const u8, t_formato: TekstaFormato) !ProxyDefConfig {
        return try legiTiponElTeksto(allocator, ProxyDefConfig, input, t_formato);
    }

    pub fn legiElDosiero(allocator: all.Allocator, path: []const u8, t_formato: TekstaFormato) !ProxyDefConfig {
        return try legiTiponElDosiero(allocator, ProxyDefConfig, path, t_formato);
    }

    fn skribiAlProtobufTeksto(self: *const ProxyDefConfig, allocator: all.Allocator,ind: []const u8) ![]const u8 {
        var bufro:std.ArrayList(u8)= .empty;

        var Server_item = self.Server;
        const Server_text = try Server_item.skribiAlTeksto(allocator, .TF_PROTOBUF);
        defer allocator.free(Server_text);
        try bufro.print(allocator, "{s}Server {{\n{s}{s}}}\n", .{ ind, Server_text, ind });
        if( self.User ) |val|  
            try bufro.print(allocator,"{s}User: \"{s}\"\n",.{ ind, val });
        if( self.Password ) |val|  
            try bufro.print(allocator,"{s}Password: \"{s}\"\n",.{ ind, val });

        return bufro.toOwnedSlice(allocator);
    }

    fn legiElProtobufTeksto(allocator: all.Allocator, it: *TokenIterType) !ProxyDefConfig {
        var mia_Mesagho= try ProxyDefConfig.initDefault(allocator); 


        while (it.next()) |tok| {
            if( equal(u8, tok, "}" ) ) break;
            const val = it.next() orelse return error.InvalidFormat;

            if( equal(u8, tok, "Server" ) ) { 
                const sub_text = try legiSubProtobufTeksto(allocator, it);
                const sub_msg = try EndPointDef.ProtocolBus.Config.EndPointDef.legiElTeksto(allocator, sub_text, .TF_PROTOBUF);
                mia_Mesagho.Server = sub_msg; 
                continue;
            }
            if( equal(u8, tok, "User" ) ) { 
                mia_Mesagho.User =  allocator.dupe(u8, val) catch "";
                continue;
            }
            if( equal(u8, tok, "Password" ) ) { 
                mia_Mesagho.Password =  allocator.dupe(u8, val) catch "";
                continue;
            }
        }

        return mia_Mesagho;
    }

    pub fn seriigiAlBin(self: *const ProxyDefConfig, allocator: all.Allocator, b_formato: BinaraFormato) ![]const u8 {
        return try seriigiTiponAlBin(allocator, ProxyDefConfig, self, b_formato);
    }

    pub fn seriigiAlDosiero(self: *const ProxyDefConfig, allocator: all.Allocator, path: []const u8, b_formato: BinaraFormato) !void {
        return try seriigiTiponAlDosiero(allocator, ProxyDefConfig, @as(*ProxyDefConfig, self), path, b_formato);
    }

    fn seriigi(self: *const ProxyDefConfig, allocator: all.Allocator, buffer: *EncodeBuffer) !usize {
 
        var tuta_longo: usize = 0;
 
    if ( self.Password ) |val| {
        const st_longa = try buffer.encodeString( val );
        tuta_longo += st_longa;
        tuta_longo += try buffer.encodeVarint(st_longa);
        tuta_longo += try buffer.encodeVarint(26);
    }  //3  opt - no def - varlong

    if ( self.User ) |val| {
        const st_longa = try buffer.encodeString( val );
        tuta_longo += st_longa;
        tuta_longo += try buffer.encodeVarint(st_longa);
        tuta_longo += try buffer.encodeVarint(18);
    }  //3  opt - no def - varlong

        const Server_longa = try self.Server.seriigi( allocator, buffer );
        tuta_longo += Server_longa;
        tuta_longo += try buffer.encodeVarint(Server_longa);
        tuta_longo += try buffer.encodeVarint(10);
        //7  req - no def - varlong

        return tuta_longo;
    }

    pub fn deseriigiElBin(allocator: all.Allocator,input: []const u8, b_formato: BinaraFormato) !ProxyDefConfig {
        return try deseriigiTiponElBin(allocator, ProxyDefConfig, input, b_formato);
    }

    pub fn deseriigiElDosiero(allocator: all.Allocator, path: [:0]const u8, b_formato: BinaraFormato) !ProxyDefConfig {
        return try deseriigiTiponElDosiero(allocator, ProxyDefConfig, path, b_formato);
    }

    fn deseriigi(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !ProxyDefConfig {
        var mia_Mesagho= try ProxyDefConfig.initDefault(allocator);

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
                const raw = try buffer.decodeBytes(try buffer.decodeVarint());
                defer allocator.free(raw);
    
                mia_Mesagho.Server =
                    try EndPointDef.ProtocolBus.Config.EndPointDef.deseriigiElBin(
                        allocator,
                        raw,
                        .BF_PROTOBUF,
                    );
            }
            else if ( field_number == 2 and wire_type == 2 ) 
                mia_Mesagho.User = try buffer.decodeString(  try buffer.decodeVarint() )
            else if ( field_number == 3 and wire_type == 2 ) 
                mia_Mesagho.Password = try buffer.decodeString(  try buffer.decodeVarint() );
        }


        return mia_Mesagho;
    }
};    // ProxyDefConfig

        };   // CentralServer
    };   // Transports
};   // ProtocolBus

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
