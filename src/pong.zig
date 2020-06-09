const std = @import("std");
const win32 = @import("win32.zig");
const assert = @import("utils.zig").assert;
const pong = @import("pong_types.zig");

pub const Pixel = packed struct {
    blue: u8,
    green: u8,
    red: u8,
    padding: u8,
};

fn debugFillBuffer(draw_buffer: *pong.DrawBuffer, x_offset: u32, y_offset: u32) void {
    assert(draw_buffer.memory.len == draw_buffer.height * draw_buffer.pitch);
    var y_index: usize = 0;
    var pixels = std.mem.bytesAsSlice(Pixel, draw_buffer.memory);
    assert(pixels.len == draw_buffer.height * draw_buffer.width);

    while (y_index < draw_buffer.height) {
        const start = y_index * draw_buffer.width;
        const end = start + draw_buffer.width;
        for (pixels[start..end]) |*pixel, x_index| {
            pixel.*.blue = @truncate(u8, x_index + x_offset);
            pixel.*.green = @truncate(u8, y_index + y_offset);
        }
        y_index += 1;
    }
}

export fn updateGame(input: *pong.Input, data: *pong.Data, draw_buffer: *pong.DrawBuffer) void {}

export fn updateSound(game_data: *pong.Data, sound: *pong.Sound) void {}
