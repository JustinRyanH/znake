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
    x: i16 = 0,
    y: i16 = 0,

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

    pub fn will_move(self: *Snake) bool {
        return state.frame == self.next_update_frame;
    }

    pub fn tick(self: *Snake) void {
        const d = self.dir.to_vec2();
        self.pos = self.pos.add(d);
        self.next_update_frame = state.frame + StepStride;
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
    frame: u32 = 0,
    input: Input = .{},
    snake: Snake = .{},
    game_state: GameState = .GameOver,

    pub fn reset(self: *State) void {
        self.frame = 0;
        self.snake.reset();
        self.game_state = .Play;
    }
};
var state: State = .{};

fn mainMenu() void {}

fn play() void {
    if (state.snake.will_move()) {
        state.snake.tick();
        if (state.snake.out_of_bounds()) {
            state.game_state = .GameOver;
        }

        state.snake.draw();
    }
    state.frame += 1;
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
}
