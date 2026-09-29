// ============================================================================
// Ciudad_api.zig
// ============================================================================
//
// Dosiero generita de ProtobuZig / kgenapi.zig.
//
// Baza proto:
//   Ciudad
//
// Generita raw:
//   Ciudad.zig
//
// Cxi tiu dosiero enhavas wrapper-ojn (sekura API) super la raw.
//
// Meza fazo:
//   - la raw-dosiero konservas la nunajn tipojn.
//   - cxi tiu dosiero generas sekurajn wrapper-ojn supre.
//
// Ebla fina fazo:
//   - la raw-dosiero pasos al *_impl.zig.
//   - cxi tiu dosiero aux gia ekvivalento farigxos cefa publika API.
//
// Ne redaktu mane krom por sencimigado.
// ============================================================================

const std = @import("std");

const RawFile = @import("Ciudad.zig");

pub const TekstaFormato = RawFile.TekstaFormato;
pub const BinaraFormato = RawFile.BinaraFormato;

// Aliaso al la generita raw-nomspaco.
// En la meza fazo gxi montras al la nuna package de la raw-dosiero.
const Raw = RawFile.geo;

// Aliaso intence nomita *_impl, kvankam en la meza fazo gxi
// montras al la nuna raw-nomspaco.
//
// Meza fazo:
//   const Ciudad_impl = Raw;
//
// Fina fazo:
//   const Ciudad_impl = RawFile.<package>_impl;

const Ciudad_impl = Raw;

// ============================================================================
// SEKURA API
// ============================================================================
//
// Celo:
//
//   - kasxi la rektan aliron al owned-kampoj kiam eble.
//   - montri kontrolitajn setter-ojn/builder-ojn/getter-ojn.
//   - proponi publikajn nomojn en la angla por generalaj operacioj:
//       serializeToBin
//       deserializeFromBin
//       writeToText
//       readFromText
//
// Antauxviditaj reguloj:
//
//   - append de repeated message faras profundan kopion.
//   - appendOwned ne estas montrata kiel komenca publika API.
//   - getXAt(index) redonas owned-kopion.
//   - la uzanto devas voki deinit() sur redonitajn kopiojn.
//   - internaj repeated slices ne estas montrataj kiel cefa API.
//

// ============================================================================
// INTERNAJ ALIASOJ AL RAW / IMPL-TIPOJ
// ============================================================================
//
// Cxi tiuj aliasoj ebligas, ke la korpo de la wrapper-oj ne dependu
// de tio, cxu ni estas en la meza aux fina fazo.
//
// Meza fazo:
//   EstMeteoImpl = cctrol_impl.EstMeteo
//
// Fina fazo:
//   EstMeteoImpl = cctrol_impl.EstMeteo_impl
//
const EstacionImpl = Ciudad_impl.Estacion;
const CiudadImpl = Ciudad_impl.Ciudad;

// ============================================================================
// PRIVATAJ HELPILOJ DE PROFUNDA KOPIO
// ============================================================================
//
// cloneImpl() faras profundan kopion per la generita binara vojo.
//
// Komenca strategio:
//
//   clone = seriigiAlBin(.BF_PROTOBUF) + deseriigiElBin(.BF_PROTOBUF)
//
// Cxi tiu versio prioritatas simplecon kaj sekurecon de ownership.
// Se seriigi/deseriigi havas cimon, gxi riparigxu en ProtobuZig,
// cxar gxi trafas ankaux la normalan uzon de mesagxoj en K6Bus.
//

fn cloneImpl(comptime T: type, allocator: std.mem.Allocator, src: *const T) !T {
    const bytes = try src.seriigiAlBin(allocator, .BF_PROTOBUF);
    defer allocator.free(bytes);

    return try T.deseriigiElBin(allocator, bytes, .BF_PROTOBUF);
}

// ============================================================================
// PUBLIKAJ WRAPPER-OJ
// ============================================================================
//
// Provizore cxiu wrapper enhavas nur:
//
//   impl: TipoImpl
//
// En la sekvaj pasxoj generigxos:
//
//   - initDefault()
//   - deinit()
//   - serializeToBin()
//   - deserializeFromBin()
//   - writeToText()
//   - readFromText()
//   - sekuraj setter-oj/getter-oj/builder-oj
//
pub const Estacion = struct {
    impl: EstacionImpl,

    const Self = @This();

    pub fn initDefault(allocator: std.mem.Allocator) !Self {
        return .{
            .impl = try EstacionImpl.initDefault(allocator),
        };
    }

    pub fn deinit(self: *const Self, allocator: std.mem.Allocator) void {
        self.impl.deinit(allocator);
    }

    pub fn clone(self: *const Self, allocator: std.mem.Allocator) !Self {
        return .{
            .impl = try cloneImpl(
                EstacionImpl,
                allocator,
                &self.impl,
            ),
        };
    }

    pub fn setId(self: *Self, value: u32) void {
        self.impl.id = value;
    }

    pub fn getId(self: *const Self) ?u32 {
        return self.impl.id;
    }

    pub fn hasId(self: *const Self) bool {
        return self.impl.id != null;
    }

    pub fn clearId(self: *Self) void {
        self.impl.id = null;
    }

    pub fn setNombre(
        self: *Self,
        allocator: std.mem.Allocator,
        value: []const u8,
    ) !void {
        const tmp = try allocator.dupe(u8, value);
        allocator.free(self.impl.nombre);
        self.impl.nombre = tmp;
    }

    pub fn getNombre(self: *const Self) []const u8 {
        return self.impl.nombre;
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
            .impl = try EstacionImpl.legiElTeksto(
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
            .impl = try EstacionImpl.legiElDosiero(
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
            .impl = try EstacionImpl.deseriigiElBin(
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
            .impl = try EstacionImpl.deseriigiElDosiero(
                allocator,
                path,
                format,
            ),
        };
    }
};

pub const Ciudad = struct {
    impl: CiudadImpl,

    const Self = @This();

    pub fn initDefault(allocator: std.mem.Allocator) !Self {
        return .{
            .impl = try CiudadImpl.initDefault(allocator),
        };
    }

    pub fn deinit(self: *const Self, allocator: std.mem.Allocator) void {
        self.impl.deinit(allocator);
    }

    pub fn clone(self: *const Self, allocator: std.mem.Allocator) !Self {
        return .{
            .impl = try cloneImpl(
                CiudadImpl,
                allocator,
                &self.impl,
            ),
        };
    }

    pub fn setNombre(self: *Self, allocator: std.mem.Allocator, value: []const u8) !void {
        const tmp = try allocator.dupe(u8, value);

        if (self.impl.nombre) |old| {
            allocator.free(old);
        }

        self.impl.nombre = tmp;
    }

    pub fn getNombre(self: *const Self) ?[]const u8 {
        return self.impl.nombre;
    }

    pub fn hasNombre(self: *const Self) bool {
        return self.impl.nombre != null;
    }

    pub fn clearNombre(self: *Self, allocator: std.mem.Allocator) void {
        if (self.impl.nombre) |old| {
            allocator.free(old);
        }

        self.impl.nombre = null;
    }

    pub fn getEstacionesCount(self: *const Self) usize {
        return self.impl.estaciones.len;
    }

    pub fn getEstacionesAt(self: *const Self, allocator: std.mem.Allocator, index: usize) !Estacion {
        if (index >= self.impl.estaciones.len) {
            return error.IndexOutOfBounds;
        }

        return .{
            .impl = try cloneImpl(
                EstacionImpl,
                allocator,
                &self.impl.estaciones[index],
            ),
        };
    }

    pub fn appendEstaciones(self: *Self, allocator: std.mem.Allocator, value: *const Estacion) !void {
        const tmp_item = try cloneImpl(
            EstacionImpl,
            allocator,
            &value.impl,
        );
        errdefer tmp_item.deinit(allocator);

        const old_len = self.impl.estaciones.len;
        self.impl.estaciones = try allocator.realloc(
            self.impl.estaciones,
            old_len + 1,
        );

        self.impl.estaciones[old_len] = tmp_item;
    }

    pub fn clearEstaciones(self: *Self, allocator: std.mem.Allocator) !void {
        for (self.impl.estaciones) |*item| {
            item.deinit(allocator);
        }
        allocator.free(self.impl.estaciones);
        self.impl.estaciones = try allocator.alloc(EstacionImpl, 0);
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
            .impl = try CiudadImpl.legiElTeksto(
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
            .impl = try CiudadImpl.legiElDosiero(
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
            .impl = try CiudadImpl.deseriigiElBin(
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
            .impl = try CiudadImpl.deseriigiElDosiero(
                allocator,
                path,
                format,
            ),
        };
    }
};

// ============================================================================
// FINO DE LA SEKURA API
// ============================================================================
