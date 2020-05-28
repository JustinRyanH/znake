const std = @import("std");
const win32 = @import("win32.zig");
const pong = @import("pong.zig");
const win32_draw = @import("win32_draw.zig");

const GameDrawBuffer = pong.GameDrawBuffer;
const Win32OffscreenBuffer = win32_draw.Win32OffscreenBuffer;

fn Win32ProcessKeyboard(keyboard: *pong.Keyboard, message: *win32.MSG) void {
    const vk_code = @intCast(u32, message.wParam);
    const was_down: bool = message.lParam & (1 << 30) != 0;
    const is_down: bool = message.lParam & (1 << 31) == 0;

    if (vk_code >= '0' and vk_code <= '9') {
        const down_shift: i32 = @intCast(i32, (vk_code - '0'));
        std.debug.assert(down_shift > 0);
        const splat: u32 = @shlExact(@as(u32, 1), @intCast(u5, down_shift));

        const u32_keyboard = @bitCast(u32, keyboard.numbers);
        const new_keyboard = if (is_down) u32_keyboard | splat else u32_keyboard ^ splat;
        keyboard.numbers = @bitCast(pong.NumberKeys, new_keyboard);
    }
}

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
    const width = 640;
    const height = 480;
    var win32_draw_buffer = Win32OffscreenBuffer.init(width, height) catch |err| @panic("Could not create Allocat Memory for Win32 Draw Buffer");

    var keyboard = pong.Keyboard{
        .letter_keys = pong.LetterKeys{},
        .numbers = pong.NumberKeys{},
        .special_keys = pong.SpecialKeys{},
    };
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
            switch (message.message) {
                win32.WM_KEYUP, win32.WM_KEYDOWN, win32.WM_SYSKEYUP, win32.WM_SYSKEYDOWN => {
                    Win32ProcessKeyboard(&keyboard, message);
                },
                else => {},
            }
            window.dispatch_message(message);
        }
        pong.UpdateGame(&keyboard);

        win32_draw_buffer.sync(&game_draw_buffer);
        pong.DebugFillBuffer(&game_draw_buffer);

        _ = win32_draw_buffer.blit(HDC);
    }
    return 0;
}
