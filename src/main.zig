// TODO: Fix where Food can spawn on top of snake
// TODO: Score, Collect and Show Score on Game Over
// TODO: More Juicy Death
// TODO: Particals when Snake eats fruit
// TODO: Textures for Snake

const w4 = @import("wasm4.zig");
const Game = @import("game.zig");

const heap = @import("std").heap;
const rand = @import("std").rand;
const math = @import("std").math;
const Allocator = @import("std").mem.Allocator;
const ArrayList = @import("std").ArrayList;

///////////////////////
// "Heap" Allocation
//////////////////////

const StackMemorySize = 0x3000;
const FreeMemoryStart = 0x19A0 + StackMemorySize;
const FreeMemoryAvailable = 0xE65F - StackMemorySize;

var FreeMemory: *[FreeMemoryAvailable]u8 = @intToPtr(*[FreeMemoryAvailable]u8, FreeMemoryStart);

///////////////////////
// "Game Globals"
//////////////////////
const TitleBarSize = 2;
const WorldWidth = w4.CANVAS_SIZE / SnakeSize;
const WorldHeight = (w4.CANVAS_SIZE - TitleBarSize) / SnakeSize;
const SnakeSize = 8;
const SnakeSizeHalf = SnakeSize / 2;
const TopBarSize = SnakeSize * TitleBarSize;
const StepStride = 10;

const SnakeYMin = TitleBarSize;
const SnakeYMax = WorldHeight;
const SnakeXMin = 0;
const SnakeXMax = WorldWidth;

var FixedBufferAllocator = heap.FixedBufferAllocator.init(FreeMemory[0..]);
var fixedAlloator = FixedBufferAllocator.allocator();

var prng = rand.DefaultPrng.init(40);

///////////////////////
// Game Types
//////////////////////

pub const Segment = Game.Segment;
const SegmentList = ArrayList(Segment);
pub const Direction = Game.Direction;
pub const Vec2 = Game.Vec2;
pub const Fruit = Game.Fruit;

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
    y_min: u8 = SnakeYMin,
    y_max: u8 = SnakeYMax,
    x_min: u8 = SnakeXMin,
    x_max: u8 = SnakeXMax,

    frame: u32 = 0,
    next_tick: u32 = StepStride,
    input: Input = .{},
    maybe_next_direction: Direction = .Up,
    segments: SegmentList,
    deadSegments: SegmentList,
    fruit: Fruit = .{},
    game_state: GameState = .GameOver,

    pub fn alloc_and_init(allocator: Allocator) *State {
        state = allocator.create(State) catch @panic("Could not Allocate Game Data");
        state.* = .{
            .allocator = allocator,
            .random = prng.random(),
            .segments = SegmentList.init(allocator),
            .deadSegments = SegmentList.init(allocator),
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
        prng = rand.DefaultPrng.init(self.frame);
        self.frame = 0;
        self.random = prng.random();

        self.next_tick = StepStride;
        self.segments.clearAndFree();
        state.maybe_next_direction = .Up;

        const StartPosition = Vec2{ .x = (WorldWidth / 2) - 1, .y = (WorldHeight / 2) };
        const starting_segment = Segment{ .direction = state.maybe_next_direction, .position = StartPosition };
        const starting_tail = Segment{ .direction = state.maybe_next_direction, .position = starting_segment.position.add(Vec2{ .x = 0, .y = 1 }) };
        self.addSegment(starting_segment);
        self.addSegment(starting_tail);
        self.game_state = .Play;
        self.nextFruit();
    }

    pub fn willCollideWithSelf(self: *State) bool {
        const snake_head = self.snakeHead();
        const next_pos = snake_head.nextPosition();
        for (self.segments.items[1..]) |segment| {
            if (segment.nextPosition().equals(next_pos)) {
                return true;
            }
        }

        return false;
    }

    pub fn nextFruit(self: *State) void {
        self.fruit.pos = Vec2{
            .x = self.random.intRangeLessThan(i32, self.x_min, self.x_max),
            .y = self.random.intRangeLessThan(i32, self.y_min + 1, self.y_max),
        };
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
            const nextPosition = segment.nextPosition();
            segments[i].position = nextPosition;
            segments[i + 1].direction = segments[i].direction;
        }
    }

    pub fn addSegment(self: *State, segment: Segment) void {
        self.segments.append(segment) catch @panic("Cannot Grow Snake");
    }

    pub fn willBeOutOfBounds(self: *const State, segment: *Segment) bool {
        const position = segment.position.add(segment.direction.to_vec2());
        if (position.y < self.y_min or position.y > self.y_max) {
            return true;
        }
        if (position.x < self.x_min or position.x > self.x_max) {
            return true;
        }
        return false;
    }
};

pub fn drawSegment(segment: *const Segment) void {
    const x = (segment.position.x * SnakeSize);
    const y = (segment.position.y * SnakeSize);
    w4.DRAW_COLORS.* = 2;
    w4.rect(x, y, SnakeSize, SnakeSize);
}

pub fn drawSegmentSmall(segment: *const Segment) void {
    const dir = segment.direction.to_vec2();
    var x = (segment.position.x * SnakeSize);
    var y = (segment.position.y * SnakeSize);

    if (dir.x == 0) {
        x += SnakeSizeHalf / 2;
    }

    if (dir.y > 0) {
        y += SnakeSizeHalf;
    }

    if (dir.x > 0) {
        x += SnakeSizeHalf;
    }

    if (dir.y == 0) {
        y += SnakeSizeHalf / 2;
    }

    w4.DRAW_COLORS.* = 2;
    w4.rect(x, y, SnakeSizeHalf, SnakeSizeHalf);
}

pub fn drawFruit(fruit: *const Fruit) void {
    if (fruit.pos) |pos| {
        const x = (pos.x * SnakeSize);
        const y = (pos.y * SnakeSize);
        w4.DRAW_COLORS.* = 3;
        w4.rect(x + SnakeSizeHalf / 2, y + SnakeSizeHalf / 2, SnakeSizeHalf, SnakeSizeHalf);
    }
}

pub fn drawState(st: *const State) void {
    var i: usize = 1;
    const segments = st.segments.items;
    drawSegment(&segments[0]);
    while (i < segments.len) : (i += 1) {
        if (i == segments.len - 1) {
            drawSegmentSmall(&segments[i]);
        } else {
            drawSegment(&segments[i]);
        }
    }
    drawFruit(&st.fruit);
}

var state: *State = undefined;
fn mainMenu() void {
    w4.text("WELCOME!", 48, w4.CANVAS_SIZE / 2);
    if (state.input.down(Input.ButtonB)) {
        w4.DRAW_COLORS.* = 0x02;
    } else {
        w4.DRAW_COLORS.* = 0x04;
    }
    w4.text("Press Z to Start", 16, w4.CANVAS_SIZE / 2 + 14);
    if (state.input.just_released(Input.ButtonB)) {
        state.reset();
    }
}

fn play() void {
    var snake_head = state.snakeHead();
    if (state.input.just_pressed(Input.Left)) {
        if (snake_head.direction.opposite() != .Left) {
            state.maybe_next_direction = .Left;
        }
    }
    if (state.input.just_pressed(Input.Right)) {
        if (snake_head.direction.opposite() != .Right) {
            state.maybe_next_direction = .Right;
        }
    }
    if (state.input.just_pressed(Input.Up)) {
        if (snake_head.direction.opposite() != .Up) {
            state.maybe_next_direction = .Up;
        }
    }
    if (state.input.just_pressed(Input.Down)) {
        if (snake_head.direction.opposite() != .Down) {
            state.maybe_next_direction = .Down;
        }
    }

    if (state.should_tick()) {
        snake_head.direction = state.maybe_next_direction;
        if (state.willBeOutOfBounds(snake_head) or state.willCollideWithSelf()) {
            state.game_state = .GameOver;
        } else if (state.fruit.missing()) {
            var segments = state.segments.items;
            const last_segment = segments[segments.len - 1];
            state.updateSegments();
            state.addSegment(last_segment);
            w4.tone(180, 4, 50, w4.TONE_MODE1);
            state.nextFruit();
        } else {
            state.updateSegments();
            w4.tone(90, 3, 10, w4.TONE_MODE1);
        }

        state.maybEat();
    }
    drawState(state);
}

fn gameOver() void {
    w4.DRAW_COLORS.* = 0x04;
    w4.text("GAME OVER", 42, w4.CANVAS_SIZE - 15);
    if (state.input.down(Input.ButtonB)) {
        w4.DRAW_COLORS.* = 0x02;
    } else {
        w4.DRAW_COLORS.* = 0x04;
    }

    w4.text("Press Z to Restart", 8, w4.CANVAS_SIZE - 30);
    if (state.input.just_released(Input.ButtonB)) {
        state.reset();
    }
}

export fn start() void {
    state = State.alloc_and_init(fixedAlloator);
    state.reset();
    state.game_state = .Menu;
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

    state.frame += 1;
    state.input.swap();
}
