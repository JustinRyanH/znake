const std = @import("std");
const win32 = @import("win32.zig");
const pong = @import("pong.zig");

const GameDrawBuffer = pong.GameDrawBuffer;

var RUNNING = false;

const BYTES_PER_PIXEL = 4;
const Win32OffscreenBuffer = struct {
    const BitmapInfoHeader = win32.BITMAPINFOHEADER;
    const BitmapInfo = win32.BITMAPINFO;
    const Self = @This();

    info: BitmapInfo,
    memory: *c_void,
    width: i32,
    height: i32,
    pitch: i32,

    pub fn init(width: i32, height: i32) !Self {
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
                .memory = memory,
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
                .memory = memory,
            };
        }
        return win32.WindowError.FailedToAllocateMemory;
    }

    pub fn release(self: Self) !void {
        if (!win32.VirtualFree(self.memory, 0, win32.MEM_RELEASE)) {}
    }

    pub fn gamebuffer(self: Self) GameDrawBuffer {
        return GameDrawBuffer{
            .height = self.height,
            .width = self.width,
            .pitch = self.pitch,
            .memory = self.memory,
        };
    }

    pub fn sync(self: Self, draw_buffer: *GameDrawBuffer) void {
        draw_buffer.height = self.height;
        draw_buffer.width = self.width;
        draw_buffer.pitch = self.pitch;
        draw_buffer.memory = self.memory;
    }

    pub fn blit(self: *Self, hdc: win32.HDC) bool {
        return win32.StretchDIBits(hdc, 0, 0, self.width, self.height, 0, 0, self.width, self.height, self.memory, &self.info, win32.DIB_RGB_COLORS, win32.SRCCOPY) != 0;
    }

    fn buildInfo(width: i32, height: i32) BitmapInfo {
        const header = BitmapInfoHeader{
            .biWidth = width,
            .biHeight = -height,
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

pub fn ProcessWidnowsEvents(window: win32.HWND, message: win32.UINT, w_param: win32.WPARAM, l_param: win32.LPARAM) callconv(.Stdcall) win32.LRESULT {
    var result: win32.LRESULT = std.mem.zeroes(win32.LRESULT);
    switch (message) {
        win32.WM_QUIT, win32.WM_CLOSE, win32.WM_DESTROY => {
            RUNNING = false;
        },
        else => {
            result = win32.DefWindowProcA(window, message, w_param, l_param);
        },
    }
    return result;
}

pub export fn WinMain(hInstance: win32.HINSTANCE, hPrevInstance: win32.HINSTANCE, lpCmdLine: win32.PWSTR, nCmdShow: win32.INT) win32.INT {
    var win32_draw_buffer = Win32OffscreenBuffer.init(640, 480) catch |err| @panic("Could not create Allocat Memory for Win32 Draw Buffer");

    var game_buffer = win32_draw_buffer.gamebuffer();

    var window = win32.Window.init(.{
        .wnd_proc = ProcessWidnowsEvents,
        .window_name = "Zig Pong Example",
        .window_class_name = "PongWindowClass",
        .h_instance = hInstance,
        .width = 640,
        .height = 480,
    }) catch |err| @panic("Could not Load Window");
    RUNNING = true;
    const HDC = win32.GetDC(window.window);

    while (RUNNING) {
        while (window.peek_message()) |message| {
            window.dispatch_message(message);

            win32_draw_buffer.sync(&game_buffer);

            _ = win32_draw_buffer.blit(HDC);
        }
    }
    return 0;
}
