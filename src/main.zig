const w4 = @import("wasm4.zig");

const TitleBarSize = 4;
const WorldWidth = w4.CANVAS_SIZE / SnakeSize;
const WorldHeight = (w4.CANVAS_SIZE - TitleBarSize) / SnakeSize;
const SnakeSize = 4;
const TopBarSize = SnakeSize * TitleBarSize;
const StepStride = 8;

const SnakeYMin = TitleBarSize;
const SnakeYMax = WorldHeight;
const SnakeXMin = 0;
const SnakeXMax = WorldWidth;

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

    pub fn tick(self: *Snake) void {
        if (state.frame == self.next_update_frame) {
            const d = self.dir.to_vec2();
            self.pos = self.pos.add(d);
            self.next_update_frame = state.frame + StepStride;
        }
    }

    pub fn out_of_bounds(self: *Snake) bool {
        if (self.pos.y < SnakeYMin or self.pos.y > SnakeYMax) {
            return true;
        }
        if (self.pos.x < SnakeXMin or self.pos.x > SnakeYMax) {
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

pub const GameState = enum {
    Menu,
    Play,
    GameOver,
};

pub const State = struct {
    frame: u32 = 0,
    snake: Snake = .{},
    game_state: GameState = .GameOver,
    last_input: u8 = 0,
    current_input: u8 = 0,

    pub fn button_1_just_pressed() bool {
        return false;
    }

    pub fn button_1_down() bool {
        return state.current_input & w4.BUTTON_1 != 0;
    }

    pub fn button_1_up() bool {
        return !State.button_1_down();
    }

    pub fn button_1_just_released() bool {
        return false;
    }
};
var state: State = .{};

fn mainMenu() void {}

fn play() void {
    state.snake.tick();
    if (state.snake.out_of_bounds()) {
        state.snake.reset();
    }

    state.snake.draw();
    state.frame += 1;
}
fn gameOver() void {
    w4.text("GAME OVER", 42, w4.CANVAS_SIZE / 2);
    if (State.button_1_down()) {
        w4.DRAW_COLORS.* = 0x02;
    } else {
        w4.DRAW_COLORS.* = 0x04;
    }
    w4.text("Press X to Restart", 8, w4.CANVAS_SIZE / 2 + 14);
}

export fn update() void {
    state.current_input = w4.GAMEPAD1.*;

    w4.DRAW_COLORS.* = 0x04;
    w4.rect(0, 0, w4.CANVAS_SIZE, TopBarSize);
    w4.DRAW_COLORS.* = 2;
    w4.text("WASM4 Znake", 32, 4);

    switch (state.game_state) {
        .Menu => mainMenu(),
        .Play => play(),
        .GameOver => gameOver(),
    }
    state.last_input = state.current_input;
}
