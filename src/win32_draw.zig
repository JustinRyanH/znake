const std = @import("std");
const win32 = @import("win32.zig");
const snake = @import("snake_types.zig");

pub const WindowDimension = struct {
    width: i32,
    height: i32,
};

pub const BYTES_PER_PIXEL = 4;
pub const Win32OffscreenBuffer = struct {
    const BitmapInfoHeader = win32.BITMAPINFOHEADER;
    const BitmapInfo = win32.BITMAPINFO;
    const Self = @This();

    info: BitmapInfo,
    memory: [*]u8,
    width: u32,
    height: u32,
    pitch: u32,

    pub fn init(width: u32, height: u32) !Self {
        if (win32.VirtualAlloc(
            null,
            @intCast(usize, width * height * BYTES_PER_PIXEL),
            win32.MEM_COMMIT | win32.MEM_RESERVE,
            win32.PAGE_READWRITE,
        )) |memory| {
            return Self{
                .width = width,
                .height = height,
                .pitch = width * BYTES_PER_PIXEL,
                .info = buildInfo(width, height),
                .memory = @ptrCast([*]u8, memory),
            };
        }
        return win32.WindowError.FailedToAllocateMemory;
    }

    pub fn resize(self: *Self, width: i32, height: i32) !Self {
        if (!self.release()) {
            return win32.WindowError.FailedToUnallocateMemory;
        }
        if (win32.VirtualAlloc(
            null,
            @intCast(usize, width * height * BYTES_PER_PIXEL),
            win32.MEM_COMMIT | win32.MEM_RESERVE,
            win32.PAGE_READWRITE,
        )) |memory| {
            return Self{
                .width = width,
                .height = height,
                .pitch = width * BYTES_PER_PIXEL,
                .info = header(width, height),
                .memory = @ptrCast([*]u8, memory),
            };
        }
        return win32.WindowError.FailedToAllocateMemory;
    }

    pub fn release(self: Self) !void {
        if (!win32.VirtualFree(self.memory, 0, win32.MEM_RELEASE)) {}
    }

    pub fn gamebuffer(self: Self) snake.DrawBuffer {
        return snake.DrawBuffer{
            .height = self.height,
            .width = self.width,
            .pitch = self.pitch,
            .memory = self.memory[0..(self.pitch * self.height)],
        };
    }

    pub fn sync(self: Self, draw_buffer: *snake.DrawBuffer) void {
        draw_buffer.height = self.height;
        draw_buffer.width = self.width;
        draw_buffer.pitch = self.pitch;
        draw_buffer.memory = self.memory[0..(self.pitch * self.height)];
    }

    pub fn blit(self: *Self, hdc: win32.HDC, dimension: WindowDimension) bool {
        const buffer_width = @intCast(i32, self.width);
        const buffer_height = @intCast(i32, self.height);

        var center_window_x = std.math.max(0, @divTrunc(dimension.width, 2));
        var center_window_y = std.math.max(0, @divTrunc(dimension.height, 2));
        var center_buffer_x = std.math.max(0, @divTrunc(buffer_width, 2));
        var center_buffer_y = std.math.max(0, @divTrunc(buffer_height, 2));

        const draw_start_x = std.math.max(0, center_window_x - center_buffer_x);
        const draw_start_y = std.math.max(0, center_window_y - center_buffer_y);

        _ = win32.PatBlt(hdc, 0, 0, dimension.width, draw_start_y, win32.BLACKNESS) != 0;
        _ = win32.PatBlt(hdc, 0, 0, draw_start_x, dimension.height, win32.BLACKNESS) != 0;
        _ = win32.PatBlt(hdc, 0, draw_start_y + buffer_height, dimension.width, dimension.height - (draw_start_y - buffer_height), win32.BLACKNESS) != 0;
        _ = win32.PatBlt(hdc, draw_start_x + buffer_width, 0, dimension.width - (draw_start_x + buffer_width), dimension.height - draw_start_y, win32.BLACKNESS) != 0;

        return win32.StretchDIBits(
            hdc,
            draw_start_x,
            draw_start_y,
            buffer_width,
            buffer_height,
            0,
            0,
            buffer_width,
            buffer_height,
            self.memory,
            &self.info,
            win32.DIB_RGB_COLORS,
            win32.SRCCOPY,
        ) != 0;
    }

    fn buildInfo(width: u32, height: u32) BitmapInfo {
        const header = BitmapInfoHeader{
            .biWidth = @intCast(i32, width),
            .biHeight = -@intCast(i32, height),
            .biPlanes = 1,
            .biBitCount = 32,
            .biCompression = win32.BI_RGB,
        };
        return BitmapInfo{
            .bmiHeader = header,
            .bmiColors = undefined,
        };
    }
};
