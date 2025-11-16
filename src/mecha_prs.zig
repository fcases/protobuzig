const std = @import("std");
const equal = std.mem.eql;
const dbgPrint = std.debug.print;
const shpa = std.heap.page_allocator;
const mecha = @import("mecha");

///////////////////////////////////////////////////////
///////////////////////////////////////////////////////

const pbError = error{
    InvalidFieldLabel,
    // InvalidFieldType,
    UnknownWireType,
    AllocationFailed,
    WriteError,
};

pub const Tipoj = enum {
    TYPE_MESSAGE,
    TYPE_ENUM,
    TYPE_BOOL,
    TYPE_STRING,
    TYPE_INT32,
    TYPE_INT64,
    TYPE_SINT32,
    TYPE_SINT64,
    TYPE_SFIXED32,
    TYPE_SFIXED64,
    TYPE_UINT32,
    TYPE_UINT64,
    TYPE_FIXED32,
    TYPE_FIXED64,
    TYPE_FLOAT,
    TYPE_DOUBLE,
    TYPE_BYTES,
    TYPE_UNRESOLVED, // para tipos de mensaje o enum no resueltos aún
};

pub const Etikedo = enum { LABEL_OPTIONAL, LABEL_REQUIRED, LABEL_REPEATED };

fn getFieldLabelEnum(label: []const u8) !Etikedo {
    if (equal(u8, label, "optional")) return .LABEL_OPTIONAL;
    if (equal(u8, label, "required")) return .LABEL_REQUIRED;
    if (equal(u8, label, "repeated")) return .LABEL_REPEATED;
    return pbError.InvalidFieldLabel;
}

pub fn getFieldTypeEnum(field_type: []const u8) !Tipoj {
    if (equal(u8, field_type, "message")) return .TYPE_MESSAGE;
    if (equal(u8, field_type, "enum")) return .TYPE_ENUM;
    if (equal(u8, field_type, "bool")) return .TYPE_BOOL;
    if (equal(u8, field_type, "string")) return .TYPE_STRING;
    if (equal(u8, field_type, "int32")) return .TYPE_INT32;
    if (equal(u8, field_type, "int64")) return .TYPE_INT64;
    if (equal(u8, field_type, "sint32")) return .TYPE_SINT32;
    if (equal(u8, field_type, "sint64")) return .TYPE_SINT64;
    if (equal(u8, field_type, "sfixed32")) return .TYPE_SFIXED32;
    if (equal(u8, field_type, "sfixed64")) return .TYPE_SFIXED64;
    if (equal(u8, field_type, "uint32")) return .TYPE_UINT32;
    if (equal(u8, field_type, "uint64")) return .TYPE_UINT64;
    if (equal(u8, field_type, "fixed32")) return .TYPE_FIXED32;
    if (equal(u8, field_type, "fixed64")) return .TYPE_FIXED64;
    if (equal(u8, field_type, "float")) return .TYPE_FLOAT;
    if (equal(u8, field_type, "double")) return .TYPE_DOUBLE;
    if (equal(u8, field_type, "bytes")) return .TYPE_BYTES;
    // return pbError.InvalidFieldType;
    return .TYPE_UNRESOLVED; // para tipos de mensaje o enum";
}

///////////////////////////////////////////////////////
///////////////////////////////////////////////////////
pub const EnumTipo = enum(u8) { LINIO, SYNTAX, IMPORT, PACKAGE, ENUM, OPTION, MESSAGE, FIELD, ALIA };

pub const RespondUnio = union {
    l: []u8,
    s: []u8,
    i: []u8,
    p: []u8,
    e: Enum,
    o: Option,
    m: Message,
    f: Field,
};

pub const Respondo = struct { Type: EnumTipo, Data: RespondUnio = undefined };

pub const Option = struct {
    name: []const u8,
    value: []const u8,
};

pub const EnumValue = struct {
    name: []const u8,
    number: u32,
};

pub const Enum = struct {
    name: []const u8,
    values: []EnumValue,
};

pub const Field = struct { name: []const u8, field_type: []const u8, field_type_enum: Tipoj = undefined, label: []const u8, label_enum: Etikedo, number: u32, default_value: ?[]const u8, packed_value: bool = false };

pub const Message = struct {
    name: []const u8,
    fields: []Field,
    internal_enums: []Enum, // enums dentro de mensajes
    internal_msgs: []Message, // Messages dentro de mensajes
};

pub const ProtoFile = struct {
    syntax: []const u8 = "proto2", // "proto3" o "proto2"
    package_name: ?[]const u8 = "",
    imports: [][]const u8 = &.{},
    options: []Option,
    messages: []Message,
    enums: []Enum, // enums fuera de mensajes
};

///////////////////////////////////////////////////////
///////////////////////////////////////////////////////

const ws = mecha.oneOf(.{
    mecha.string(" "), // espacio
    mecha.string("\t"), // tab
    mecha.string("\r"), // tab
    mecha.string("\n"), // salto de línea
}).many(.{ .collect = false });

const anu_parser = mecha.combine(.{
    mecha.ascii.alphanumeric.many(.{ .min = 1, .collect = true }).asStr(), //0
    mecha.combine(.{
        mecha.string("_"),
        mecha.ascii.alphanumeric.many(.{ .min = 1, .collect = true }).asStr(),
    }).many(.{ .collect = true }).opt(), // 1
}).map(struct {
    pub fn mapFn(items: anytype) []const u8 {
        if (items[1]) |more| {
            var full_name = std.ArrayList(u8).empty;
            full_name.appendSlice(shpa, items[0]) catch {};
            for (more) |part| {
                full_name.appendSlice(shpa, part[0]) catch {}; // "_"
                full_name.appendSlice(shpa, part[1]) catch {}; // next part
            }
            const result = full_name.toOwnedSlice(shpa) catch &[_]u8{};
            return result;
        } else {
            return shpa.dupe(u8, items[0]) catch &[_]u8{};
        }
    }
}.mapFn);

fn quotedStringFn(gpa: std.mem.Allocator, input: []const u8) error{ OtherError, OutOfMemory }!mecha.Result([]const u8) {
    _ = gpa;
    if (input.len == 0 or input[0] != '"') return error.OtherError;

    var i: usize = 1;
    while (i < input.len and input[i] != '"') : (i += 1) {}
    if (i >= input.len) return error.OtherError;

    return mecha.Result([]const u8).ok(i + 1, input[0 .. i + 1]);
}
const quoted_string = mecha.Parser([]const u8){ .parse = &quotedStringFn };

fn isNotNewline(c: u8) bool {
    // Retorna true si el byte NO es un salto de línea (ASCII 10)
    return c != '\n';
}

// Parser que coincide con UN SOLO byte que no sea un salto de línea.
const non_newline_char = mecha.ascii.wrap(isNotNewline);

//////////////////////////////////////////////
//////////////////////////////////////////////
//////////////////////////////////////////////
//////////////////////////////////////////////

const syntax_parser = mecha.combine(.{
    ws.discard(), // _
    mecha.string("syntax").discard(), ws.discard(), // _, _
    mecha.string("=").discard(), ws.discard(), // _, _
    mecha.oneOf(.{
        mecha.ascii.alphanumeric.many(.{ .min = 1, .collect = true }).asStr(),
        quoted_string,
    }),
    ws.discard(), // 0, _
    mecha.string(";").opt().discard(), ws.discard(), // _, _
}).map(struct {
    pub fn mapFn(items: anytype) Respondo {
        dbgPrint("found syntax value: {s}\n\n", .{items});
        return Respondo{ .Type = .SYNTAX, .Data = .{ .s = shpa.dupe(u8, items) catch &[_]u8{} } };
    }
}.mapFn);

const import_parser = mecha.combine(.{
    ws, // 0
    mecha.string("import"), ws, // 1, 2
    quoted_string, ws.discard(), // 3, _
    mecha.string(";").opt().discard(), ws.discard(), // _, _
}).map(struct {
    pub fn mapFn(items: anytype) Respondo {
        dbgPrint("found import: {s}\n\n", .{items[3]});
        return Respondo{ .Type = .IMPORT, .Data = .{ .i = shpa.dupe(u8, items[3]) catch &[_]u8{} } };
    }
}.mapFn);

const package_parser = mecha.combine(.{
    ws.discard(), // _
    mecha.string("package").discard(), ws.discard(), // _, _
    mecha.combine(.{
        anu_parser,
        mecha.combine(.{
            mecha.string("."),
            anu_parser,
        }).many(.{ .collect = true }).opt(),
    }),
    ws.discard(), // 0, _
    mecha.string(";").opt().discard(), ws.discard(), // _, _
}).map(struct {
    pub fn mapFn(items: anytype) Respondo {
        if (items[1]) |more| {
            var full_name = std.ArrayList(u8).empty;
            full_name.appendSlice(shpa, items[0]) catch {};
            for (more) |part| {
                full_name.appendSlice(shpa, part[0]) catch {}; // "."
                full_name.appendSlice(shpa, part[1]) catch {}; // next part
            }
            const result: []u8 = full_name.toOwnedSlice(shpa) catch &[_]u8{};
            full_name.deinit(shpa);
            dbgPrint("found Package value: {s}\n\n", .{result});
            return Respondo{ .Type = .PACKAGE, .Data = .{ .p = result } };
        } else {
            dbgPrint("found Package value: {s}\n\n", .{items[0]});
            return Respondo{ .Type = .PACKAGE, .Data = .{ .p = shpa.dupe(u8, items[0]) catch &[_]u8{} } };
        }
    }
}.mapFn);

const option_parser = mecha.combine(.{
    ws, // 0
    mecha.string("option"), ws, // 1,2
    anu_parser, ws, // 3,4
    mecha.string("="), ws, // 5,6
    mecha.ascii.alphanumeric.many(.{ .min = 1, .collect = true }).asStr(), ws, // 7,8
    mecha.string(";").opt(), ws.discard(), // 9, _
}).map(struct {
    pub fn mapFn(items: anytype) Respondo {
        const value = shpa.dupe(u8, items[7]) catch &[_]u8{};
        const name = items[3];
        dbgPrint("found option: {s}: {s}\n\n", .{ name, value });

        return Respondo{ .Type = .OPTION, .Data = .{ .o = Option{
            .name = name,
            .value = value,
        } } };
    }
}.mapFn);

const enum_parser = mecha.combine(.{
    ws, // 0
    mecha.string("enum"), ws, // 1, 2
    anu_parser, ws, // 3, 4
    mecha.string("{"), ws, // 5, 6
    mecha.many( // 7
        mecha.combine(.{
            ws, // 7: 0
            anu_parser, ws, // 7: 1, 2
            mecha.string("="), ws, // 7: 3, 4
            mecha.intToken(.{}), ws, // 7: 5, 6
            mecha.string(";").opt(), ws, // 7: 7, 8
        }).map(struct {
            pub fn mapFn(items: anytype) EnumValue {
                const name = shpa.dupe(u8, items[1]) catch &[_]u8{};
                const number = std.fmt.parseInt(u32, items[5], 10) catch 0;
                return EnumValue{
                    .name = name,
                    .number = number,
                };
            }
        }.mapFn), .{}),
    ws, // 8, 9
    mecha.string("}"), ws, // 10, 11
    mecha.string(";").opt(), ws, // 12,13
}).map(struct {
    pub fn mapFn(items: anytype) Respondo {
        const name = shpa.dupe(u8, items[3]) catch &[_]u8{};
        const enum_value_results = items[7];

        dbgPrint("found Enum: {s}\n", .{name});
        var values = std.ArrayList(EnumValue).empty;
        for (enum_value_results) |ev| {
            values.append(shpa, ev) catch {};
            dbgPrint("  -{s} = {d}\n", .{ ev.name, ev.number });
        }
        dbgPrint("\n", .{});

        return Respondo{ .Type = .ENUM, .Data = .{ .e = Enum{
            .name = name,
            .values = values.toOwnedSlice(shpa) catch &[_]EnumValue{},
        } } };
    }
}.mapFn);

const default_parser = mecha.combine(.{
    mecha.string("["), ws, // 0, 1
    mecha.string("default"), ws, // 2, 3
    mecha.string("="), ws, // 4, 5
    mecha.oneOf(.{
        anu_parser,
        quoted_string,
    }),
    ws, // 6, 7
    mecha.string("]"), // 8
}).map(struct {
    pub fn mapFn(items: anytype) []const u8 {
        return items[6];
    }
}.mapFn);

const packed_parser = mecha.combine(.{
    mecha.string("["), ws, // 0,1
    mecha.string("packed"), ws, // 2,3
    mecha.string("="),                                             ws, // 4,5
    mecha.oneOf(.{ mecha.string("true"), mecha.string("false") }),
    ws, // 6,7
    mecha.string("]"), // 8
}).map(struct {
    pub fn mapFn(items: anytype) []const u8 {
        return items[6];
    }
}.mapFn);

const field_parser = mecha.combine(.{
    ws.discard(), // ojo con esto
    mecha.oneOf(.{
        mecha.string("optional"),
        mecha.string("required"),
        mecha.string("repeated"),
    }),
    ws, // 0,1
    anu_parser, ws, // 2,3
    anu_parser, ws, // 4,5
    mecha.string("="), ws, // 6,7
    mecha.intToken(.{}), ws, // 8,9
    mecha.opt(default_parser), ws, // 10,11
    mecha.opt(packed_parser), ws, // 12,13
    mecha.string(";"), ws, // 14,15
}).map(struct {
    pub fn mapFn(items: anytype) Respondo {
        const label = shpa.dupe(u8, items[0]) catch &[_]u8{};
        const field_type = shpa.dupe(u8, items[2]) catch &[_]u8{};
        const name = shpa.dupe(u8, items[4]) catch &[_]u8{};
        const number = std.fmt.parseInt(u32, items[8], 10) catch 0;

        const default_value = if (items[10]) |def| shpa.dupe(u8, def) catch &[_]u8{} else null;
        const packed_value = if (items[12]) |pck| equal(u8, pck, "true") else false;

        return Respondo{ .Type = .FIELD, .Data = .{ .f = Field{
            .label = label,
            .label_enum = getFieldLabelEnum(label) catch @panic("Invalid field label"),
            .field_type = field_type,
            .field_type_enum = getFieldTypeEnum(field_type) catch @panic("Invalid field type"),
            .name = name,
            .number = number,
            .default_value = default_value,
            .packed_value = packed_value,
        } } };
    }
}.mapFn);

const message_internal_parser = mecha.combine(.{
    ws, // 0
    mecha.string("message"), ws, // 1,2
    anu_parser, ws, // 3,4
    mecha.string("{"), ws, // 5,6
    mecha.many(field_parser, .{}), ws, // 7,8
    mecha.string("}"), ws, // 9,10
    mecha.string(";").opt(), ws, // 11,12
}).map(struct {
    pub fn mapFn(items: anytype) Respondo {
        const name = shpa.dupe(u8, items[3]) catch &[_]u8{};
        const field_results = items[7];

        dbgPrint("found Message: {s}\n", .{name});
        var fields = std.ArrayList(Field).empty;
        for (field_results) |resp| {
            fields.append(shpa, resp.Data.f) catch {};
            const def_value: []const u8 = resp.Data.f.default_value orelse "void";
            const pck_value: []const u8 = if (resp.Data.f.label_enum == .LABEL_REPEATED and resp.Data.f.packed_value) ", packed" else "";
            dbgPrint("    {d}: {s} := {s} ( {s} , [{s}{s}] )\n", .{ resp.Data.f.number, resp.Data.f.name, resp.Data.f.field_type, resp.Data.f.label, def_value, pck_value });
        }
        dbgPrint("\n", .{});

        return Respondo{
            .Type = .MESSAGE,
            .Data = .{
                .m = Message{
                    .name = name,
                    .fields = fields.toOwnedSlice(shpa) catch &[_]Field{},
                    // Para Enums internos a Message
                    .internal_enums = &[_]Enum{},
                    .internal_msgs = &[_]Message{},
                },
            },
        };
    }
}.mapFn);

const message_parser = mecha.combine(.{
    ws, // 0
    mecha.string("message"), ws, // 1,2
    anu_parser, ws, // 3,4
    mecha.string("{"), ws, // 5,6
    mecha.oneOf(.{
        field_parser,
        enum_parser,
        message_internal_parser,
    }).many(.{ .collect = true }),
    ws, // 7,8
    mecha.string("}"), ws, // 9,10
    mecha.string(";").opt(), ws, // 11,12
}).map(struct {
    pub fn mapFn(items: anytype) Respondo {
        const name = shpa.dupe(u8, items[3]) catch &[_]u8{};
        const oneof_results = items[7];

        dbgPrint("found Message: {s}\n", .{name});
        var fields = std.ArrayList(Field).empty;
        var enums = std.ArrayList(Enum).empty;
        var msgs = std.ArrayList(Message).empty;
        for (oneof_results) |one| {
            switch (one.Type) {
                .ENUM => {
                    enums.append(shpa, one.Data.e) catch {};
                },
                .FIELD => {
                    fields.append(shpa, one.Data.f) catch {};
                },
                .MESSAGE => {
                    msgs.append(shpa, one.Data.m) catch {};
                },
                else => {},
            }
        }
        dbgPrint("\n", .{});

        return Respondo{ .Type = .MESSAGE, .Data = .{ .m = Message{
            .name = name,
            .fields = fields.toOwnedSlice(shpa) catch &[_]Field{},
            .internal_enums = enums.toOwnedSlice(shpa) catch &[_]Enum{},
            .internal_msgs = msgs.toOwnedSlice(shpa) catch &[_]Message{},
        } } };
    }
}.mapFn);

const other_line_parser = mecha.combine(.{
    non_newline_char.many(.{ .min = 1 }).discard(),
    mecha.string("\n").discard(),
}).map(struct {
    pub fn mapFn(items: anytype) Respondo {
        _ = items; // Ignorar el resultado void/tuple
        return Respondo{ .Type = .LINIO, .Data = .{ .l = &[_]u8{} } };
    }
}.mapFn);

pub const protofile_parser = mecha.oneOf(.{
    syntax_parser,
    import_parser,
    package_parser,
    option_parser,
    enum_parser,
    message_parser,
    other_line_parser,
}).many(.{ .collect = true }).map(struct {
    pub fn mapFn(items: anytype) ProtoFile {
        var mia_syntax: []u8 = &[_]u8{};
        var mia_imports = std.ArrayList([]const u8).empty;
        var mia_package: []u8 = &[_]u8{};
        var mia_options = std.ArrayList(Option).empty;
        var mia_enums = std.ArrayList(Enum).empty;
        var mia_messages = std.ArrayList(Message).empty;

        for (items) |it| {
            switch (it.Type) {
                .LINIO => {
                    // dbgPrint(".0 {s}\n", .{it.Data.l});
                },
                .SYNTAX => {
                    mia_syntax = it.Data.s;
                },
                .IMPORT => {
                    mia_imports.append(shpa, it.Data.i) catch {};
                },
                .PACKAGE => {
                    mia_package = it.Data.p;
                },
                .OPTION => {
                    mia_options.append(shpa, it.Data.o) catch {};
                },
                .ENUM => {
                    mia_enums.append(shpa, it.Data.e) catch {};
                },
                .MESSAGE => {
                    mia_messages.append(shpa, it.Data.m) catch {};
                },
                else => {},
            }
        }

        // Por ciuj tipojn .TYPE_UNRESOLVED
        for (mia_messages.items) |msg| {
            dbgPrint("msg {s}\n", .{msg.name});
            for (msg.fields, 0..) |field, i| {
                if (field.field_type_enum == .TYPE_UNRESOLVED) {
                    dbgPrint("Searching for unresolved: {s}\n", .{field.field_type});
                    for (mia_messages.items) |mm| {
                        if (equal(u8, mm.name, field.field_type)) {
                            msg.fields[i].field_type_enum = .TYPE_MESSAGE;
                            dbgPrint("message definition found: {s}\n\n", .{mm.name});
                            break;
                        }
                    }
                    for (mia_enums.items) |me| {
                        if (equal(u8, me.name, field.field_type)) {
                            msg.fields[i].field_type_enum = .TYPE_ENUM;
                            dbgPrint("enum definition found: {s}\n\n", .{me.name});
                            break;
                        }
                    }
                }
            }
        }

        return ProtoFile{
            .syntax = mia_syntax,
            .imports = mia_imports.toOwnedSlice(shpa) catch &[_][]const u8{},
            .package_name = mia_package, //items[1],
            .options = mia_options.toOwnedSlice(shpa) catch &[_]Option{},
            .enums = mia_enums.toOwnedSlice(shpa) catch &[_]Enum{},
            .messages = mia_messages.toOwnedSlice(shpa) catch &[_]Message{},
        };
    }
}.mapFn);
