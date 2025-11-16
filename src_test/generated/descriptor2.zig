const std = @import("std");
const dbg = std.debug;
const zon = std.zon;
const all = std.mem;
const  io = std.Io;
const EncodeBuffer = @import("encdec.zig").EncodeBuffer;
const DecodeBuffer = @import("encdec.zig").DecodeBuffer;


pub const google = struct {

    pub const protobuf = struct {


pub const FileDescriptorSet = struct {
    file: []FileDescriptorProto,

    pub fn skribiAlZonTeksto(self: *FileDescriptorSet, allocator: all.Allocator) ![]u8 {
        return skribiTiponAlZonTeksto(allocator, FileDescriptorSet, @as(*FileDescriptorSet,self));
    }

    pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !FileDescriptorSet {
        return legiTiponElZonTeksto(allocator, FileDescriptorSet, input);
    }

    pub fn skribiAlZonDosiero(self: *FileDescriptorSet, allocator: all.Allocator, path: []const u8) !void {
        try skribiTiponAlZonDosiero(allocator, FileDescriptorSet, @as(*FileDescriptorSet, self), path);
    }

    pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !FileDescriptorSet {
        return legiTiponElZonDosiero(allocator, FileDescriptorSet, path);
    }

    pub fn encode(self: *const FileDescriptorSet, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
 
        const key_file = 10;
        tuta_longo += try buffer.encodeVarint(key_file);
        var v_file_longo: usize = 0;
        { 
            var aux= try EncodeBuffer.init(std.heap.page_allocator,1024); 
            var mia_enc=&aux; 
            defer mia_enc.deinit(); 
            for (self.file) |item| { 
                v_file_longo += try item.encode( mia_enc );
            } 
        }
        tuta_longo += try buffer.encodeVarint(v_file_longo); 
        for (self.file) |item| { 
            tuta_longo += try item.encode( buffer );
        }

        return tuta_longo;
    }

    pub fn decode(self: *const FileDescriptorSet, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
       _=self;_=buffer;tuta_longo=3;
        return tuta_longo;
    }

};

pub const FileDescriptorProto = struct {
    name: ?[]const u8 = null,
    package: ?[]const u8 = null,
    dependency: [][]const u8,
    public_dependency: []i32,
    weak_dependency: []i32,
    message_type: []DescriptorProto,
    enum_type: []EnumDescriptorProto,
    service: []ServiceDescriptorProto,
    extension: []FieldDescriptorProto,
    options: ?FileOptions = null,
    source_code_info: ?SourceCodeInfo = null,
    syntax: ?[]const u8 = null,
    edition: ?Edition = null,

    pub fn skribiAlZonTeksto(self: *FileDescriptorProto, allocator: all.Allocator) ![]u8 {
        return skribiTiponAlZonTeksto(allocator, FileDescriptorProto, @as(*FileDescriptorProto,self));
    }

    pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !FileDescriptorProto {
        return legiTiponElZonTeksto(allocator, FileDescriptorProto, input);
    }

    pub fn skribiAlZonDosiero(self: *FileDescriptorProto, allocator: all.Allocator, path: []const u8) !void {
        try skribiTiponAlZonDosiero(allocator, FileDescriptorProto, @as(*FileDescriptorProto, self), path);
    }

    pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !FileDescriptorProto {
        return legiTiponElZonDosiero(allocator, FileDescriptorProto, path);
    }

    pub fn encode(self: *const FileDescriptorProto, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
 
        if (self.edition != null) {
            const key_edition = 112;
            tuta_longo += try buffer.encodeVarint(key_edition);
            if( self.edition ) |val| {
                tuta_longo += try buffer.encodeVarint( val );
            }
        }

        if ( self.syntax != null ) {   
            const st= if ( self.syntax ) |val| val else "";
            if ( ! std.mem.eql(u8, st, "null") ) { 
                const key_syntax = 98;
                tuta_longo += try buffer.encodeVarint(key_syntax);
                tuta_longo += try buffer.encodeString(st);
            }
        }

        if (self.source_code_info != null) {
            const key_source_code_info = 72;
            tuta_longo += try buffer.encodeVarint(key_source_code_info);
            if( self.source_code_info ) |val| {
                tuta_longo += try buffer.encodeVarint( val );
            }
        }

        if (self.options != null) {
            const key_options = 64;
            tuta_longo += try buffer.encodeVarint(key_options);
            if( self.options ) |val| {
                tuta_longo += try buffer.encodeVarint( val );
            }
        }

        const key_extension = 58;
        tuta_longo += try buffer.encodeVarint(key_extension);
        var v_extension_longo: usize = 0;
        { 
            var aux= try EncodeBuffer.init(std.heap.page_allocator,1024); 
            var mia_enc=&aux; 
            defer mia_enc.deinit(); 
            for (self.extension) |item| { 
                v_extension_longo += try mia_enc.encodeVarint( item );
            } 
        }
        tuta_longo += try buffer.encodeVarint(v_extension_longo); 
        for (self.extension) |item| { 
            tuta_longo += try buffer.encodeVarint( item );
        }

        const key_service = 50;
        tuta_longo += try buffer.encodeVarint(key_service);
        var v_service_longo: usize = 0;
        { 
            var aux= try EncodeBuffer.init(std.heap.page_allocator,1024); 
            var mia_enc=&aux; 
            defer mia_enc.deinit(); 
            for (self.service) |item| { 
                v_service_longo += try mia_enc.encodeVarint( item );
            } 
        }
        tuta_longo += try buffer.encodeVarint(v_service_longo); 
        for (self.service) |item| { 
            tuta_longo += try buffer.encodeVarint( item );
        }

        const key_enum_type = 42;
        tuta_longo += try buffer.encodeVarint(key_enum_type);
        var v_enum_type_longo: usize = 0;
        { 
            var aux= try EncodeBuffer.init(std.heap.page_allocator,1024); 
            var mia_enc=&aux; 
            defer mia_enc.deinit(); 
            for (self.enum_type) |item| { 
                v_enum_type_longo += try mia_enc.encodeVarint( item );
            } 
        }
        tuta_longo += try buffer.encodeVarint(v_enum_type_longo); 
        for (self.enum_type) |item| { 
            tuta_longo += try buffer.encodeVarint( item );
        }

        const key_message_type = 34;
        tuta_longo += try buffer.encodeVarint(key_message_type);
        var v_message_type_longo: usize = 0;
        { 
            var aux= try EncodeBuffer.init(std.heap.page_allocator,1024); 
            var mia_enc=&aux; 
            defer mia_enc.deinit(); 
            for (self.message_type) |item| { 
                v_message_type_longo += try item.encode( mia_enc );
            } 
        }
        tuta_longo += try buffer.encodeVarint(v_message_type_longo); 
        for (self.message_type) |item| { 
            tuta_longo += try item.encode( buffer );
        }

        const key_weak_dependency = 90;
        tuta_longo += try buffer.encodeVarint(key_weak_dependency);
        var v_weak_dependency_longo: usize = 0;
        { 
            var aux= try EncodeBuffer.init(std.heap.page_allocator,1024); 
            var mia_enc=&aux; 
            defer mia_enc.deinit(); 
            for (self.weak_dependency) |item| { 
                v_weak_dependency_longo += try mia_enc.encodeInt32( item );
            } 
        }
        tuta_longo += try buffer.encodeVarint(v_weak_dependency_longo); 
        for (self.weak_dependency) |item| { 
            tuta_longo += try buffer.encodeInt32( item );
        }

        const key_public_dependency = 82;
        tuta_longo += try buffer.encodeVarint(key_public_dependency);
        var v_public_dependency_longo: usize = 0;
        { 
            var aux= try EncodeBuffer.init(std.heap.page_allocator,1024); 
            var mia_enc=&aux; 
            defer mia_enc.deinit(); 
            for (self.public_dependency) |item| { 
                v_public_dependency_longo += try mia_enc.encodeInt32( item );
            } 
        }
        tuta_longo += try buffer.encodeVarint(v_public_dependency_longo); 
        for (self.public_dependency) |item| { 
            tuta_longo += try buffer.encodeInt32( item );
        }

        const key_dependency = 26;
        tuta_longo += try buffer.encodeVarint(key_dependency);
        var v_dependency_longo: usize = 0;
        { 
            var aux= try EncodeBuffer.init(std.heap.page_allocator,1024); 
            var mia_enc=&aux; 
            defer mia_enc.deinit(); 
            for (self.dependency) |item| { 
                v_dependency_longo += try mia_enc.encodeString( item );
            } 
        }
        tuta_longo += try buffer.encodeVarint(v_dependency_longo); 
        for (self.dependency) |item| { 
            tuta_longo += try buffer.encodeString( item );
        }

        if ( self.package != null ) {   
            const st= if ( self.package ) |val| val else "";
            if ( ! std.mem.eql(u8, st, "null") ) { 
                const key_package = 18;
                tuta_longo += try buffer.encodeVarint(key_package);
                tuta_longo += try buffer.encodeString(st);
            }
        }

        if ( self.name != null ) {   
            const st= if ( self.name ) |val| val else "";
            if ( ! std.mem.eql(u8, st, "null") ) { 
                const key_name = 10;
                tuta_longo += try buffer.encodeVarint(key_name);
                tuta_longo += try buffer.encodeString(st);
            }
        }

        return tuta_longo;
    }

    pub fn decode(self: *const FileDescriptorProto, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
       _=self;_=buffer;tuta_longo=3;
        return tuta_longo;
    }

};

pub const DescriptorProto = struct {
    name: ?[]const u8 = null,
    field: []FieldDescriptorProto,
    extension: []FieldDescriptorProto,
    nested_type: []DescriptorProto,
    enum_type: []EnumDescriptorProto,
    extension_range: []ExtensionRange,
    oneof_decl: []OneofDescriptorProto,
    options: ?MessageOptions = null,
    reserved_range: []ReservedRange,
    reserved_name: [][]const u8,

    pub fn skribiAlZonTeksto(self: *DescriptorProto, allocator: all.Allocator) ![]u8 {
        return skribiTiponAlZonTeksto(allocator, DescriptorProto, @as(*DescriptorProto,self));
    }

    pub fn legiElZonTeksto(allocator: all.Allocator, input: [:0]const u8) !DescriptorProto {
        return legiTiponElZonTeksto(allocator, DescriptorProto, input);
    }

    pub fn skribiAlZonDosiero(self: *DescriptorProto, allocator: all.Allocator, path: []const u8) !void {
        try skribiTiponAlZonDosiero(allocator, DescriptorProto, @as(*DescriptorProto, self), path);
    }

    pub fn legiElZonDosiero(allocator: all.Allocator, path: [:0]const u8) !DescriptorProto {
        return legiTiponElZonDosiero(allocator, DescriptorProto, path);
    }

    pub fn encode(self: *const DescriptorProto, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
 
        const key_reserved_name = 82;
        tuta_longo += try buffer.encodeVarint(key_reserved_name);
        var v_reserved_name_longo: usize = 0;
        { 
            var aux= try EncodeBuffer.init(std.heap.page_allocator,1024); 
            var mia_enc=&aux; 
            defer mia_enc.deinit(); 
            for (self.reserved_name) |item| { 
                v_reserved_name_longo += try mia_enc.encodeString( item );
            } 
        }
        tuta_longo += try buffer.encodeVarint(v_reserved_name_longo); 
        for (self.reserved_name) |item| { 
            tuta_longo += try buffer.encodeString( item );
        }

        const key_reserved_range = 74;
        tuta_longo += try buffer.encodeVarint(key_reserved_range);
        var v_reserved_range_longo: usize = 0;
        { 
            var aux= try EncodeBuffer.init(std.heap.page_allocator,1024); 
            var mia_enc=&aux; 
            defer mia_enc.deinit(); 
            for (self.reserved_range) |item| { 
                v_reserved_range_longo += try mia_enc.encodeVarint( item );
            } 
        }
        tuta_longo += try buffer.encodeVarint(v_reserved_range_longo); 
        for (self.reserved_range) |item| { 
            tuta_longo += try buffer.encodeVarint( item );
        }

        if (self.options != null) {
            const key_options = 56;
            tuta_longo += try buffer.encodeVarint(key_options);
            if( self.options ) |val| {
                tuta_longo += try buffer.encodeVarint( val );
            }
        }

        const key_oneof_decl = 66;
        tuta_longo += try buffer.encodeVarint(key_oneof_decl);
        var v_oneof_decl_longo: usize = 0;
        { 
            var aux= try EncodeBuffer.init(std.heap.page_allocator,1024); 
            var mia_enc=&aux; 
            defer mia_enc.deinit(); 
            for (self.oneof_decl) |item| { 
                v_oneof_decl_longo += try mia_enc.encodeVarint( item );
            } 
        }
        tuta_longo += try buffer.encodeVarint(v_oneof_decl_longo); 
        for (self.oneof_decl) |item| { 
            tuta_longo += try buffer.encodeVarint( item );
        }

        const key_extension_range = 42;
        tuta_longo += try buffer.encodeVarint(key_extension_range);
        var v_extension_range_longo: usize = 0;
        { 
            var aux= try EncodeBuffer.init(std.heap.page_allocator,1024); 
            var mia_enc=&aux; 
            defer mia_enc.deinit(); 
            for (self.extension_range) |item| { 
                v_extension_range_longo += try mia_enc.encodeVarint( item );
            } 
        }
        tuta_longo += try buffer.encodeVarint(v_extension_range_longo); 
        for (self.extension_range) |item| { 
            tuta_longo += try buffer.encodeVarint( item );
        }

        const key_enum_type = 34;
        tuta_longo += try buffer.encodeVarint(key_enum_type);
        var v_enum_type_longo: usize = 0;
        { 
            var aux= try EncodeBuffer.init(std.heap.page_allocator,1024); 
            var mia_enc=&aux; 
            defer mia_enc.deinit(); 
            for (self.enum_type) |item| { 
                v_enum_type_longo += try mia_enc.encodeVarint( item );
            } 
        }
        tuta_longo += try buffer.encodeVarint(v_enum_type_longo); 
        for (self.enum_type) |item| { 
            tuta_longo += try buffer.encodeVarint( item );
        }

        const key_nested_type = 26;
        tuta_longo += try buffer.encodeVarint(key_nested_type);
        var v_nested_type_longo: usize = 0;
        { 
            var aux= try EncodeBuffer.init(std.heap.page_allocator,1024); 
            var mia_enc=&aux; 
            defer mia_enc.deinit(); 
            for (self.nested_type) |item| { 
                v_nested_type_longo += try item.encode( mia_enc );
            } 
        }
        tuta_longo += try buffer.encodeVarint(v_nested_type_longo); 
        for (self.nested_type) |item| { 
            tuta_longo += try item.encode( buffer );
        }

        const key_extension = 50;
        tuta_longo += try buffer.encodeVarint(key_extension);
        var v_extension_longo: usize = 0;
        { 
            var aux= try EncodeBuffer.init(std.heap.page_allocator,1024); 
            var mia_enc=&aux; 
            defer mia_enc.deinit(); 
            for (self.extension) |item| { 
                v_extension_longo += try mia_enc.encodeVarint( item );
            } 
        }
        tuta_longo += try buffer.encodeVarint(v_extension_longo); 
        for (self.extension) |item| { 
            tuta_longo += try buffer.encodeVarint( item );
        }

        const key_field = 18;
        tuta_longo += try buffer.encodeVarint(key_field);
        var v_field_longo: usize = 0;
        { 
            var aux= try EncodeBuffer.init(std.heap.page_allocator,1024); 
            var mia_enc=&aux; 
            defer mia_enc.deinit(); 
            for (self.field) |item| { 
                v_field_longo += try mia_enc.encodeVarint( item );
            } 
        }
        tuta_longo += try buffer.encodeVarint(v_field_longo); 
        for (self.field) |item| { 
            tuta_longo += try buffer.encodeVarint( item );
        }

        if ( self.name != null ) {   
            const st= if ( self.name ) |val| val else "";
            if ( ! std.mem.eql(u8, st, "null") ) { 
                const key_name = 10;
                tuta_longo += try buffer.encodeVarint(key_name);
                tuta_longo += try buffer.encodeString(st);
            }
        }

        return tuta_longo;
    }

    pub fn decode(self: *const DescriptorProto, buffer: *EncodeBuffer) !usize {
        var tuta_longo: usize = 0;
       _=self;_=buffer;tuta_longo=3;
        return tuta_longo;
    }

};

    };
};
//////////////////////////////////////////////
/// //////////////////////////////////////////
/// //////////////////////////////////////////
//////////////////////////////////////////////

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
    const teksto = try skribiTiponAlZonTeksto(allocator,T, value);

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

