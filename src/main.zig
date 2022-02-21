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

    pub fn draw(self: *Segment) void {
        const x = (self.position.x * SnakeSize);
        const y = (self.position.y * SnakeSize);
        w4.DRAW_COLORS.* = 2;
        w4.rect(x, y, SnakeSize, SnakeSize);
    }

    pub fn go(self: *Segment, direction: Direction) void {
        if (self.direction == direction.opposite()) {
            return;
        }
        self.direction = direction;
    }

    pub fn willBeOutOfBounds(self: *Segment) bool {
        const position = self.position.add(self.direction.to_vec2());
        if (position.y < SnakeYMin or position.y > SnakeYMax) {
            return true;
        }
        if (position.x < SnakeXMin or position.x > SnakeYMax) {
            return true;
        }
        return false;
    }
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

    pub fn opposite(self: Direction) Direction {
        return switch (self) {
            .Up => .Down,
            .Down => .Up,
            .Left => .Right,
            .Right => .Left,
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

    pub fn missing(self: *Fruit) bool {
        return self.pos == null;
    }

    pub fn overlaps(self: *Fruit, other: Vec2) bool {
        if (self.pos) |pos| {
            return pos.equals(other);
        }
        return false;
    }

    pub fn next(self: *Fruit, random: rand.Random) void {
        self.pos = Vec2{
            .x = random.intRangeLessThan(i32, 1, WorldWidth - 1),
            .y = random.intRangeLessThan(i32, TitleBarSize + 1, WorldHeight + TitleBarSize - 1),
        };
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
    next_tick: u32 = StepStride,
    input: Input = .{},
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

    pub fn should_tick(self: *State) bool {
        if (self.frame == self.next_tick) {
            self.next_tick = self.frame + StepStride;
            return true;
        }
        return false;
    }

    pub fn reset(self: *State) void {
        self.frame = 0;
        self.next_tick = StepStride;
        self.segments.clearAndFree();

        const starting_segment = Segment{
            .direction = .Up,
            .position = .{ .x = (WorldWidth / 2) - 1, .y = (WorldHeight / 2) },
        };
        self.segments.append(starting_segment) catch unreachable;
        self.game_state = .Play;
        prng = rand.DefaultPrng.init(40);
        self.random = prng.random();
        self.nextFruit();
    }

    pub fn willCollideWithSelf(self: *State) bool {
        return false;
    }

    pub fn nextFruit(self: *State) void {
        self.fruit.next(state.random);
    }

    pub fn snakeHead(self: *State) *Segment {
        return &self.segments.items[0];
    }

    pub fn maybEat(self: *State) void {
        const snake_head = self.snakeHead();
        if (!self.fruit.overlaps(snake_head.position)) {
            return;
        }
        self.fruit.pos = null;
    }

    pub fn updateSegments(self: *State) void {
        const segments = self.segments.items;
        var i: usize = segments.len;
        while (i > 0) {
            i -= 1;
            const segment = segments[i];
            const new_position = segment.position.add(segment.direction.to_vec2());
            segments[i].position = new_position;
            segments[i + 1].direction = segments[i].direction;
        }
    }

    pub fn draw(self: *State) void {
        var i: i16 = 0;
        const segments = self.segments.items;
        while (i < segments.len) : (i += 1) {
            segments[i].draw();
        }
    }
};
var state: *State = undefined;

fn mainMenu() void {}

fn play() void {
    var snake_head = state.snakeHead();
    if (state.input.just_pressed(Input.Left)) {
        snake_head.go(.Left);
    }
    if (state.input.just_pressed(Input.Right)) {
        snake_head.go(.Right);
    }
    if (state.input.just_pressed(Input.Up)) {
        snake_head.go(.Up);
    }
    if (state.input.just_pressed(Input.Down)) {
        snake_head.go(.Down);
    }

    if (state.should_tick()) {
        if (snake_head.willBeOutOfBounds() or state.willCollideWithSelf()) {
            state.game_state = .GameOver;
        } else if (state.fruit.missing()) {
            var segments = state.segments.items;
            const last_segment = segments[segments.len - 1];
            state.updateSegments();
            state.segments.append(last_segment) catch unreachable;
            w4.tone(180, 4, 50, w4.TONE_MODE1);
            state.nextFruit();
        } else {
            state.updateSegments();
            w4.tone(90, 3, 10, w4.TONE_MODE1);
        }

        state.maybEat();
    }
    state.frame += 1;
    state.draw();
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
    state.reset();

    state.nextFruit();
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
    // printMemory();
}

fn printMemory() void {
    var buffer: [32]u8 = undefined;
    var stack_allocator = heap.FixedBufferAllocator.init(buffer[0..]);
    var list = ArrayList(u8).init(stack_allocator.allocator());
    defer list.deinit();

    list.writer().print("mem: {}/{}", .{ FixedBufferAllocator.end_index, FreeMemory[0..].len }) catch unreachable;

    w4.DRAW_COLORS.* = 0x3;
    w4.text(list.items, 4, 148);
}
