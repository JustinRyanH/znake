const std = @import("std");
const win32 = @import("win32.zig");
const snake = @import("snake_types.zig");

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

    pub fn blit(self: *Self, hdc: win32.HDC) bool {
        // TODO(justin): Take in Window Information and center it,
        // OR keep the aspect ratio the same and still center it
        return win32.StretchDIBits(
            hdc,
            0,
            0,
            @intCast(i32, self.width),
            @intCast(i32, self.height),
            0,
            0,
            @intCast(i32, self.width),
            @intCast(i32, self.height),
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
