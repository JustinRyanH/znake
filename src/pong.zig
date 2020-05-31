const std = @import("std");
const win32 = @import("win32.zig");
const assert = @import("utils.zig").assert;

pub const KeyState = enum(u1) { Up = 0, Down = 1 };

pub const LetterKeys = packed struct {
    space: KeyState = .Up,
    a: KeyState = .Up,
    b: KeyState = .Up,
    c: KeyState = .Up,
    d: KeyState = .Up,
    e: KeyState = .Up,
    f: KeyState = .Up,
    g: KeyState = .Up,
    h: KeyState = .Up,
    i: KeyState = .Up,
    j: KeyState = .Up,
    k: KeyState = .Up,
    l: KeyState = .Up,
    m: KeyState = .Up,
    n: KeyState = .Up,
    o: KeyState = .Up,
    p: KeyState = .Up,
    q: KeyState = .Up,
    r: KeyState = .Up,
    s: KeyState = .Up,
    t: KeyState = .Up,
    u: KeyState = .Up,
    v: KeyState = .Up,
    w: KeyState = .Up,
    x: KeyState = .Up,
    y: KeyState = .Up,
    z: KeyState = .Up,
    backspace: KeyState = .Up,
    tab: KeyState = .Up,
    enter: KeyState = .Up,
    del: KeyState = .Up,
    clear: KeyState = .Up,
};

pub const NumberKeys = packed struct {
    zero: KeyState = .Up,
    one: KeyState = .Up,
    two: KeyState = .Up,
    three: KeyState = .Up,
    four: KeyState = .Up,
    five: KeyState = .Up,
    six: KeyState = .Up,
    seven: KeyState = .Up,
    eight: KeyState = .Up,
    nine: KeyState = .Up,
    numpad_zero: KeyState = .Up,
    numpad_one: KeyState = .Up,
    numpad_two: KeyState = .Up,
    numpad_three: KeyState = .Up,
    numpad_four: KeyState = .Up,
    numpad_five: KeyState = .Up,
    numpad_six: KeyState = .Up,
    numpad_seven: KeyState = .Up,
    numpad_eight: KeyState = .Up,
    numpad_nine: KeyState = .Up,
    add: KeyState = .Up,
    seperator: KeyState = .Up,
    subtract: KeyState = .Up,
    decimal: KeyState = .Up,
    extra: u8 = 0,
};

pub const SpecialKeys = packed struct {
    general_shift: KeyState = .Up,
    general_ctrl: KeyState = .Up,
    general_alt: KeyState = .Up,
    left_shift: KeyState = .Up,
    left_ctrl: KeyState = .Up,
    left_alt: KeyState = .Up,
    right_shift: KeyState = .Up,
    right_ctrl: KeyState = .Up,
    right_alt: KeyState = .Up,
    left_arrow: KeyState = .Up,
    up_arrow: KeyState = .Up,
    right_arrow: KeyState = .Up,
    down_arrow: KeyState = .Up,
    page_up: KeyState = .Up,
    page_down: KeyState = .Up,
    end: KeyState = .Up,
    home: KeyState = .Up,
    insert: KeyState = .Up,
    rest: u14 = 0,
};

pub const GameInput = struct {
    keyboard: Keyboard,
};

pub const Keyboard = struct {
    letter: LetterKeys,
    number: NumberKeys,
    special: SpecialKeys,
};

pub const DebugData = struct {
    x_offset: u32,
    y_offset: u32,
    tone_hz: u32,
    sine_time: f32,
};

pub const GameData = struct {
    initialized: bool = false,

    permanent_storage: []u8,
    transient_storage: []u8,
};

pub const GameDrawBuffer = struct {
    height: u32,
    width: u32,
    pitch: u32,
    memory: []u8,
};

pub const Pixel = packed struct {
    blue: u8,
    green: u8,
    red: u8,
    padding: u8,
};

pub fn debugFillBuffer(draw_buffer: *GameDrawBuffer, x_offset: u32, y_offset: u32) void {
    assert(draw_buffer.memory.len == draw_buffer.height * draw_buffer.pitch);
    var y_index: usize = 0;
    var pixels = std.mem.bytesAsSlice(Pixel, draw_buffer.memory);
    assert(pixels.len == draw_buffer.height * draw_buffer.width);

    while (y_index < draw_buffer.height) {
        const start = y_index * draw_buffer.width;
        const end = start + draw_buffer.width;
        for (pixels[start..end]) |*pixel, x_index| {
            pixel.*.blue = @truncate(u8, x_index + x_offset);
            pixel.*.green = @truncate(u8, y_index + y_offset);
        }
        y_index += 1;
    }
}

pub fn updateGame(input: *GameInput, data: *GameData, draw_buffer: *GameDrawBuffer) void {
    const debug_data = @ptrCast(*DebugData, @alignCast(@alignOf(DebugData), data.permanent_storage[0..@sizeOf(DebugData)]));

    if (!data.initialized) {
        data.initialized = true;
        debug_data.tone_hz = 440;
    }

    const keyboard = input.keyboard;
    if (keyboard.letter.w == .Down or keyboard.special.up_arrow == .Down) {
        debug_data.*.y_offset = debug_data.y_offset +% 1;
    } else if (keyboard.letter.s == .Down or keyboard.special.down_arrow == .Down) {
        debug_data.*.y_offset = debug_data.y_offset -% 1;
    }

    if (keyboard.letter.a == .Down or keyboard.special.up_arrow == .Down) {
        debug_data.*.x_offset = debug_data.x_offset +% 1;
    } else if (keyboard.letter.d == .Down or keyboard.special.down_arrow == .Down) {
        debug_data.*.x_offset = debug_data.x_offset -% 1;
    }
    debugFillBuffer(draw_buffer, debug_data.x_offset, debug_data.y_offset);
}
