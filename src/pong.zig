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
        for (pixels[start..end]) |*pixel, x_index| {
            pixel.*.blue = @truncate(u8, x_index);
            pixel.*.green = @truncate(u8, y_index);
        }
        y_index += 1;
    }
}
