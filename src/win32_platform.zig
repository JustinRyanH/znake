const std = @import("std");
const win32 = @import("win32.zig");
const snake = @import("snake_types.zig");
const utils = @import("utils.zig");
const platform_draw = @import("win32_draw.zig");
const platform_sound = @import("win32_sound.zig");
const assert = @import("utils.zig").assert;
const page_allocator = std.heap.page_allocator;

pub const panic = win32.win32_panic;
const InDebug = true;
const DrawBuffer = snake.DrawBuffer;
const Win32OffscreenBuffer = platform_draw.Win32OffscreenBuffer;
const NanosecondsInSeconds = 1000000000;
const NanosecondsInMilliseconds = 1000000;
const MillisecondsInSeconds = 1000;
const GameUpdateHz = 30.0;
const target_seconds: f32 = 1.0 / GameUpdateHz;

const DLLName = "game.dll";
const DLLTempName = "game_temp.dll";

var clock_frequency: f32 = undefined;
var exe_dir: []const u8 = undefined;

const GameFunctions = struct {
    updateGame: snake.UpdateGame,
    updateSound: snake.UpdateSound,
};

const Win32GameCode = struct {
    const OpenFlags = std.fs.File.OpenFlags;
    const CopyFileOptions = std.fs.CopyFileOptions;
    const Self = @This();

    src: []const u8,
    tmp: []const u8,
    code: ?std.DynLib = null,
    game_functions: ?GameFunctions = null,
    last_write_time: i64 = -1,

    pub fn load(source: []const u8, temp: []const u8) !Self {
        var result = Win32GameCode{
            .src = source,
            .tmp = temp,
        };
        try result.reload();
        return result;
    }

    pub fn reload(self: *Self) !void {
        self.unload();

        self.last_write_time = try getLastWrite(self.src);
        try std.fs.copyFileAbsolute(self.src, self.tmp, CopyFileOptions{});
        self.code = try std.DynLib.open(self.tmp);
        errdefer self.code.close();

        {
            var loaded = true;
            var game_functions: GameFunctions = undefined;
            if (self.code) |*dyn_lib| {
                if (dyn_lib.lookup(snake.UpdateSound, "updateSound")) |updateSound| {
                    game_functions.updateSound = updateSound;
                } else {
                    loaded = false;
                }

                if (dyn_lib.lookup(snake.UpdateGame, "updateGame")) |updateGame| {
                    game_functions.updateGame = updateGame;
                } else {
                    loaded = false;
                }
            }
            self.game_functions = if (loaded) game_functions else null;
        }

        return;
    }

    pub fn unload(self: *Self) void {
        if (self.code) |*code| {
            self.game_functions = null;
            code.close();
        }
    }

    pub fn hasChanged(self: *Self) bool {
        const new_time = getLastWrite(self.src) catch |err| {
            win32.debug("Hot Reload Boinked", .{});
            return false;
        };
        return self.last_write_time != new_time;
    }

    fn getLastWrite(source: []const u8) !i64 {
        // TODO(jhurstwright): std.os.fstat
        const file = try std.fs.openFileAbsolute(source, OpenFlags{ .read = true, .write = false });
        defer file.close();

        const stat = try file.stat();
        return stat.mtime;
    }
};

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

fn Win32ProcessKeyboard(keyboard: *snake.Keyboard, message: *win32.MSG) void {
    const vk_code = @intCast(u32, message.wParam);
    const was_down: bool = message.lParam & (1 << 30) != 0;
    const is_down: bool = message.lParam & (1 << 31) == 0;

    bitCastKeys(snake.NumberKeys, &keyboard.number, vk_code, '0', '9', 0, is_down);
    bitCastKeys(snake.NumberKeys, &keyboard.number, vk_code, win32.VK_NUMPAD0, win32.VK_NUMPAD9, 10, is_down);
    bitCastKeys(snake.NumberKeys, &keyboard.number, vk_code, win32.VK_MULTIPLY, win32.VK_DIVIDE, 20, is_down);
    bitCastKeys(snake.NumberKeys, &keyboard.number, vk_code, win32.VK_MULTIPLY, win32.VK_DIVIDE, 20, is_down);

    bitCastKeys(snake.SpecialKeys, &keyboard.special, vk_code, win32.VK_SHIFT, win32.VK_MENU, 0, is_down);
    bitCastKeys(snake.SpecialKeys, &keyboard.special, vk_code, win32.VK_LSHIFT, win32.VK_RMENU, 3, is_down);
    bitCastKeys(snake.SpecialKeys, &keyboard.special, vk_code, win32.VK_LEFT, win32.VK_DOWN, 9, is_down);
    bitCastKeys(snake.SpecialKeys, &keyboard.special, vk_code, win32.VK_PRIOR, win32.VK_HOME, 13, is_down);
    bitCastKey(snake.SpecialKeys, &keyboard.special, vk_code, win32.VK_INSERT, 17, is_down);

    bitCastKey(snake.LetterKeys, &keyboard.letter, vk_code, win32.VK_SPACE, 0, is_down);
    bitCastKeys(snake.LetterKeys, &keyboard.letter, vk_code, 'A', 'Z', 1, is_down);
    bitCastKeys(snake.LetterKeys, &keyboard.letter, vk_code, win32.VK_BACK, win32.VK_TAB, 1, is_down);
    bitCastKey(snake.LetterKeys, &keyboard.letter, vk_code, win32.VK_RETURN, 29, is_down);
    bitCastKey(snake.LetterKeys, &keyboard.letter, vk_code, win32.VK_DELETE, 30, is_down);
    bitCastKey(snake.LetterKeys, &keyboard.letter, vk_code, win32.VK_CLEAR, 31, is_down);
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

fn win32CreateGameData() !snake.Data {
    const permament_storage_size = utils.megabytes(64);
    const transient_storage_size = utils.megabytes(512);
    if (win32.VirtualAlloc(
        null,
        permament_storage_size + transient_storage_size,
        win32.MEM_COMMIT | win32.MEM_RESERVE,
        win32.PAGE_READWRITE,
    )) |memory| {
        const casted_memory = @ptrCast([*]u8, memory);
        const result = snake.Data{
            .permanent_storage = casted_memory[0..permament_storage_size],
            .transient_storage = casted_memory[permament_storage_size..(transient_storage_size + permament_storage_size)],
        };

        assert(result.permanent_storage.len == permament_storage_size);
        assert(result.transient_storage.len == transient_storage_size);

        return result;
    }
    return win32.WindowError.FailedToAllocateMemory;
}

pub fn win32GetWindowDimensions(window: *win32.Window) platform_draw.WindowDimension {
    var rect: win32.RECT = undefined;
    _ = win32.GetClientRect(window.window, &rect);

    return platform_draw.WindowDimension{
        .width = rect.right - rect.left,
        .height = rect.bottom - rect.top,
    };
}

fn win32GetSecondsElasped(recent: i64, later: i64) f32 {
    return @intToFloat(f32, later - recent) / clock_frequency;
}

fn win32InitGameSound(channels: u32, samples_per_second: u32) !snake.Sound {
    const max_latency_in_seconds = 4;
    const memory_size = samples_per_second * channels * max_latency_in_seconds;
    if (win32.VirtualAlloc(
        null,
        memory_size,
        win32.MEM_COMMIT | win32.MEM_RESERVE,
        win32.PAGE_READWRITE,
    )) |memory| {
        const casted_memory = @ptrCast([*]i16, @alignCast(@alignOf(i16), memory));
        return snake.Sound{
            .sample_buffer = casted_memory[0..memory_size],
            .sample_slice = casted_memory[0..memory_size],
            .samples_per_second = samples_per_second,
        };
    }
    return win32.WindowError.FailedToAllocateMemory;
}

fn win32CalculateFramesToWrite(game_sound: *snake.Sound, win32_sound: *platform_sound.SoundOutput) void {
    var padding = platform_sound.getPadding(win32_sound) catch |_| return;
    var frames_to_write = @intCast(i32, win32_sound.samples_per_second) - @intCast(i32, padding);
    if (frames_to_write > win32_sound.latency_frame_count) {
        frames_to_write = @intCast(i32, win32_sound.latency_frame_count) * 2;
    }
    if (frames_to_write < 0) {
        frames_to_write = @intCast(i32, win32_sound.latency_frame_count) * 2;
    }
    game_sound.sample_slice = game_sound.sample_buffer[0..(@intCast(usize, frames_to_write) * 2)];
}

pub export fn WinMain(hInstance: win32.HINSTANCE, hPrevInstance: win32.HINSTANCE, lpCmdLine: win32.PWSTR, nCmdShow: win32.INT) win32.INT {
    var pathBuffer = std.fs.selfExePathAlloc(page_allocator) catch |err| @panic("Failed to get Exe Path");
    // NOTE(jhurstwright): Don't actually free this because the OS will when the EXE close.
    // but I"m going to put commented out defers because why not
    // defer page_allocator.free(pathBuffer);
    if (std.fs.path.dirname(pathBuffer)) |path| {
        exe_dir = path[0..path.len];
    } else {
        @panic("Failed to get EXE directory");
    }

    const source_dll = std.fs.path.join(page_allocator, &[_][]const u8{ exe_dir, DLLName }) catch |err| {
        win32.debug("Err: {}\n", .{err});
        @panic("Failed to create source dll");
    };
    const tmp_dll = std.fs.path.join(page_allocator, &[_][]const u8{ exe_dir, DLLTempName }) catch |err| {
        win32.debug("Err: {}\n", .{err});
        @panic("Failed to create source dll");
    };

    var game_code = Win32GameCode.load(source_dll, tmp_dll) catch |err| {
        win32.debug("Err: {}\n", .{err});
        win32.debug("SourceDLL: {}\n", .{source_dll});
        win32.debug("TempDLL: {}\n", .{tmp_dll});
        @panic("Failed Loading Game Code");
    };

    clock_frequency = @intToFloat(f32, win32.GetFreq());
    win32.time_begin_period(1) catch |err| @panic("Time Period Begin Failure");
    defer win32.time_end_period(1) catch |err| @panic("Time Period End Failure");

    var game_sound = win32InitGameSound(2, 48000) catch |err| @panic("Failed to Initialize Sound");

    var win32_sound = platform_sound.init() catch |err| @panic("Failed to Initialize Sound");
    win32_sound.latency_frame_count = win32_sound.samples_per_second / @floatToInt(u32, GameUpdateHz);
    defer platform_sound.deinit(&win32_sound);

    var input = snake.Input{
        .delta_time = target_seconds,
        .keyboard = snake.Keyboard{
            .letter = snake.LetterKeys{},
            .number = snake.NumberKeys{},
            .special = snake.SpecialKeys{},
        },
        .window = snake.Window{
            .width = 640,
            .height = 480,
        },
    };

    var win32_draw_buffer = Win32OffscreenBuffer.init(input.window.width, input.window.height) catch |err| {
        win32.debug("Could not create Allocat Memory for Win32 Draw Buffer", .{});
        @panic("Could not create Allocat Memory for Win32 Draw Buffer");
    };
    var game_data = win32CreateGameData() catch |err| {
        win32.debug("Failed to Allocate Memory for the Game", .{});
        @panic("Failed to Allocate Memory for the Game");
    };

    var game_draw_buffer = win32_draw_buffer.gamebuffer();
    var window = win32.Window.init(.{
        .wnd_proc = ProcessWindowsEvents,
        .window_name = "Zig snake Example",
        .window_class_name = "snakeWindowClass",
        .h_instance = hInstance,
        .width = @intCast(i32, input.window.width),
        .height = @intCast(i32, input.window.height),
    }) catch |err| {
        win32.debug("Could not Load Window", .{});
        @panic("Could not Load Window");
    };

    RUNNING = true;
    const HDC = win32.GetDC(window.window);

    var last_counter = win32.GetWallClock();
    while (RUNNING) {
        if (game_code.hasChanged()) {
            win32.debug("Game Code Changed\n", .{});
            game_code.reload() catch unreachable;
        }
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

        if (game_code.game_functions) |game| {
            // TODO(jhurstwright): Turn this off in release mode
            const before = std.mem.toBytes(input);
            game.updateGame(&input, &game_data, &game_draw_buffer);
            game.updateSound(&game_data, &game_sound);

            // NOTE(jhurstwright): I want to assert that the game update doesn't mutate the input.
            // This will blow up if I accidently do that
            // TODO(jhurstwright): Turn this off in release mode
            const after = std.mem.toBytes(input);
            assert(std.mem.eql(u8, after[0..after.len], before[0..before.len]));
        }
        platform_sound.fillBuffer(&win32_sound, game_sound.sample_slice);

        var end_counter = win32.GetWallClock();

        var elapsed = win32GetSecondsElasped(last_counter, end_counter);
        if (target_seconds > elapsed) {
            const nanoSecondsToWait = @floatToInt(u64, target_seconds * MillisecondsInSeconds - elapsed * MillisecondsInSeconds) * NanosecondsInMilliseconds;
            // NOTE(jhurstwright): Shaving off a half a millisecond seems to reduce the misses
            std.time.sleep(nanoSecondsToWait - 500);
        } else {
            win32.debug("Missed Target Frame Rate\n", .{});
        }
        elapsed = win32GetSecondsElasped(last_counter, end_counter);
        if (elapsed > target_seconds) {
            win32.debug("Missed Alarm Clock: {d:1}, {d:1}\n", .{ elapsed, target_seconds });
        }
        while (elapsed < target_seconds) {
            elapsed = win32GetSecondsElasped(last_counter, end_counter);
            end_counter = win32.GetWallClock();
        }

        // const ms_per_frame = MillisecondsInSeconds * elapsed;
        // win32.debug("MS PER FRAME: {d:1}\n", .{ms_per_frame});
        last_counter = end_counter;
        input.frame += 1;

        const dimension = win32GetWindowDimensions(&window);
        _ = win32_draw_buffer.blit(HDC, dimension);
    }
    return 0;
}
