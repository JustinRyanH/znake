const w4 = @import("wasm4.zig");

const WorldWidth = w4.CANVAS_SIZE;
const WorldHeight = w4.CANVAS_SIZE - TopBarSize;
const SnakeSize = 4;
const TopBarSize = 16;

pub const Vec2 = struct {
    x: i16 = 0,
    y: i16 = 0,
};

pub const Snake = struct {
    pos: Vec2 = .{
        .x = (WorldWidth / 2) - 1,
        .y = (WorldHeight / 2) + TopBarSize,
    },

    pub fn draw(self: *Snake) void {
        w4.rect(self.pos.x, self.pos.y, SnakeSize, SnakeSize);
    }
};
pub const State = struct {
    snake: Snake = .{},
};
var state: State = .{};

export fn update() void {
    w4.DRAW_COLORS.* = 0x04;
    w4.rect(0, 0, w4.CANVAS_SIZE, TopBarSize);
    w4.DRAW_COLORS.* = 2;
    w4.text("WASM4 Znake", 32, 4);

    state.snake.draw();
}
