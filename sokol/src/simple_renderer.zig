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
    ptr: anytype,
    comptime setPixelFn: fn (ptr: *anyopaque, x: i32, y: i32) void,
    comptime setPixelAltFn: fn (ptr: *anyopaque, x: i32, y: i32) void,
    comptime setFrontendPalleteFn: fn (ptr: *anyopaque, color: u2) void,
    comptime setBackgroundPalleteFn: fn (ptr: *anyopaque, color: ?u2) void,
) SimpleRenderer {
    const Ptr = @TypeOf(point);
    const ptr_info = @typeInfo(Ptr);

    assert(ptr_info == .Pointer); // Must be a pointer
    assert(ptr_info.Pointer.size == .One); // Must be a single-item pointer

    const gen = struct {
        fn setPixelImpl(ptr: *anyopaque, x: i32, y: i32) void {
            const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
            return @call(.{ .modifier = .always_inline }, setPixelFn, .{ self, x, y });
        }
        fn setPixelAlternativeImpl(ptr: *anyopaque, x: i32, y: i32) void {
            const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
            return @call(.{ .modifier = .always_inline }, setPixelAltFn, .{ self, x, y });
        }
        fn setFrontendPalleteImpl(self: *Renderer, color: u2) void {
            const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
            return @call(.{ .modifier = .always_inline }, setFrontendPalleteFn, .{ self, x, y });
        }

        fn setBackgroundPalleteImpl(self: *Renderer, color: ?u2) void {
            const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
            return @call(.{ .modifier = .always_inline }, setBackgroundPalleteFn, .{ self, x, y });
        }

        const vtable = VTable{
            .setBackgroundPallete = setBackgroundPalleteImpl,
            .setFrontendPallete = setFrontendPalleteImpl,
            .setPixel = setPixelImpl,
            .setPixelAlternative = setPixelAlternativeImpl,
        };
    };

    return .{
        .ptr = point,
        .vtable = &gen.vtable,
    };
}
