const std = @import("std");
const win32 = @import("win32.zig");
const assert = @import("utils.zig").assert;
const snake = @import("snake_types.zig");

pub const Pixel = packed struct {
    blue: u8 = 0,
    green: u8 = 0,
    red: u8 = 0,
    padding: u8 = 0,
};

pub const PixelF32 = packed struct {
    const Self = @This();
    blue: f32 = 0.0,
    green: f32 = 0.0,
    red: f32 = 0.0,
    padding: f32 = 0.0,

    pub fn to_u8(self: Self) Pixel {
        return Pixel{
            .blue = @floatToInt(u8, std.math.clamp(self.blue * 255.0, 0.0, 255.0)),
            .green = @floatToInt(u8, std.math.clamp(self.green * 255.0, 0.0, 255.0)),
            .red = @floatToInt(u8, std.math.clamp(self.red * 255.0, 0.0, 255.0)),
            .padding = 0,
        };
    }
};

pub const Coords = struct {
    min_x: u32,
    min_y: u32,
    max_x: u32,
    max_y: u32,
};

fn clearBuffer(draw_buffer: *snake.DrawBuffer, color: Pixel) void {
    assert(draw_buffer.memory.len == draw_buffer.height * draw_buffer.pitch);
    var y_index: usize = 0;
    var pixels = std.mem.bytesAsSlice(Pixel, draw_buffer.memory);

    assert(pixels.len == draw_buffer.height * draw_buffer.width);

    while (y_index < draw_buffer.height) {
        const start = y_index * draw_buffer.width;
        const end = start + draw_buffer.width;
        for (pixels[start..end]) |*pixel, x_index| {
            pixel.* = color;
        }
        y_index += 1;
    }
}

fn drawSquare(buffer: *snake.DrawBuffer, coords: var, pixel: PixelF32) void {
    var pixels = std.mem.bytesAsSlice(Pixel, buffer.memory);

    var y: u32 = coords.min_y;
    while (y < coords.max_y) : (y += 1) {
        var x: u32 = coords.min_x;
        while (x < coords.max_x) : (x += 1) {
            pixels[x + (y * buffer.width)] = pixel.to_u8();
        }
    }
}

const CornflowerBlue = PixelF32{
    .red = (100.0 / 255.0),
    .green = (149.0 / 255.0),
    .blue = (237.0 / 255.0),
};

export fn updateGame(input: *snake.Input, data: *snake.Data, draw_buffer: *snake.DrawBuffer) void {
    clearBuffer(draw_buffer, Pixel{});
    drawSquare(draw_buffer, .{ .min_x = 0, .min_y = 0, .max_x = draw_buffer.width, .max_y = draw_buffer.height }, CornflowerBlue);
    drawSquare(draw_buffer, .{ .min_x = 50, .min_y = 50, .max_x = 75, .max_y = 75 }, PixelF32{ .blue = 0.75, .red = 0.5 });
}

export fn updateSound(game_data: *snake.Data, sound: *snake.Sound) void {}
