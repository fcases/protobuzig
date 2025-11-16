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
                v_file_longo += try mia_enc.encodeVarint( item );
            } 
        }
        tuta_longo += try buffer.encodeVarint(v_file_longo); 
        for (self.file) |item| { 
            tuta_longo += try buffer.encodeVarint( item );
        }

        return tuta_longo;
    }

    pub fn decode(self: *const FileDescriptorSet, buffer: *EncodeBuffer) !usize {
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

