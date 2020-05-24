const std = @import("std");
const win32 = @import("win32.zig");
const pong = @import("pong.zig");
const win32_draw = @import("win32_draw.zig");

const GameDrawBuffer = pong.GameDrawBuffer;
const Win32OffscreenBuffer = win32_draw.Win32OffscreenBuffer;

var RUNNING = false;
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
    const width = 320;
    const height = 240;
    var win32_draw_buffer = Win32OffscreenBuffer.init(width, height) catch |err| @panic("Could not create Allocat Memory for Win32 Draw Buffer");

    var game_draw_buffer = win32_draw_buffer.gamebuffer();

    var window = win32.Window.init(.{
        .wnd_proc = ProcessWidnowsEvents,
        .window_name = "Zig Pong Example",
        .window_class_name = "PongWindowClass",
        .h_instance = hInstance,
        .width = width,
        .height = height,
    }) catch |err| @panic("Could not Load Window");
    RUNNING = true;
    const HDC = win32.GetDC(window.window);

    while (RUNNING) {
        while (window.peek_message()) |message| {
            window.dispatch_message(message);

            win32_draw_buffer.sync(&game_draw_buffer);
            pong.DebugFillBuffer(&game_draw_buffer);

            _ = win32_draw_buffer.blit(HDC);
        }
    }
    return 0;
}
