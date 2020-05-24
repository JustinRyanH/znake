const std = @import("std");
const assert = std.debug.assert;

pub const DebugData = struct {
    x_offset: i32,
    y_offset: i32,
    tone_hz: u32,
    sine_time: f32,
};

pub const GameData = struct {
    initialized: bool = false,

    permanent_storage: [*]u8,
    permanent_storage_size: usize,

    transient_storage: [*]u8,
    transient_storage_Size: usize,
};

pub const GameDrawBuffer = struct {
    height: u32,
    width: u32,
    pitch: u32,
    memory: []u8,
};

// pub export fn GameUpdateDrawBuffer(arg_buffer: [*c]struct_GameDrawBuffer) void {
//     var buffer = arg_buffer;
//     var row: [*c]u8_5 = @ptrCast([*c]u8_5, @alignCast(@alignOf(u8_5), buffer.*.memory));
//     {
//         var green_shift: c_int = 0;
//         while (green_shift < buffer.*.height) : (green_shift += 1) {
//             var pixel: [*c]u32_7 = @ptrCast([*c]u32_7, @alignCast(@alignOf(u32_7), row));
//             {
//                 var blue_shift: c_int = 0;
//                 while (blue_shift < buffer.*.width) : (blue_shift += 1) {
//                     var blue: u8_5 = @bitCast(u8_5, @truncate(i8, (blue_shift)));
//                     var green: u8_5 = @bitCast(u8_5, @truncate(i8, (green_shift)));
//                     (blk: {
//                         const ref = &pixel;
//                         const tmp = ref.*;
//                         ref.* += 1;
//                         break :blk tmp;
//                     }).?.* = @bitCast(u32_7, ((@bitCast(c_int, @as(c_uint, green)) << @intCast(@import("std").math.Log2Int(c_int), 8)) | @bitCast(c_int, @as(c_uint, blue))));
//                 }
//             }
//             row += buffer.*.pitch;
//         }
//     }
// }

pub const Pixel = packed struct {
    blue: u8,
    green: u8,
    red: u8,
    padding: u8,
};

pub fn DebugFillBuffer(draw_buffer: *GameDrawBuffer) void {
    assert(draw_buffer.memory.len == draw_buffer.height * draw_buffer.pitch);
    var y_index: usize = 0;
    var pixels = std.mem.bytesAsSlice(Pixel, draw_buffer.memory);
    assert(pixels.len == draw_buffer.height * draw_buffer.width);

    while (y_index < draw_buffer.height) {
        const start = y_index * draw_buffer.width;
        const end = start + draw_buffer.width;
        for (pixels[start..end]) |*pixel| {
            pixel.*.blue = 0xFF;
            pixel.*.green = 0xFF;
        }
        y_index += 1;
    }
}
