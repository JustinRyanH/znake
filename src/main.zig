const w4 = @import("wasm4.zig");
const heap = @import("std").heap;
const rand = @import("std").rand;
const Allocator = @import("std").mem.Allocator;
const ArrayList = @import("std").ArrayList;

const StackMemorySize = 0x3000;
const FreeMemoryStart = 0x19A0 + StackMemorySize;
const FreeMemoryAvailable = 0xE65F - StackMemorySize;

var FreeMemory: *[FreeMemoryAvailable]u8 = @intToPtr(*[FreeMemoryAvailable]u8, FreeMemoryStart);

const TitleBarSize = 4;
const WorldWidth = w4.CANVAS_SIZE / SnakeSize;
const WorldHeight = (w4.CANVAS_SIZE - TitleBarSize) / SnakeSize;
const SnakeSize = 4;
const TopBarSize = SnakeSize * TitleBarSize;
const StepStride = 10;

const SnakeYMin = TitleBarSize;
const SnakeYMax = WorldHeight;
const SnakeXMin = 0;
const SnakeXMax = WorldWidth;

var FixedBufferAllocator = heap.FixedBufferAllocator.init(FreeMemory[0..]);
var fixedAlloator = FixedBufferAllocator.allocator();

var prng = rand.DefaultPrng.init(40);

const SegmentList = ArrayList(Segment);
pub const Segment = struct {
    position: Vec2,
    direction: Direction,
};

pub const Direction = enum {
    Up,
    Down,
    Left,
    Right,

    pub fn to_vec2(self: Direction) Vec2 {
        return switch (self) {
            .Up => .{ .y = -1 },
            .Down => .{ .y = 1 },
            .Left => .{ .x = -1 },
            .Right => .{ .x = 1 },
        };
    }
};

pub const Vec2 = struct {
    x: i32 = 0,
    y: i32 = 0,

    pub fn add(self: Vec2, other: Vec2) Vec2 {
        return Vec2{
            .x = self.x + other.x,
            .y = self.y + other.y,
        };
    }

    pub fn equals(self: Vec2, other: Vec2) bool {
        return self.x == other.x and self.y == other.y;
    }
};

pub const Fruit = struct {
    pos: ?Vec2 = null,

    pub fn draw(self: *Fruit) void {
        if (self.pos) |pos| {
            const x = (pos.x * SnakeSize);
            const y = (pos.y * SnakeSize);
            w4.DRAW_COLORS.* = 3;
            w4.rect(x + 1, y + 1, 2, 2);
        }
    }

    pub fn exists(self: *Fruit) bool {
        self.pos == null;
    }

    pub fn overlaps(self: *Fruit, other: Vec2) bool {
        if (self.pos) |pos| {
            return pos.equals(other);
        }
        return false;
    }

    pub fn next(self: *Fruit, random: rand.Random) void {
        self.pos = Vec2{
            .x = random.intRangeLessThan(i32, 0, WorldWidth),
            .y = random.intRangeLessThan(i32, TitleBarSize, WorldHeight + TitleBarSize),
        };
    }
};

pub const Snake = struct {
    const DefaultDirectoin: Direction = .Up;

    next_update_frame: u32 = StepStride,
    pos: Vec2 = .{ .x = (WorldWidth / 2) - 1, .y = (WorldHeight / 2) },
    dir: Direction = DefaultDirectoin,

    pub fn reset(self: *Snake) void {
        self.next_update_frame = state.frame + StepStride;
        self.pos = .{ .x = (WorldWidth / 2) - 1, .y = (WorldHeight / 2) };
        self.dir = DefaultDirectoin;
    }

    pub fn will_move(self: *Snake) bool {
        return state.frame == self.next_update_frame;
    }

    pub fn maybe_eat(self: *Snake, fruit: *Fruit) void {
        if (fruit.overlaps(self.pos)) {
            fruit.pos = null;
        }
    }

    pub fn tick(self: *Snake) void {
        const d = self.dir.to_vec2();
        self.pos = self.pos.add(d);
        self.next_update_frame = state.frame + StepStride;
    }

    pub fn will_be_out_of_bounds(self: *Snake) bool {
        const pos = self.pos.add(self.dir.to_vec2());
        if (pos.y < SnakeYMin or pos.y > SnakeYMax) {
            return true;
        }
        if (pos.x < SnakeXMin or pos.x > SnakeYMax) {
            return true;
        }
        return false;
    }

    pub fn draw(self: *Snake) void {
        const x = (self.pos.x * SnakeSize);
        const y = (self.pos.y * SnakeSize);
        w4.DRAW_COLORS.* = 2;
        w4.rect(x, y, SnakeSize, SnakeSize);
    }
};

pub const Input = packed struct {
    const ButtonA = w4.BUTTON_1;
    const ButtonB = w4.BUTTON_2;
    const Left = w4.BUTTON_LEFT;
    const Right = w4.BUTTON_RIGHT;
    const Up = w4.BUTTON_UP;
    const Down = w4.BUTTON_DOWN;

    frame: u8 = 0,
    last_frame: u8 = 0,

    pub fn down(self: *Input, button: u8) bool {
        return self.frame & button != 0;
    }

    pub fn up(self: *Input, button: u8) bool {
        return !self.down(button);
    }

    pub fn just_released(self: *Input, button: u8) bool {
        const last_down = self.last_frame_down(button);
        return last_down and self.up(button);
    }

    pub fn just_pressed(self: *Input, button: u8) bool {
        const last_up = !self.last_frame_down(button);
        return last_up and self.down(button);
    }

    pub fn process(self: *Input) void {
        self.frame = w4.GAMEPAD1.*;
    }

    pub fn swap(self: *Input) void {
        self.last_frame = self.frame;
    }

    fn last_frame_down(self: *Input, button: u8) bool {
        return self.last_frame & button != 0;
    }
};

pub const GameState = enum {
    Menu,
    Play,
    GameOver,
};

pub const State = struct {
    allocator: Allocator,
    random: rand.Random,

    frame: u32 = 0,
    input: Input = .{},
    snake: Snake = .{},
    segments: SegmentList,
    fruit: Fruit = .{},
    game_state: GameState = .GameOver,

    pub fn alloc_and_init(allocator: Allocator) *State {
        state = allocator.create(State) catch unreachable;
        state.* = .{
            .allocator = allocator,
            .random = prng.random(),
            .segments = SegmentList.init(allocator),
        };
        return state;
    }

    pub fn reset(self: *State) void {
        self.frame = 0;
        self.snake.reset();
        self.game_state = .Play;
        prng = rand.DefaultPrng.init(40);
        self.random = prng.random();
        self.next_fruit();
    }

    pub fn next_fruit(self: *State) void {
        self.fruit.next(state.random);
    }
};
var state: *State = undefined;

fn mainMenu() void {}

fn play() void {
    if (state.input.just_pressed(Input.Left)) {
        state.snake.dir = .Left;
    }
    if (state.input.just_pressed(Input.Right)) {
        state.snake.dir = .Right;
    }
    if (state.input.just_pressed(Input.Up)) {
        state.snake.dir = .Up;
    }
    if (state.input.just_pressed(Input.Down)) {
        state.snake.dir = .Down;
    }

    if (state.snake.will_move()) {
        if (state.snake.will_be_out_of_bounds()) {
            state.game_state = .GameOver;
        } else {
            state.snake.tick();
        }
        state.snake.maybe_eat(&state.fruit);
    }
    state.frame += 1;
    state.snake.draw();
    state.fruit.draw();
}

fn gameOver() void {
    w4.text("GAME OVER", 42, w4.CANVAS_SIZE / 2);
    if (state.input.down(Input.ButtonB)) {
        w4.DRAW_COLORS.* = 0x02;
    } else {
        w4.DRAW_COLORS.* = 0x04;
    }
    w4.text("Press Z to Restart", 8, w4.CANVAS_SIZE / 2 + 14);
    if (state.input.just_released(Input.ButtonB)) {
        state.reset();
    }
}

export fn start() void {
    state = State.alloc_and_init(fixedAlloator);
    state.next_fruit();
}

export fn update() void {
    state.input.process();

    w4.DRAW_COLORS.* = 0x04;
    w4.rect(0, 0, w4.CANVAS_SIZE, TopBarSize);
    w4.DRAW_COLORS.* = 2;
    w4.text("WASM4 Znake", 32, 4);

    switch (state.game_state) {
        .Menu => mainMenu(),
        .Play => play(),
        .GameOver => gameOver(),
    }
    state.input.swap();
    printMemory();
}

fn printMemory() void {
    var buffer: [32]u8 = undefined;
    var stack_allocator = heap.FixedBufferAllocator.init(buffer[0..]);
    var list = ArrayList(u8).init(stack_allocator.allocator());
    defer list.deinit();

    list.writer().print("mem: {}/{}", .{ FixedBufferAllocator.end_index, FreeMemory[0..].len }) catch unreachable;
    w4.tracef("%d", list.items.len);

    w4.DRAW_COLORS.* = 0x3;
    w4.text(list.items, 4, 148);
}
