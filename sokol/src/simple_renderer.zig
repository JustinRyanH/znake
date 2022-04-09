const std = @import("std");
const SimpleRenderer = @This();

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
