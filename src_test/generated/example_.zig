const std = @import("std");
const dbg = std.debug;
const zon = std.zon;
const all = std.mem;
const equal = std.mem.eql;
const io = std.Io;
const encdec = @import("../encdec.zig");
const EncodeBuffer = encdec.EncodeBuffer;
const DecodeBuffer = encdec.DecodeBuffer;

pub const ProtocolBus = struct {
    pub const Enum1 = enum(u64) {
        EAA_UNSPECIFIED = 0,
        EAA_STARTED = 1,
        EAA_RUNNING = 2,
        EAA_FINISHED = 3,
    };

    pub const AppConfig = struct {
        pub const Enum3 = enum(u64) {
            ENAA_UNSPECIFIED = 0,
            ENAA_STARTED = 1,
            ENAA_FINISHED = 2,
        };

        pub const CrossConnectorDef_2 = struct {
            Transports: [][]const u8,

            pub fn initDefault(allocator: all.Allocator) !CrossConnectorDef_2 {
                const self = try allocator.create(CrossConnectorDef_2);
                self.* = CrossConnectorDef_2{
                    .Transports = try allocator.alloc([]const u8, 0),
                };
                return self.*;
            }

            pub fn skribiAlZonTeksto(self: *CrossConnectorDef_2, allocator: all.Allocator) ![]u8 {
                return skribiTiponAlZonTeksto(allocator, CrossConnectorDef_2, @as(*CrossConnectorDef_2, self));
            }

            pub fn skribiAlZonDosiero(self: *CrossConnectorDef_2, allocator: all.Allocator, path: []const u8) !void {
                try skribiTiponAlZonDosiero(allocator, CrossConnectorDef_2, @as(*CrossConnectorDef_2, self), path);
            }

            pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !CrossConnectorDef_2 {
                return legiTiponElZonTeksto(allocator, CrossConnectorDef_2, input);
            }

            pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !CrossConnectorDef_2 {
                return legiTiponElZonDosiero(allocator, CrossConnectorDef_2, path);
            }

            pub fn skribiAlProtobufTeksto(self: *const CrossConnectorDef_2, allocator: all.Allocator, ind: []const u8) ![]const u8 {
                const indent = std.mem.concatWithSentinel(std.heap.page_allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
                var bufro: std.ArrayList(u8) = .empty;
                if (equal(u8, indent, "")) {
                    {}
                }

                for (self.Transports) |obj|
                    try bufro.print(allocator, "{s}Transports: \"{s}\"\n", .{ ind, obj });

                return bufro.toOwnedSlice(allocator);
            }

            pub fn skribiAlJsonTeksto(self: *const CrossConnectorDef_2, allocator: all.Allocator) ![]const u8 {
                var skribila_asignilo = std.Io.Writer.Allocating.init(allocator);

                std.json.fmt(self, .{ .whitespace = .indent_3 }).format(&skribila_asignilo.writer) catch |err| {
                    std.debug.print("eraro dum seriigo: {}\n", .{err});
                    return err;
                };

                return skribila_asignilo.writer.buffered();
            }

            pub fn skribiAlPBDosiero(self: *CrossConnectorDef_2, allocator: all.Allocator) ![]u8 {
                _ = self;
                _ = allocator;
            }

            pub fn serialize(self: *CrossConnectorDef_2, allocator: all.Allocator) ![]u8 {
                return serializeTipon(allocator, CrossConnectorDef_2, @as(*CrossConnectorDef_2, self));
            }

            fn encode(self: *const CrossConnectorDef_2, buffer: *EncodeBuffer) !usize {
                var tuta_longo: usize = 0;

                for (self.Transports) |item| {
                    const Transports_longa = try buffer.encodeString(item);
                    tuta_longo += Transports_longa;
                    tuta_longo += try buffer.encodeVarint(Transports_longa);
                    tuta_longo += try buffer.encodeVarint(10);
                } // 11  rept - no def - varlong

                return tuta_longo;
            }

            pub fn deserialize(allocator: all.Allocator, input: []const u8) !CrossConnectorDef_2 {
                return deserializeTipon(allocator, CrossConnectorDef_2, input);
            }

            fn decode(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !CrossConnectorDef_2 {
                var mia_Mesagho = try CrossConnectorDef_2.initDefault(allocator);

                var end: usize = undefined;
                if (data_length) |val|
                    end = buffer.read_index + val
                else
                    end = buffer.buffer.len;

                var Transports_list: std.ArrayList([]const u8) = .empty;

                while (buffer.read_index < end) {
                    const key: u64 = buffer.decodeVarint() catch 0;
                    const wire_type = key & 0x7;
                    const field_number = key >> 3;

                    if (field_number == 1 and wire_type == 2) {
                        try Transports_list.append(allocator, try buffer.decodeString(try buffer.decodeVarint()));
                    }
                }

                mia_Mesagho.Transports = try Transports_list.toOwnedSlice(allocator);

                return mia_Mesagho;
            }
        };

        ActivateTrace: ?bool = false,
        TraceLevel: ?i32 = 0,
        Domains: []DomainCfg,
        a: ?Enum1 = null,
        b: ?Enum1 = .EAA_RUNNING,
        Hola: ?i32 = null,

        pub fn initDefault(allocator: all.Allocator) !AppConfig {
            const self = try allocator.create(AppConfig);
            self.* = AppConfig{
                .ActivateTrace = false,
                .TraceLevel = 0,
                .Domains = try allocator.alloc(DomainCfg, 0),
                .a = null,
                .b = .EAA_RUNNING,
                .Hola = null,
            };
            return self.*;
        }

        pub fn skribiAlZonTeksto(self: *AppConfig, allocator: all.Allocator) ![]u8 {
            return skribiTiponAlZonTeksto(allocator, AppConfig, @as(*AppConfig, self));
        }

        pub fn skribiAlZonDosiero(self: *AppConfig, allocator: all.Allocator, path: []const u8) !void {
            try skribiTiponAlZonDosiero(allocator, AppConfig, @as(*AppConfig, self), path);
        }

        pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !AppConfig {
            return legiTiponElZonTeksto(allocator, AppConfig, input);
        }

        pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !AppConfig {
            return legiTiponElZonDosiero(allocator, AppConfig, path);
        }

        pub fn skribiAlProtobufTeksto(self: *const AppConfig, allocator: all.Allocator, ind: []const u8) ![]const u8 {
            const indent = std.mem.concatWithSentinel(std.heap.page_allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
            var bufro: std.ArrayList(u8) = .empty;
            if (equal(u8, indent, "")) {
                {}
            }

            if (self.ActivateTrace) |val|
                try bufro.print(allocator, "{s}ActivateTrace: {any}\n", .{ ind, val });
            if (self.TraceLevel) |val|
                try bufro.print(allocator, "{s}TraceLevel: {any}\n", .{ ind, val });
            for (self.Domains) |obj|
                try bufro.print(allocator, "{s}Domains {{\n{s}{s}}}\n", .{ ind, try obj.skribiAlProtobufTeksto(allocator, indent), ind });
            if (self.a) |val|
                try bufro.print(allocator, "{s}a: {any}\n", .{ ind, val });
            if (self.b) |val|
                try bufro.print(allocator, "{s}b: {any}\n", .{ ind, val });
            if (self.Hola) |val|
                try bufro.print(allocator, "{s}Hola: {any}\n", .{ ind, val });

            return bufro.toOwnedSlice(allocator);
        }

        pub fn skribiAlJsonTeksto(self: *const AppConfig, allocator: all.Allocator) ![]const u8 {
            var skribila_asignilo = std.Io.Writer.Allocating.init(allocator);

            std.json.fmt(self, .{ .whitespace = .indent_3 }).format(&skribila_asignilo.writer) catch |err| {
                std.debug.print("eraro dum seriigo: {}\n", .{err});
                return err;
            };

            return skribila_asignilo.writer.buffered();
        }

        pub fn skribiAlPBDosiero(self: *AppConfig, allocator: all.Allocator) ![]u8 {
            _ = self;
            _ = allocator;
        }

        pub fn serialize(self: *AppConfig, allocator: all.Allocator) ![]u8 {
            return serializeTipon(allocator, AppConfig, @as(*AppConfig, self));
        }

        fn encode(self: *const AppConfig, buffer: *EncodeBuffer) !usize {
            var tuta_longo: usize = 0;

            if (self.Hola) |val| {
                tuta_longo += try buffer.encodeInt32(val);
                tuta_longo += try buffer.encodeVarint(48);
            } //1 opt - no def - no varlong

            if (self.b) |val| {
                if (val != .EAA_RUNNING) {
                    tuta_longo += try buffer.encodeVarint(@intFromEnum(val));
                    tuta_longo += try buffer.encodeVarint(40);
                }
            } //2 opt - def - no varlong

            if (self.a) |val| {
                tuta_longo += try buffer.encodeVarint(@intFromEnum(val));
                tuta_longo += try buffer.encodeVarint(32);
            } //1 opt - no def - no varlong

            for (self.Domains) |item| {
                const Domains_longa = try item.encode(buffer);
                tuta_longo += Domains_longa;
                tuta_longo += try buffer.encodeVarint(Domains_longa);
                tuta_longo += try buffer.encodeVarint(26);
            } // 11  rept - no def - varlong

            if (self.TraceLevel) |val| {
                if (val != 0) {
                    tuta_longo += try buffer.encodeInt32(val);
                    tuta_longo += try buffer.encodeVarint(16);
                }
            } //2 opt - def - no varlong

            if (self.ActivateTrace) |val| {
                if (val != false) {
                    tuta_longo += try buffer.encodeBool(val);
                    tuta_longo += try buffer.encodeVarint(8);
                }
            } //2 opt - def - no varlong

            return tuta_longo;
        }

        pub fn deserialize(allocator: all.Allocator, input: []const u8) !AppConfig {
            return deserializeTipon(allocator, AppConfig, input);
        }

        fn decode(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !AppConfig {
            var mia_Mesagho = try AppConfig.initDefault(allocator);

            var end: usize = undefined;
            if (data_length) |val|
                end = buffer.read_index + val
            else
                end = buffer.buffer.len;

            var Domains_list: std.ArrayList(DomainCfg) = .empty;

            while (buffer.read_index < end) {
                const key: u64 = buffer.decodeVarint() catch 0;
                const wire_type = key & 0x7;
                const field_number = key >> 3;

                if (field_number == 1 and wire_type == 0)
                    mia_Mesagho.ActivateTrace = try buffer.decodeBool()
                else if (field_number == 2 and wire_type == 0)
                    mia_Mesagho.TraceLevel = try buffer.decodeInt32()
                else if (field_number == 3 and wire_type == 2) {
                    try Domains_list.append(allocator, try DomainCfg.decode(allocator, buffer, try buffer.decodeVarint()));
                } else if (field_number == 4 and wire_type == 0)
                    mia_Mesagho.a = try std.meta.intToEnum(Enum1, try buffer.decodeVarint())
                else if (field_number == 5 and wire_type == 0)
                    mia_Mesagho.b = try std.meta.intToEnum(Enum1, try buffer.decodeVarint())
                else if (field_number == 6 and wire_type == 0)
                    mia_Mesagho.Hola = try buffer.decodeInt32();
            }

            mia_Mesagho.Domains = try Domains_list.toOwnedSlice(allocator);

            return mia_Mesagho;
        }
    };

    pub const DomainCfg = struct {
        Id: i32,
        ActivateDefaultTransport: bool = false,
        DirectDispacthToSubs: ?bool = false,
        KeyFile: ?[]const u8 = "Me@myComputer_20120525150544.pbusk",
        Transports: []TransportDef,
        CrossConnector: ?CrossConnectorDef = null,

        pub fn initDefault(allocator: all.Allocator) !DomainCfg {
            const self = try allocator.create(DomainCfg);
            self.* = DomainCfg{
                .Id = 0,
                .ActivateDefaultTransport = false,
                .DirectDispacthToSubs = false,
                .KeyFile = "Me@myComputer_20120525150544.pbusk",
                .Transports = try allocator.alloc(TransportDef, 0),
                .CrossConnector = null,
            };
            return self.*;
        }

        pub fn skribiAlZonTeksto(self: *DomainCfg, allocator: all.Allocator) ![]u8 {
            return skribiTiponAlZonTeksto(allocator, DomainCfg, @as(*DomainCfg, self));
        }

        pub fn skribiAlZonDosiero(self: *DomainCfg, allocator: all.Allocator, path: []const u8) !void {
            try skribiTiponAlZonDosiero(allocator, DomainCfg, @as(*DomainCfg, self), path);
        }

        pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !DomainCfg {
            return legiTiponElZonTeksto(allocator, DomainCfg, input);
        }

        pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !DomainCfg {
            return legiTiponElZonDosiero(allocator, DomainCfg, path);
        }

        pub fn skribiAlProtobufTeksto(self: *const DomainCfg, allocator: all.Allocator, ind: []const u8) ![]const u8 {
            const indent = std.mem.concatWithSentinel(std.heap.page_allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
            var bufro: std.ArrayList(u8) = .empty;
            if (equal(u8, indent, "")) {
                {}
            }

            try bufro.print(allocator, "{s}Id: {any}\n", .{ ind, self.Id });
            try bufro.print(allocator, "{s}ActivateDefaultTransport: {any}\n", .{ ind, self.ActivateDefaultTransport });
            if (self.DirectDispacthToSubs) |val|
                try bufro.print(allocator, "{s}DirectDispacthToSubs: {any}\n", .{ ind, val });
            if (self.KeyFile) |val|
                try bufro.print(allocator, "{s}KeyFile: \"{s}\"\n", .{ ind, val });
            for (self.Transports) |obj|
                try bufro.print(allocator, "{s}Transports {{\n{s}{s}}}\n", .{ ind, try obj.skribiAlProtobufTeksto(allocator, indent), ind });
            if (self.CrossConnector) |val|
                try bufro.print(allocator, "{s}CrossConnector {{\n{s}{s}}}\n", .{ ind, try val.skribiAlProtobufTeksto(allocator, indent), ind });

            return bufro.toOwnedSlice(allocator);
        }

        pub fn skribiAlJsonTeksto(self: *const DomainCfg, allocator: all.Allocator) ![]const u8 {
            var skribila_asignilo = std.Io.Writer.Allocating.init(allocator);

            std.json.fmt(self, .{ .whitespace = .indent_3 }).format(&skribila_asignilo.writer) catch |err| {
                std.debug.print("eraro dum seriigo: {}\n", .{err});
                return err;
            };

            return skribila_asignilo.writer.buffered();
        }

        pub fn skribiAlPBDosiero(self: *DomainCfg, allocator: all.Allocator) ![]u8 {
            _ = self;
            _ = allocator;
        }

        pub fn serialize(self: *DomainCfg, allocator: all.Allocator) ![]u8 {
            return serializeTipon(allocator, DomainCfg, @as(*DomainCfg, self));
        }

        fn encode(self: *const DomainCfg, buffer: *EncodeBuffer) !usize {
            var tuta_longo: usize = 0;

            if (self.CrossConnector) |val| {
                const st_longa = try val.encode(buffer);
                tuta_longo += st_longa;
                tuta_longo += try buffer.encodeVarint(st_longa);
                tuta_longo += try buffer.encodeVarint(50);
            } //3  opt - no def - varlong

            for (self.Transports) |item| {
                const Transports_longa = try item.encode(buffer);
                tuta_longo += Transports_longa;
                tuta_longo += try buffer.encodeVarint(Transports_longa);
                tuta_longo += try buffer.encodeVarint(42);
            } // 11  rept - no def - varlong

            if (self.KeyFile) |val| {
                if (!equal(u8, val, "Me@myComputer_20120525150544.pbusk")) {
                    const st_longa = try buffer.encodeString(val);
                    tuta_longo += st_longa;
                    tuta_longo += try buffer.encodeVarint(st_longa);
                    tuta_longo += try buffer.encodeVarint(34);
                }
            } //4  opt - def - varlong

            if (self.DirectDispacthToSubs) |val| {
                if (val != false) {
                    tuta_longo += try buffer.encodeBool(val);
                    tuta_longo += try buffer.encodeVarint(24);
                }
            } //2 opt - def - no varlong

            if (self.ActivateDefaultTransport != false) {
                tuta_longo += try buffer.encodeBool(self.ActivateDefaultTransport);
                tuta_longo += try buffer.encodeVarint(16);
            } //6  req - def - no varlong

            tuta_longo += try buffer.encodeInt32(self.Id);
            tuta_longo += try buffer.encodeVarint(8);
            //5 req - no def - no varlong

            return tuta_longo;
        }

        pub fn deserialize(allocator: all.Allocator, input: []const u8) !DomainCfg {
            return deserializeTipon(allocator, DomainCfg, input);
        }

        fn decode(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !DomainCfg {
            var mia_Mesagho = try DomainCfg.initDefault(allocator);

            var end: usize = undefined;
            if (data_length) |val|
                end = buffer.read_index + val
            else
                end = buffer.buffer.len;

            var Transports_list: std.ArrayList(TransportDef) = .empty;

            while (buffer.read_index < end) {
                const key: u64 = buffer.decodeVarint() catch 0;
                const wire_type = key & 0x7;
                const field_number = key >> 3;

                if (field_number == 1 and wire_type == 0)
                    mia_Mesagho.Id = try buffer.decodeInt32()
                else if (field_number == 2 and wire_type == 0)
                    mia_Mesagho.ActivateDefaultTransport = try buffer.decodeBool()
                else if (field_number == 3 and wire_type == 0)
                    mia_Mesagho.DirectDispacthToSubs = try buffer.decodeBool()
                else if (field_number == 4 and wire_type == 2)
                    mia_Mesagho.KeyFile = try buffer.decodeString(try buffer.decodeVarint())
                else if (field_number == 5 and wire_type == 2) {
                    try Transports_list.append(allocator, try TransportDef.decode(allocator, buffer, try buffer.decodeVarint()));
                } else if (field_number == 6 and wire_type == 2)
                    mia_Mesagho.CrossConnector = try CrossConnectorDef.decode(allocator, buffer, try buffer.decodeVarint());
            }

            mia_Mesagho.Transports = try Transports_list.toOwnedSlice(allocator);

            return mia_Mesagho;
        }
    };

    pub const TransportDef = struct {
        TransportName: []const u8 = "MCastDefault0",
        DllImport: []const u8 = "Default",
        TransportClass: []const u8 = "Default",
        ReceiveOwnMsgs: ?bool = false,
        MCastParams: ?MCastDefConfig = null,
        BCastParams: ?BCastDefConfig = null,
        UDPStarParams: ?UDPStarDefConfig = null,

        pub fn initDefault(allocator: all.Allocator) !TransportDef {
            const self = try allocator.create(TransportDef);
            self.* = TransportDef{
                .TransportName = "MCastDefault0",
                .DllImport = "Default",
                .TransportClass = "Default",
                .ReceiveOwnMsgs = false,
                .MCastParams = null,
                .BCastParams = null,
                .UDPStarParams = null,
            };
            return self.*;
        }

        pub fn skribiAlZonTeksto(self: *TransportDef, allocator: all.Allocator) ![]u8 {
            return skribiTiponAlZonTeksto(allocator, TransportDef, @as(*TransportDef, self));
        }

        pub fn skribiAlZonDosiero(self: *TransportDef, allocator: all.Allocator, path: []const u8) !void {
            try skribiTiponAlZonDosiero(allocator, TransportDef, @as(*TransportDef, self), path);
        }

        pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !TransportDef {
            return legiTiponElZonTeksto(allocator, TransportDef, input);
        }

        pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !TransportDef {
            return legiTiponElZonDosiero(allocator, TransportDef, path);
        }

        pub fn skribiAlProtobufTeksto(self: *const TransportDef, allocator: all.Allocator, ind: []const u8) ![]const u8 {
            const indent = std.mem.concatWithSentinel(std.heap.page_allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
            var bufro: std.ArrayList(u8) = .empty;
            if (equal(u8, indent, "")) {
                {}
            }

            try bufro.print(allocator, "{s}TransportName: \"{s}\"\n", .{ ind, self.TransportName });
            try bufro.print(allocator, "{s}DllImport: \"{s}\"\n", .{ ind, self.DllImport });
            try bufro.print(allocator, "{s}TransportClass: \"{s}\"\n", .{ ind, self.TransportClass });
            if (self.ReceiveOwnMsgs) |val|
                try bufro.print(allocator, "{s}ReceiveOwnMsgs: {any}\n", .{ ind, val });
            if (self.MCastParams) |val|
                try bufro.print(allocator, "{s}MCastParams {{\n{s}{s}}}\n", .{ ind, try val.skribiAlProtobufTeksto(allocator, indent), ind });
            if (self.BCastParams) |val|
                try bufro.print(allocator, "{s}BCastParams {{\n{s}{s}}}\n", .{ ind, try val.skribiAlProtobufTeksto(allocator, indent), ind });
            if (self.UDPStarParams) |val|
                try bufro.print(allocator, "{s}UDPStarParams {{\n{s}{s}}}\n", .{ ind, try val.skribiAlProtobufTeksto(allocator, indent), ind });

            return bufro.toOwnedSlice(allocator);
        }

        pub fn skribiAlJsonTeksto(self: *const TransportDef, allocator: all.Allocator) ![]const u8 {
            var skribila_asignilo = std.Io.Writer.Allocating.init(allocator);

            std.json.fmt(self, .{ .whitespace = .indent_3 }).format(&skribila_asignilo.writer) catch |err| {
                std.debug.print("eraro dum seriigo: {}\n", .{err});
                return err;
            };

            return skribila_asignilo.writer.buffered();
        }

        pub fn skribiAlPBDosiero(self: *TransportDef, allocator: all.Allocator) ![]u8 {
            _ = self;
            _ = allocator;
        }

        pub fn serialize(self: *TransportDef, allocator: all.Allocator) ![]u8 {
            return serializeTipon(allocator, TransportDef, @as(*TransportDef, self));
        }

        fn encode(self: *const TransportDef, buffer: *EncodeBuffer) !usize {
            var tuta_longo: usize = 0;

            if (self.UDPStarParams) |val| {
                const st_longa = try val.encode(buffer);
                tuta_longo += st_longa;
                tuta_longo += try buffer.encodeVarint(st_longa);
                tuta_longo += try buffer.encodeVarint(58);
            } //3  opt - no def - varlong

            if (self.BCastParams) |val| {
                const st_longa = try val.encode(buffer);
                tuta_longo += st_longa;
                tuta_longo += try buffer.encodeVarint(st_longa);
                tuta_longo += try buffer.encodeVarint(50);
            } //3  opt - no def - varlong

            if (self.MCastParams) |val| {
                const st_longa = try val.encode(buffer);
                tuta_longo += st_longa;
                tuta_longo += try buffer.encodeVarint(st_longa);
                tuta_longo += try buffer.encodeVarint(42);
            } //3  opt - no def - varlong

            if (self.ReceiveOwnMsgs) |val| {
                if (val != false) {
                    tuta_longo += try buffer.encodeBool(val);
                    tuta_longo += try buffer.encodeVarint(32);
                }
            } //2 opt - def - no varlong

            if (!equal(u8, self.TransportClass, "Default")) {
                const st_longa = try buffer.encodeString(self.TransportClass);
                tuta_longo += st_longa;
                tuta_longo += try buffer.encodeVarint(st_longa);
                tuta_longo += try buffer.encodeVarint(26);
            } //8 req - def - varlong

            if (!equal(u8, self.DllImport, "Default")) {
                const st_longa = try buffer.encodeString(self.DllImport);
                tuta_longo += st_longa;
                tuta_longo += try buffer.encodeVarint(st_longa);
                tuta_longo += try buffer.encodeVarint(18);
            } //8 req - def - varlong

            if (!equal(u8, self.TransportName, "MCastDefault0")) {
                const st_longa = try buffer.encodeString(self.TransportName);
                tuta_longo += st_longa;
                tuta_longo += try buffer.encodeVarint(st_longa);
                tuta_longo += try buffer.encodeVarint(10);
            } //8 req - def - varlong

            return tuta_longo;
        }

        pub fn deserialize(allocator: all.Allocator, input: []const u8) !TransportDef {
            return deserializeTipon(allocator, TransportDef, input);
        }

        fn decode(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !TransportDef {
            var mia_Mesagho = try TransportDef.initDefault(allocator);

            var end: usize = undefined;
            if (data_length) |val|
                end = buffer.read_index + val
            else
                end = buffer.buffer.len;

            while (buffer.read_index < end) {
                const key: u64 = buffer.decodeVarint() catch 0;
                const wire_type = key & 0x7;
                const field_number = key >> 3;

                if (field_number == 1 and wire_type == 2)
                    mia_Mesagho.TransportName = try buffer.decodeString(try buffer.decodeVarint())
                else if (field_number == 2 and wire_type == 2)
                    mia_Mesagho.DllImport = try buffer.decodeString(try buffer.decodeVarint())
                else if (field_number == 3 and wire_type == 2)
                    mia_Mesagho.TransportClass = try buffer.decodeString(try buffer.decodeVarint())
                else if (field_number == 4 and wire_type == 0)
                    mia_Mesagho.ReceiveOwnMsgs = try buffer.decodeBool()
                else if (field_number == 5 and wire_type == 2)
                    mia_Mesagho.MCastParams = try MCastDefConfig.decode(allocator, buffer, try buffer.decodeVarint())
                else if (field_number == 6 and wire_type == 2)
                    mia_Mesagho.BCastParams = try BCastDefConfig.decode(allocator, buffer, try buffer.decodeVarint())
                else if (field_number == 7 and wire_type == 2)
                    mia_Mesagho.UDPStarParams = try UDPStarDefConfig.decode(allocator, buffer, try buffer.decodeVarint());
            }

            return mia_Mesagho;
        }
    };

    pub const TransportCfg = struct {
        TransportName: []const u8 = "MCastDefault0",
        DllImport: []const u8 = "Default",
        TransportClass: []const u8 = "Default",
        ReceiveOwnMsgs: ?bool = false,
        Params: []const u8 = "",
        mnbvX: MCastDefConfig,

        pub fn initDefault(allocator: all.Allocator) !TransportCfg {
            const self = try allocator.create(TransportCfg);
            self.* = TransportCfg{
                .TransportName = "MCastDefault0",
                .DllImport = "Default",
                .TransportClass = "Default",
                .ReceiveOwnMsgs = false,
                .Params = "",
                .mnbvX = undefined,
            };
            return self.*;
        }

        pub fn skribiAlZonTeksto(self: *TransportCfg, allocator: all.Allocator) ![]u8 {
            return skribiTiponAlZonTeksto(allocator, TransportCfg, @as(*TransportCfg, self));
        }

        pub fn skribiAlZonDosiero(self: *TransportCfg, allocator: all.Allocator, path: []const u8) !void {
            try skribiTiponAlZonDosiero(allocator, TransportCfg, @as(*TransportCfg, self), path);
        }

        pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !TransportCfg {
            return legiTiponElZonTeksto(allocator, TransportCfg, input);
        }

        pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !TransportCfg {
            return legiTiponElZonDosiero(allocator, TransportCfg, path);
        }

        pub fn skribiAlProtobufTeksto(self: *const TransportCfg, allocator: all.Allocator, ind: []const u8) ![]const u8 {
            const indent = std.mem.concatWithSentinel(std.heap.page_allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
            var bufro: std.ArrayList(u8) = .empty;
            if (equal(u8, indent, "")) {
                {}
            }

            try bufro.print(allocator, "{s}TransportName: \"{s}\"\n", .{ ind, self.TransportName });
            try bufro.print(allocator, "{s}DllImport: \"{s}\"\n", .{ ind, self.DllImport });
            try bufro.print(allocator, "{s}TransportClass: \"{s}\"\n", .{ ind, self.TransportClass });
            if (self.ReceiveOwnMsgs) |val|
                try bufro.print(allocator, "{s}ReceiveOwnMsgs: {any}\n", .{ ind, val });
            try bufro.print(allocator, "{s}Params: \"{s}\"\n", .{ ind, self.Params });
            try bufro.print(allocator, "{s}mnbvX {{\n{s}{s}}}\n", .{ ind, try self.mnbvX.skribiAlProtobufTeksto(allocator, indent), ind });

            return bufro.toOwnedSlice(allocator);
        }

        pub fn skribiAlJsonTeksto(self: *const TransportCfg, allocator: all.Allocator) ![]const u8 {
            var skribila_asignilo = std.Io.Writer.Allocating.init(allocator);

            std.json.fmt(self, .{ .whitespace = .indent_3 }).format(&skribila_asignilo.writer) catch |err| {
                std.debug.print("eraro dum seriigo: {}\n", .{err});
                return err;
            };

            return skribila_asignilo.writer.buffered();
        }

        pub fn skribiAlPBDosiero(self: *TransportCfg, allocator: all.Allocator) ![]u8 {
            _ = self;
            _ = allocator;
        }

        pub fn serialize(self: *TransportCfg, allocator: all.Allocator) ![]u8 {
            return serializeTipon(allocator, TransportCfg, @as(*TransportCfg, self));
        }

        fn encode(self: *const TransportCfg, buffer: *EncodeBuffer) !usize {
            var tuta_longo: usize = 0;

            const mnbvX_longa = try self.mnbvX.encode(buffer);
            tuta_longo += mnbvX_longa;
            tuta_longo += try buffer.encodeVarint(mnbvX_longa);
            tuta_longo += try buffer.encodeVarint(50);
            //7  req - no def - varlong

            if (!equal(u8, self.Params, "")) {
                const st_longa = try buffer.encodeString(self.Params);
                tuta_longo += st_longa;
                tuta_longo += try buffer.encodeVarint(st_longa);
                tuta_longo += try buffer.encodeVarint(42);
            } //8 req - def - varlong

            if (self.ReceiveOwnMsgs) |val| {
                if (val != false) {
                    tuta_longo += try buffer.encodeBool(val);
                    tuta_longo += try buffer.encodeVarint(32);
                }
            } //2 opt - def - no varlong

            if (!equal(u8, self.TransportClass, "Default")) {
                const st_longa = try buffer.encodeString(self.TransportClass);
                tuta_longo += st_longa;
                tuta_longo += try buffer.encodeVarint(st_longa);
                tuta_longo += try buffer.encodeVarint(26);
            } //8 req - def - varlong

            if (!equal(u8, self.DllImport, "Default")) {
                const st_longa = try buffer.encodeString(self.DllImport);
                tuta_longo += st_longa;
                tuta_longo += try buffer.encodeVarint(st_longa);
                tuta_longo += try buffer.encodeVarint(18);
            } //8 req - def - varlong

            if (!equal(u8, self.TransportName, "MCastDefault0")) {
                const st_longa = try buffer.encodeString(self.TransportName);
                tuta_longo += st_longa;
                tuta_longo += try buffer.encodeVarint(st_longa);
                tuta_longo += try buffer.encodeVarint(10);
            } //8 req - def - varlong

            return tuta_longo;
        }

        pub fn deserialize(allocator: all.Allocator, input: []const u8) !TransportCfg {
            return deserializeTipon(allocator, TransportCfg, input);
        }

        fn decode(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !TransportCfg {
            var mia_Mesagho = try TransportCfg.initDefault(allocator);

            var end: usize = undefined;
            if (data_length) |val|
                end = buffer.read_index + val
            else
                end = buffer.buffer.len;

            while (buffer.read_index < end) {
                const key: u64 = buffer.decodeVarint() catch 0;
                const wire_type = key & 0x7;
                const field_number = key >> 3;

                if (field_number == 1 and wire_type == 2)
                    mia_Mesagho.TransportName = try buffer.decodeString(try buffer.decodeVarint())
                else if (field_number == 2 and wire_type == 2)
                    mia_Mesagho.DllImport = try buffer.decodeString(try buffer.decodeVarint())
                else if (field_number == 3 and wire_type == 2)
                    mia_Mesagho.TransportClass = try buffer.decodeString(try buffer.decodeVarint())
                else if (field_number == 4 and wire_type == 0)
                    mia_Mesagho.ReceiveOwnMsgs = try buffer.decodeBool()
                else if (field_number == 5 and wire_type == 2)
                    mia_Mesagho.Params = try buffer.decodeString(try buffer.decodeVarint())
                else if (field_number == 6 and wire_type == 2)
                    mia_Mesagho.mnbvX = try MCastDefConfig.decode(allocator, buffer, try buffer.decodeVarint());
            }

            return mia_Mesagho;
        }
    };

    pub const MCastDefConfig = struct {
        LocalAddress: []const u8 = "Any",
        MCastAddress: []const u8 = "239.255.0.1",
        Port: i32,
        TTL: ?i32 = 1,
        ReceiveBuffer: ?i32 = 134217727,
        SendBuffer: ?i32 = 134217727,

        pub fn initDefault(allocator: all.Allocator) !MCastDefConfig {
            const self = try allocator.create(MCastDefConfig);
            self.* = MCastDefConfig{
                .LocalAddress = "Any",
                .MCastAddress = "239.255.0.1",
                .Port = 0,
                .TTL = 1,
                .ReceiveBuffer = 134217727,
                .SendBuffer = 134217727,
            };
            return self.*;
        }

        pub fn skribiAlZonTeksto(self: *MCastDefConfig, allocator: all.Allocator) ![]u8 {
            return skribiTiponAlZonTeksto(allocator, MCastDefConfig, @as(*MCastDefConfig, self));
        }

        pub fn skribiAlZonDosiero(self: *MCastDefConfig, allocator: all.Allocator, path: []const u8) !void {
            try skribiTiponAlZonDosiero(allocator, MCastDefConfig, @as(*MCastDefConfig, self), path);
        }

        pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !MCastDefConfig {
            return legiTiponElZonTeksto(allocator, MCastDefConfig, input);
        }

        pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !MCastDefConfig {
            return legiTiponElZonDosiero(allocator, MCastDefConfig, path);
        }

        pub fn skribiAlProtobufTeksto(self: *const MCastDefConfig, allocator: all.Allocator, ind: []const u8) ![]const u8 {
            const indent = std.mem.concatWithSentinel(std.heap.page_allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
            var bufro: std.ArrayList(u8) = .empty;
            if (equal(u8, indent, "")) {
                {}
            }

            try bufro.print(allocator, "{s}LocalAddress: \"{s}\"\n", .{ ind, self.LocalAddress });
            try bufro.print(allocator, "{s}MCastAddress: \"{s}\"\n", .{ ind, self.MCastAddress });
            try bufro.print(allocator, "{s}Port: {any}\n", .{ ind, self.Port });
            if (self.TTL) |val|
                try bufro.print(allocator, "{s}TTL: {any}\n", .{ ind, val });
            if (self.ReceiveBuffer) |val|
                try bufro.print(allocator, "{s}ReceiveBuffer: {any}\n", .{ ind, val });
            if (self.SendBuffer) |val|
                try bufro.print(allocator, "{s}SendBuffer: {any}\n", .{ ind, val });

            return bufro.toOwnedSlice(allocator);
        }

        pub fn skribiAlJsonTeksto(self: *const MCastDefConfig, allocator: all.Allocator) ![]const u8 {
            var skribila_asignilo = std.Io.Writer.Allocating.init(allocator);

            std.json.fmt(self, .{ .whitespace = .indent_3 }).format(&skribila_asignilo.writer) catch |err| {
                std.debug.print("eraro dum seriigo: {}\n", .{err});
                return err;
            };

            return skribila_asignilo.writer.buffered();
        }

        pub fn skribiAlPBDosiero(self: *MCastDefConfig, allocator: all.Allocator) ![]u8 {
            _ = self;
            _ = allocator;
        }

        pub fn serialize(self: *MCastDefConfig, allocator: all.Allocator) ![]u8 {
            return serializeTipon(allocator, MCastDefConfig, @as(*MCastDefConfig, self));
        }

        fn encode(self: *const MCastDefConfig, buffer: *EncodeBuffer) !usize {
            var tuta_longo: usize = 0;

            if (self.SendBuffer) |val| {
                if (val != 134217727) {
                    tuta_longo += try buffer.encodeInt32(val);
                    tuta_longo += try buffer.encodeVarint(48);
                }
            } //2 opt - def - no varlong

            if (self.ReceiveBuffer) |val| {
                if (val != 134217727) {
                    tuta_longo += try buffer.encodeInt32(val);
                    tuta_longo += try buffer.encodeVarint(40);
                }
            } //2 opt - def - no varlong

            if (self.TTL) |val| {
                if (val != 1) {
                    tuta_longo += try buffer.encodeInt32(val);
                    tuta_longo += try buffer.encodeVarint(32);
                }
            } //2 opt - def - no varlong

            tuta_longo += try buffer.encodeInt32(self.Port);
            tuta_longo += try buffer.encodeVarint(24);
            //5 req - no def - no varlong

            if (!equal(u8, self.MCastAddress, "239.255.0.1")) {
                const st_longa = try buffer.encodeString(self.MCastAddress);
                tuta_longo += st_longa;
                tuta_longo += try buffer.encodeVarint(st_longa);
                tuta_longo += try buffer.encodeVarint(18);
            } //8 req - def - varlong

            if (!equal(u8, self.LocalAddress, "Any")) {
                const st_longa = try buffer.encodeString(self.LocalAddress);
                tuta_longo += st_longa;
                tuta_longo += try buffer.encodeVarint(st_longa);
                tuta_longo += try buffer.encodeVarint(10);
            } //8 req - def - varlong

            return tuta_longo;
        }

        pub fn deserialize(allocator: all.Allocator, input: []const u8) !MCastDefConfig {
            return deserializeTipon(allocator, MCastDefConfig, input);
        }

        fn decode(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !MCastDefConfig {
            var mia_Mesagho = try MCastDefConfig.initDefault(allocator);

            var end: usize = undefined;
            if (data_length) |val|
                end = buffer.read_index + val
            else
                end = buffer.buffer.len;

            while (buffer.read_index < end) {
                const key: u64 = buffer.decodeVarint() catch 0;
                const wire_type = key & 0x7;
                const field_number = key >> 3;

                if (field_number == 1 and wire_type == 2)
                    mia_Mesagho.LocalAddress = try buffer.decodeString(try buffer.decodeVarint())
                else if (field_number == 2 and wire_type == 2)
                    mia_Mesagho.MCastAddress = try buffer.decodeString(try buffer.decodeVarint())
                else if (field_number == 3 and wire_type == 0)
                    mia_Mesagho.Port = try buffer.decodeInt32()
                else if (field_number == 4 and wire_type == 0)
                    mia_Mesagho.TTL = try buffer.decodeInt32()
                else if (field_number == 5 and wire_type == 0)
                    mia_Mesagho.ReceiveBuffer = try buffer.decodeInt32()
                else if (field_number == 6 and wire_type == 0)
                    mia_Mesagho.SendBuffer = try buffer.decodeInt32();
            }

            return mia_Mesagho;
        }
    };

    pub const BCastDefConfig = struct {
        LocalAddress: []const u8 = "Any",
        BCastAddress: []const u8 = "192.168.2.255",
        Port: i32 = 40069,
        ReceiveBuffer: ?i32 = 134217727,
        SendBuffer: ?i32 = 134217727,

        pub fn initDefault(allocator: all.Allocator) !BCastDefConfig {
            const self = try allocator.create(BCastDefConfig);
            self.* = BCastDefConfig{
                .LocalAddress = "Any",
                .BCastAddress = "192.168.2.255",
                .Port = 40069,
                .ReceiveBuffer = 134217727,
                .SendBuffer = 134217727,
            };
            return self.*;
        }

        pub fn skribiAlZonTeksto(self: *BCastDefConfig, allocator: all.Allocator) ![]u8 {
            return skribiTiponAlZonTeksto(allocator, BCastDefConfig, @as(*BCastDefConfig, self));
        }

        pub fn skribiAlZonDosiero(self: *BCastDefConfig, allocator: all.Allocator, path: []const u8) !void {
            try skribiTiponAlZonDosiero(allocator, BCastDefConfig, @as(*BCastDefConfig, self), path);
        }

        pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !BCastDefConfig {
            return legiTiponElZonTeksto(allocator, BCastDefConfig, input);
        }

        pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !BCastDefConfig {
            return legiTiponElZonDosiero(allocator, BCastDefConfig, path);
        }

        pub fn skribiAlProtobufTeksto(self: *const BCastDefConfig, allocator: all.Allocator, ind: []const u8) ![]const u8 {
            const indent = std.mem.concatWithSentinel(std.heap.page_allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
            var bufro: std.ArrayList(u8) = .empty;
            if (equal(u8, indent, "")) {
                {}
            }

            try bufro.print(allocator, "{s}LocalAddress: \"{s}\"\n", .{ ind, self.LocalAddress });
            try bufro.print(allocator, "{s}BCastAddress: \"{s}\"\n", .{ ind, self.BCastAddress });
            try bufro.print(allocator, "{s}Port: {any}\n", .{ ind, self.Port });
            if (self.ReceiveBuffer) |val|
                try bufro.print(allocator, "{s}ReceiveBuffer: {any}\n", .{ ind, val });
            if (self.SendBuffer) |val|
                try bufro.print(allocator, "{s}SendBuffer: {any}\n", .{ ind, val });

            return bufro.toOwnedSlice(allocator);
        }

        pub fn skribiAlJsonTeksto(self: *const BCastDefConfig, allocator: all.Allocator) ![]const u8 {
            var skribila_asignilo = std.Io.Writer.Allocating.init(allocator);

            std.json.fmt(self, .{ .whitespace = .indent_3 }).format(&skribila_asignilo.writer) catch |err| {
                std.debug.print("eraro dum seriigo: {}\n", .{err});
                return err;
            };

            return skribila_asignilo.writer.buffered();
        }

        pub fn skribiAlPBDosiero(self: *BCastDefConfig, allocator: all.Allocator) ![]u8 {
            _ = self;
            _ = allocator;
        }

        pub fn serialize(self: *BCastDefConfig, allocator: all.Allocator) ![]u8 {
            return serializeTipon(allocator, BCastDefConfig, @as(*BCastDefConfig, self));
        }

        fn encode(self: *const BCastDefConfig, buffer: *EncodeBuffer) !usize {
            var tuta_longo: usize = 0;

            if (self.SendBuffer) |val| {
                if (val != 134217727) {
                    tuta_longo += try buffer.encodeInt32(val);
                    tuta_longo += try buffer.encodeVarint(40);
                }
            } //2 opt - def - no varlong

            if (self.ReceiveBuffer) |val| {
                if (val != 134217727) {
                    tuta_longo += try buffer.encodeInt32(val);
                    tuta_longo += try buffer.encodeVarint(32);
                }
            } //2 opt - def - no varlong

            if (self.Port != 40069) {
                tuta_longo += try buffer.encodeInt32(self.Port);
                tuta_longo += try buffer.encodeVarint(24);
            } //6  req - def - no varlong

            if (!equal(u8, self.BCastAddress, "192.168.2.255")) {
                const st_longa = try buffer.encodeString(self.BCastAddress);
                tuta_longo += st_longa;
                tuta_longo += try buffer.encodeVarint(st_longa);
                tuta_longo += try buffer.encodeVarint(18);
            } //8 req - def - varlong

            if (!equal(u8, self.LocalAddress, "Any")) {
                const st_longa = try buffer.encodeString(self.LocalAddress);
                tuta_longo += st_longa;
                tuta_longo += try buffer.encodeVarint(st_longa);
                tuta_longo += try buffer.encodeVarint(10);
            } //8 req - def - varlong

            return tuta_longo;
        }

        pub fn deserialize(allocator: all.Allocator, input: []const u8) !BCastDefConfig {
            return deserializeTipon(allocator, BCastDefConfig, input);
        }

        fn decode(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !BCastDefConfig {
            var mia_Mesagho = try BCastDefConfig.initDefault(allocator);

            var end: usize = undefined;
            if (data_length) |val|
                end = buffer.read_index + val
            else
                end = buffer.buffer.len;

            while (buffer.read_index < end) {
                const key: u64 = buffer.decodeVarint() catch 0;
                const wire_type = key & 0x7;
                const field_number = key >> 3;

                if (field_number == 1 and wire_type == 2)
                    mia_Mesagho.LocalAddress = try buffer.decodeString(try buffer.decodeVarint())
                else if (field_number == 2 and wire_type == 2)
                    mia_Mesagho.BCastAddress = try buffer.decodeString(try buffer.decodeVarint())
                else if (field_number == 3 and wire_type == 0)
                    mia_Mesagho.Port = try buffer.decodeInt32()
                else if (field_number == 4 and wire_type == 0)
                    mia_Mesagho.ReceiveBuffer = try buffer.decodeInt32()
                else if (field_number == 5 and wire_type == 0)
                    mia_Mesagho.SendBuffer = try buffer.decodeInt32();
            }

            return mia_Mesagho;
        }
    };

    pub const UDPStarDefConfig = struct {
        LocalAddress: []const u8 = "Any",
        Port: i32 = 40069,
        EndPoint: []EndPointDef,
        ReceiveBuffer: ?i32 = 134217727,
        SendBuffer: ?i32 = 134217727,

        pub fn initDefault(allocator: all.Allocator) !UDPStarDefConfig {
            const self = try allocator.create(UDPStarDefConfig);
            self.* = UDPStarDefConfig{
                .LocalAddress = "Any",
                .Port = 40069,
                .EndPoint = try allocator.alloc(EndPointDef, 0),
                .ReceiveBuffer = 134217727,
                .SendBuffer = 134217727,
            };
            return self.*;
        }

        pub fn skribiAlZonTeksto(self: *UDPStarDefConfig, allocator: all.Allocator) ![]u8 {
            return skribiTiponAlZonTeksto(allocator, UDPStarDefConfig, @as(*UDPStarDefConfig, self));
        }

        pub fn skribiAlZonDosiero(self: *UDPStarDefConfig, allocator: all.Allocator, path: []const u8) !void {
            try skribiTiponAlZonDosiero(allocator, UDPStarDefConfig, @as(*UDPStarDefConfig, self), path);
        }

        pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !UDPStarDefConfig {
            return legiTiponElZonTeksto(allocator, UDPStarDefConfig, input);
        }

        pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !UDPStarDefConfig {
            return legiTiponElZonDosiero(allocator, UDPStarDefConfig, path);
        }

        pub fn skribiAlProtobufTeksto(self: *const UDPStarDefConfig, allocator: all.Allocator, ind: []const u8) ![]const u8 {
            const indent = std.mem.concatWithSentinel(std.heap.page_allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
            var bufro: std.ArrayList(u8) = .empty;
            if (equal(u8, indent, "")) {
                {}
            }

            try bufro.print(allocator, "{s}LocalAddress: \"{s}\"\n", .{ ind, self.LocalAddress });
            try bufro.print(allocator, "{s}Port: {any}\n", .{ ind, self.Port });
            for (self.EndPoint) |obj|
                try bufro.print(allocator, "{s}EndPoint {{\n{s}{s}}}\n", .{ ind, try obj.skribiAlProtobufTeksto(allocator, indent), ind });
            if (self.ReceiveBuffer) |val|
                try bufro.print(allocator, "{s}ReceiveBuffer: {any}\n", .{ ind, val });
            if (self.SendBuffer) |val|
                try bufro.print(allocator, "{s}SendBuffer: {any}\n", .{ ind, val });

            return bufro.toOwnedSlice(allocator);
        }

        pub fn skribiAlJsonTeksto(self: *const UDPStarDefConfig, allocator: all.Allocator) ![]const u8 {
            var skribila_asignilo = std.Io.Writer.Allocating.init(allocator);

            std.json.fmt(self, .{ .whitespace = .indent_3 }).format(&skribila_asignilo.writer) catch |err| {
                std.debug.print("eraro dum seriigo: {}\n", .{err});
                return err;
            };

            return skribila_asignilo.writer.buffered();
        }

        pub fn skribiAlPBDosiero(self: *UDPStarDefConfig, allocator: all.Allocator) ![]u8 {
            _ = self;
            _ = allocator;
        }

        pub fn serialize(self: *UDPStarDefConfig, allocator: all.Allocator) ![]u8 {
            return serializeTipon(allocator, UDPStarDefConfig, @as(*UDPStarDefConfig, self));
        }

        fn encode(self: *const UDPStarDefConfig, buffer: *EncodeBuffer) !usize {
            var tuta_longo: usize = 0;

            if (self.SendBuffer) |val| {
                if (val != 134217727) {
                    tuta_longo += try buffer.encodeInt32(val);
                    tuta_longo += try buffer.encodeVarint(40);
                }
            } //2 opt - def - no varlong

            if (self.ReceiveBuffer) |val| {
                if (val != 134217727) {
                    tuta_longo += try buffer.encodeInt32(val);
                    tuta_longo += try buffer.encodeVarint(32);
                }
            } //2 opt - def - no varlong

            for (self.EndPoint) |item| {
                const EndPoint_longa = try item.encode(buffer);
                tuta_longo += EndPoint_longa;
                tuta_longo += try buffer.encodeVarint(EndPoint_longa);
                tuta_longo += try buffer.encodeVarint(26);
            } // 11  rept - no def - varlong

            if (self.Port != 40069) {
                tuta_longo += try buffer.encodeInt32(self.Port);
                tuta_longo += try buffer.encodeVarint(16);
            } //6  req - def - no varlong

            if (!equal(u8, self.LocalAddress, "Any")) {
                const st_longa = try buffer.encodeString(self.LocalAddress);
                tuta_longo += st_longa;
                tuta_longo += try buffer.encodeVarint(st_longa);
                tuta_longo += try buffer.encodeVarint(10);
            } //8 req - def - varlong

            return tuta_longo;
        }

        pub fn deserialize(allocator: all.Allocator, input: []const u8) !UDPStarDefConfig {
            return deserializeTipon(allocator, UDPStarDefConfig, input);
        }

        fn decode(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !UDPStarDefConfig {
            var mia_Mesagho = try UDPStarDefConfig.initDefault(allocator);

            var end: usize = undefined;
            if (data_length) |val|
                end = buffer.read_index + val
            else
                end = buffer.buffer.len;

            var EndPoint_list: std.ArrayList(EndPointDef) = .empty;

            while (buffer.read_index < end) {
                const key: u64 = buffer.decodeVarint() catch 0;
                const wire_type = key & 0x7;
                const field_number = key >> 3;

                if (field_number == 1 and wire_type == 2)
                    mia_Mesagho.LocalAddress = try buffer.decodeString(try buffer.decodeVarint())
                else if (field_number == 2 and wire_type == 0)
                    mia_Mesagho.Port = try buffer.decodeInt32()
                else if (field_number == 3 and wire_type == 2) {
                    try EndPoint_list.append(allocator, try EndPointDef.decode(allocator, buffer, try buffer.decodeVarint()));
                } else if (field_number == 4 and wire_type == 0)
                    mia_Mesagho.ReceiveBuffer = try buffer.decodeInt32()
                else if (field_number == 5 and wire_type == 0)
                    mia_Mesagho.SendBuffer = try buffer.decodeInt32();
            }

            mia_Mesagho.EndPoint = try EndPoint_list.toOwnedSlice(allocator);

            return mia_Mesagho;
        }
    };

    pub const EndPointDef = struct {
        Host: []const u8,
        Port: i32 = 40069,
        Nenio: []i32,
        Neniam: []f32,

        pub fn initDefault(allocator: all.Allocator) !EndPointDef {
            const self = try allocator.create(EndPointDef);
            self.* = EndPointDef{
                .Host = "",
                .Port = 40069,
                .Nenio = try allocator.alloc(i32, 0),
                .Neniam = try allocator.alloc(f32, 0),
            };
            return self.*;
        }

        pub fn skribiAlZonTeksto(self: *EndPointDef, allocator: all.Allocator) ![]u8 {
            return skribiTiponAlZonTeksto(allocator, EndPointDef, @as(*EndPointDef, self));
        }

        pub fn skribiAlZonDosiero(self: *EndPointDef, allocator: all.Allocator, path: []const u8) !void {
            try skribiTiponAlZonDosiero(allocator, EndPointDef, @as(*EndPointDef, self), path);
        }

        pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !EndPointDef {
            return legiTiponElZonTeksto(allocator, EndPointDef, input);
        }

        pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !EndPointDef {
            return legiTiponElZonDosiero(allocator, EndPointDef, path);
        }

        pub fn skribiAlProtobufTeksto(self: *const EndPointDef, allocator: all.Allocator, ind: []const u8) ![]const u8 {
            const indent = std.mem.concatWithSentinel(std.heap.page_allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
            var bufro: std.ArrayList(u8) = .empty;
            if (equal(u8, indent, "")) {
                {}
            }

            try bufro.print(allocator, "{s}Host: \"{s}\"\n", .{ ind, self.Host });
            try bufro.print(allocator, "{s}Port: {any}\n", .{ ind, self.Port });
            for (self.Nenio) |obj|
                try bufro.print(allocator, "{s}Nenio: {any}\n", .{ ind, obj });
            for (self.Neniam) |obj|
                try bufro.print(allocator, "{s}Neniam: {any}\n", .{ ind, obj });

            return bufro.toOwnedSlice(allocator);
        }

        pub fn skribiAlJsonTeksto(self: *const EndPointDef, allocator: all.Allocator) ![]const u8 {
            var skribila_asignilo = std.Io.Writer.Allocating.init(allocator);

            std.json.fmt(self, .{ .whitespace = .indent_3 }).format(&skribila_asignilo.writer) catch |err| {
                std.debug.print("eraro dum seriigo: {}\n", .{err});
                return err;
            };

            return skribila_asignilo.writer.buffered();
        }

        pub fn skribiAlPBDosiero(self: *EndPointDef, allocator: all.Allocator) ![]u8 {
            _ = self;
            _ = allocator;
        }

        pub fn serialize(self: *EndPointDef, allocator: all.Allocator) ![]u8 {
            return serializeTipon(allocator, EndPointDef, @as(*EndPointDef, self));
        }

        fn encode(self: *const EndPointDef, buffer: *EncodeBuffer) !usize {
            var tuta_longo: usize = 0;

            var Neniam_longa: usize = 0;
            for (self.Neniam) |item|
                Neniam_longa += try buffer.encodeFloat(item);
            tuta_longo += Neniam_longa;
            tuta_longo += try buffer.encodeVarint(Neniam_longa);
            tuta_longo += try buffer.encodeVarint(34);
            // 9 rept - no def - no varlong  PACKED

            for (self.Nenio) |item| {
                tuta_longo += try buffer.encodeInt32(item);
                tuta_longo += try buffer.encodeVarint(26);
            } // 9 rept - no def - no varlong

            if (self.Port != 40069) {
                tuta_longo += try buffer.encodeInt32(self.Port);
                tuta_longo += try buffer.encodeVarint(16);
            } //6  req - def - no varlong

            const Host_longa = try buffer.encodeString(self.Host);
            tuta_longo += Host_longa;
            tuta_longo += try buffer.encodeVarint(Host_longa);
            tuta_longo += try buffer.encodeVarint(10);
            //7  req - no def - varlong

            return tuta_longo;
        }

        pub fn deserialize(allocator: all.Allocator, input: []const u8) !EndPointDef {
            return deserializeTipon(allocator, EndPointDef, input);
        }

        fn decode(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !EndPointDef {
            var mia_Mesagho = try EndPointDef.initDefault(allocator);

            var end: usize = undefined;
            if (data_length) |val|
                end = buffer.read_index + val
            else
                end = buffer.buffer.len;

            var Nenio_list: std.ArrayList(i32) = .empty;
            var Neniam_list: std.ArrayList(f32) = .empty;

            while (buffer.read_index < end) {
                const key: u64 = buffer.decodeVarint() catch 0;
                const wire_type = key & 0x7;
                const field_number = key >> 3;

                if (field_number == 1 and wire_type == 2)
                    mia_Mesagho.Host = try buffer.decodeString(try buffer.decodeVarint())
                else if (field_number == 2 and wire_type == 0)
                    mia_Mesagho.Port = try buffer.decodeInt32()
                else if (field_number == 3 and wire_type == 2) {
                    try Nenio_list.append(allocator, try buffer.decodeInt32());
                } else if (field_number == 4 and wire_type == 2) {
                    const Neniam_len = try buffer.decodeVarint();
                    const Neniam_end = buffer.read_index + Neniam_len;
                    while (buffer.read_index < Neniam_end)
                        try Neniam_list.append(allocator, try buffer.decodeFloat());
                    if (buffer.read_index != Neniam_end) return error.AllocationFailed;
                }
            }

            mia_Mesagho.Nenio = try Nenio_list.toOwnedSlice(allocator);
            mia_Mesagho.Neniam = try Neniam_list.toOwnedSlice(allocator);

            return mia_Mesagho;
        }
    };

    pub const CrossConnectorDef = struct {
        Transports: [][]const u8,

        pub fn initDefault(allocator: all.Allocator) !CrossConnectorDef {
            const self = try allocator.create(CrossConnectorDef);
            self.* = CrossConnectorDef{
                .Transports = try allocator.alloc([]const u8, 0),
            };
            return self.*;
        }

        pub fn skribiAlZonTeksto(self: *CrossConnectorDef, allocator: all.Allocator) ![]u8 {
            return skribiTiponAlZonTeksto(allocator, CrossConnectorDef, @as(*CrossConnectorDef, self));
        }

        pub fn skribiAlZonDosiero(self: *CrossConnectorDef, allocator: all.Allocator, path: []const u8) !void {
            try skribiTiponAlZonDosiero(allocator, CrossConnectorDef, @as(*CrossConnectorDef, self), path);
        }

        pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !CrossConnectorDef {
            return legiTiponElZonTeksto(allocator, CrossConnectorDef, input);
        }

        pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !CrossConnectorDef {
            return legiTiponElZonDosiero(allocator, CrossConnectorDef, path);
        }

        pub fn skribiAlProtobufTeksto(self: *const CrossConnectorDef, allocator: all.Allocator, ind: []const u8) ![]const u8 {
            const indent = std.mem.concatWithSentinel(std.heap.page_allocator, u8, &[_][]const u8{ ind, "    " }, 0) catch unreachable;
            var bufro: std.ArrayList(u8) = .empty;
            if (equal(u8, indent, "")) {
                {}
            }

            for (self.Transports) |obj|
                try bufro.print(allocator, "{s}Transports: \"{s}\"\n", .{ ind, obj });

            return bufro.toOwnedSlice(allocator);
        }

        pub fn skribiAlJsonTeksto(self: *const CrossConnectorDef, allocator: all.Allocator) ![]const u8 {
            var skribila_asignilo = std.Io.Writer.Allocating.init(allocator);

            std.json.fmt(self, .{ .whitespace = .indent_3 }).format(&skribila_asignilo.writer) catch |err| {
                std.debug.print("eraro dum seriigo: {}\n", .{err});
                return err;
            };

            return skribila_asignilo.writer.buffered();
        }

        pub fn skribiAlPBDosiero(self: *CrossConnectorDef, allocator: all.Allocator) ![]u8 {
            _ = self;
            _ = allocator;
        }

        pub fn serialize(self: *CrossConnectorDef, allocator: all.Allocator) ![]u8 {
            return serializeTipon(allocator, CrossConnectorDef, @as(*CrossConnectorDef, self));
        }

        fn encode(self: *const CrossConnectorDef, buffer: *EncodeBuffer) !usize {
            var tuta_longo: usize = 0;

            for (self.Transports) |item| {
                const Transports_longa = try buffer.encodeString(item);
                tuta_longo += Transports_longa;
                tuta_longo += try buffer.encodeVarint(Transports_longa);
                tuta_longo += try buffer.encodeVarint(10);
            } // 11  rept - no def - varlong

            return tuta_longo;
        }

        pub fn deserialize(allocator: all.Allocator, input: []const u8) !CrossConnectorDef {
            return deserializeTipon(allocator, CrossConnectorDef, input);
        }

        fn decode(allocator: all.Allocator, buffer: *DecodeBuffer, data_length: ?usize) !CrossConnectorDef {
            var mia_Mesagho = try CrossConnectorDef.initDefault(allocator);

            var end: usize = undefined;
            if (data_length) |val|
                end = buffer.read_index + val
            else
                end = buffer.buffer.len;

            var Transports_list: std.ArrayList([]const u8) = .empty;

            while (buffer.read_index < end) {
                const key: u64 = buffer.decodeVarint() catch 0;
                const wire_type = key & 0x7;
                const field_number = key >> 3;

                if (field_number == 1 and wire_type == 2) {
                    try Transports_list.append(allocator, try buffer.decodeString(try buffer.decodeVarint()));
                }
            }

            mia_Mesagho.Transports = try Transports_list.toOwnedSlice(allocator);

            return mia_Mesagho;
        }
    };
}; // ProtocolBus

//////////////////////////////////////////////
/// //////////////////////////////////////////
/// //////////////////////////////////////////
//////////////////////////////////////////////

const TekstaFormato = enum(u8) {
    TF_ZIG_ZON,
    TF_JSON,
    TF_PROTOBUF,
    //    TF_ASN1,
};

const BinaraFormato = enum(u8) {
    BF_PROTOBUF,
    BF_Base64,
    //    BF_ASN1_DER,
    //    BF_OMG_CDR,
};

pub fn skribiTiponAlTeksto(allocator: all.Allocator, comptime T: type, value: *T, t_formato: TekstaFormato) ![]u8 {
    var skribila_asignilo = std.Io.Writer.Allocating.init(allocator);

    const self = @as(T, value.*);
    const bytes: *[]u8 = undefined;
    switch (t_formato) {
        .TF_ZIG_ZON => {
            zon.stringify.serialize(self, .{}, &skribila_asignilo.writer) catch |err| {
                std.debug.print("eraro dum seriigo: {}\n", .{err});
                return err;
            };
        },
        .TF_JSON => {
            std.json.fmt(self, .{ .whitespace = .indent_3 }).format(&skribila_asignilo.writer) catch |err| {
                std.debug.print("eraro dum seriigo: {}\n", .{err});
                return err;
            };
        },
        .TF_PROTOBUF => {
            bytes = try self.skribiAlProtobufTeksto(allocator, "") catch |err| {
                std.debug.print("eraro dum seriigo: {}\n", .{err});
                return err;
            };
        },
        else => {
            return error.UnsupportedFormat;
        },
    }

    return if (t_formato == .TF_PROTOBUF) bytes else skribila_asignilo.writer.buffered();
}

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
    const teksto = try skribiTiponAlZonTeksto(allocator, T, value);

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
