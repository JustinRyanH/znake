const mem = @import("std").mem;
const rand = @import("std").rand;

const ArrayList = @import("std").ArrayList;

pub const Vec2 = struct {
    x: i32 = 0,
    y: i32 = 0,

    pub fn add(self: Vec2, other: Vec2) Vec2 {
        return Vec2{
            .x = self.x + other.x,
            .y = self.y + other.y,
        };
    }

    pub fn sub(self: Vec2, other: Vec2) Vec2 {
        return Vec2{
            .x = self.x - other.x,
            .y = self.y - other.y,
        };
    }

    pub fn scalar(self: Vec2, by: i32) Vec2 {
        return Vec2{
            .x = self.x * by,
            .y = self.y * by,
        };
    }

    pub fn equals(self: Vec2, other: Vec2) bool {
        return self.x == other.x and self.y == other.y;
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

pub const Segment = struct {
    position: Vec2,
    direction: Direction,

    pub fn nextPosition(self: *const Segment) Vec2 {
        return self.position.add(self.direction.to_vec2());
    }

    pub fn go(self: *Segment, direction: Direction) void {
        if (self.direction == direction.opposite()) {
            return;
        }
        self.direction = direction;
    }
};
pub const SegmentList = ArrayList(Segment);

pub const Fruit = struct {
    pos: ?Vec2 = null,

    pub fn missing(self: *Fruit) bool {
        return self.pos == null;
    }

    pub fn overlaps(self: *Fruit, other: Vec2) bool {
        if (self.pos) |pos| {
            return pos.equals(other);
        }
        return false;
    }
};

pub const GameState = enum {
    Menu,
    Play,
    GameOver,
};

pub const Input = packed struct {
    pub const ButtonA = 1;
    pub const ButtonB = 2;
    pub const Left = 16;
    pub const Right = 32;
    pub const Up = 64;
    pub const Down = 128;

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

    pub fn process(self: *Input, current: u8) void {
        self.frame = current;
    }

    pub fn swap(self: *Input) void {
        self.last_frame = self.frame;
    }

    fn last_frame_down(self: *Input, button: u8) bool {
        return self.last_frame & button != 0;
    }
};
