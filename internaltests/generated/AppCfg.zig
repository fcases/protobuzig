const std = @import("std");
const dbg = std.debug;
const all = std.mem;
const equal = std.mem.eql;
const  io = std.Io;

const encdec = @import("encdec.zig");
const EncodeBuffer = encdec.EncodeBuffer;
const DecodeBuffer = encdec.DecodeBuffer;

//const TokenIterType = std.mem.TokenIterator(u8, .any);
const TokenIterType = CustomTokenizer;

pub const ProtocolBus = struct {

    pub const Config = struct {


pub const AppConfig = struct {
    ActivateTrace: ?bool = false ,
    TraceLevel: ?i32 = 0 ,
    Domains: []DomainCfg,

    pub fn initDefault(allocator: all.Allocator) !AppConfig {
        return AppConfig {
            .ActivateTrace = false,
            .TraceLevel = 0,
            .Domains = try allocator.alloc(DomainCfg, 0),
        };
    }

    pub fn deinit(self: *const AppConfig, allocator: all.Allocator) void {
        for (self.Domains) |item| {
            item.deinit(allocator);
        }
        allocator.free(self.Domains);
    }

    pub fn skribiAlTeksto(self: *AppConfig, allocator: all.Allocator, t_formato: TekstaFormato) ![]const u8 {
        return try skribiTiponAlTeksto(allocator, AppConfig, @as(*AppConfig, self), t_formato);
    }

    pub fn skribiAlDosiero(self: *AppConfig, allocator: all.Allocator, path: []const u8, t_formato: TekstaFormato) !void {
        try skribiTiponAlDosiero(allocator, AppConfig, @as(*AppConfig, self), path, t_formato);
    }

    pub fn legiElTeksto(allocator: all.Allocator, input: []const u8, t_formato: TekstaFormato) !AppConfig {
        return try legiTiponElTeksto(allocator, AppConfig, input, t_formato);
    }

    pub fn legiElDosiero(allocator: all.Allocator, path: []const u8, t_formato: TekstaFormato) !AppConfig {
        return try legiTiponElDosiero(allocator, AppConfig, path, t_formato);
    }

    fn skribiAlProtobufTeksto(self: *const AppConfig, allocator: all.Allocator,ind: []const u8) ![]const u8 {
        var bufro:std.ArrayList(u8)= .empty;

        if( self.ActivateTrace ) |val|  
            try bufro.print(allocator,"{s}ActivateTrace: {any}\n",.{ ind, val });
        if( self.TraceLevel ) |val|  
            try bufro.print(allocator,"{s}TraceLevel: {any}\n",.{ ind, val });
        for(self.Domains) |obj| {
            const indent = std.mem.concatWithSentinel(allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
            defer allocator.free(indent);
            const Domains_text = try obj.skribiAlProtobufTeksto(allocator, indent);
            defer allocator.free(Domains_text);

            try bufro.print(allocator, "{s}Domains {{\n{s}{s}}}\n", .{ ind, Domains_text, ind });
        }

        return bufro.toOwnedSlice(allocator);
    }

    fn legiElProtobufTeksto(allocator: all.Allocator, it: *TokenIterType) !AppConfig {
        var mia_Mesagho = try AppConfig.initDefault(allocator);
        errdefer mia_Mesagho.deinit(allocator);

        var Domains_list: std.ArrayList(DomainCfg) = .empty; 
        while (it.next()) |tok| {
            if( equal(u8, tok, "}" ) ) break;
            const val = it.next() orelse return error.InvalidFormat;

            if( equal(u8, tok, "ActivateTrace" ) ) {
                mia_Mesagho.ActivateTrace =  if( equal(u8, val,"true") ) true else false;
                continue;
            }
            if( equal(u8, tok, "TraceLevel" ) ) {
                mia_Mesagho.TraceLevel =  std.fmt.parseInt(i32,val,10) catch 0;
                continue;
            }
            if( equal(u8, tok, "Domains" ) ) {
                const sub_msg = try DomainCfg.legiElProtobufTeksto(allocator, it); 
                try Domains_list.append(allocator, sub_msg); 
                continue;
            }
        }
        for (mia_Mesagho.Domains) |item| {
            item.deinit(allocator);
        }
        allocator.free(mia_Mesagho.Domains);
        mia_Mesagho.Domains = try Domains_list.toOwnedSlice(allocator); 

        return mia_Mesagho;
    }

    pub fn seriigiAlBin(self: *const AppConfig, allocator: all.Allocator, b_formato: BinaraFormato) ![]const u8 {
        return try seriigiTiponAlBin(allocator, AppConfig, self, b_formato);
    }

    pub fn seriigiAlDosiero(self: *const AppConfig, allocator: all.Allocator, path: []const u8, b_formato: BinaraFormato) !void {
        return try seriigiTiponAlDosiero(allocator, AppConfig, @as(*AppConfig, self), path, b_formato);
    }

    fn seriigi(self: *const AppConfig, allocator: all.Allocator, buffer: *EncodeBuffer) !usize {
 
        var tuta_longo: usize = 0;
 
        var Domains_i: usize = self.Domains.len;
        while (Domains_i > 0) {
            Domains_i -= 1;
            const item = self.Domains[Domains_i];
            const Domains_longa = try item.seriigi( allocator, buffer );
            tuta_longo += Domains_longa;
            tuta_longo += try buffer.encodeVarint(Domains_longa);
            tuta_longo += try buffer.encodeVarint(26);
        }  // 11  rept - no def - varlong

        if( self.TraceLevel ) |val| {
            tuta_longo += try buffer.encodeInt32( val );
            tuta_longo += try buffer.encodeVarint(16);
        }   //1 opt - no def - no varlong

        if( self.ActivateTrace ) |val| {
            tuta_longo += try buffer.encodeBool( val );
            tuta_longo += try buffer.encodeVarint(8);
        }   //1 opt - no def - no varlong

        return tuta_longo;
    }

    pub fn deseriigiElBin(allocator: all.Allocator,input: []const u8, b_formato: BinaraFormato) !AppConfig {
        return try deseriigiTiponElBin(allocator, AppConfig, input, b_formato);
    }

    pub fn deseriigiElDosiero(allocator: all.Allocator, path: [:0]const u8, b_formato: BinaraFormato) !AppConfig {
        return try deseriigiTiponElDosiero(allocator, AppConfig, path, b_formato);
    }

    fn deseriigi(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !AppConfig {
        var mia_Mesagho = try AppConfig.initDefault(allocator);
        errdefer mia_Mesagho.deinit(allocator);

        var end: usize = undefined;
        if (data_length) |val|
            end = buffer.read_index + val
        else
            end = buffer.buffer.len;

        var Domains_list: std.ArrayList(DomainCfg) = .empty; 

        while (buffer.read_index < end) {
            const key: u64 = buffer.decodeVarint() catch 0 ;    
            const wire_type = key & 0x7;  
            const field_number = key >> 3;

            if ( field_number == 1 and wire_type == 0 ) 
                mia_Mesagho.ActivateTrace = try buffer.decodeBool()
            else if ( field_number == 2 and wire_type == 0 ) 
                mia_Mesagho.TraceLevel = try buffer.decodeInt32()
            else if ( field_number == 3 and wire_type == 2 ) 
            { 
                try Domains_list.append( 
                    allocator, 
                    try DomainCfg.deseriigi(allocator, buffer, try buffer.decodeVarint() )
                );
            }
        }

        const tmp_Domains = try Domains_list.toOwnedSlice(allocator);
        for (mia_Mesagho.Domains) |*item| {
            item.deinit(allocator);
        }
        allocator.free(mia_Mesagho.Domains);
        mia_Mesagho.Domains = tmp_Domains;

        return mia_Mesagho;
    }
};    // AppConfig

pub const DomainCfg = struct {
    Id: i32,
    ActivateDefaultTransport: bool = false ,
    DirectDispacthToSubs: ?bool = false ,
    KeyFile: ?[]const u8 = null,
    Transports: []TransportDef,
    CrossConnector: ?CrossConnectorDef = null,

    pub fn initDefault(allocator: all.Allocator) !DomainCfg {
        return DomainCfg {
            .Id = 0,
            .ActivateDefaultTransport = false,
            .DirectDispacthToSubs = false,
            .KeyFile = null,
            .Transports = try allocator.alloc(TransportDef, 0),
            .CrossConnector = null,
        };
    }

    pub fn deinit(self: *const DomainCfg, allocator: all.Allocator) void {
        if( self.KeyFile ) |f| {
            allocator.free(f);
        }
        for (self.Transports) |item| {
            item.deinit(allocator);
        }
        allocator.free(self.Transports);
        if (self.CrossConnector) |item| {
            item.deinit(allocator);
        }
    }

    pub fn skribiAlTeksto(self: *DomainCfg, allocator: all.Allocator, t_formato: TekstaFormato) ![]const u8 {
        return try skribiTiponAlTeksto(allocator, DomainCfg, @as(*DomainCfg, self), t_formato);
    }

    pub fn skribiAlDosiero(self: *DomainCfg, allocator: all.Allocator, path: []const u8, t_formato: TekstaFormato) !void {
        try skribiTiponAlDosiero(allocator, DomainCfg, @as(*DomainCfg, self), path, t_formato);
    }

    pub fn legiElTeksto(allocator: all.Allocator, input: []const u8, t_formato: TekstaFormato) !DomainCfg {
        return try legiTiponElTeksto(allocator, DomainCfg, input, t_formato);
    }

    pub fn legiElDosiero(allocator: all.Allocator, path: []const u8, t_formato: TekstaFormato) !DomainCfg {
        return try legiTiponElDosiero(allocator, DomainCfg, path, t_formato);
    }

    fn skribiAlProtobufTeksto(self: *const DomainCfg, allocator: all.Allocator,ind: []const u8) ![]const u8 {
        var bufro:std.ArrayList(u8)= .empty;

        try bufro.print(allocator,"{s}Id: {any}\n",.{ind, self.Id });
        try bufro.print(allocator,"{s}ActivateDefaultTransport: {any}\n",.{ind, self.ActivateDefaultTransport });
        if( self.DirectDispacthToSubs ) |val|  
            try bufro.print(allocator,"{s}DirectDispacthToSubs: {any}\n",.{ ind, val });
        if( self.KeyFile ) |val|  
            try bufro.print(allocator,"{s}KeyFile: \"{s}\"\n",.{ ind, val });
        for(self.Transports) |obj| {
            const indent = std.mem.concatWithSentinel(allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
            defer allocator.free(indent);
            const Transports_text = try obj.skribiAlProtobufTeksto(allocator, indent);
            defer allocator.free(Transports_text);

            try bufro.print(allocator, "{s}Transports {{\n{s}{s}}}\n", .{ ind, Transports_text, ind });
        }
        if( self.CrossConnector ) |val|  {
            const indent = std.mem.concatWithSentinel(allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
            defer allocator.free(indent);
            const CrossConnector_text = try val.skribiAlProtobufTeksto(allocator, indent);
            defer allocator.free(CrossConnector_text);

            try bufro.print(allocator, "{s}CrossConnector {{\n{s}{s}}}\n", .{ ind, CrossConnector_text, ind });
        }

        return bufro.toOwnedSlice(allocator);
    }

    fn legiElProtobufTeksto(allocator: all.Allocator, it: *TokenIterType) !DomainCfg {
        var mia_Mesagho = try DomainCfg.initDefault(allocator);
        errdefer mia_Mesagho.deinit(allocator);

        var Transports_list: std.ArrayList(TransportDef) = .empty; 
        while (it.next()) |tok| {
            if( equal(u8, tok, "}" ) ) break;
            const val = it.next() orelse return error.InvalidFormat;

            if( equal(u8, tok, "Id" ) ) {
                mia_Mesagho.Id =  std.fmt.parseInt(i32,val,10) catch 0;
                continue;
            }
            if( equal(u8, tok, "ActivateDefaultTransport" ) ) {
                mia_Mesagho.ActivateDefaultTransport =  if( equal(u8, val,"true") ) true else false;
                continue;
            }
            if( equal(u8, tok, "DirectDispacthToSubs" ) ) {
                mia_Mesagho.DirectDispacthToSubs =  if( equal(u8, val,"true") ) true else false;
                continue;
            }
            if( equal(u8, tok, "KeyFile" ) ) {
                if (mia_Mesagho.KeyFile) |old| {
                    allocator.free(old);
                }
                mia_Mesagho.KeyFile = try allocator.dupe(u8, val);
                continue;
            }
            if( equal(u8, tok, "Transports" ) ) {
                const sub_msg = try TransportDef.legiElProtobufTeksto(allocator, it); 
                try Transports_list.append(allocator, sub_msg); 
                continue;
            }
            if( equal(u8, tok, "CrossConnector" ) ) {
                const sub_msg = try CrossConnectorDef.legiElProtobufTeksto(allocator, it); 
                mia_Mesagho.CrossConnector = sub_msg; 
                continue;
            }
        }
        for (mia_Mesagho.Transports) |item| {
            item.deinit(allocator);
        }
        allocator.free(mia_Mesagho.Transports);
        mia_Mesagho.Transports = try Transports_list.toOwnedSlice(allocator); 

        return mia_Mesagho;
    }

    pub fn seriigiAlBin(self: *const DomainCfg, allocator: all.Allocator, b_formato: BinaraFormato) ![]const u8 {
        return try seriigiTiponAlBin(allocator, DomainCfg, self, b_formato);
    }

    pub fn seriigiAlDosiero(self: *const DomainCfg, allocator: all.Allocator, path: []const u8, b_formato: BinaraFormato) !void {
        return try seriigiTiponAlDosiero(allocator, DomainCfg, @as(*DomainCfg, self), path, b_formato);
    }

    fn seriigi(self: *const DomainCfg, allocator: all.Allocator, buffer: *EncodeBuffer) !usize {
 
        var tuta_longo: usize = 0;
 
        if ( self.CrossConnector ) |val| {
            const st_longa = try val.seriigi( allocator, buffer );
            tuta_longo += st_longa;
            tuta_longo += try buffer.encodeVarint(st_longa);
            tuta_longo += try buffer.encodeVarint(50);
        }  //3  opt - no def - varlong

        var Transports_i: usize = self.Transports.len;
        while (Transports_i > 0) {
            Transports_i -= 1;
            const item = self.Transports[Transports_i];
            const Transports_longa = try item.seriigi( allocator, buffer );
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
            tuta_longo += try buffer.encodeBool( val );
            tuta_longo += try buffer.encodeVarint(24);
        }   //1 opt - no def - no varlong

        if( self.ActivateDefaultTransport != false )  {
            tuta_longo += try buffer.encodeBool( self.ActivateDefaultTransport );
            tuta_longo += try buffer.encodeVarint(16);
        }  //6  req - def - no varlong

        tuta_longo += try buffer.encodeInt32( self.Id );
        tuta_longo += try buffer.encodeVarint(8);
        //5 req - no def - no varlong

        return tuta_longo;
    }

    pub fn deseriigiElBin(allocator: all.Allocator,input: []const u8, b_formato: BinaraFormato) !DomainCfg {
        return try deseriigiTiponElBin(allocator, DomainCfg, input, b_formato);
    }

    pub fn deseriigiElDosiero(allocator: all.Allocator, path: [:0]const u8, b_formato: BinaraFormato) !DomainCfg {
        return try deseriigiTiponElDosiero(allocator, DomainCfg, path, b_formato);
    }

    fn deseriigi(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !DomainCfg {
        var mia_Mesagho = try DomainCfg.initDefault(allocator);
        errdefer mia_Mesagho.deinit(allocator);

        var end: usize = undefined;
        if (data_length) |val|
            end = buffer.read_index + val
        else
            end = buffer.buffer.len;

        var Transports_list: std.ArrayList(TransportDef) = .empty; 

        while (buffer.read_index < end) {
            const key: u64 = buffer.decodeVarint() catch 0 ;    
            const wire_type = key & 0x7;  
            const field_number = key >> 3;

            if ( field_number == 1 and wire_type == 0 ) 
                mia_Mesagho.Id = try buffer.decodeInt32()
            else if ( field_number == 2 and wire_type == 0 ) 
                mia_Mesagho.ActivateDefaultTransport = try buffer.decodeBool()
            else if ( field_number == 3 and wire_type == 0 ) 
                mia_Mesagho.DirectDispacthToSubs = try buffer.decodeBool()
            else if ( field_number == 4 and wire_type == 2 ) 
            {
                const tmp_KeyFile = try buffer.decodeString(  try buffer.decodeVarint() );
                if (mia_Mesagho.KeyFile) |old| {
                    allocator.free(old);
                }
                mia_Mesagho.KeyFile = tmp_KeyFile;
            }
            else if ( field_number == 5 and wire_type == 2 ) 
            { 
                try Transports_list.append( 
                    allocator, 
                    try TransportDef.deseriigi(allocator, buffer, try buffer.decodeVarint() )
                );
            }
            else if ( field_number == 6 and wire_type == 2 ) 
                mia_Mesagho.CrossConnector = try CrossConnectorDef.deseriigi(allocator, buffer, try buffer.decodeVarint() );
        }

        const tmp_Transports = try Transports_list.toOwnedSlice(allocator);
        for (mia_Mesagho.Transports) |*item| {
            item.deinit(allocator);
        }
        allocator.free(mia_Mesagho.Transports);
        mia_Mesagho.Transports = tmp_Transports;

        return mia_Mesagho;
    }
};    // DomainCfg

pub const TransportDef = struct {
    TransportName: []const u8,
    DllImport: []const u8,
    TransportClass: []const u8,
    ReceiveOwnMsgs: ?bool = false ,
    MCastParams: ?MCastDefConfig = null,
    BCastParams: ?BCastDefConfig = null,
    UDPStarParams: ?UDPStarDefConfig = null,

    pub fn initDefault(allocator: all.Allocator) !TransportDef {
        return TransportDef {
            .TransportName = try allocator.dupe(u8, "MCastDefault0"),
            .DllImport = try allocator.dupe(u8, "Default"),
            .TransportClass = try allocator.dupe(u8, "Default"),
            .ReceiveOwnMsgs = false,
            .MCastParams = null,
            .BCastParams = null,
            .UDPStarParams = null,
        };
    }

    pub fn deinit(self: *const TransportDef, allocator: all.Allocator) void {
        allocator.free(self.TransportName);
        allocator.free(self.DllImport);
        allocator.free(self.TransportClass);
        if (self.MCastParams) |item| {
            item.deinit(allocator);
        }
        if (self.BCastParams) |item| {
            item.deinit(allocator);
        }
        if (self.UDPStarParams) |item| {
            item.deinit(allocator);
        }
    }

    pub fn skribiAlTeksto(self: *TransportDef, allocator: all.Allocator, t_formato: TekstaFormato) ![]const u8 {
        return try skribiTiponAlTeksto(allocator, TransportDef, @as(*TransportDef, self), t_formato);
    }

    pub fn skribiAlDosiero(self: *TransportDef, allocator: all.Allocator, path: []const u8, t_formato: TekstaFormato) !void {
        try skribiTiponAlDosiero(allocator, TransportDef, @as(*TransportDef, self), path, t_formato);
    }

    pub fn legiElTeksto(allocator: all.Allocator, input: []const u8, t_formato: TekstaFormato) !TransportDef {
        return try legiTiponElTeksto(allocator, TransportDef, input, t_formato);
    }

    pub fn legiElDosiero(allocator: all.Allocator, path: []const u8, t_formato: TekstaFormato) !TransportDef {
        return try legiTiponElDosiero(allocator, TransportDef, path, t_formato);
    }

    fn skribiAlProtobufTeksto(self: *const TransportDef, allocator: all.Allocator,ind: []const u8) ![]const u8 {
        var bufro:std.ArrayList(u8)= .empty;

        try bufro.print(allocator,"{s}TransportName: \"{s}\"\n",.{ind, self.TransportName });
        try bufro.print(allocator,"{s}DllImport: \"{s}\"\n",.{ind, self.DllImport });
        try bufro.print(allocator,"{s}TransportClass: \"{s}\"\n",.{ind, self.TransportClass });
        if( self.ReceiveOwnMsgs ) |val|  
            try bufro.print(allocator,"{s}ReceiveOwnMsgs: {any}\n",.{ ind, val });
        if( self.MCastParams ) |val|  {
            const indent = std.mem.concatWithSentinel(allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
            defer allocator.free(indent);
            const MCastParams_text = try val.skribiAlProtobufTeksto(allocator, indent);
            defer allocator.free(MCastParams_text);

            try bufro.print(allocator, "{s}MCastParams {{\n{s}{s}}}\n", .{ ind, MCastParams_text, ind });
        }
        if( self.BCastParams ) |val|  {
            const indent = std.mem.concatWithSentinel(allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
            defer allocator.free(indent);
            const BCastParams_text = try val.skribiAlProtobufTeksto(allocator, indent);
            defer allocator.free(BCastParams_text);

            try bufro.print(allocator, "{s}BCastParams {{\n{s}{s}}}\n", .{ ind, BCastParams_text, ind });
        }
        if( self.UDPStarParams ) |val|  {
            const indent = std.mem.concatWithSentinel(allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
            defer allocator.free(indent);
            const UDPStarParams_text = try val.skribiAlProtobufTeksto(allocator, indent);
            defer allocator.free(UDPStarParams_text);

            try bufro.print(allocator, "{s}UDPStarParams {{\n{s}{s}}}\n", .{ ind, UDPStarParams_text, ind });
        }

        return bufro.toOwnedSlice(allocator);
    }

    fn legiElProtobufTeksto(allocator: all.Allocator, it: *TokenIterType) !TransportDef {
        var mia_Mesagho = try TransportDef.initDefault(allocator);
        errdefer mia_Mesagho.deinit(allocator);


        while (it.next()) |tok| {
            if( equal(u8, tok, "}" ) ) break;
            const val = it.next() orelse return error.InvalidFormat;

            if( equal(u8, tok, "TransportName" ) ) {
                allocator.free(mia_Mesagho.TransportName);
                mia_Mesagho.TransportName = try allocator.dupe(u8, val);
                continue;
            }
            if( equal(u8, tok, "DllImport" ) ) {
                allocator.free(mia_Mesagho.DllImport);
                mia_Mesagho.DllImport = try allocator.dupe(u8, val);
                continue;
            }
            if( equal(u8, tok, "TransportClass" ) ) {
                allocator.free(mia_Mesagho.TransportClass);
                mia_Mesagho.TransportClass = try allocator.dupe(u8, val);
                continue;
            }
            if( equal(u8, tok, "ReceiveOwnMsgs" ) ) {
                mia_Mesagho.ReceiveOwnMsgs =  if( equal(u8, val,"true") ) true else false;
                continue;
            }
            if( equal(u8, tok, "MCastParams" ) ) {
                const sub_msg = try MCastDefConfig.legiElProtobufTeksto(allocator, it); 
                mia_Mesagho.MCastParams = sub_msg; 
                continue;
            }
            if( equal(u8, tok, "BCastParams" ) ) {
                const sub_msg = try BCastDefConfig.legiElProtobufTeksto(allocator, it); 
                mia_Mesagho.BCastParams = sub_msg; 
                continue;
            }
            if( equal(u8, tok, "UDPStarParams" ) ) {
                const sub_msg = try UDPStarDefConfig.legiElProtobufTeksto(allocator, it); 
                mia_Mesagho.UDPStarParams = sub_msg; 
                continue;
            }
        }

        return mia_Mesagho;
    }

    pub fn seriigiAlBin(self: *const TransportDef, allocator: all.Allocator, b_formato: BinaraFormato) ![]const u8 {
        return try seriigiTiponAlBin(allocator, TransportDef, self, b_formato);
    }

    pub fn seriigiAlDosiero(self: *const TransportDef, allocator: all.Allocator, path: []const u8, b_formato: BinaraFormato) !void {
        return try seriigiTiponAlDosiero(allocator, TransportDef, @as(*TransportDef, self), path, b_formato);
    }

    fn seriigi(self: *const TransportDef, allocator: all.Allocator, buffer: *EncodeBuffer) !usize {
 
        var tuta_longo: usize = 0;
 
        if ( self.UDPStarParams ) |val| {
            const st_longa = try val.seriigi( allocator, buffer );
            tuta_longo += st_longa;
            tuta_longo += try buffer.encodeVarint(st_longa);
            tuta_longo += try buffer.encodeVarint(58);
        }  //3  opt - no def - varlong

        if ( self.BCastParams ) |val| {
            const st_longa = try val.seriigi( allocator, buffer );
            tuta_longo += st_longa;
            tuta_longo += try buffer.encodeVarint(st_longa);
            tuta_longo += try buffer.encodeVarint(50);
        }  //3  opt - no def - varlong

        if ( self.MCastParams ) |val| {
            const st_longa = try val.seriigi( allocator, buffer );
            tuta_longo += st_longa;
            tuta_longo += try buffer.encodeVarint(st_longa);
            tuta_longo += try buffer.encodeVarint(42);
        }  //3  opt - no def - varlong

        if( self.ReceiveOwnMsgs ) |val| {
            tuta_longo += try buffer.encodeBool( val );
            tuta_longo += try buffer.encodeVarint(32);
        }   //1 opt - no def - no varlong

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

    pub fn deseriigiElBin(allocator: all.Allocator,input: []const u8, b_formato: BinaraFormato) !TransportDef {
        return try deseriigiTiponElBin(allocator, TransportDef, input, b_formato);
    }

    pub fn deseriigiElDosiero(allocator: all.Allocator, path: [:0]const u8, b_formato: BinaraFormato) !TransportDef {
        return try deseriigiTiponElDosiero(allocator, TransportDef, path, b_formato);
    }

    fn deseriigi(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !TransportDef {
        var mia_Mesagho = try TransportDef.initDefault(allocator);
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
                const tmp_TransportName = try buffer.decodeString(  try buffer.decodeVarint() );
                allocator.free(mia_Mesagho.TransportName);
                mia_Mesagho.TransportName = tmp_TransportName;
            }
            else if ( field_number == 2 and wire_type == 2 ) 
            {
                const tmp_DllImport = try buffer.decodeString(  try buffer.decodeVarint() );
                allocator.free(mia_Mesagho.DllImport);
                mia_Mesagho.DllImport = tmp_DllImport;
            }
            else if ( field_number == 3 and wire_type == 2 ) 
            {
                const tmp_TransportClass = try buffer.decodeString(  try buffer.decodeVarint() );
                allocator.free(mia_Mesagho.TransportClass);
                mia_Mesagho.TransportClass = tmp_TransportClass;
            }
            else if ( field_number == 4 and wire_type == 0 ) 
                mia_Mesagho.ReceiveOwnMsgs = try buffer.decodeBool()
            else if ( field_number == 5 and wire_type == 2 ) 
                mia_Mesagho.MCastParams = try MCastDefConfig.deseriigi(allocator, buffer, try buffer.decodeVarint() )
            else if ( field_number == 6 and wire_type == 2 ) 
                mia_Mesagho.BCastParams = try BCastDefConfig.deseriigi(allocator, buffer, try buffer.decodeVarint() )
            else if ( field_number == 7 and wire_type == 2 ) 
                mia_Mesagho.UDPStarParams = try UDPStarDefConfig.deseriigi(allocator, buffer, try buffer.decodeVarint() );
        }


        return mia_Mesagho;
    }
};    // TransportDef

pub const MCastDefConfig = struct {
    LocalAddress: []const u8,
    MCastAddress: []const u8,
    Port: i32 = 40069 ,
    TTL: ?i32 = 1 ,
    ReceiveBuffer: ?i32 = 134217727 ,
    SendBuffer: ?i32 = 134217727 ,

    pub fn initDefault(allocator: all.Allocator) !MCastDefConfig {
        return MCastDefConfig {
            .LocalAddress = try allocator.dupe(u8, "Any"),
            .MCastAddress = try allocator.dupe(u8, "239.255.0.1"),
            .Port = 40069,
            .TTL = 1,
            .ReceiveBuffer = 134217727,
            .SendBuffer = 134217727,
        };
    }

    pub fn deinit(self: *const MCastDefConfig, allocator: all.Allocator) void {
        allocator.free(self.LocalAddress);
        allocator.free(self.MCastAddress);
    }

    pub fn skribiAlTeksto(self: *MCastDefConfig, allocator: all.Allocator, t_formato: TekstaFormato) ![]const u8 {
        return try skribiTiponAlTeksto(allocator, MCastDefConfig, @as(*MCastDefConfig, self), t_formato);
    }

    pub fn skribiAlDosiero(self: *MCastDefConfig, allocator: all.Allocator, path: []const u8, t_formato: TekstaFormato) !void {
        try skribiTiponAlDosiero(allocator, MCastDefConfig, @as(*MCastDefConfig, self), path, t_formato);
    }

    pub fn legiElTeksto(allocator: all.Allocator, input: []const u8, t_formato: TekstaFormato) !MCastDefConfig {
        return try legiTiponElTeksto(allocator, MCastDefConfig, input, t_formato);
    }

    pub fn legiElDosiero(allocator: all.Allocator, path: []const u8, t_formato: TekstaFormato) !MCastDefConfig {
        return try legiTiponElDosiero(allocator, MCastDefConfig, path, t_formato);
    }

    fn skribiAlProtobufTeksto(self: *const MCastDefConfig, allocator: all.Allocator,ind: []const u8) ![]const u8 {
        var bufro:std.ArrayList(u8)= .empty;

        try bufro.print(allocator,"{s}LocalAddress: \"{s}\"\n",.{ind, self.LocalAddress });
        try bufro.print(allocator,"{s}MCastAddress: \"{s}\"\n",.{ind, self.MCastAddress });
        try bufro.print(allocator,"{s}Port: {any}\n",.{ind, self.Port });
        if( self.TTL ) |val|  
            try bufro.print(allocator,"{s}TTL: {any}\n",.{ ind, val });
        if( self.ReceiveBuffer ) |val|  
            try bufro.print(allocator,"{s}ReceiveBuffer: {any}\n",.{ ind, val });
        if( self.SendBuffer ) |val|  
            try bufro.print(allocator,"{s}SendBuffer: {any}\n",.{ ind, val });

        return bufro.toOwnedSlice(allocator);
    }

    fn legiElProtobufTeksto(allocator: all.Allocator, it: *TokenIterType) !MCastDefConfig {
        var mia_Mesagho = try MCastDefConfig.initDefault(allocator);
        errdefer mia_Mesagho.deinit(allocator);


        while (it.next()) |tok| {
            if( equal(u8, tok, "}" ) ) break;
            const val = it.next() orelse return error.InvalidFormat;

            if( equal(u8, tok, "LocalAddress" ) ) {
                allocator.free(mia_Mesagho.LocalAddress);
                mia_Mesagho.LocalAddress = try allocator.dupe(u8, val);
                continue;
            }
            if( equal(u8, tok, "MCastAddress" ) ) {
                allocator.free(mia_Mesagho.MCastAddress);
                mia_Mesagho.MCastAddress = try allocator.dupe(u8, val);
                continue;
            }
            if( equal(u8, tok, "Port" ) ) {
                mia_Mesagho.Port =  std.fmt.parseInt(i32,val,10) catch 0;
                continue;
            }
            if( equal(u8, tok, "TTL" ) ) {
                mia_Mesagho.TTL =  std.fmt.parseInt(i32,val,10) catch 0;
                continue;
            }
            if( equal(u8, tok, "ReceiveBuffer" ) ) {
                mia_Mesagho.ReceiveBuffer =  std.fmt.parseInt(i32,val,10) catch 0;
                continue;
            }
            if( equal(u8, tok, "SendBuffer" ) ) {
                mia_Mesagho.SendBuffer =  std.fmt.parseInt(i32,val,10) catch 0;
                continue;
            }
        }

        return mia_Mesagho;
    }

    pub fn seriigiAlBin(self: *const MCastDefConfig, allocator: all.Allocator, b_formato: BinaraFormato) ![]const u8 {
        return try seriigiTiponAlBin(allocator, MCastDefConfig, self, b_formato);
    }

    pub fn seriigiAlDosiero(self: *const MCastDefConfig, allocator: all.Allocator, path: []const u8, b_formato: BinaraFormato) !void {
        return try seriigiTiponAlDosiero(allocator, MCastDefConfig, @as(*MCastDefConfig, self), path, b_formato);
    }

    fn seriigi(self: *const MCastDefConfig, allocator: all.Allocator, buffer: *EncodeBuffer) !usize {
 
        _ = allocator;
        var tuta_longo: usize = 0;
 
        if( self.SendBuffer ) |val| {
            tuta_longo += try buffer.encodeInt32( val );
            tuta_longo += try buffer.encodeVarint(48);
        }   //1 opt - no def - no varlong

        if( self.ReceiveBuffer ) |val| {
            tuta_longo += try buffer.encodeInt32( val );
            tuta_longo += try buffer.encodeVarint(40);
        }   //1 opt - no def - no varlong

        if( self.TTL ) |val| {
            tuta_longo += try buffer.encodeInt32( val );
            tuta_longo += try buffer.encodeVarint(32);
        }   //1 opt - no def - no varlong

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

    pub fn deseriigiElBin(allocator: all.Allocator,input: []const u8, b_formato: BinaraFormato) !MCastDefConfig {
        return try deseriigiTiponElBin(allocator, MCastDefConfig, input, b_formato);
    }

    pub fn deseriigiElDosiero(allocator: all.Allocator, path: [:0]const u8, b_formato: BinaraFormato) !MCastDefConfig {
        return try deseriigiTiponElDosiero(allocator, MCastDefConfig, path, b_formato);
    }

    fn deseriigi(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !MCastDefConfig {
        var mia_Mesagho = try MCastDefConfig.initDefault(allocator);
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
                const tmp_LocalAddress = try buffer.decodeString(  try buffer.decodeVarint() );
                allocator.free(mia_Mesagho.LocalAddress);
                mia_Mesagho.LocalAddress = tmp_LocalAddress;
            }
            else if ( field_number == 2 and wire_type == 2 ) 
            {
                const tmp_MCastAddress = try buffer.decodeString(  try buffer.decodeVarint() );
                allocator.free(mia_Mesagho.MCastAddress);
                mia_Mesagho.MCastAddress = tmp_MCastAddress;
            }
            else if ( field_number == 3 and wire_type == 0 ) 
                mia_Mesagho.Port = try buffer.decodeInt32()
            else if ( field_number == 4 and wire_type == 0 ) 
                mia_Mesagho.TTL = try buffer.decodeInt32()
            else if ( field_number == 5 and wire_type == 0 ) 
                mia_Mesagho.ReceiveBuffer = try buffer.decodeInt32()
            else if ( field_number == 6 and wire_type == 0 ) 
                mia_Mesagho.SendBuffer = try buffer.decodeInt32();
        }


        return mia_Mesagho;
    }
};    // MCastDefConfig

pub const BCastDefConfig = struct {
    LocalAddress: []const u8,
    BCastAddress: []const u8,
    Port: i32 = 40069 ,
    ReceiveBuffer: ?i32 = 134217727 ,
    SendBuffer: ?i32 = 134217727 ,

    pub fn initDefault(allocator: all.Allocator) !BCastDefConfig {
        return BCastDefConfig {
            .LocalAddress = try allocator.dupe(u8, "Any"),
            .BCastAddress = try allocator.dupe(u8, "192.168.2.255"),
            .Port = 40069,
            .ReceiveBuffer = 134217727,
            .SendBuffer = 134217727,
        };
    }

    pub fn deinit(self: *const BCastDefConfig, allocator: all.Allocator) void {
        allocator.free(self.LocalAddress);
        allocator.free(self.BCastAddress);
    }

    pub fn skribiAlTeksto(self: *BCastDefConfig, allocator: all.Allocator, t_formato: TekstaFormato) ![]const u8 {
        return try skribiTiponAlTeksto(allocator, BCastDefConfig, @as(*BCastDefConfig, self), t_formato);
    }

    pub fn skribiAlDosiero(self: *BCastDefConfig, allocator: all.Allocator, path: []const u8, t_formato: TekstaFormato) !void {
        try skribiTiponAlDosiero(allocator, BCastDefConfig, @as(*BCastDefConfig, self), path, t_formato);
    }

    pub fn legiElTeksto(allocator: all.Allocator, input: []const u8, t_formato: TekstaFormato) !BCastDefConfig {
        return try legiTiponElTeksto(allocator, BCastDefConfig, input, t_formato);
    }

    pub fn legiElDosiero(allocator: all.Allocator, path: []const u8, t_formato: TekstaFormato) !BCastDefConfig {
        return try legiTiponElDosiero(allocator, BCastDefConfig, path, t_formato);
    }

    fn skribiAlProtobufTeksto(self: *const BCastDefConfig, allocator: all.Allocator,ind: []const u8) ![]const u8 {
        var bufro:std.ArrayList(u8)= .empty;

        try bufro.print(allocator,"{s}LocalAddress: \"{s}\"\n",.{ind, self.LocalAddress });
        try bufro.print(allocator,"{s}BCastAddress: \"{s}\"\n",.{ind, self.BCastAddress });
        try bufro.print(allocator,"{s}Port: {any}\n",.{ind, self.Port });
        if( self.ReceiveBuffer ) |val|  
            try bufro.print(allocator,"{s}ReceiveBuffer: {any}\n",.{ ind, val });
        if( self.SendBuffer ) |val|  
            try bufro.print(allocator,"{s}SendBuffer: {any}\n",.{ ind, val });

        return bufro.toOwnedSlice(allocator);
    }

    fn legiElProtobufTeksto(allocator: all.Allocator, it: *TokenIterType) !BCastDefConfig {
        var mia_Mesagho = try BCastDefConfig.initDefault(allocator);
        errdefer mia_Mesagho.deinit(allocator);


        while (it.next()) |tok| {
            if( equal(u8, tok, "}" ) ) break;
            const val = it.next() orelse return error.InvalidFormat;

            if( equal(u8, tok, "LocalAddress" ) ) {
                allocator.free(mia_Mesagho.LocalAddress);
                mia_Mesagho.LocalAddress = try allocator.dupe(u8, val);
                continue;
            }
            if( equal(u8, tok, "BCastAddress" ) ) {
                allocator.free(mia_Mesagho.BCastAddress);
                mia_Mesagho.BCastAddress = try allocator.dupe(u8, val);
                continue;
            }
            if( equal(u8, tok, "Port" ) ) {
                mia_Mesagho.Port =  std.fmt.parseInt(i32,val,10) catch 0;
                continue;
            }
            if( equal(u8, tok, "ReceiveBuffer" ) ) {
                mia_Mesagho.ReceiveBuffer =  std.fmt.parseInt(i32,val,10) catch 0;
                continue;
            }
            if( equal(u8, tok, "SendBuffer" ) ) {
                mia_Mesagho.SendBuffer =  std.fmt.parseInt(i32,val,10) catch 0;
                continue;
            }
        }

        return mia_Mesagho;
    }

    pub fn seriigiAlBin(self: *const BCastDefConfig, allocator: all.Allocator, b_formato: BinaraFormato) ![]const u8 {
        return try seriigiTiponAlBin(allocator, BCastDefConfig, self, b_formato);
    }

    pub fn seriigiAlDosiero(self: *const BCastDefConfig, allocator: all.Allocator, path: []const u8, b_formato: BinaraFormato) !void {
        return try seriigiTiponAlDosiero(allocator, BCastDefConfig, @as(*BCastDefConfig, self), path, b_formato);
    }

    fn seriigi(self: *const BCastDefConfig, allocator: all.Allocator, buffer: *EncodeBuffer) !usize {
 
        _ = allocator;
        var tuta_longo: usize = 0;
 
        if( self.SendBuffer ) |val| {
            tuta_longo += try buffer.encodeInt32( val );
            tuta_longo += try buffer.encodeVarint(40);
        }   //1 opt - no def - no varlong

        if( self.ReceiveBuffer ) |val| {
            tuta_longo += try buffer.encodeInt32( val );
            tuta_longo += try buffer.encodeVarint(32);
        }   //1 opt - no def - no varlong

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

    pub fn deseriigiElBin(allocator: all.Allocator,input: []const u8, b_formato: BinaraFormato) !BCastDefConfig {
        return try deseriigiTiponElBin(allocator, BCastDefConfig, input, b_formato);
    }

    pub fn deseriigiElDosiero(allocator: all.Allocator, path: [:0]const u8, b_formato: BinaraFormato) !BCastDefConfig {
        return try deseriigiTiponElDosiero(allocator, BCastDefConfig, path, b_formato);
    }

    fn deseriigi(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !BCastDefConfig {
        var mia_Mesagho = try BCastDefConfig.initDefault(allocator);
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
                const tmp_LocalAddress = try buffer.decodeString(  try buffer.decodeVarint() );
                allocator.free(mia_Mesagho.LocalAddress);
                mia_Mesagho.LocalAddress = tmp_LocalAddress;
            }
            else if ( field_number == 2 and wire_type == 2 ) 
            {
                const tmp_BCastAddress = try buffer.decodeString(  try buffer.decodeVarint() );
                allocator.free(mia_Mesagho.BCastAddress);
                mia_Mesagho.BCastAddress = tmp_BCastAddress;
            }
            else if ( field_number == 3 and wire_type == 0 ) 
                mia_Mesagho.Port = try buffer.decodeInt32()
            else if ( field_number == 4 and wire_type == 0 ) 
                mia_Mesagho.ReceiveBuffer = try buffer.decodeInt32()
            else if ( field_number == 5 and wire_type == 0 ) 
                mia_Mesagho.SendBuffer = try buffer.decodeInt32();
        }


        return mia_Mesagho;
    }
};    // BCastDefConfig

pub const UDPStarDefConfig = struct {
    LocalAddress: []const u8,
    Port: i32 = 40069 ,
    EndPoint: []EndPointDef,
    ReceiveBuffer: ?i32 = 134217727 ,
    SendBuffer: ?i32 = 134217727 ,

    pub fn initDefault(allocator: all.Allocator) !UDPStarDefConfig {
        return UDPStarDefConfig {
            .LocalAddress = try allocator.dupe(u8, "Any"),
            .Port = 40069,
            .EndPoint = try allocator.alloc(EndPointDef, 0),
            .ReceiveBuffer = 134217727,
            .SendBuffer = 134217727,
        };
    }

    pub fn deinit(self: *const UDPStarDefConfig, allocator: all.Allocator) void {
        allocator.free(self.LocalAddress);
        for (self.EndPoint) |item| {
            item.deinit(allocator);
        }
        allocator.free(self.EndPoint);
    }

    pub fn skribiAlTeksto(self: *UDPStarDefConfig, allocator: all.Allocator, t_formato: TekstaFormato) ![]const u8 {
        return try skribiTiponAlTeksto(allocator, UDPStarDefConfig, @as(*UDPStarDefConfig, self), t_formato);
    }

    pub fn skribiAlDosiero(self: *UDPStarDefConfig, allocator: all.Allocator, path: []const u8, t_formato: TekstaFormato) !void {
        try skribiTiponAlDosiero(allocator, UDPStarDefConfig, @as(*UDPStarDefConfig, self), path, t_formato);
    }

    pub fn legiElTeksto(allocator: all.Allocator, input: []const u8, t_formato: TekstaFormato) !UDPStarDefConfig {
        return try legiTiponElTeksto(allocator, UDPStarDefConfig, input, t_formato);
    }

    pub fn legiElDosiero(allocator: all.Allocator, path: []const u8, t_formato: TekstaFormato) !UDPStarDefConfig {
        return try legiTiponElDosiero(allocator, UDPStarDefConfig, path, t_formato);
    }

    fn skribiAlProtobufTeksto(self: *const UDPStarDefConfig, allocator: all.Allocator,ind: []const u8) ![]const u8 {
        var bufro:std.ArrayList(u8)= .empty;

        try bufro.print(allocator,"{s}LocalAddress: \"{s}\"\n",.{ind, self.LocalAddress });
        try bufro.print(allocator,"{s}Port: {any}\n",.{ind, self.Port });
        for(self.EndPoint) |obj| {
            const indent = std.mem.concatWithSentinel(allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
            defer allocator.free(indent);
            const EndPoint_text = try obj.skribiAlProtobufTeksto(allocator, indent);
            defer allocator.free(EndPoint_text);

            try bufro.print(allocator, "{s}EndPoint {{\n{s}{s}}}\n", .{ ind, EndPoint_text, ind });
        }
        if( self.ReceiveBuffer ) |val|  
            try bufro.print(allocator,"{s}ReceiveBuffer: {any}\n",.{ ind, val });
        if( self.SendBuffer ) |val|  
            try bufro.print(allocator,"{s}SendBuffer: {any}\n",.{ ind, val });

        return bufro.toOwnedSlice(allocator);
    }

    fn legiElProtobufTeksto(allocator: all.Allocator, it: *TokenIterType) !UDPStarDefConfig {
        var mia_Mesagho = try UDPStarDefConfig.initDefault(allocator);
        errdefer mia_Mesagho.deinit(allocator);

        var EndPoint_list: std.ArrayList(EndPointDef) = .empty; 
        while (it.next()) |tok| {
            if( equal(u8, tok, "}" ) ) break;
            const val = it.next() orelse return error.InvalidFormat;

            if( equal(u8, tok, "LocalAddress" ) ) {
                allocator.free(mia_Mesagho.LocalAddress);
                mia_Mesagho.LocalAddress = try allocator.dupe(u8, val);
                continue;
            }
            if( equal(u8, tok, "Port" ) ) {
                mia_Mesagho.Port =  std.fmt.parseInt(i32,val,10) catch 0;
                continue;
            }
            if( equal(u8, tok, "EndPoint" ) ) {
                const sub_msg = try EndPointDef.legiElProtobufTeksto(allocator, it); 
                try EndPoint_list.append(allocator, sub_msg); 
                continue;
            }
            if( equal(u8, tok, "ReceiveBuffer" ) ) {
                mia_Mesagho.ReceiveBuffer =  std.fmt.parseInt(i32,val,10) catch 0;
                continue;
            }
            if( equal(u8, tok, "SendBuffer" ) ) {
                mia_Mesagho.SendBuffer =  std.fmt.parseInt(i32,val,10) catch 0;
                continue;
            }
        }
        for (mia_Mesagho.EndPoint) |item| {
            item.deinit(allocator);
        }
        allocator.free(mia_Mesagho.EndPoint);
        mia_Mesagho.EndPoint = try EndPoint_list.toOwnedSlice(allocator); 

        return mia_Mesagho;
    }

    pub fn seriigiAlBin(self: *const UDPStarDefConfig, allocator: all.Allocator, b_formato: BinaraFormato) ![]const u8 {
        return try seriigiTiponAlBin(allocator, UDPStarDefConfig, self, b_formato);
    }

    pub fn seriigiAlDosiero(self: *const UDPStarDefConfig, allocator: all.Allocator, path: []const u8, b_formato: BinaraFormato) !void {
        return try seriigiTiponAlDosiero(allocator, UDPStarDefConfig, @as(*UDPStarDefConfig, self), path, b_formato);
    }

    fn seriigi(self: *const UDPStarDefConfig, allocator: all.Allocator, buffer: *EncodeBuffer) !usize {
 
        var tuta_longo: usize = 0;
 
        if( self.SendBuffer ) |val| {
            tuta_longo += try buffer.encodeInt32( val );
            tuta_longo += try buffer.encodeVarint(40);
        }   //1 opt - no def - no varlong

        if( self.ReceiveBuffer ) |val| {
            tuta_longo += try buffer.encodeInt32( val );
            tuta_longo += try buffer.encodeVarint(32);
        }   //1 opt - no def - no varlong

        var EndPoint_i: usize = self.EndPoint.len;
        while (EndPoint_i > 0) {
            EndPoint_i -= 1;
            const item = self.EndPoint[EndPoint_i];
            const EndPoint_longa = try item.seriigi( allocator, buffer );
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

    pub fn deseriigiElBin(allocator: all.Allocator,input: []const u8, b_formato: BinaraFormato) !UDPStarDefConfig {
        return try deseriigiTiponElBin(allocator, UDPStarDefConfig, input, b_formato);
    }

    pub fn deseriigiElDosiero(allocator: all.Allocator, path: [:0]const u8, b_formato: BinaraFormato) !UDPStarDefConfig {
        return try deseriigiTiponElDosiero(allocator, UDPStarDefConfig, path, b_formato);
    }

    fn deseriigi(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !UDPStarDefConfig {
        var mia_Mesagho = try UDPStarDefConfig.initDefault(allocator);
        errdefer mia_Mesagho.deinit(allocator);

        var end: usize = undefined;
        if (data_length) |val|
            end = buffer.read_index + val
        else
            end = buffer.buffer.len;

        var EndPoint_list: std.ArrayList(EndPointDef) = .empty; 

        while (buffer.read_index < end) {
            const key: u64 = buffer.decodeVarint() catch 0 ;    
            const wire_type = key & 0x7;  
            const field_number = key >> 3;

            if ( field_number == 1 and wire_type == 2 ) 
            {
                const tmp_LocalAddress = try buffer.decodeString(  try buffer.decodeVarint() );
                allocator.free(mia_Mesagho.LocalAddress);
                mia_Mesagho.LocalAddress = tmp_LocalAddress;
            }
            else if ( field_number == 2 and wire_type == 0 ) 
                mia_Mesagho.Port = try buffer.decodeInt32()
            else if ( field_number == 3 and wire_type == 2 ) 
            { 
                try EndPoint_list.append( 
                    allocator, 
                    try EndPointDef.deseriigi(allocator, buffer, try buffer.decodeVarint() )
                );
            }
            else if ( field_number == 4 and wire_type == 0 ) 
                mia_Mesagho.ReceiveBuffer = try buffer.decodeInt32()
            else if ( field_number == 5 and wire_type == 0 ) 
                mia_Mesagho.SendBuffer = try buffer.decodeInt32();
        }

        const tmp_EndPoint = try EndPoint_list.toOwnedSlice(allocator);
        for (mia_Mesagho.EndPoint) |*item| {
            item.deinit(allocator);
        }
        allocator.free(mia_Mesagho.EndPoint);
        mia_Mesagho.EndPoint = tmp_EndPoint;

        return mia_Mesagho;
    }
};    // UDPStarDefConfig

pub const EndPointDef = struct {
    Host: []const u8,
    Port: i32 = 40069 ,

    pub fn initDefault(allocator: all.Allocator) !EndPointDef {
        return EndPointDef {
            .Host = try allocator.dupe(u8, ""),
            .Port = 40069,
        };
    }

    pub fn deinit(self: *const EndPointDef, allocator: all.Allocator) void {
        allocator.free(self.Host);
    }

    pub fn skribiAlTeksto(self: *EndPointDef, allocator: all.Allocator, t_formato: TekstaFormato) ![]const u8 {
        return try skribiTiponAlTeksto(allocator, EndPointDef, @as(*EndPointDef, self), t_formato);
    }

    pub fn skribiAlDosiero(self: *EndPointDef, allocator: all.Allocator, path: []const u8, t_formato: TekstaFormato) !void {
        try skribiTiponAlDosiero(allocator, EndPointDef, @as(*EndPointDef, self), path, t_formato);
    }

    pub fn legiElTeksto(allocator: all.Allocator, input: []const u8, t_formato: TekstaFormato) !EndPointDef {
        return try legiTiponElTeksto(allocator, EndPointDef, input, t_formato);
    }

    pub fn legiElDosiero(allocator: all.Allocator, path: []const u8, t_formato: TekstaFormato) !EndPointDef {
        return try legiTiponElDosiero(allocator, EndPointDef, path, t_formato);
    }

    fn skribiAlProtobufTeksto(self: *const EndPointDef, allocator: all.Allocator,ind: []const u8) ![]const u8 {
        var bufro:std.ArrayList(u8)= .empty;

        try bufro.print(allocator,"{s}Host: \"{s}\"\n",.{ind, self.Host });
        try bufro.print(allocator,"{s}Port: {any}\n",.{ind, self.Port });

        return bufro.toOwnedSlice(allocator);
    }

    fn legiElProtobufTeksto(allocator: all.Allocator, it: *TokenIterType) !EndPointDef {
        var mia_Mesagho = try EndPointDef.initDefault(allocator);
        errdefer mia_Mesagho.deinit(allocator);


        while (it.next()) |tok| {
            if( equal(u8, tok, "}" ) ) break;
            const val = it.next() orelse return error.InvalidFormat;

            if( equal(u8, tok, "Host" ) ) {
                allocator.free(mia_Mesagho.Host);
                mia_Mesagho.Host = try allocator.dupe(u8, val);
                continue;
            }
            if( equal(u8, tok, "Port" ) ) {
                mia_Mesagho.Port =  std.fmt.parseInt(i32,val,10) catch 0;
                continue;
            }
        }

        return mia_Mesagho;
    }

    pub fn seriigiAlBin(self: *const EndPointDef, allocator: all.Allocator, b_formato: BinaraFormato) ![]const u8 {
        return try seriigiTiponAlBin(allocator, EndPointDef, self, b_formato);
    }

    pub fn seriigiAlDosiero(self: *const EndPointDef, allocator: all.Allocator, path: []const u8, b_formato: BinaraFormato) !void {
        return try seriigiTiponAlDosiero(allocator, EndPointDef, @as(*EndPointDef, self), path, b_formato);
    }

    fn seriigi(self: *const EndPointDef, allocator: all.Allocator, buffer: *EncodeBuffer) !usize {
 
        _ = allocator;
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

    pub fn deseriigiElBin(allocator: all.Allocator,input: []const u8, b_formato: BinaraFormato) !EndPointDef {
        return try deseriigiTiponElBin(allocator, EndPointDef, input, b_formato);
    }

    pub fn deseriigiElDosiero(allocator: all.Allocator, path: [:0]const u8, b_formato: BinaraFormato) !EndPointDef {
        return try deseriigiTiponElDosiero(allocator, EndPointDef, path, b_formato);
    }

    fn deseriigi(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !EndPointDef {
        var mia_Mesagho = try EndPointDef.initDefault(allocator);
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
                const tmp_Host = try buffer.decodeString(  try buffer.decodeVarint() );
                allocator.free(mia_Mesagho.Host);
                mia_Mesagho.Host = tmp_Host;
            }
            else if ( field_number == 2 and wire_type == 0 ) 
                mia_Mesagho.Port = try buffer.decodeInt32();
        }


        return mia_Mesagho;
    }
};    // EndPointDef

pub const CrossConnectorDef = struct {
    Transports: [][]const u8,

    pub fn initDefault(allocator: all.Allocator) !CrossConnectorDef {
        return CrossConnectorDef {
            .Transports = try allocator.alloc([]const u8, 0),
        };
    }

    pub fn deinit(self: *const CrossConnectorDef, allocator: all.Allocator) void {
        for (self.Transports) |item| {
            allocator.free(item);
        }
        allocator.free(self.Transports);
    }

    pub fn skribiAlTeksto(self: *CrossConnectorDef, allocator: all.Allocator, t_formato: TekstaFormato) ![]const u8 {
        return try skribiTiponAlTeksto(allocator, CrossConnectorDef, @as(*CrossConnectorDef, self), t_formato);
    }

    pub fn skribiAlDosiero(self: *CrossConnectorDef, allocator: all.Allocator, path: []const u8, t_formato: TekstaFormato) !void {
        try skribiTiponAlDosiero(allocator, CrossConnectorDef, @as(*CrossConnectorDef, self), path, t_formato);
    }

    pub fn legiElTeksto(allocator: all.Allocator, input: []const u8, t_formato: TekstaFormato) !CrossConnectorDef {
        return try legiTiponElTeksto(allocator, CrossConnectorDef, input, t_formato);
    }

    pub fn legiElDosiero(allocator: all.Allocator, path: []const u8, t_formato: TekstaFormato) !CrossConnectorDef {
        return try legiTiponElDosiero(allocator, CrossConnectorDef, path, t_formato);
    }

    fn skribiAlProtobufTeksto(self: *const CrossConnectorDef, allocator: all.Allocator,ind: []const u8) ![]const u8 {
        var bufro:std.ArrayList(u8)= .empty;

        for(self.Transports) |obj| {
            try bufro.print(allocator,"{s}Transports: \"{s}\"\n",.{ind, obj });
        }

        return bufro.toOwnedSlice(allocator);
    }

    fn legiElProtobufTeksto(allocator: all.Allocator, it: *TokenIterType) !CrossConnectorDef {
        var mia_Mesagho = try CrossConnectorDef.initDefault(allocator);
        errdefer mia_Mesagho.deinit(allocator);

        var Transports_list: std.ArrayList([]const u8) = .empty; 
        while (it.next()) |tok| {
            if( equal(u8, tok, "}" ) ) break;
            const val = it.next() orelse return error.InvalidFormat;

            if( equal(u8, tok, "Transports" ) ) {
                try Transports_list.append(allocator, allocator.dupe(u8, val) catch "");
                continue;
            }
        }
        for (mia_Mesagho.Transports) |item| {
            allocator.free(item);
        }
        allocator.free(mia_Mesagho.Transports);
        mia_Mesagho.Transports = try Transports_list.toOwnedSlice(allocator); 

        return mia_Mesagho;
    }

    pub fn seriigiAlBin(self: *const CrossConnectorDef, allocator: all.Allocator, b_formato: BinaraFormato) ![]const u8 {
        return try seriigiTiponAlBin(allocator, CrossConnectorDef, self, b_formato);
    }

    pub fn seriigiAlDosiero(self: *const CrossConnectorDef, allocator: all.Allocator, path: []const u8, b_formato: BinaraFormato) !void {
        return try seriigiTiponAlDosiero(allocator, CrossConnectorDef, @as(*CrossConnectorDef, self), path, b_formato);
    }

    fn seriigi(self: *const CrossConnectorDef, allocator: all.Allocator, buffer: *EncodeBuffer) !usize {
 
        _ = allocator;
        var tuta_longo: usize = 0;
 
        var Transports_i: usize = self.Transports.len;
        while (Transports_i > 0) {
            Transports_i -= 1;
            const item = self.Transports[Transports_i];
            const Transports_longa = try buffer.encodeString( item );
            tuta_longo += Transports_longa;
            tuta_longo += try buffer.encodeVarint(Transports_longa);
            tuta_longo += try buffer.encodeVarint(10);
        }  // 11  rept - no def - varlong

        return tuta_longo;
    }

    pub fn deseriigiElBin(allocator: all.Allocator,input: []const u8, b_formato: BinaraFormato) !CrossConnectorDef {
        return try deseriigiTiponElBin(allocator, CrossConnectorDef, input, b_formato);
    }

    pub fn deseriigiElDosiero(allocator: all.Allocator, path: [:0]const u8, b_formato: BinaraFormato) !CrossConnectorDef {
        return try deseriigiTiponElDosiero(allocator, CrossConnectorDef, path, b_formato);
    }

    fn deseriigi(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !CrossConnectorDef {
        var mia_Mesagho = try CrossConnectorDef.initDefault(allocator);
        errdefer mia_Mesagho.deinit(allocator);

        var end: usize = undefined;
        if (data_length) |val|
            end = buffer.read_index + val
        else
            end = buffer.buffer.len;

        var Transports_list: std.ArrayList([]const u8) = .empty; 

        while (buffer.read_index < end) {
            const key: u64 = buffer.decodeVarint() catch 0 ;    
            const wire_type = key & 0x7;  
            const field_number = key >> 3;

            if ( field_number == 1 and wire_type == 2 ) 
            { 
                try Transports_list.append( 
                    allocator, 
                    try buffer.decodeString(  try buffer.decodeVarint() )
                );
            }
        }

        const tmp_Transports = try Transports_list.toOwnedSlice(allocator);
        for (mia_Mesagho.Transports) |item| {
            allocator.free(item);
        }
        allocator.free(mia_Mesagho.Transports);
        mia_Mesagho.Transports = tmp_Transports;

        return mia_Mesagho;
    }
};    // CrossConnectorDef

    };   // Config
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
    var parsed_owned: ?[]u8 = null;
    defer {
        if (parsed_owned) |buf| {
            allocator.free(buf);
        }
    }

    switch (b_formato) {
        .BF_PROTOBUF => {
            parsed = input;
        },
        .BF_BASE64 => {
            const dec=std.base64.standard.Decoder;
            const base64_decoded_longo = try dec.calcSizeForSlice(input);
            const base64_decoded = try allocator.alloc(u8, base64_decoded_longo);

            parsed_owned = base64_decoded;

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
//            var it: TokenIterType = std.mem.tokenizeAny(u8, input, ":\", \n\r\t");
            var it: TokenIterType = TokenIterType.init( input);
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

/// Tokenizador sencillo para Protobuf Text.
/// - Devuelve slices prestados del buffer original.
/// - Los literales entre comillas se devuelven sin las comillas.
/// - No interpreta todavia escapes como \\n, \\x01 o \\001.
/// - Reconoce { } < > [ ] como tokens independientes.
/// - Ignora espacios, :, ',', ';' y comentarios iniciados por #.
pub const CustomTokenizer = struct {
    buffer: []const u8,
    index: usize,
    const Self = @This();

    pub fn init(buffer: []const u8) Self {
        return .{ .buffer = buffer, .index = 0, };
    }

    pub fn peek(self: Self) ?[]const u8 {
        var copy = self;
        return copy.next();
    }

    /// El slice devuelto apunta directamente al buffer original.
    pub fn next(self: *Self) ?[]const u8 {
        self.skipIgnored();
        if (self.index >= self.buffer.len) { return null; }

        const current = self.buffer[self.index];
        if (current == '"' or current == '\'') { return self.readQuotedToken(); }
        if (isStructuralToken(current)) {
            const start = self.index;
            self.index += 1;
            return self.buffer[start..self.index];
        }
        return self.readBareToken();
    }

    fn skipIgnored(self: *Self) void {
        while (self.index < self.buffer.len) {
            const current = self.buffer[self.index];

            if (isDelimiter(current)) {
                self.index += 1;
                continue;
            }
            if (current == '#') {
                self.skipComment();
                continue;
            }
            break;
        }
    }
    fn skipComment(self: *Self) void {
        while (
            self.index < self.buffer.len and
            self.buffer[self.index] != '\n'
        ) {  self.index += 1; }
    }

    fn readQuotedToken(self: *Self) ?[]const u8 {
        const quote = self.buffer[self.index];

        self.index += 1;
        const content_start = self.index;

        while (self.index < self.buffer.len) {
            const current = self.buffer[self.index];

            if (current == '\\') {
                self.index += 1;
                if (self.index < self.buffer.len) { self.index += 1; }
                continue;
            }
            if (current == quote) {
                const content_end = self.index;
                self.index += 1;
                return self.buffer[content_start..content_end];
            }
            if (current == '\n' or current == '\r') { return null; }
            self.index += 1;
        }
        return null;
    }

    fn readBareToken(self: *Self) ?[]const u8 {
        const start = self.index;

        while (self.index < self.buffer.len) {
            const current = self.buffer[self.index];

            if (
                isDelimiter(current) or
                isStructuralToken(current) or
                current == '"' or
                current == '\'' or
                current == '#'
            ) { break; }
            self.index += 1;
        }
        if (self.index == start) { return null; }

        return self.buffer[start..self.index];
    }

    fn isDelimiter(c: u8) bool {
        return switch (c) {
            ' ', '\t', '\n', '\r', ':', ',', ';' => true,
            else => false,
        };
    }

    fn isStructuralToken(c: u8) bool {
        return switch (c) {
            '{', '}', '<', '>', '[', ']' => true,
            else => false,
        };
    }
};

