const std = @import("std");

pub const Pixel = packed struct {
    r: u8 = 0,
    g: u8 = 0,
    b: u8 = 0,
    a: u8 = 255,
};

pub const DrawPixelEnum = enum {
    skip,
    draw,
};

const DrawPixel = union(DrawPixelEnum) {
    draw: Pixel,
    skip: void,
};

pub fn bytemaskToDraws(byte: u8, pallete: Pixel) [8]DrawPixel {
    _ = byte;
    return [_]DrawPixel{
        DrawPixel.skip,
        DrawPixel.skip,
        DrawPixel{ .draw = pallete },
        DrawPixel{ .draw = pallete },
        DrawPixel.skip,
        DrawPixel.skip,
        DrawPixel{ .draw = pallete },
        DrawPixel{ .draw = pallete },
    };
}

test "bytemask to Pixels" {
    const incoming_pixel = Pixel{ .r = 255, .b = 255 };
    const byte: u8 = 0b11001100;
    const skip = DrawPixel.skip;
    const incoming_cmd = DrawPixel{ .draw = incoming_pixel };
    const expected: [8]DrawPixel = [_]DrawPixel{
        skip,
        skip,
        incoming_cmd,
        incoming_cmd,
        skip,
        skip,
        incoming_cmd,
        incoming_cmd,
    };
    const result = bytemaskToDraws(byte, incoming_pixel);
    try std.testing.expectEqual(expected, result);
}
