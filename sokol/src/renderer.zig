const std = @import("std");

pub const Pixel = packed struct {
    r: u8 = 0,
    g: u8 = 0,
    b: u8 = 0,
    a: u8 = 255,
};

pub const DrawPixel = enum {
    background,
    foreground,
};

pub fn bytemaskToDraws(byte: u8) [8]DrawPixel {
    var result: [8]DrawPixel = undefined;
    var byte_copy = byte;
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        const value = byte_copy & 0b10000000;
        byte_copy = byte_copy << 1;
        if (value > 0) {
            result[i] = DrawPixel.background;
        } else {
            result[i] = DrawPixel.foreground;
        }
    }
    return result;
}

test "bytemask to Pixels" {
    const byte: u8 = 0b11001100;
    const background = DrawPixel.background;
    const incoming_cmd = DrawPixel.foreground;
    const expected: [8]DrawPixel = [_]DrawPixel{
        background,
        background,
        incoming_cmd,
        incoming_cmd,
        background,
        background,
        incoming_cmd,
        incoming_cmd,
    };
    const result = bytemaskToDraws(byte);
    try std.testing.expectEqual(expected, result);
}
