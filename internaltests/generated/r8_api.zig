// ============================================================================
// r8_api.zig
// ============================================================================
//
// Dosiero generita de ProtobuZig / kgenapi.zig.
//
// Baza proto:
//   r8
//
// Generita raw:
//   r8.zig
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

const RawFile = @import("r8.zig");

pub const TekstaFormato = RawFile.TekstaFormato;
pub const BinaraFormato = RawFile.BinaraFormato;

// Aliaso al la generita raw-nomspaco.
// En la meza fazo gxi montras al la nuna package de la raw-dosiero.
const Raw = RawFile;

// Aliaso intence nomita *_impl, kvankam en la meza fazo gxi
// montras al la nuna raw-nomspaco.
//
// Meza fazo:
//   const r8_impl = Raw;
//
// Fina fazo:
//   const r8_impl = RawFile.<package>_impl;

const r8_impl = Raw;

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
const PackedMsgImpl = r8_impl.PackedMsg;

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
pub const PackedMsg = struct {
    impl: PackedMsgImpl,

    const Self = @This();

    pub fn initDefault(allocator: std.mem.Allocator) !Self {
        return .{
            .impl = try PackedMsgImpl.initDefault(allocator),
        };
    }

    pub fn deinit(self: *const Self, allocator: std.mem.Allocator) void {
        self.impl.deinit(allocator);
    }

    pub fn clone(self: *const Self, allocator: std.mem.Allocator) !Self {
        return .{
            .impl = try cloneImpl(
                PackedMsgImpl,
                allocator,
                &self.impl,
            ),
        };
    }

    pub fn getPathCount(self: *const Self) usize {
        return self.impl.path.len;
    }

    pub fn getPathAt(self: *const Self, index: usize) !i32 {
        if (index >= self.impl.path.len) {
            return error.IndexOutOfBounds;
        }

        return self.impl.path[index];
    }

    pub fn appendPath(
        self: *Self,
        allocator: std.mem.Allocator,
        value: i32,
    ) !void {
        const old_len = self.impl.path.len;

        self.impl.path = try allocator.realloc(
            self.impl.path,
            old_len + 1,
        );

        self.impl.path[old_len] = value;
    }

    pub fn setPath(
        self: *Self,
        allocator: std.mem.Allocator,
        values: []const i32,
    ) !void {
        const tmp = try allocator.dupe(i32, values);

        allocator.free(self.impl.path);
        self.impl.path = tmp;
    }

    pub fn clearPath(
        self: *Self,
        allocator: std.mem.Allocator,
    ) !void {
        allocator.free(self.impl.path);
        self.impl.path = try allocator.alloc(i32, 0);
    }

    pub fn getSimpleCount(self: *const Self) usize {
        return self.impl.simple.len;
    }

    pub fn getSimpleAt(self: *const Self, index: usize) !i32 {
        if (index >= self.impl.simple.len) {
            return error.IndexOutOfBounds;
        }

        return self.impl.simple[index];
    }

    pub fn appendSimple(
        self: *Self,
        allocator: std.mem.Allocator,
        value: i32,
    ) !void {
        const old_len = self.impl.simple.len;

        self.impl.simple = try allocator.realloc(
            self.impl.simple,
            old_len + 1,
        );

        self.impl.simple[old_len] = value;
    }

    pub fn setSimple(
        self: *Self,
        allocator: std.mem.Allocator,
        values: []const i32,
    ) !void {
        const tmp = try allocator.dupe(i32, values);

        allocator.free(self.impl.simple);
        self.impl.simple = tmp;
    }

    pub fn clearSimple(
        self: *Self,
        allocator: std.mem.Allocator,
    ) !void {
        allocator.free(self.impl.simple);
        self.impl.simple = try allocator.alloc(i32, 0);
    }

    pub fn getValsCount(self: *const Self) usize {
        return self.impl.vals.len;
    }

    pub fn getValsAt(self: *const Self, index: usize) !f64 {
        if (index >= self.impl.vals.len) {
            return error.IndexOutOfBounds;
        }

        return self.impl.vals[index];
    }

    pub fn appendVals(
        self: *Self,
        allocator: std.mem.Allocator,
        value: f64,
    ) !void {
        const old_len = self.impl.vals.len;

        self.impl.vals = try allocator.realloc(
            self.impl.vals,
            old_len + 1,
        );

        self.impl.vals[old_len] = value;
    }

    pub fn setVals(
        self: *Self,
        allocator: std.mem.Allocator,
        values: []const f64,
    ) !void {
        const tmp = try allocator.dupe(f64, values);

        allocator.free(self.impl.vals);
        self.impl.vals = tmp;
    }

    pub fn clearVals(
        self: *Self,
        allocator: std.mem.Allocator,
    ) !void {
        allocator.free(self.impl.vals);
        self.impl.vals = try allocator.alloc(f64, 0);
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
            .impl = try PackedMsgImpl.legiElTeksto(
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
            .impl = try PackedMsgImpl.legiElDosiero(
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
            .impl = try PackedMsgImpl.deseriigiElBin(
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
            .impl = try PackedMsgImpl.deseriigiElDosiero(
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
