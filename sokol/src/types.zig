const std = @import("std");
const ecs = @import("ecs");
const ArrayList = std.ArrayList;
const mem = std.mem;

pub const Bounds = struct {
    x_min: i32,
    x_max: i32,
    y_min: i32,
    y_max: i32,
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

pub const GameEvents = struct {
    const GameEvent = enum {
        EatFruit,
        TickHappened,
        Died,
        NextStage,
        ShouldReseed,
    };

    inner: ArrayList(GameEvent),

    pub fn init(allocator: mem.Allocator) GameEvents {
        return .{
            .inner = ArrayList(GameEvent).init(allocator),
        };
    }

    pub fn clear(self: *GameEvents) void {
        self.inner.clearAndFree();
    }

    pub fn ticked(self: *GameEvents) void {
        self.append(.TickHappened);
    }

    pub fn died(self: *GameEvents) void {
        self.append(.Died);
    }

    pub fn eatFruit(self: *GameEvents) void {
        self.append(.EatFruit);
    }

    pub fn nextStage(self: *GameEvents) void {
        self.append(.NextStage);
    }

    pub fn reseed(self: *GameEvents) void {
        self.append(.ShouldReseed);
    }

    pub fn hasNextStage(self: *GameEvents) bool {
        for (self.inner.items) |event| {
            if (event == .NextStage) {
                return true;
            }
        }
        return false;
    }

    pub fn hasTicked(self: *GameEvents) bool {
        for (self.inner.items) |event| {
            if (event == .TickHappened) {
                return true;
            }
        }
        return false;
    }

    pub fn hasDied(self: *GameEvents) bool {
        for (self.inner.items) |event| {
            if (event == .Died) {
                return true;
            }
        }
        return false;
    }

    pub fn hasEatenFruit(self: *GameEvents) bool {
        for (self.inner.items) |event| {
            if (event == .EatFruit) {
                return true;
            }
        }
        return false;
    }

    pub fn shouldReseed(self: *GameEvents) bool {
        for (self.inner.items) |event| {
            if (event == .ShouldReseed) {
                return true;
            }
        }
        return false;
    }

    fn append(self: *GameEvents, event: GameEvent) void {
        self.inner.append(event) catch @panic("Cannot Append Event");
    }
};

pub const SnakeEdges = struct {
    tail: ecs.Entity,
    head: ecs.Entity,
};

pub const SegmentComponent = struct {
    const SegmentType = enum {
        Head,
        Body,
        Tail,
    };

    previous_entity: ?ecs.Entity = null,
    next_entity: ?ecs.Entity = null,
    direction: Direction,
    segment_type: SegmentType,

    pub fn nextPosition(self: *const SegmentComponent, position: Vec2) Vec2 {
        return position.add(self.direction.to_vec2());
    }

    pub fn go(self: *SegmentComponent, direction: Direction) void {
        if (self.direction == direction.opposite()) {
            return;
        }
        self.direction = direction;
    }
};
