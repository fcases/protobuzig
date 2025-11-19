const std=@import("std");
const appcfg=@import("AppCfg.zig");

const alloc=std.heap.page_allocator;

//export var miaAppCfg = AppConfig.initDefault(alloc);

pub export fn AppConfig_initDefault() AppConfig {
    return  miaAppCfg=AppConfig.initDefault(alloc) catch {};
}


pub export fn skribiAlTeksto( 
    t_formato: encdec.TekstaFormato,
    out_ptr: *[*]const u8,
    out_len: *usize) 
void {
   const bytes= miaAppCfg.skribiAlTeksto(alloc, t_formato) catch {};
   out_ptr=&bytes;
   out_len=bytes.len;
}
