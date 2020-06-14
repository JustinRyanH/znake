const std = @import("std");
const builtin = @import("builtin");
const win32 = @import("win32.zig");
const assert = @import("utils.zig").assert;
const snake = @import("snake_types.zig");

pub const panic = switch (builtin.os.tag) {
    builtin.Os.Tag.windows => win32.win32_panic,
    else => @compileError("Unsupported OS"),
};

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

    inline fn to_u8(self: Self) Pixel {
        return Pixel{
            .blue = @floatToInt(u8, std.math.clamp(self.blue * 255.0, 0.0, 255.0)),
            .green = @floatToInt(u8, std.math.clamp(self.green * 255.0, 0.0, 255.0)),
            .red = @floatToInt(u8, std.math.clamp(self.red * 255.0, 0.0, 255.0)),
            .padding = 0,
        };
    }
};

const SquareCoordinates = struct {
    min_x: f32 = 0.0,
    min_y: f32 = 0.0,
    max_x: f32 = 0.0,
    max_y: f32 = 0.0,
};

fn drawSquare(buffer: *snake.DrawBuffer, coords: SquareCoordinates, pixel: PixelF32) void {
    var pixels = std.mem.bytesAsSlice(Pixel, buffer.memory);

    const start_draw_edge_y: u32 = @floatToInt(u32, std.math.clamp(coords.min_y, 0, @intToFloat(f32, buffer.height)));
    const start_draw_edge_x: u32 = @floatToInt(u32, std.math.clamp(coords.min_x, 0, @intToFloat(f32, buffer.width)));
    const end_draw_edge_y = @floatToInt(u32, std.math.clamp(coords.max_y, 0, @intToFloat(f32, buffer.height)));
    const end_draw_edge_x = @floatToInt(u32, std.math.clamp(coords.max_x, 0, @intToFloat(f32, buffer.width)));

    var y = start_draw_edge_y;
    while (y < end_draw_edge_y) : (y += 1) {
        var x = start_draw_edge_x;
        while (x < end_draw_edge_x) : (x += 1) {
            pixels[x + (y * buffer.width)] = pixel.to_u8();
        }
    }
}

const DebugData = struct {
    const Self = @This();
    const width = 8.0;
    player_x: f32,
    player_y: f32,

    pub const ToDraw = struct {
        coords: SquareCoordinates,
        color: PixelF32,
    };

    pub fn to_draw_player(self: *Self) ToDraw {
        return ToDraw{
            .coords = SquareCoordinates{
                .min_x = self.player_x - width,
                .min_y = self.player_y - width,
                .max_x = self.player_x + width,
                .max_y = self.player_y + width,
            },
            .color = PixelF32{
                .red = 1.0,
            },
        };
    }
};

fn getDebugData(data: *snake.Data) *DebugData {
    return @ptrCast(*DebugData, @alignCast(@alignOf(DebugData), data.permanent_storage[0..@sizeOf(DebugData)]));
}

const CornflowerBlue = PixelF32{
    .red = (100.0 / 255.0),
    .green = (149.0 / 255.0),
    .blue = (237.0 / 255.0),
};

export fn updateGame(input: *snake.Input, data: *snake.Data, draw_buffer: *snake.DrawBuffer) void {
    var debug_data = getDebugData(data);

    if (!data.initialized) {
        data.initialized = true;
        debug_data.player_x = @intToFloat(f32, @divFloor(draw_buffer.width, 2)) - 16.0;
        debug_data.player_y = @intToFloat(f32, @divFloor(draw_buffer.height, 2)) - 32.0;
    }

    if (input.keyboard.letter.a == .Down) {
        debug_data.player_x -= (4.0 * 32.0 * input.delta_time);
    }

    if (input.keyboard.letter.d == .Down) {
        debug_data.player_x += (4.0 * 32.0 * input.delta_time);
    }

    if (input.keyboard.letter.w == .Down) {
        debug_data.player_y -= (4.0 * 32.0 * input.delta_time);
    }

    if (input.keyboard.letter.s == .Down) {
        debug_data.player_y += (4.0 * 32.0 * input.delta_time);
    }

    const player_draw = debug_data.to_draw_player();
    drawSquare(draw_buffer, SquareCoordinates{ .min_x = 0.0, .min_y = 0.0, .max_x = @intToFloat(f32, draw_buffer.width), .max_y = @intToFloat(f32, draw_buffer.height) }, CornflowerBlue);
    drawSquare(draw_buffer, player_draw.coords, player_draw.color);
}

export fn updateSound(game_data: *snake.Data, sound: *snake.Sound) void {}
