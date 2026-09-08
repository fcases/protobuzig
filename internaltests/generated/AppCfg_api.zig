// ============================================================================
// AppCfg_api.zig
// ============================================================================
//
// Fichero generado por ProtobuZig / kgenapi.zig.
//
// Proto base:
//   AppCfg
//
// Raw generado:
//   AppCfg.zig
//
// Este fichero contiene wrappers/API segura sobre el raw generado.
//
// Fase intermedia:
//   - el fichero raw mantiene los tipos actuales.
//   - este fichero genera wrappers seguros encima.
//
// Fase final posible:
//   - el fichero raw pasara a *_impl.zig.
//   - este fichero o su equivalente pasara a ser la API publica principal.
//
// No editar a mano salvo para depuracion.
// ============================================================================

const std = @import("std");

const RawFile = @import("AppCfg.zig");

pub const TekstaFormato = RawFile.TekstaFormato;
pub const BinaraFormato = RawFile.BinaraFormato;

// Alias al namespace raw generado.
// En fase intermedia apunta al package actual del fichero raw.
const Raw = RawFile.ProtocolBus.Config;

// Alias intencionadamente llamado *_impl aunque en fase intermedia
// apunte al namespace raw actual.
//
// Fase intermedia:
//   const AppCfg_impl = Raw;
//
// Fase final:
//   const AppCfg_impl = RawFile.<package>_impl;

const AppCfg_impl = Raw;

// ============================================================================
// API SEGURA
// ============================================================================
//
// Objetivo:
//
//   - ocultar el acceso directo a campos owned siempre que sea posible.
//   - exponer setters/builders/getters controlados.
//   - ofrecer nombres publicos en ingles para operaciones generales:
//       serializeToBin
//       deserializeFromBin
//       writeToText
//       readFromText
//
// Reglas previstas:
//
//   - append de repeated message hace copia profunda.
//   - no se expone appendOwned como API publica inicial.
//   - getXAt(index) devuelve copia owned.
//   - el usuario debe llamar deinit() sobre copias devueltas.
//   - no se exponen slices repeated internos como API principal.
//

// ============================================================================
// ALIASES INTERNOS A TIPOS RAW / IMPL
// ============================================================================
//
// Estos aliases permiten que el cuerpo de los wrappers no dependa de si
// estamos en fase intermedia o fase final.
//
// Fase intermedia:
//   EstMeteoImpl = cctrol_impl.EstMeteo
//
// Fase final:
//   EstMeteoImpl = cctrol_impl.EstMeteo_impl
//
const AppConfigImpl = AppCfg_impl.AppConfig;
const DomainCfgImpl = AppCfg_impl.DomainCfg;
const TransportDefImpl = AppCfg_impl.TransportDef;
const MCastDefConfigImpl = AppCfg_impl.MCastDefConfig;
const BCastDefConfigImpl = AppCfg_impl.BCastDefConfig;
const UDPStarDefConfigImpl = AppCfg_impl.UDPStarDefConfig;
const EndPointDefImpl = AppCfg_impl.EndPointDef;
const CrossConnectorDefImpl = AppCfg_impl.CrossConnectorDef;

// ============================================================================
// HELPERS PRIVADOS DE COPIA PROFUNDA
// ============================================================================
//
// cloneImpl() realiza una copia profunda usando el camino binario generado.
//
// Estrategia inicial:
//
//   clone = seriigiAlBin(.BF_PROTOBUF) + deseriigiElBin(.BF_PROTOBUF)
//
// Esta version prioriza simplicidad y seguridad de ownership.
// Si seriigi/deseriigi tiene un bug, debe corregirse en ProtobuZig,
// porque afecta tambien al uso normal de mensajes en K6Bus.
//

fn cloneImpl(comptime T: type, allocator: std.mem.Allocator, src: *const T) !T {
    const bytes = try src.seriigiAlBin(allocator, .BF_PROTOBUF);
    defer allocator.free(bytes);

    return try T.deseriigiElBin(allocator, bytes, .BF_PROTOBUF);
}

// ============================================================================
// WRAPPERS PUBLICOS
// ============================================================================
//
// De momento cada wrapper solo contiene:
//
//   impl: TipoImpl
//
// En los siguientes pasos se generaran:
//
//   - initDefault()
//   - deinit()
//   - serializeToBin()
//   - deserializeFromBin()
//   - writeToText()
//   - readFromText()
//   - setters/getters/builders seguros
//
pub const AppConfig = struct {
    impl: AppConfigImpl,

    const Self = @This();

    pub fn initDefault(allocator: std.mem.Allocator) !Self {
        return .{
            .impl = try AppConfigImpl.initDefault(allocator),
        };
    }

    pub fn deinit(self: *const Self, allocator: std.mem.Allocator) void {
        self.impl.deinit(allocator);
    }

    pub fn clone(self: *const Self, allocator: std.mem.Allocator) !Self {
        return .{
            .impl = try cloneImpl(
                AppConfigImpl,
                allocator,
                &self.impl,
            ),
        };
    }

    pub fn setActivateTrace(self: *Self, value: bool) void {
        self.impl.ActivateTrace = value;
    }

    pub fn getActivateTrace(self: *const Self) ?bool {
        return self.impl.ActivateTrace;
    }

    pub fn hasActivateTrace(self: *const Self) bool {
        return self.impl.ActivateTrace != null;
    }

    pub fn clearActivateTrace(self: *Self) void {
        self.impl.ActivateTrace = null;
    }

    pub fn setTraceLevel(self: *Self, value: i32) void {
        self.impl.TraceLevel = value;
    }

    pub fn getTraceLevel(self: *const Self) ?i32 {
        return self.impl.TraceLevel;
    }

    pub fn hasTraceLevel(self: *const Self) bool {
        return self.impl.TraceLevel != null;
    }

    pub fn clearTraceLevel(self: *Self) void {
        self.impl.TraceLevel = null;
    }

    pub fn getDomainsCount(self: *const Self) usize {
        return self.impl.Domains.len;
    }

    pub fn getDomainsAt(self: *const Self, allocator: std.mem.Allocator, index: usize) !DomainCfg {
        if (index >= self.impl.Domains.len) {
            return error.IndexOutOfBounds;
        }

        return .{
            .impl = try cloneImpl(
                DomainCfgImpl,
                allocator,
                &self.impl.Domains[index],
            ),
        };
    }

    pub fn appendDomains(self: *Self, allocator: std.mem.Allocator, value: *const DomainCfg) !void {
        const tmp_item = try cloneImpl(
            DomainCfgImpl,
            allocator,
            &value.impl,
        );
        errdefer tmp_item.deinit(allocator);

        const old_len = self.impl.Domains.len;
        self.impl.Domains = try allocator.realloc(
            self.impl.Domains,
            old_len + 1,
        );

        self.impl.Domains[old_len] = tmp_item;
    }

    pub fn clearDomains(self: *Self, allocator: std.mem.Allocator) !void {
        for (self.impl.Domains) |*item| {
            item.deinit(allocator);
        }
        allocator.free(self.impl.Domains);
        self.impl.Domains = try allocator.alloc(DomainCfgImpl, 0);
    }

    pub fn writeToText(
        self: *Self,
        allocator: std.mem.Allocator,
        format: TekstaFormato,
    ) ![]const u8 {
        return try self.impl.skribiAlTeksto(
            allocator,
            format,
        );
    }

    pub fn writeToFile(
        self: *Self,
        allocator: std.mem.Allocator,
        path: []const u8,
        format: TekstaFormato,
    ) !void {
        try self.impl.skribiAlDosiero(
            allocator,
            path,
            format,
        );
    }

    pub fn readFromText(
        allocator: std.mem.Allocator,
        input: []const u8,
        format: TekstaFormato,
    ) !Self {
        return .{
            .impl = try AppConfigImpl.legiElTeksto(
                allocator,
                input,
                format,
            ),
        };
    }

    pub fn readFromFile(
        allocator: std.mem.Allocator,
        path: []const u8,
        format: TekstaFormato,
    ) !Self {
        return .{
            .impl = try AppConfigImpl.legiElDosiero(
                allocator,
                path,
                format,
            ),
        };
    }

    pub fn serializeToBin(
        self: *const Self,
        allocator: std.mem.Allocator,
        format: BinaraFormato,
    ) ![]const u8 {
        return try self.impl.seriigiAlBin(
            allocator,
            format,
        );
    }

    pub fn serializeToFile(
        self: *const Self,
        allocator: std.mem.Allocator,
        path: []const u8,
        format: BinaraFormato,
    ) !void {
        try self.impl.seriigiAlDosiero(
            allocator,
            path,
            format,
        );
    }

    pub fn deserializeFromBin(
        allocator: std.mem.Allocator,
        input: []const u8,
        format: BinaraFormato,
    ) !Self {
        return .{
            .impl = try AppConfigImpl.deseriigiElBin(
                allocator,
                input,
                format,
            ),
        };
    }

    pub fn deserializeFromFile(
        allocator: std.mem.Allocator,
        path: [:0]const u8,
        format: BinaraFormato,
    ) !Self {
        return .{
            .impl = try AppConfigImpl.deseriigiElDosiero(
                allocator,
                path,
                format,
            ),
        };
    }
};

pub const DomainCfg = struct {
    impl: DomainCfgImpl,

    const Self = @This();

    pub fn initDefault(allocator: std.mem.Allocator) !Self {
        return .{
            .impl = try DomainCfgImpl.initDefault(allocator),
        };
    }

    pub fn deinit(self: *const Self, allocator: std.mem.Allocator) void {
        self.impl.deinit(allocator);
    }

    pub fn clone(self: *const Self, allocator: std.mem.Allocator) !Self {
        return .{
            .impl = try cloneImpl(
                DomainCfgImpl,
                allocator,
                &self.impl,
            ),
        };
    }

    pub fn setId(self: *Self, value: i32) void {
        self.impl.Id = value;
    }

    pub fn getId(self: *const Self) i32 {
        return self.impl.Id;
    }

    pub fn setActivateDefaultTransport(self: *Self, value: bool) void {
        self.impl.ActivateDefaultTransport = value;
    }

    pub fn getActivateDefaultTransport(self: *const Self) bool {
        return self.impl.ActivateDefaultTransport;
    }

    pub fn setDirectDispacthToSubs(self: *Self, value: bool) void {
        self.impl.DirectDispacthToSubs = value;
    }

    pub fn getDirectDispacthToSubs(self: *const Self) ?bool {
        return self.impl.DirectDispacthToSubs;
    }

    pub fn hasDirectDispacthToSubs(self: *const Self) bool {
        return self.impl.DirectDispacthToSubs != null;
    }

    pub fn clearDirectDispacthToSubs(self: *Self) void {
        self.impl.DirectDispacthToSubs = null;
    }

    pub fn setKeyFile(self: *Self, allocator: std.mem.Allocator, value: []const u8) !void {
        const tmp = try allocator.dupe(u8, value);

        if (self.impl.KeyFile) |old| {
            allocator.free(old);
        }

        self.impl.KeyFile = tmp;
    }

    pub fn getKeyFile(self: *const Self) ?[]const u8 {
        return self.impl.KeyFile;
    }

    pub fn hasKeyFile(self: *const Self) bool {
        return self.impl.KeyFile != null;
    }

    pub fn clearKeyFile(self: *Self, allocator: std.mem.Allocator) void {
        if (self.impl.KeyFile) |old| {
            allocator.free(old);
        }

        self.impl.KeyFile = null;
    }

    pub fn setCrossConnector(self: *Self, allocator: std.mem.Allocator, value: *const CrossConnectorDef) !void {
        const tmp = try cloneImpl(CrossConnectorDefImpl, allocator, &value.impl);

        if (self.impl.CrossConnector) |*old| {
            old.deinit(allocator);
        }

        self.impl.CrossConnector = tmp;
    }

    pub fn hasCrossConnector(self: *const Self) bool {
        return self.impl.CrossConnector != null;
    }

    pub fn getCrossConnector(self: *const Self, allocator: std.mem.Allocator) !CrossConnectorDef {
        if (self.impl.CrossConnector) |*value| {
            return .{
                .impl = try cloneImpl(
                    CrossConnectorDefImpl,
                    allocator,
                    value,
                ),
            };
        }

        return error.MissingField;
    }

    pub fn clearCrossConnector(self: *Self, allocator: std.mem.Allocator) void {
        if (self.impl.CrossConnector) |*old| {
            old.deinit(allocator);
        }

        self.impl.CrossConnector = null;
    }

    pub fn getTransportsCount(self: *const Self) usize {
        return self.impl.Transports.len;
    }

    pub fn getTransportsAt(self: *const Self, allocator: std.mem.Allocator, index: usize) !TransportDef {
        if (index >= self.impl.Transports.len) {
            return error.IndexOutOfBounds;
        }

        return .{
            .impl = try cloneImpl(
                TransportDefImpl,
                allocator,
                &self.impl.Transports[index],
            ),
        };
    }

    pub fn appendTransports(self: *Self, allocator: std.mem.Allocator, value: *const TransportDef) !void {
        const tmp_item = try cloneImpl(
            TransportDefImpl,
            allocator,
            &value.impl,
        );
        errdefer tmp_item.deinit(allocator);

        const old_len = self.impl.Transports.len;
        self.impl.Transports = try allocator.realloc(
            self.impl.Transports,
            old_len + 1,
        );

        self.impl.Transports[old_len] = tmp_item;
    }

    pub fn clearTransports(self: *Self, allocator: std.mem.Allocator) !void {
        for (self.impl.Transports) |*item| {
            item.deinit(allocator);
        }
        allocator.free(self.impl.Transports);
        self.impl.Transports = try allocator.alloc(TransportDefImpl, 0);
    }

    pub fn writeToText(
        self: *Self,
        allocator: std.mem.Allocator,
        format: TekstaFormato,
    ) ![]const u8 {
        return try self.impl.skribiAlTeksto(
            allocator,
            format,
        );
    }

    pub fn writeToFile(
        self: *Self,
        allocator: std.mem.Allocator,
        path: []const u8,
        format: TekstaFormato,
    ) !void {
        try self.impl.skribiAlDosiero(
            allocator,
            path,
            format,
        );
    }

    pub fn readFromText(
        allocator: std.mem.Allocator,
        input: []const u8,
        format: TekstaFormato,
    ) !Self {
        return .{
            .impl = try DomainCfgImpl.legiElTeksto(
                allocator,
                input,
                format,
            ),
        };
    }

    pub fn readFromFile(
        allocator: std.mem.Allocator,
        path: []const u8,
        format: TekstaFormato,
    ) !Self {
        return .{
            .impl = try DomainCfgImpl.legiElDosiero(
                allocator,
                path,
                format,
            ),
        };
    }

    pub fn serializeToBin(
        self: *const Self,
        allocator: std.mem.Allocator,
        format: BinaraFormato,
    ) ![]const u8 {
        return try self.impl.seriigiAlBin(
            allocator,
            format,
        );
    }

    pub fn serializeToFile(
        self: *const Self,
        allocator: std.mem.Allocator,
        path: []const u8,
        format: BinaraFormato,
    ) !void {
        try self.impl.seriigiAlDosiero(
            allocator,
            path,
            format,
        );
    }

    pub fn deserializeFromBin(
        allocator: std.mem.Allocator,
        input: []const u8,
        format: BinaraFormato,
    ) !Self {
        return .{
            .impl = try DomainCfgImpl.deseriigiElBin(
                allocator,
                input,
                format,
            ),
        };
    }

    pub fn deserializeFromFile(
        allocator: std.mem.Allocator,
        path: [:0]const u8,
        format: BinaraFormato,
    ) !Self {
        return .{
            .impl = try DomainCfgImpl.deseriigiElDosiero(
                allocator,
                path,
                format,
            ),
        };
    }
};

pub const TransportDef = struct {
    impl: TransportDefImpl,

    const Self = @This();

    pub fn initDefault(allocator: std.mem.Allocator) !Self {
        return .{
            .impl = try TransportDefImpl.initDefault(allocator),
        };
    }

    pub fn deinit(self: *const Self, allocator: std.mem.Allocator) void {
        self.impl.deinit(allocator);
    }

    pub fn clone(self: *const Self, allocator: std.mem.Allocator) !Self {
        return .{
            .impl = try cloneImpl(
                TransportDefImpl,
                allocator,
                &self.impl,
            ),
        };
    }

    pub fn setReceiveOwnMsgs(self: *Self, value: bool) void {
        self.impl.ReceiveOwnMsgs = value;
    }

    pub fn getReceiveOwnMsgs(self: *const Self) ?bool {
        return self.impl.ReceiveOwnMsgs;
    }

    pub fn hasReceiveOwnMsgs(self: *const Self) bool {
        return self.impl.ReceiveOwnMsgs != null;
    }

    pub fn clearReceiveOwnMsgs(self: *Self) void {
        self.impl.ReceiveOwnMsgs = null;
    }

    pub fn setTransportName(
        self: *Self,
        allocator: std.mem.Allocator,
        value: []const u8,
    ) !void {
        const tmp = try allocator.dupe(u8, value);
        allocator.free(self.impl.TransportName);
        self.impl.TransportName = tmp;
    }

    pub fn getTransportName(self: *const Self) []const u8 {
        return self.impl.TransportName;
    }

    pub fn setDllImport(
        self: *Self,
        allocator: std.mem.Allocator,
        value: []const u8,
    ) !void {
        const tmp = try allocator.dupe(u8, value);
        allocator.free(self.impl.DllImport);
        self.impl.DllImport = tmp;
    }

    pub fn getDllImport(self: *const Self) []const u8 {
        return self.impl.DllImport;
    }

    pub fn setTransportClass(
        self: *Self,
        allocator: std.mem.Allocator,
        value: []const u8,
    ) !void {
        const tmp = try allocator.dupe(u8, value);
        allocator.free(self.impl.TransportClass);
        self.impl.TransportClass = tmp;
    }

    pub fn getTransportClass(self: *const Self) []const u8 {
        return self.impl.TransportClass;
    }

    pub fn setMCastParams(self: *Self, allocator: std.mem.Allocator, value: *const MCastDefConfig) !void {
        const tmp = try cloneImpl(MCastDefConfigImpl, allocator, &value.impl);

        if (self.impl.MCastParams) |*old| {
            old.deinit(allocator);
        }

        self.impl.MCastParams = tmp;
    }

    pub fn hasMCastParams(self: *const Self) bool {
        return self.impl.MCastParams != null;
    }

    pub fn getMCastParams(self: *const Self, allocator: std.mem.Allocator) !MCastDefConfig {
        if (self.impl.MCastParams) |*value| {
            return .{
                .impl = try cloneImpl(
                    MCastDefConfigImpl,
                    allocator,
                    value,
                ),
            };
        }

        return error.MissingField;
    }

    pub fn clearMCastParams(self: *Self, allocator: std.mem.Allocator) void {
        if (self.impl.MCastParams) |*old| {
            old.deinit(allocator);
        }

        self.impl.MCastParams = null;
    }

    pub fn setBCastParams(self: *Self, allocator: std.mem.Allocator, value: *const BCastDefConfig) !void {
        const tmp = try cloneImpl(BCastDefConfigImpl, allocator, &value.impl);

        if (self.impl.BCastParams) |*old| {
            old.deinit(allocator);
        }

        self.impl.BCastParams = tmp;
    }

    pub fn hasBCastParams(self: *const Self) bool {
        return self.impl.BCastParams != null;
    }

    pub fn getBCastParams(self: *const Self, allocator: std.mem.Allocator) !BCastDefConfig {
        if (self.impl.BCastParams) |*value| {
            return .{
                .impl = try cloneImpl(
                    BCastDefConfigImpl,
                    allocator,
                    value,
                ),
            };
        }

        return error.MissingField;
    }

    pub fn clearBCastParams(self: *Self, allocator: std.mem.Allocator) void {
        if (self.impl.BCastParams) |*old| {
            old.deinit(allocator);
        }

        self.impl.BCastParams = null;
    }

    pub fn setUDPStarParams(self: *Self, allocator: std.mem.Allocator, value: *const UDPStarDefConfig) !void {
        const tmp = try cloneImpl(UDPStarDefConfigImpl, allocator, &value.impl);

        if (self.impl.UDPStarParams) |*old| {
            old.deinit(allocator);
        }

        self.impl.UDPStarParams = tmp;
    }

    pub fn hasUDPStarParams(self: *const Self) bool {
        return self.impl.UDPStarParams != null;
    }

    pub fn getUDPStarParams(self: *const Self, allocator: std.mem.Allocator) !UDPStarDefConfig {
        if (self.impl.UDPStarParams) |*value| {
            return .{
                .impl = try cloneImpl(
                    UDPStarDefConfigImpl,
                    allocator,
                    value,
                ),
            };
        }

        return error.MissingField;
    }

    pub fn clearUDPStarParams(self: *Self, allocator: std.mem.Allocator) void {
        if (self.impl.UDPStarParams) |*old| {
            old.deinit(allocator);
        }

        self.impl.UDPStarParams = null;
    }

    pub fn writeToText(
        self: *Self,
        allocator: std.mem.Allocator,
        format: TekstaFormato,
    ) ![]const u8 {
        return try self.impl.skribiAlTeksto(
            allocator,
            format,
        );
    }

    pub fn writeToFile(
        self: *Self,
        allocator: std.mem.Allocator,
        path: []const u8,
        format: TekstaFormato,
    ) !void {
        try self.impl.skribiAlDosiero(
            allocator,
            path,
            format,
        );
    }

    pub fn readFromText(
        allocator: std.mem.Allocator,
        input: []const u8,
        format: TekstaFormato,
    ) !Self {
        return .{
            .impl = try TransportDefImpl.legiElTeksto(
                allocator,
                input,
                format,
            ),
        };
    }

    pub fn readFromFile(
        allocator: std.mem.Allocator,
        path: []const u8,
        format: TekstaFormato,
    ) !Self {
        return .{
            .impl = try TransportDefImpl.legiElDosiero(
                allocator,
                path,
                format,
            ),
        };
    }

    pub fn serializeToBin(
        self: *const Self,
        allocator: std.mem.Allocator,
        format: BinaraFormato,
    ) ![]const u8 {
        return try self.impl.seriigiAlBin(
            allocator,
            format,
        );
    }

    pub fn serializeToFile(
        self: *const Self,
        allocator: std.mem.Allocator,
        path: []const u8,
        format: BinaraFormato,
    ) !void {
        try self.impl.seriigiAlDosiero(
            allocator,
            path,
            format,
        );
    }

    pub fn deserializeFromBin(
        allocator: std.mem.Allocator,
        input: []const u8,
        format: BinaraFormato,
    ) !Self {
        return .{
            .impl = try TransportDefImpl.deseriigiElBin(
                allocator,
                input,
                format,
            ),
        };
    }

    pub fn deserializeFromFile(
        allocator: std.mem.Allocator,
        path: [:0]const u8,
        format: BinaraFormato,
    ) !Self {
        return .{
            .impl = try TransportDefImpl.deseriigiElDosiero(
                allocator,
                path,
                format,
            ),
        };
    }
};

pub const MCastDefConfig = struct {
    impl: MCastDefConfigImpl,

    const Self = @This();

    pub fn initDefault(allocator: std.mem.Allocator) !Self {
        return .{
            .impl = try MCastDefConfigImpl.initDefault(allocator),
        };
    }

    pub fn deinit(self: *const Self, allocator: std.mem.Allocator) void {
        self.impl.deinit(allocator);
    }

    pub fn clone(self: *const Self, allocator: std.mem.Allocator) !Self {
        return .{
            .impl = try cloneImpl(
                MCastDefConfigImpl,
                allocator,
                &self.impl,
            ),
        };
    }

    pub fn setPort(self: *Self, value: i32) void {
        self.impl.Port = value;
    }

    pub fn getPort(self: *const Self) i32 {
        return self.impl.Port;
    }

    pub fn setTTL(self: *Self, value: i32) void {
        self.impl.TTL = value;
    }

    pub fn getTTL(self: *const Self) ?i32 {
        return self.impl.TTL;
    }

    pub fn hasTTL(self: *const Self) bool {
        return self.impl.TTL != null;
    }

    pub fn clearTTL(self: *Self) void {
        self.impl.TTL = null;
    }

    pub fn setReceiveBuffer(self: *Self, value: i32) void {
        self.impl.ReceiveBuffer = value;
    }

    pub fn getReceiveBuffer(self: *const Self) ?i32 {
        return self.impl.ReceiveBuffer;
    }

    pub fn hasReceiveBuffer(self: *const Self) bool {
        return self.impl.ReceiveBuffer != null;
    }

    pub fn clearReceiveBuffer(self: *Self) void {
        self.impl.ReceiveBuffer = null;
    }

    pub fn setSendBuffer(self: *Self, value: i32) void {
        self.impl.SendBuffer = value;
    }

    pub fn getSendBuffer(self: *const Self) ?i32 {
        return self.impl.SendBuffer;
    }

    pub fn hasSendBuffer(self: *const Self) bool {
        return self.impl.SendBuffer != null;
    }

    pub fn clearSendBuffer(self: *Self) void {
        self.impl.SendBuffer = null;
    }

    pub fn setLocalAddress(
        self: *Self,
        allocator: std.mem.Allocator,
        value: []const u8,
    ) !void {
        const tmp = try allocator.dupe(u8, value);
        allocator.free(self.impl.LocalAddress);
        self.impl.LocalAddress = tmp;
    }

    pub fn getLocalAddress(self: *const Self) []const u8 {
        return self.impl.LocalAddress;
    }

    pub fn setMCastAddress(
        self: *Self,
        allocator: std.mem.Allocator,
        value: []const u8,
    ) !void {
        const tmp = try allocator.dupe(u8, value);
        allocator.free(self.impl.MCastAddress);
        self.impl.MCastAddress = tmp;
    }

    pub fn getMCastAddress(self: *const Self) []const u8 {
        return self.impl.MCastAddress;
    }

    pub fn writeToText(
        self: *Self,
        allocator: std.mem.Allocator,
        format: TekstaFormato,
    ) ![]const u8 {
        return try self.impl.skribiAlTeksto(
            allocator,
            format,
        );
    }

    pub fn writeToFile(
        self: *Self,
        allocator: std.mem.Allocator,
        path: []const u8,
        format: TekstaFormato,
    ) !void {
        try self.impl.skribiAlDosiero(
            allocator,
            path,
            format,
        );
    }

    pub fn readFromText(
        allocator: std.mem.Allocator,
        input: []const u8,
        format: TekstaFormato,
    ) !Self {
        return .{
            .impl = try MCastDefConfigImpl.legiElTeksto(
                allocator,
                input,
                format,
            ),
        };
    }

    pub fn readFromFile(
        allocator: std.mem.Allocator,
        path: []const u8,
        format: TekstaFormato,
    ) !Self {
        return .{
            .impl = try MCastDefConfigImpl.legiElDosiero(
                allocator,
                path,
                format,
            ),
        };
    }

    pub fn serializeToBin(
        self: *const Self,
        allocator: std.mem.Allocator,
        format: BinaraFormato,
    ) ![]const u8 {
        return try self.impl.seriigiAlBin(
            allocator,
            format,
        );
    }

    pub fn serializeToFile(
        self: *const Self,
        allocator: std.mem.Allocator,
        path: []const u8,
        format: BinaraFormato,
    ) !void {
        try self.impl.seriigiAlDosiero(
            allocator,
            path,
            format,
        );
    }

    pub fn deserializeFromBin(
        allocator: std.mem.Allocator,
        input: []const u8,
        format: BinaraFormato,
    ) !Self {
        return .{
            .impl = try MCastDefConfigImpl.deseriigiElBin(
                allocator,
                input,
                format,
            ),
        };
    }

    pub fn deserializeFromFile(
        allocator: std.mem.Allocator,
        path: [:0]const u8,
        format: BinaraFormato,
    ) !Self {
        return .{
            .impl = try MCastDefConfigImpl.deseriigiElDosiero(
                allocator,
                path,
                format,
            ),
        };
    }
};

pub const BCastDefConfig = struct {
    impl: BCastDefConfigImpl,

    const Self = @This();

    pub fn initDefault(allocator: std.mem.Allocator) !Self {
        return .{
            .impl = try BCastDefConfigImpl.initDefault(allocator),
        };
    }

    pub fn deinit(self: *const Self, allocator: std.mem.Allocator) void {
        self.impl.deinit(allocator);
    }

    pub fn clone(self: *const Self, allocator: std.mem.Allocator) !Self {
        return .{
            .impl = try cloneImpl(
                BCastDefConfigImpl,
                allocator,
                &self.impl,
            ),
        };
    }

    pub fn setPort(self: *Self, value: i32) void {
        self.impl.Port = value;
    }

    pub fn getPort(self: *const Self) i32 {
        return self.impl.Port;
    }

    pub fn setReceiveBuffer(self: *Self, value: i32) void {
        self.impl.ReceiveBuffer = value;
    }

    pub fn getReceiveBuffer(self: *const Self) ?i32 {
        return self.impl.ReceiveBuffer;
    }

    pub fn hasReceiveBuffer(self: *const Self) bool {
        return self.impl.ReceiveBuffer != null;
    }

    pub fn clearReceiveBuffer(self: *Self) void {
        self.impl.ReceiveBuffer = null;
    }

    pub fn setSendBuffer(self: *Self, value: i32) void {
        self.impl.SendBuffer = value;
    }

    pub fn getSendBuffer(self: *const Self) ?i32 {
        return self.impl.SendBuffer;
    }

    pub fn hasSendBuffer(self: *const Self) bool {
        return self.impl.SendBuffer != null;
    }

    pub fn clearSendBuffer(self: *Self) void {
        self.impl.SendBuffer = null;
    }

    pub fn setLocalAddress(
        self: *Self,
        allocator: std.mem.Allocator,
        value: []const u8,
    ) !void {
        const tmp = try allocator.dupe(u8, value);
        allocator.free(self.impl.LocalAddress);
        self.impl.LocalAddress = tmp;
    }

    pub fn getLocalAddress(self: *const Self) []const u8 {
        return self.impl.LocalAddress;
    }

    pub fn setBCastAddress(
        self: *Self,
        allocator: std.mem.Allocator,
        value: []const u8,
    ) !void {
        const tmp = try allocator.dupe(u8, value);
        allocator.free(self.impl.BCastAddress);
        self.impl.BCastAddress = tmp;
    }

    pub fn getBCastAddress(self: *const Self) []const u8 {
        return self.impl.BCastAddress;
    }

    pub fn writeToText(
        self: *Self,
        allocator: std.mem.Allocator,
        format: TekstaFormato,
    ) ![]const u8 {
        return try self.impl.skribiAlTeksto(
            allocator,
            format,
        );
    }

    pub fn writeToFile(
        self: *Self,
        allocator: std.mem.Allocator,
        path: []const u8,
        format: TekstaFormato,
    ) !void {
        try self.impl.skribiAlDosiero(
            allocator,
            path,
            format,
        );
    }

    pub fn readFromText(
        allocator: std.mem.Allocator,
        input: []const u8,
        format: TekstaFormato,
    ) !Self {
        return .{
            .impl = try BCastDefConfigImpl.legiElTeksto(
                allocator,
                input,
                format,
            ),
        };
    }

    pub fn readFromFile(
        allocator: std.mem.Allocator,
        path: []const u8,
        format: TekstaFormato,
    ) !Self {
        return .{
            .impl = try BCastDefConfigImpl.legiElDosiero(
                allocator,
                path,
                format,
            ),
        };
    }

    pub fn serializeToBin(
        self: *const Self,
        allocator: std.mem.Allocator,
        format: BinaraFormato,
    ) ![]const u8 {
        return try self.impl.seriigiAlBin(
            allocator,
            format,
        );
    }

    pub fn serializeToFile(
        self: *const Self,
        allocator: std.mem.Allocator,
        path: []const u8,
        format: BinaraFormato,
    ) !void {
        try self.impl.seriigiAlDosiero(
            allocator,
            path,
            format,
        );
    }

    pub fn deserializeFromBin(
        allocator: std.mem.Allocator,
        input: []const u8,
        format: BinaraFormato,
    ) !Self {
        return .{
            .impl = try BCastDefConfigImpl.deseriigiElBin(
                allocator,
                input,
                format,
            ),
        };
    }

    pub fn deserializeFromFile(
        allocator: std.mem.Allocator,
        path: [:0]const u8,
        format: BinaraFormato,
    ) !Self {
        return .{
            .impl = try BCastDefConfigImpl.deseriigiElDosiero(
                allocator,
                path,
                format,
            ),
        };
    }
};

pub const UDPStarDefConfig = struct {
    impl: UDPStarDefConfigImpl,

    const Self = @This();

    pub fn initDefault(allocator: std.mem.Allocator) !Self {
        return .{
            .impl = try UDPStarDefConfigImpl.initDefault(allocator),
        };
    }

    pub fn deinit(self: *const Self, allocator: std.mem.Allocator) void {
        self.impl.deinit(allocator);
    }

    pub fn clone(self: *const Self, allocator: std.mem.Allocator) !Self {
        return .{
            .impl = try cloneImpl(
                UDPStarDefConfigImpl,
                allocator,
                &self.impl,
            ),
        };
    }

    pub fn setPort(self: *Self, value: i32) void {
        self.impl.Port = value;
    }

    pub fn getPort(self: *const Self) i32 {
        return self.impl.Port;
    }

    pub fn setReceiveBuffer(self: *Self, value: i32) void {
        self.impl.ReceiveBuffer = value;
    }

    pub fn getReceiveBuffer(self: *const Self) ?i32 {
        return self.impl.ReceiveBuffer;
    }

    pub fn hasReceiveBuffer(self: *const Self) bool {
        return self.impl.ReceiveBuffer != null;
    }

    pub fn clearReceiveBuffer(self: *Self) void {
        self.impl.ReceiveBuffer = null;
    }

    pub fn setSendBuffer(self: *Self, value: i32) void {
        self.impl.SendBuffer = value;
    }

    pub fn getSendBuffer(self: *const Self) ?i32 {
        return self.impl.SendBuffer;
    }

    pub fn hasSendBuffer(self: *const Self) bool {
        return self.impl.SendBuffer != null;
    }

    pub fn clearSendBuffer(self: *Self) void {
        self.impl.SendBuffer = null;
    }

    pub fn setLocalAddress(
        self: *Self,
        allocator: std.mem.Allocator,
        value: []const u8,
    ) !void {
        const tmp = try allocator.dupe(u8, value);
        allocator.free(self.impl.LocalAddress);
        self.impl.LocalAddress = tmp;
    }

    pub fn getLocalAddress(self: *const Self) []const u8 {
        return self.impl.LocalAddress;
    }

    pub fn getEndPointCount(self: *const Self) usize {
        return self.impl.EndPoint.len;
    }

    pub fn getEndPointAt(self: *const Self, allocator: std.mem.Allocator, index: usize) !EndPointDef {
        if (index >= self.impl.EndPoint.len) {
            return error.IndexOutOfBounds;
        }

        return .{
            .impl = try cloneImpl(
                EndPointDefImpl,
                allocator,
                &self.impl.EndPoint[index],
            ),
        };
    }

    pub fn appendEndPoint(self: *Self, allocator: std.mem.Allocator, value: *const EndPointDef) !void {
        const tmp_item = try cloneImpl(
            EndPointDefImpl,
            allocator,
            &value.impl,
        );
        errdefer tmp_item.deinit(allocator);

        const old_len = self.impl.EndPoint.len;
        self.impl.EndPoint = try allocator.realloc(
            self.impl.EndPoint,
            old_len + 1,
        );

        self.impl.EndPoint[old_len] = tmp_item;
    }

    pub fn clearEndPoint(self: *Self, allocator: std.mem.Allocator) !void {
        for (self.impl.EndPoint) |*item| {
            item.deinit(allocator);
        }
        allocator.free(self.impl.EndPoint);
        self.impl.EndPoint = try allocator.alloc(EndPointDefImpl, 0);
    }

    pub fn writeToText(
        self: *Self,
        allocator: std.mem.Allocator,
        format: TekstaFormato,
    ) ![]const u8 {
        return try self.impl.skribiAlTeksto(
            allocator,
            format,
        );
    }

    pub fn writeToFile(
        self: *Self,
        allocator: std.mem.Allocator,
        path: []const u8,
        format: TekstaFormato,
    ) !void {
        try self.impl.skribiAlDosiero(
            allocator,
            path,
            format,
        );
    }

    pub fn readFromText(
        allocator: std.mem.Allocator,
        input: []const u8,
        format: TekstaFormato,
    ) !Self {
        return .{
            .impl = try UDPStarDefConfigImpl.legiElTeksto(
                allocator,
                input,
                format,
            ),
        };
    }

    pub fn readFromFile(
        allocator: std.mem.Allocator,
        path: []const u8,
        format: TekstaFormato,
    ) !Self {
        return .{
            .impl = try UDPStarDefConfigImpl.legiElDosiero(
                allocator,
                path,
                format,
            ),
        };
    }

    pub fn serializeToBin(
        self: *const Self,
        allocator: std.mem.Allocator,
        format: BinaraFormato,
    ) ![]const u8 {
        return try self.impl.seriigiAlBin(
            allocator,
            format,
        );
    }

    pub fn serializeToFile(
        self: *const Self,
        allocator: std.mem.Allocator,
        path: []const u8,
        format: BinaraFormato,
    ) !void {
        try self.impl.seriigiAlDosiero(
            allocator,
            path,
            format,
        );
    }

    pub fn deserializeFromBin(
        allocator: std.mem.Allocator,
        input: []const u8,
        format: BinaraFormato,
    ) !Self {
        return .{
            .impl = try UDPStarDefConfigImpl.deseriigiElBin(
                allocator,
                input,
                format,
            ),
        };
    }

    pub fn deserializeFromFile(
        allocator: std.mem.Allocator,
        path: [:0]const u8,
        format: BinaraFormato,
    ) !Self {
        return .{
            .impl = try UDPStarDefConfigImpl.deseriigiElDosiero(
                allocator,
                path,
                format,
            ),
        };
    }
};

pub const EndPointDef = struct {
    impl: EndPointDefImpl,

    const Self = @This();

    pub fn initDefault(allocator: std.mem.Allocator) !Self {
        return .{
            .impl = try EndPointDefImpl.initDefault(allocator),
        };
    }

    pub fn deinit(self: *const Self, allocator: std.mem.Allocator) void {
        self.impl.deinit(allocator);
    }

    pub fn clone(self: *const Self, allocator: std.mem.Allocator) !Self {
        return .{
            .impl = try cloneImpl(
                EndPointDefImpl,
                allocator,
                &self.impl,
            ),
        };
    }

    pub fn setPort(self: *Self, value: i32) void {
        self.impl.Port = value;
    }

    pub fn getPort(self: *const Self) i32 {
        return self.impl.Port;
    }

    pub fn setHost(
        self: *Self,
        allocator: std.mem.Allocator,
        value: []const u8,
    ) !void {
        const tmp = try allocator.dupe(u8, value);
        allocator.free(self.impl.Host);
        self.impl.Host = tmp;
    }

    pub fn getHost(self: *const Self) []const u8 {
        return self.impl.Host;
    }

    pub fn writeToText(
        self: *Self,
        allocator: std.mem.Allocator,
        format: TekstaFormato,
    ) ![]const u8 {
        return try self.impl.skribiAlTeksto(
            allocator,
            format,
        );
    }

    pub fn writeToFile(
        self: *Self,
        allocator: std.mem.Allocator,
        path: []const u8,
        format: TekstaFormato,
    ) !void {
        try self.impl.skribiAlDosiero(
            allocator,
            path,
            format,
        );
    }

    pub fn readFromText(
        allocator: std.mem.Allocator,
        input: []const u8,
        format: TekstaFormato,
    ) !Self {
        return .{
            .impl = try EndPointDefImpl.legiElTeksto(
                allocator,
                input,
                format,
            ),
        };
    }

    pub fn readFromFile(
        allocator: std.mem.Allocator,
        path: []const u8,
        format: TekstaFormato,
    ) !Self {
        return .{
            .impl = try EndPointDefImpl.legiElDosiero(
                allocator,
                path,
                format,
            ),
        };
    }

    pub fn serializeToBin(
        self: *const Self,
        allocator: std.mem.Allocator,
        format: BinaraFormato,
    ) ![]const u8 {
        return try self.impl.seriigiAlBin(
            allocator,
            format,
        );
    }

    pub fn serializeToFile(
        self: *const Self,
        allocator: std.mem.Allocator,
        path: []const u8,
        format: BinaraFormato,
    ) !void {
        try self.impl.seriigiAlDosiero(
            allocator,
            path,
            format,
        );
    }

    pub fn deserializeFromBin(
        allocator: std.mem.Allocator,
        input: []const u8,
        format: BinaraFormato,
    ) !Self {
        return .{
            .impl = try EndPointDefImpl.deseriigiElBin(
                allocator,
                input,
                format,
            ),
        };
    }

    pub fn deserializeFromFile(
        allocator: std.mem.Allocator,
        path: [:0]const u8,
        format: BinaraFormato,
    ) !Self {
        return .{
            .impl = try EndPointDefImpl.deseriigiElDosiero(
                allocator,
                path,
                format,
            ),
        };
    }
};

pub const CrossConnectorDef = struct {
    impl: CrossConnectorDefImpl,

    const Self = @This();

    pub fn initDefault(allocator: std.mem.Allocator) !Self {
        return .{
            .impl = try CrossConnectorDefImpl.initDefault(allocator),
        };
    }

    pub fn deinit(self: *const Self, allocator: std.mem.Allocator) void {
        self.impl.deinit(allocator);
    }

    pub fn clone(self: *const Self, allocator: std.mem.Allocator) !Self {
        return .{
            .impl = try cloneImpl(
                CrossConnectorDefImpl,
                allocator,
                &self.impl,
            ),
        };
    }

    pub fn getTransportsCount(self: *const Self) usize {
        return self.impl.Transports.len;
    }

    pub fn getTransportsAt(self: *const Self, index: usize) ![]const u8 {
        if (index >= self.impl.Transports.len) {
            return error.IndexOutOfBounds;
        }

        return self.impl.Transports[index];
    }

    pub fn appendTransports(self: *Self, allocator: std.mem.Allocator, value: []const u8) !void {
        const tmp_item = try allocator.dupe(u8, value);
        errdefer allocator.free(tmp_item);

        const old_len = self.impl.Transports.len;
        self.impl.Transports = try allocator.realloc(
            self.impl.Transports,
            old_len + 1,
        );

        self.impl.Transports[old_len] = tmp_item;
    }

    pub fn setTransports(self: *Self, allocator: std.mem.Allocator, values: []const []const u8) !void {
        var tmp_list: std.ArrayList([]const u8) = .empty;
        errdefer {
            for (tmp_list.items) |item| {
                allocator.free(item);
            }
            tmp_list.deinit(allocator);
        }

        for (values) |value| {
            const tmp_item = try allocator.dupe(u8, value);
            errdefer allocator.free(tmp_item);
            try tmp_list.append(allocator, tmp_item);
        }

        const tmp = try tmp_list.toOwnedSlice(allocator);

        for (self.impl.Transports) |item| {
            allocator.free(item);
        }
        allocator.free(self.impl.Transports);

        self.impl.Transports = tmp;
    }

    pub fn clearTransports(self: *Self, allocator: std.mem.Allocator) !void {
        for (self.impl.Transports) |item| {
            allocator.free(item);
        }
        allocator.free(self.impl.Transports);
        self.impl.Transports = try allocator.alloc([]const u8, 0);
    }

    pub fn writeToText(
        self: *Self,
        allocator: std.mem.Allocator,
        format: TekstaFormato,
    ) ![]const u8 {
        return try self.impl.skribiAlTeksto(
            allocator,
            format,
        );
    }

    pub fn writeToFile(
        self: *Self,
        allocator: std.mem.Allocator,
        path: []const u8,
        format: TekstaFormato,
    ) !void {
        try self.impl.skribiAlDosiero(
            allocator,
            path,
            format,
        );
    }

    pub fn readFromText(
        allocator: std.mem.Allocator,
        input: []const u8,
        format: TekstaFormato,
    ) !Self {
        return .{
            .impl = try CrossConnectorDefImpl.legiElTeksto(
                allocator,
                input,
                format,
            ),
        };
    }

    pub fn readFromFile(
        allocator: std.mem.Allocator,
        path: []const u8,
        format: TekstaFormato,
    ) !Self {
        return .{
            .impl = try CrossConnectorDefImpl.legiElDosiero(
                allocator,
                path,
                format,
            ),
        };
    }

    pub fn serializeToBin(
        self: *const Self,
        allocator: std.mem.Allocator,
        format: BinaraFormato,
    ) ![]const u8 {
        return try self.impl.seriigiAlBin(
            allocator,
            format,
        );
    }

    pub fn serializeToFile(
        self: *const Self,
        allocator: std.mem.Allocator,
        path: []const u8,
        format: BinaraFormato,
    ) !void {
        try self.impl.seriigiAlDosiero(
            allocator,
            path,
            format,
        );
    }

    pub fn deserializeFromBin(
        allocator: std.mem.Allocator,
        input: []const u8,
        format: BinaraFormato,
    ) !Self {
        return .{
            .impl = try CrossConnectorDefImpl.deseriigiElBin(
                allocator,
                input,
                format,
            ),
        };
    }

    pub fn deserializeFromFile(
        allocator: std.mem.Allocator,
        path: [:0]const u8,
        format: BinaraFormato,
    ) !Self {
        return .{
            .impl = try CrossConnectorDefImpl.deseriigiElDosiero(
                allocator,
                path,
                format,
            ),
        };
    }
};

// ============================================================================
// FIN API SEGURA
// ============================================================================
