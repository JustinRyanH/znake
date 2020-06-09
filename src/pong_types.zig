pub const Window = struct {
    last_change_frame: usize = 0,
    width: u32,
    height: u32,
};

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

pub const Input = struct {
    frame: usize = 0,
    delta_time: f32,
    keyboard: Keyboard,
    window: Window,
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
    wave_period: u32,
};

pub const Data = struct {
    initialized: bool = false,

    permanent_storage: []u8,
    transient_storage: []u8,
};

pub const Sound = struct {
    sample_buffer: []i16,
    sample_slice: []i16,
    samples_per_second: u32,
};

pub const DrawBuffer = struct {
    height: u32,
    width: u32,
    pitch: u32,
    memory: []u8,
};

pub const UpdateGame = fn (input: *Input, data: *Data, draw_buffer: *DrawBuffer) void;
pub const UpdateSound = fn (game_data: *Data, sound: *Sound) void;
