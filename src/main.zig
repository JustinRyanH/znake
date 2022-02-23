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
const mem = @import("std").mem;

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

pub const Direction = Game.Direction;
pub const Fruit = Game.Fruit;
pub const GameState = Game.GameState;
pub const Input = Game.Input;
pub const Segment = Game.Segment;
pub const SegmentList = Game.SegmentList;
pub const StateSetup = Game.StateSetup;
pub const Vec2 = Game.Vec2;

pub const State = Game.State;
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

var global_state: *State = undefined;
var global_input: Input = .{};

fn mainMenu() void {
    w4.text("WELCOME!", 48, w4.CANVAS_SIZE / 2);
    if (global_input.down(Input.ButtonB)) {
        w4.DRAW_COLORS.* = 0x02;
    } else {
        w4.DRAW_COLORS.* = 0x04;
    }
    w4.text("Press Z to Start", 16, w4.CANVAS_SIZE / 2 + 14);
    if (global_input.just_released(Input.ButtonB)) {
        prng.seed(global_state.frame);
        global_state.reset();
    }
}

fn play() void {
    var snake_head = global_state.snakeHead();
    if (global_input.just_pressed(Input.Left)) {
        if (snake_head.direction.opposite() != .Left) {
            global_state.maybe_next_direction = .Left;
        }
    }
    if (global_input.just_pressed(Input.Right)) {
        if (snake_head.direction.opposite() != .Right) {
            global_state.maybe_next_direction = .Right;
        }
    }
    if (global_input.just_pressed(Input.Up)) {
        if (snake_head.direction.opposite() != .Up) {
            global_state.maybe_next_direction = .Up;
        }
    }
    if (global_input.just_pressed(Input.Down)) {
        if (snake_head.direction.opposite() != .Down) {
            global_state.maybe_next_direction = .Down;
        }
    }

    if (global_state.shouldTick()) {
        snake_head.direction = global_state.maybe_next_direction;
        if (global_state.willBeOutOfBounds(snake_head) or global_state.willCollideWithSelf()) {
            global_state.game_state = .GameOver;
        } else if (global_state.fruit.missing()) {
            var segments = global_state.segments.items;
            const last_segment = segments[segments.len - 1];
            global_state.updateSegments();
            global_state.addSegment(last_segment);
            w4.tone(180, 4, 50, w4.TONE_MODE1);
            global_state.nextFruit();
        } else {
            global_state.updateSegments();
            w4.tone(90, 3, 10, w4.TONE_MODE1);
        }

        global_state.maybEat();
    }
    drawState(global_state);
}

fn gameOver() void {
    w4.DRAW_COLORS.* = 0x04;
    w4.text("GAME OVER", 42, w4.CANVAS_SIZE - 15);

    if (global_state.input.down(Input.ButtonB)) {
        w4.DRAW_COLORS.* = 0x02;
        w4.text("Press Z to Restart", 8, w4.CANVAS_SIZE - 30);
    } else {
        w4.DRAW_COLORS.* = 0x04;
        w4.text("Press Z to Restart", 8, w4.CANVAS_SIZE - 30);
    }

    if (global_state.input.just_released(Input.ButtonB)) {
        prng.seed(global_state.frame);
        global_state.reset();
    }
}

export fn start() void {
    global_state = State.allocAndInit(fixedAlloator, .{
        .y_min = SnakeYMin,
        .y_max = SnakeYMax,
        .x_min = SnakeXMin,
        .x_max = SnakeXMax,
        .step_stride = StepStride,
        .random = prng.random(),
    });
    global_state.reset();
    global_state.game_state = .Menu;
    global_state.nextFruit();
}

export fn update() void {
    global_input.process(w4.GAMEPAD1.*);
    global_state.updateInput(global_input);

    w4.DRAW_COLORS.* = 0x04;
    w4.rect(0, 0, w4.CANVAS_SIZE, TopBarSize);
    w4.DRAW_COLORS.* = 2;
    w4.text("WASM4 Znake", 32, 4);

    switch (global_state.game_state) {
        .Menu => mainMenu(),
        .Play => play(),
        .GameOver => gameOver(),
    }

    global_state.frame += 1;
    global_input.swap();
}
