const std = @import("std");
const meta = std.meta;
const trait = meta.trait;

fn CopyPtrAttrsCopy(comptime source: type, comptime size: std.builtin.TypeInfo.Pointer.Size, comptime child: type) type {
    const info = @typeInfo(source).Pointer;
    return @Type(.{
        .Pointer = .{
            .size = size,
            .is_const = info.is_const,
            .is_volatile = info.is_volatile,
            .is_allowzero = info.is_allowzero,
            .alignment = info.alignment,
            .address_space = info.address_space,
            .child = child,
            .sentinel = null,
        },
    });
}

fn BytesAsSliceReturnTypeCopy(comptime T: type, comptime bytesType: type) type {
    if (!(trait.isSlice(bytesType) or trait.isPtrTo(.Array)(bytesType)) or meta.Elem(bytesType) != u8) {
        @compileError("expected []u8 or *[_]u8, passed " ++ @typeName(bytesType));
    }

    if (trait.isPtrTo(.Array)(bytesType) and @typeInfo(meta.Child(bytesType)).Array.len % @sizeOf(T) != 0) {
        @compileError("number of bytes in " ++ @typeName(bytesType) ++ " is not divisible by size of " ++ @typeName(T));
    }

    return CopyPtrAttrsCopy(bytesType, .Slice, T);
}

pub fn bitcastSlice(comptime T: type, bytes: anytype) BytesAsSliceReturnTypeCopy(T, @TypeOf(bytes)) {
    // let's not give an undefined pointer to @ptrCast
    // it may be equal to zero and fail a null check
    if (bytes.len == 0) {
        return &[0]T{};
    }
    const cast_target = CopyPtrAttrsCopy(@TypeOf(bytes), .Many, T);

    const slice_type = @typeInfo(@TypeOf(bytes)).Pointer.child;

    const target_slice_type_size = @bitSizeOf(T);
    const original_slice_type_size = @bitSizeOf(slice_type);
    if (target_slice_type_size < original_slice_type_size) {
        const len_multiplayer = @divExact(original_slice_type_size, target_slice_type_size);
        return @ptrCast(cast_target, bytes)[0..(bytes.len * len_multiplayer)];
    }
    std.debug.print("target_type_size: {}\n", .{target_slice_type_size});
    std.debug.print("original_type_size: {}\n", .{original_slice_type_size});

    return @ptrCast(cast_target, bytes)[0..@divExact(bytes.len, @sizeOf(T))];
}
