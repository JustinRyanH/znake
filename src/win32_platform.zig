const std = @import("std");
const win32 = @import("win32.zig");
const pong = @import("pong.zig");
const utils = @import("utils.zig");
const platform_draw = @import("win32_draw.zig");
const platform_sound = @import("win32_sound.zig");
const assert = @import("utils.zig").assert;

pub const panic = win32.win32_panic;

const GameDrawBuffer = pong.GameDrawBuffer;
const Win32OffscreenBuffer = platform_draw.Win32OffscreenBuffer;
const GameUpdateHz = 30.0;

var clock_frequency: f32 = undefined;

fn bitCastKey(T: var, target: *T, vk_code: u32, key: u32, offset: u5, is_down: bool) void {
    if (vk_code == key) {
        const down_shift: i32 = @intCast(i32, (vk_code - key)) + @intCast(i32, offset);
        assert(down_shift >= 0);
        const splat: u32 = @shlExact(@as(u32, 1), @intCast(u5, down_shift));

        const u32_keyboard = @bitCast(u32, target.*);
        const new_keyboard = if (is_down) u32_keyboard | splat else u32_keyboard ^ splat;
        target.* = @bitCast(T, new_keyboard);
    }
}

fn bitCastKeys(T: var, target: *T, vk_code: u32, min: u32, max: u32, offset: u5, is_down: bool) void {
    if (vk_code >= min and vk_code <= max) {
        const down_shift: i32 = @intCast(i32, (vk_code - min)) + @intCast(i32, offset);
        assert(down_shift >= 0);
        const splat: u32 = @shlExact(@as(u32, 1), @intCast(u5, down_shift));

        const u32_keyboard = @bitCast(u32, target.*);
        const new_keyboard = if (is_down) u32_keyboard | splat else u32_keyboard ^ splat;
        target.* = @bitCast(T, new_keyboard);
    }
}

fn Win32ProcessKeyboard(keyboard: *pong.Keyboard, message: *win32.MSG) void {
    const vk_code = @intCast(u32, message.wParam);
    const was_down: bool = message.lParam & (1 << 30) != 0;
    const is_down: bool = message.lParam & (1 << 31) == 0;

    bitCastKeys(pong.NumberKeys, &keyboard.number, vk_code, '0', '9', 0, is_down);
    bitCastKeys(pong.NumberKeys, &keyboard.number, vk_code, win32.VK_NUMPAD0, win32.VK_NUMPAD9, 10, is_down);
    bitCastKeys(pong.NumberKeys, &keyboard.number, vk_code, win32.VK_MULTIPLY, win32.VK_DIVIDE, 20, is_down);
    bitCastKeys(pong.NumberKeys, &keyboard.number, vk_code, win32.VK_MULTIPLY, win32.VK_DIVIDE, 20, is_down);

    bitCastKeys(pong.SpecialKeys, &keyboard.special, vk_code, win32.VK_SHIFT, win32.VK_MENU, 0, is_down);
    bitCastKeys(pong.SpecialKeys, &keyboard.special, vk_code, win32.VK_LSHIFT, win32.VK_RMENU, 3, is_down);
    bitCastKeys(pong.SpecialKeys, &keyboard.special, vk_code, win32.VK_LEFT, win32.VK_DOWN, 9, is_down);
    bitCastKeys(pong.SpecialKeys, &keyboard.special, vk_code, win32.VK_PRIOR, win32.VK_HOME, 13, is_down);
    bitCastKey(pong.SpecialKeys, &keyboard.special, vk_code, win32.VK_INSERT, 17, is_down);

    bitCastKey(pong.LetterKeys, &keyboard.letter, vk_code, win32.VK_SPACE, 0, is_down);
    bitCastKeys(pong.LetterKeys, &keyboard.letter, vk_code, 'A', 'Z', 1, is_down);
    bitCastKeys(pong.LetterKeys, &keyboard.letter, vk_code, win32.VK_BACK, win32.VK_TAB, 1, is_down);
    bitCastKey(pong.LetterKeys, &keyboard.letter, vk_code, win32.VK_RETURN, 29, is_down);
    bitCastKey(pong.LetterKeys, &keyboard.letter, vk_code, win32.VK_DELETE, 30, is_down);
    bitCastKey(pong.LetterKeys, &keyboard.letter, vk_code, win32.VK_CLEAR, 31, is_down);
}

var RUNNING = false;
pub fn ProcessWindowsEvents(window: win32.HWND, message: win32.UINT, w_param: win32.WPARAM, l_param: win32.LPARAM) callconv(.Stdcall) win32.LRESULT {
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

fn win32CreateGameData() !pong.GameData {
    const permament_storage_size = utils.megabytes(64);
    const transient_storage_size = utils.megabytes(512);
    if (win32.VirtualAlloc(
        null,
        permament_storage_size + transient_storage_size,
        win32.MEM_COMMIT | win32.MEM_RESERVE,
        win32.PAGE_READWRITE,
    )) |memory| {
        const casted_memory = @ptrCast([*]u8, memory);
        const result = pong.GameData{
            .permanent_storage = casted_memory[0..permament_storage_size],
            .transient_storage = casted_memory[permament_storage_size..(transient_storage_size + permament_storage_size)],
        };

        assert(result.permanent_storage.len == permament_storage_size);
        assert(result.transient_storage.len == transient_storage_size);

        return result;
    }
    return win32.WindowError.FailedToAllocateMemory;
}

fn win32GetSecondsElasped(recent: i64, later: i64) f32 {
    return @intToFloat(f32, later - recent) / clock_frequency;
}

fn win32InitGameSound(channels: u32, samples_per_second: u32) !pong.Sound {
    const max_latency_in_seconds = 2;
    const memory_size = samples_per_second * channels * max_latency_in_seconds;
    if (win32.VirtualAlloc(
        null,
        memory_size,
        win32.MEM_COMMIT | win32.MEM_RESERVE,
        win32.PAGE_READWRITE,
    )) |memory| {
        const casted_memory = @ptrCast([*]f32, @alignCast(@alignOf(f32), memory));
        // sample_buffer: []f32,
        // samples_to_write: i32 = 0,
        // samples_per_second: i32 = 48000,
        return pong.Sound{
            .sample_buffer = casted_memory[0..memory_size],
            .samples_to_write = 0,
            .samples_per_second = samples_per_second,
        };
    }
    return win32.WindowError.FailedToAllocateMemory;
}

fn win32CalculateFramesToWrite(game_sound: *pong.Sound, win32_sound: *platform_sound.SoundOutput) void {
    var padding = platform_sound.getPadding(win32_sound) catch |_| return;
    var samples_to_write = @intCast(i32, win32_sound.samples_per_second) - @intCast(i32, padding);
    if (samples_to_write > win32_sound.latency_frame_count) {
        game_sound.samples_to_write = win32_sound.latency_frame_count;
    }
    if (samples_to_write < 0) {
        game_sound.samples_to_write = win32_sound.latency_frame_count;
    }
}

pub export fn WinMain(hInstance: win32.HINSTANCE, hPrevInstance: win32.HINSTANCE, lpCmdLine: win32.PWSTR, nCmdShow: win32.INT) win32.INT {
    clock_frequency = @intToFloat(f32, win32.GetFreq());
    win32.time_begin_period(1) catch |err| @panic("Time Period Begin Failure");
    defer win32.time_end_period(1) catch |err| @panic("Time Period End Failure");

    var game_sound = win32InitGameSound(2, 48000) catch |err| @panic("Failed to Initialize Sound");

    var win32_sound = platform_sound.init() catch |err| @panic("Failed to Initialize Sound");
    win32_sound.latency_frame_count = win32_sound.samples_per_second / @floatToInt(u32, GameUpdateHz);
    defer platform_sound.deinit(&win32_sound);

    const width = 640;
    const height = 480;
    var win32_draw_buffer = Win32OffscreenBuffer.init(width, height) catch |err| {
        win32.debug("Could not create Allocat Memory for Win32 Draw Buffer", .{});
        @panic("Could not create Allocat Memory for Win32 Draw Buffer");
    };
    var game_data = win32CreateGameData() catch |err| {
        win32.debug("Failed to Allocate Memory for the Game", .{});
        @panic("Failed to Allocate Memory for the Game");
    };

    var input = pong.GameInput{
        .keyboard = pong.Keyboard{
            .letter = pong.LetterKeys{},
            .number = pong.NumberKeys{},
            .special = pong.SpecialKeys{},
        },
    };

    var game_draw_buffer = win32_draw_buffer.gamebuffer();
    var window = win32.Window.init(.{
        .wnd_proc = ProcessWindowsEvents,
        .window_name = "Zig Pong Example",
        .window_class_name = "PongWindowClass",
        .h_instance = hInstance,
        .width = width,
        .height = height,
    }) catch |err| {
        win32.debug("Could not Load Window", .{});
        @panic("Could not Load Window");
    };

    RUNNING = true;
    const HDC = win32.GetDC(window.window);

    var last_counter = win32.GetWallClock();
    while (RUNNING) {
        while (window.peek_message()) |message| {
            switch (message.message) {
                win32.WM_KEYUP, win32.WM_KEYDOWN, win32.WM_SYSKEYUP, win32.WM_SYSKEYDOWN => {
                    Win32ProcessKeyboard(&input.keyboard, message);
                },
                else => {},
            }
            window.dispatch_message(message);
        }
        win32CalculateFramesToWrite(&game_sound, &win32_sound);
        win32_draw_buffer.sync(&game_draw_buffer);

        pong.updateGame(&input, &game_data, &game_draw_buffer);
        pong.updateSound(&game_data, &game_sound);
        platform_sound.fillBuffer(&win32_sound, game_sound.sample_buffer[0..game_sound.samples_to_write]);

        const end_counter = win32.GetWallClock();
        const ms_per_frame = 1000.0 * win32GetSecondsElasped(last_counter, end_counter);
        // win32.debug("MS PER FRAME: {d:1}\n", .{ms_per_frame});
        last_counter = end_counter;

        _ = win32_draw_buffer.blit(HDC);
    }
    return 0;
}
