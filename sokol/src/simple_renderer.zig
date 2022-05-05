const SimpleRenderer = @This();

const std = @import("std");
const RendererVals = @import("renderer_vals.zig");
const mem = std.mem;

pub const FONT = RendererVals.FONT;
pub const BlitOptions = packed struct {
    flip_x: bool = false,
    flip_y: bool = false,
    _: u6 = 0,
};

ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    setPixel: fn (ptr: *anyopaque, x: i32, y: i32) void,
    setPixelAlternative: fn (ptr: *anyopaque, x: i32, y: i32) void,
    setFrontendPallete: fn (ptr: *anyopaque, color: u2) void,
    setBackgroundPallete: fn (ptr: *anyopaque, color: ?u2) void,
    getHeight: fn (ptr: *anyopaque) i32,
    getWidth: fn (ptr: *anyopaque) i32,
};

pub fn init(
    pointer: anytype,
    comptime setPixelFn: fn (ptr: @TypeOf(pointer), x: i32, y: i32) void,
    comptime setPixelAltFn: fn (ptr: @TypeOf(pointer), x: i32, y: i32) void,
    comptime setFrontendPalleteFn: fn (ptr: @TypeOf(pointer), color: u2) void,
    comptime setBackgroundPalleteFn: fn (ptr: @TypeOf(pointer), color: ?u2) void,
    comptime widthFn: fn (ptr: @TypeOf(pointer)) i32,
    comptime heightFn: fn (ptr: @TypeOf(pointer)) i32,
) SimpleRenderer {
    const Ptr = @TypeOf(pointer);
    const ptr_info = @typeInfo(Ptr);

    std.debug.assert(ptr_info == .Pointer); // Must be a pointer
    std.debug.assert(ptr_info.Pointer.size == .One); // Must be a single-item pointer

    const alignment = ptr_info.Pointer.alignment;

    const gen = struct {
        fn setPixelImpl(ptr: *anyopaque, x: i32, y: i32) void {
            const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
            return @call(.{ .modifier = .always_inline }, setPixelFn, .{ self, x, y });
        }
        fn setPixelAlternativeImpl(ptr: *anyopaque, x: i32, y: i32) void {
            const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
            return @call(.{ .modifier = .always_inline }, setPixelAltFn, .{ self, x, y });
        }
        fn setFrontendPalleteImpl(ptr: *anyopaque, color: u2) void {
            const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
            return @call(.{ .modifier = .always_inline }, setFrontendPalleteFn, .{ self, color });
        }

        fn setBackgroundPalleteImpl(ptr: *anyopaque, color: ?u2) void {
            const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
            return @call(.{ .modifier = .always_inline }, setBackgroundPalleteFn, .{ self, color });
        }

        fn getHeightImpl(ptr: *anyopaque) i32 {
            const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
            return @call(.{ .modifier = .always_inline }, heightFn, .{self});
        }

        fn getWidthImpl(ptr: *anyopaque) i32 {
            const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
            return @call(.{ .modifier = .always_inline }, widthFn, .{self});
        }

        const vtable = VTable{
            .setBackgroundPallete = setBackgroundPalleteImpl,
            .setFrontendPallete = setFrontendPalleteImpl,
            .setPixel = setPixelImpl,
            .setPixelAlternative = setPixelAlternativeImpl,
            .getHeight = getHeightImpl,
            .getWidth = getWidthImpl,
        };
    };

    return .{
        .ptr = pointer,
        .vtable = &gen.vtable,
    };
}

pub fn setForegroundPallete(self: *SimpleRenderer, color: u2) void {
    return self.vtable.setFrontendPallete(self.ptr, color);
}

pub fn setBackgroundPallete(self: *SimpleRenderer, color: u2) void {
    return self.vtable.setFrontendPallete(self.ptr, color);
}

pub fn setPixel(self: *SimpleRenderer, x: i32, y: i32) void {
    return self.vtable.setPixel(self.ptr, x, y);
}

pub fn setAltPixel(self: *SimpleRenderer, x: i32, y: i32) void {
    return self.vtable.setPixelAlternative(self.ptr, x, y);
}

pub fn getWidth(self: *SimpleRenderer) i32 {
    return self.vtable.getWidth(self.ptr);
}

pub fn getHeight(self: *SimpleRenderer) i32 {
    return self.vtable.getHeight(self.ptr);
}

pub fn reset(self: *SimpleRenderer) void {
    var x: i32 = 0;
    while (x < self.getWidth()) : (x += 1) {
        var y: i32 = 0;
        while (y < self.getHeight()) : (y += 1) {
            self.setPixel(x, y);
        }
    }
}

pub fn drawRect(self: *SimpleRenderer, x: i32, y: i32, width: u16, height: u16) void {
    const realX = std.math.clamp(x, 0, self.getWidth());
    const realY = std.math.clamp(y, 0, self.getHeight());
    const x2 = std.math.clamp(x + width, 0, self.getWidth());
    const y2 = std.math.clamp(y + height, 0, self.getHeight());

    var i = realX;
    while (i < x2) : (i += 1) {
        var j = realY;
        while (j < y2) : (j += 1) {
            self.setPixel(@intCast(i32, i), @intCast(i32, j));
        }
    }
}

pub fn blitBytesOld(self: *SimpleRenderer, source: []const u8, dst_x: i32, dst_y: i32, width: i32, height: i32, src_x: usize, src_y: usize, options: BlitOptions) void {
    _ = options;
    const min_x = std.math.clamp(dst_x, 0, self.getWidth());
    const max_x = std.math.clamp(dst_x + width - 1, 0, self.getWidth());
    const min_y = std.math.clamp(dst_y, 0, self.getHeight());
    const max_y = std.math.clamp(dst_y + height - 1, 0, self.getHeight());
    const source_start = src_y * @intCast(usize, width) + src_x;
    var x: i32 = min_x;
    var y: i32 = min_y;

    var byte_index = source_start;
    while (byte_index < source.len) : (byte_index += 1) {
        const byte = source[byte_index];
        const commands = RendererVals.bytemaskToDraws(byte);
        for (commands) |cmd| {
            switch (cmd) {
                .background => self.setAltPixel(x, y),
                .foreground => self.setPixel(x, y),
            }
            if (x >= max_x) {
                y += 1;
                x = min_x;
            } else {
                x += 1;
            }
            if (y > max_y) {
                return;
            }
        }
    }
}

pub fn blitBytes(self: *SimpleRenderer, source: []const u8, dst_x: i32, dst_y: i32, width: i32, height: i32, src_x: usize, src_y: usize, options: BlitOptions) void {
    _ = options;
    self.blitBytesOld(source, dst_x, dst_y, width, height, src_x, src_y, options);
    // const min_x: i32 = 0;
    // const min_y: i32 = 0;

    // const max_x: i32 = std.math.clamp(dst_x + width - 1, 0, self.getWidth()) - dst_x;
    // const max_y: i32 = std.math.clamp(dst_y + height - 1, 0, self.getHeight()) - dst_y;

    // var y = min_y;
    // while (y < max_y) : (y += 1) {
    //     var x = min_x;
    //     while (x < max_x) : (x += 1) {
    //         const sx = src_x + @intCast(usize, x);
    //         const sy = src_y + @intCast(usize, y);
    //         const dx = dst_x + x;
    //         const dy = dst_y + y;
    //         const draw = RendererVals.getDrawCommand(source, sx, sy, 1);
    //         switch (draw) {
    //             .background => self.setAltPixel(dx, dy),
    //             .foreground => self.setPixel(dx, dy),
    //         }
    //     }
    // }
}

pub fn drawText(self: *SimpleRenderer, text: []const u8, x: u8, y: u8) void {
    var i: u8 = x;
    for (text) |byte| {
        var source_start: usize = (byte - 32);
        source_start = source_start << 3;
        if (i > self.getWidth()) return;
        self.blitBytes(&FONT, i, y, 8, 8, source_start, 0, .{});
        i += 8;
    }
}
