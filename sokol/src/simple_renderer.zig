const std = @import("std");
const SimpleRenderer = @This();

ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    setPixel: fn (ptr: *anyopaque, x: i32, y: i32) void,
    setPixelAlternative: fn (ptr: *anyopaque, x: i32, y: i32) void,
    setFrontendPallete: fn (ptr: *anyopaque, color: u2) void,
    setBackgroundPallete: fn (ptr: *anyopaque, color: ?u2) void,
};

pub fn init(
    pointer: anytype,
    comptime setPixelFn: fn (ptr: @TypeOf(pointer), x: i32, y: i32) void,
    comptime setPixelAltFn: fn (ptr: @TypeOf(pointer), x: i32, y: i32) void,
    comptime setFrontendPalleteFn: fn (ptr: @TypeOf(pointer), color: u2) void,
    comptime setBackgroundPalleteFn: fn (ptr: @TypeOf(pointer), color: ?u2) void,
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

        const vtable = VTable{
            .setBackgroundPallete = setBackgroundPalleteImpl,
            .setFrontendPallete = setFrontendPalleteImpl,
            .setPixel = setPixelImpl,
            .setPixelAlternative = setPixelAlternativeImpl,
        };
    };

    return .{
        .ptr = pointer,
        .vtable = &gen.vtable,
    };
}

pub fn setForegroundPallete(self: SimpleRenderer, color: u2) void {
    return self.vtable.setFrontendPallete(self.ptr, color);
}

pub fn setBackgroundPallete(self: SimpleRenderer, color: u2) void {
    return self.vtable.setFrontendPallete(self.ptr, color);
}
