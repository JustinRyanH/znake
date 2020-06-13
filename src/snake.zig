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

const SquareCoordinates = struct {
    min_x: f32 = 0.0,
    min_y: f32 = 0.0,
    max_x: f32 = 0.0,
    max_y: f32 = 0.0,
};

fn drawSquare(buffer: *snake.DrawBuffer, coords: SquareCoordinates, pixel: PixelF32) void {
    var pixels = std.mem.bytesAsSlice(Pixel, buffer.memory);

    var y: u32 = @floatToInt(u32, std.math.round(coords.min_y));
    while (y < @floatToInt(u32, coords.max_y)) : (y += 1) {
        var x: u32 = @floatToInt(u32, std.math.round(coords.min_x));
        while (x < @floatToIn(u32, coords.max_x)) : (x += 1) {
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
    drawSquare(draw_buffer, SquareCoordinates{ .min_x = 0.0, .min_y = 0.0, .max_x = @intToFloat(f32, draw_buffer.width), .max_y = @intToFloat(f32, draw_buffer.height) }, CornflowerBlue);
    drawSquare(draw_buffer, SquareCoordinates{ .min_x = 50.0, .min_y = 50.0, .max_x = 75.0, .max_y = 75.0 }, PixelF32{ .blue = 0.75, .red = 0.5 });
}

export fn updateSound(game_data: *snake.Data, sound: *snake.Sound) void {}
