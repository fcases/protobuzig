// ============================================================================
// r8_api.zig
// ============================================================================
//
// Fichero generado por ProtobuZig / kgenapi.zig.
//
// Proto base:
//   r8
//
// Raw generado:
//   r8.zig
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

const RawFile = @import("r8.zig");

pub const TekstaFormato = RawFile.TekstaFormato;
pub const BinaraFormato = RawFile.BinaraFormato;

// Alias al namespace raw generado.
// En fase intermedia apunta al package actual del fichero raw.
const Raw = RawFile.r8;

// Alias intencionadamente llamado *_impl aunque en fase intermedia
// apunte al namespace raw actual.
//
// Fase intermedia:
//   const r8_impl = Raw;
//
// Fase final:
//   const r8_impl = RawFile.<package>_impl;

const r8_impl = Raw;

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
const PackedMsgImpl = r8_impl.PackedMsg;

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
// FIN API SEGURA
// ============================================================================
