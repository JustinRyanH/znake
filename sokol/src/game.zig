const std = @import("std");
const SimpleRenderer = @import("simple_renderer.zig");
const ecs = @import("ecs");
const mem = std.mem;
const rand = std.rand;
const ArrayList = std.ArrayList;

pub const CANVAS_SIZE = 160;
pub const SNAKE_SIZE = 8;

const SNAKE_HALF_SIZE = SNAKE_SIZE / 2;
const PositionComponent = Vec2;

pub const GameEvent = enum {
    EatFruit,
    TickHappened,
    Died,
    NextStage,
    ShouldReseed,
};
pub const GameEvents = struct {
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

pub const SegmentV2 = struct {
    const SegmentType = enum {
        Head,
        Body,
        Tail,
    };

    previous_entity: ?ecs.Entity = null,
    next_entity: ?ecs.Entity = null,
    direction: Direction,
    segment_type: SegmentType,

    pub fn nextPosition(self: *const SegmentV2, position: Vec2) Vec2 {
        return position.add(self.direction.to_vec2());
    }

    pub fn go(self: *SegmentV2, direction: Direction) void {
        if (self.direction == direction.opposite()) {
            return;
        }
        self.direction = direction;
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

    pub fn justReleased(self: *Input, button: u8) bool {
        const last_down = self.last_frame_down(button);
        return last_down and self.up(button);
    }

    pub fn justPressed(self: *Input, button: u8) bool {
        const last_up = !self.last_frame_down(button);
        return last_up and self.down(button);
    }

    pub fn setDown(self: *Input, button: u8) void {
        self.frame = self.frame | button;
    }
    pub fn setUp(self: *Input, button: u8) void {
        self.frame = self.frame & ~button;
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

pub const StateSetup = struct {
    y_min: u8,
    y_max: u8,
    x_min: u8,
    x_max: u8,
    step_stride: u32,
    random: rand.Random,
};

pub const State = struct {
    allocator: mem.Allocator,
    registery: ecs.Registry,
    random: rand.Random,
    y_min: u8,
    y_max: u8,
    x_min: u8,
    x_max: u8,
    step_stride: u32,

    frame: u32 = 0,
    input: Input = .{},

    maybe_next_direction: Direction = .Up,
    segments: SegmentList,
    deadSegments: SegmentList,
    events: GameEvents,
    fruit: Fruit = .{},
    game_state: GameState = .Menu,
    snake_head: ?ecs.Entity = null,
    snake_tail: ?ecs.Entity = null,

    pub fn updateInput(self: *State, input: Input) void {
        self.input = input;
    }

    fn render(self: *State, renderer: *SimpleRenderer) void {
        _ = self;
        renderer.setForegroundPallete(0);
        renderer.reset();

        renderer.setForegroundPallete(3);
        renderer.drawRect(0, 0, CANVAS_SIZE, 16);
        renderer.setBackgroundPallete(0);
        renderer.drawText("SOKOL Znake", 34, 4);
    }

    pub fn update(self: *State, input: *Input, renderer: *SimpleRenderer) void {
        self.input = input.*;
        self.frame += 1;
        self.updateGame();
        self.render(renderer);
        input.swap();

        switch (self.game_state) {
            .Menu => mainMenu(self, renderer),
            .Play => play(self, renderer),
            .GameOver => gameOver(self, renderer),
        }
    }

    pub fn updateGame(self: *State) void {
        switch (self.game_state) {
            .GameOver => {
                if (self.input.justReleased(Input.ButtonB)) {
                    self.events.nextStage();
                    self.reset();
                }
            },
            .Menu => {
                if (self.input.justReleased(Input.ButtonB)) {
                    self.events.nextStage();
                    self.reset();
                }
            },
            .Play => {
                var snake_head = self.snakeHead();
                if (self.input.justPressed(Input.Left)) {
                    if (snake_head.direction.opposite() != .Left) {
                        self.maybe_next_direction = .Left;
                    }
                }
                if (self.input.justPressed(Input.Right)) {
                    if (snake_head.direction.opposite() != .Right) {
                        self.maybe_next_direction = .Right;
                    }
                }
                if (self.input.justPressed(Input.Up)) {
                    if (snake_head.direction.opposite() != .Up) {
                        self.maybe_next_direction = .Up;
                    }
                }
                if (self.input.justPressed(Input.Down)) {
                    if (snake_head.direction.opposite() != .Down) {
                        self.maybe_next_direction = .Down;
                    }
                }
                if (self.shouldTick()) {
                    self.events.ticked();
                    snake_head.direction = self.maybe_next_direction;
                    {
                        var view = self.registery.view(.{SegmentV2}, .{});
                        var head = view.get(self.snake_head.?);
                        head.*.direction = self.maybe_next_direction;
                    }
                    if (self.willBeOutOfBounds(snake_head) or self.willCollideWithSelf()) {
                        self.events.died();
                        self.game_state = .GameOver;
                    } else if (self.fruit.missing()) {
                        var segments = self.segments.items;
                        const last_segment = segments[segments.len - 1];
                        self.updateSegments();
                        var tail_entity = self.addTail(self.snake_tail.?, last_segment.direction, last_segment.position);
                        self.snake_tail = tail_entity;
                        self.addSegment(last_segment);
                        self.nextFruit();
                    } else {
                        self.updateSegments();
                    }

                    self.maybEat();
                }
            },
        }
    }

    pub fn allocAndInit(allocator: mem.Allocator, config: StateSetup) *State {
        var state = allocator.create(State) catch @panic("Could not Allocate Game Data");
        state.* = .{
            .registery = ecs.Registry.init(allocator),
            .y_min = config.y_min,
            .y_max = config.y_max,
            .x_min = config.x_min,
            .x_max = config.x_max,
            .step_stride = config.step_stride,
            .allocator = allocator,
            .random = config.random,
            .segments = SegmentList.init(allocator),
            .deadSegments = SegmentList.init(allocator),
            .events = GameEvents.init(allocator),
        };
        return state;
    }

    pub fn shouldTick(self: *State) bool {
        return @mod(self.frame, self.step_stride) == 0;
    }

    pub fn reset(self: *State) void {
        self.frame = 0;
        {
            var view = self.registery.view(.{ SegmentV2, PositionComponent }, .{});
            var iter = view.iterator();
            while (iter.next()) |entity| {
                self.registery.destroy(entity);
            }
            self.snake_head = null;
            self.snake_tail = null;
        }

        self.segments.clearAndFree();
        self.maybe_next_direction = .Up;

        const x = (self.x_max - self.x_min) / 2 - 1;
        const y = (self.y_max - self.y_min) / 2 - 1;
        const StartPosition = Vec2{ .x = x, .y = y };
        const starting_segment = Segment{ .direction = self.maybe_next_direction, .position = StartPosition };
        const starting_tail = Segment{ .direction = self.maybe_next_direction, .position = starting_segment.position.add(Vec2{ .x = 0, .y = 1 }) };
        var head_entity = self.addHead(starting_segment.direction, starting_segment.position);
        var tail_entity = self.addTail(head_entity, starting_tail.direction, starting_tail.position);
        self.snake_head = head_entity;
        self.snake_tail = tail_entity;
        self.addSegment(starting_segment);
        self.addSegment(starting_tail);
        self.game_state = .Play;
        self.nextFruit();
    }

    pub fn clearEvents(self: *State) void {
        self.events.clear();
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
        self.events.eatFruit();
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
            if (i + 1 < segments.len) {
                segments[i + 1].direction = segments[i].direction;
            }
        }
        {
            var view = self.registery.view(.{ SegmentV2, PositionComponent }, .{});
            var iter = view.iterator();
            while (iter.next()) |entity| {
                var pos = view.get(PositionComponent, entity);
                var segment = view.get(SegmentV2, entity);
                pos.* = segment.nextPosition(pos.*);
                if (segment.previous_entity) |entt| {
                    var previous_segment = view.get(SegmentV2, entt);
                    segment.*.direction = previous_segment.direction;
                }
            }
        }
    }

    pub fn addHead(self: *State, direction: Direction, pos: PositionComponent) ecs.Entity {
        var entity = self.registery.create();
        const segment_v2 = SegmentV2{ .direction = direction, .segment_type = .Head };
        self.registery.add(entity, segment_v2);
        self.registery.add(entity, pos);
        return entity;
    }

    pub fn addTail(self: *State, last: ecs.Entity, direction: Direction, pos: PositionComponent) ecs.Entity {
        var entity = self.registery.create();
        const segment_v2 = SegmentV2{ .direction = direction, .previous_entity = last, .segment_type = .Tail };
        self.registery.add(entity, segment_v2);
        self.registery.add(entity, pos);
        {
            var view = self.registery.view(.{SegmentV2}, .{});
            var segment = view.get(last);
            segment.*.next_entity = entity;
            if (segment.*.segment_type == .Tail) {
                segment.*.segment_type = .Body;
            }
        }
        return entity;
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

test "Input" {
    var input: Input = .{};
    try std.testing.expect(input.frame == 0);
    input.setDown(Input.Left);
    input.setDown(Input.ButtonA);
    input.setDown(Input.ButtonB);
    try std.testing.expect(input.down(Input.Left) == true);
    try std.testing.expect(input.down(Input.ButtonA) == true);
    try std.testing.expect(input.justPressed(Input.Left));

    input.setUp(Input.ButtonA);
    try std.testing.expect(input.up(Input.ButtonA) == true);
    try std.testing.expect(input.down(Input.Left) == true);

    input.swap();
    input.setUp(Input.Left);
    try std.testing.expect(input.justReleased(Input.Left) == true);
    try std.testing.expect(input.up(Input.Left) == true);
}

pub fn drawSegment(segment: *const Segment, simple_renderer: *SimpleRenderer) void {
    const x = (segment.position.x * SNAKE_SIZE);
    const y = (segment.position.y * SNAKE_SIZE);
    simple_renderer.setForegroundPallete(1);
    simple_renderer.drawRect(x, y, SNAKE_SIZE, SNAKE_SIZE);
}

pub fn drawSegmentSmall(segment: *const Segment, simple_renderer: *SimpleRenderer) void {
    const dir = segment.direction.to_vec2();
    var x = (segment.position.x * SNAKE_SIZE);
    var y = (segment.position.y * SNAKE_SIZE);

    if (dir.x == 0) {
        x += SNAKE_HALF_SIZE / 2;
    }

    if (dir.y > 0) {
        y += SNAKE_HALF_SIZE;
    }

    if (dir.x > 0) {
        x += SNAKE_HALF_SIZE;
    }

    if (dir.y == 0) {
        y += SNAKE_HALF_SIZE / 2;
    }

    simple_renderer.setForegroundPallete(1);
    simple_renderer.drawRect(x, y, SNAKE_HALF_SIZE, SNAKE_HALF_SIZE);
}

pub fn drawSegmentSmallV2(direction: *const Direction, position: *PositionComponent, simple_renderer: *SimpleRenderer) void {
    const dir = direction.to_vec2();
    var x = (position.x * SNAKE_SIZE);
    var y = (position.y * SNAKE_SIZE);

    if (dir.x == 0) {
        x += SNAKE_HALF_SIZE / 2;
    }

    if (dir.y > 0) {
        y += SNAKE_HALF_SIZE;
    }

    if (dir.x > 0) {
        x += SNAKE_HALF_SIZE;
    }

    if (dir.y == 0) {
        y += SNAKE_HALF_SIZE / 2;
    }

    simple_renderer.setForegroundPallete(1);
    simple_renderer.drawRect(x, y, SNAKE_HALF_SIZE, SNAKE_HALF_SIZE);
}

pub fn drawFruit(
    fruit: *const Fruit,
    simple_renderer: *SimpleRenderer,
) void {
    if (fruit.pos) |pos| {
        const x = (pos.x * SNAKE_SIZE);
        const y = (pos.y * SNAKE_SIZE);
        simple_renderer.setForegroundPallete(3);
        simple_renderer.drawRect(x + SNAKE_HALF_SIZE / 2, y + SNAKE_HALF_SIZE / 2, SNAKE_HALF_SIZE, SNAKE_HALF_SIZE);
    }
}

pub fn drawState(self: *State, simple_renderer: *SimpleRenderer) void {
    {
        var view = self.registery.view(.{ SegmentV2, PositionComponent }, .{});
        var iter = view.iterator();
        while (iter.next()) |entity| {
            var pos = view.get(PositionComponent, entity);
            const segment = view.get(SegmentV2, entity);

            switch (segment.segment_type) {
                .Tail => drawSegmentSmallV2(&segment.direction, pos, simple_renderer),
                else => {
                    const x = (pos.x * SNAKE_SIZE);
                    const y = (pos.y * SNAKE_SIZE);

                    simple_renderer.setForegroundPallete(1);
                    simple_renderer.drawRect(x, y, SNAKE_SIZE, SNAKE_SIZE);
                },
            }
        }
    }

    drawFruit(&self.fruit, simple_renderer);
}

pub fn play(state: *State, simple_renderer: *SimpleRenderer) void {
    const tick_happened = state.events.hasTicked();
    const has_eaten = state.events.hasEatenFruit();

    if (tick_happened) {
        if (has_eaten) {
            // Print Sound
        } else {
            // Sound
        }
    }
    drawState(state, simple_renderer);
}

pub fn gameOver(state: *State, simple_renderer: *SimpleRenderer) void {
    simple_renderer.setForegroundPallete(1);
    simple_renderer.drawText("GAME OVER", 42, CANVAS_SIZE - 15);

    if (state.input.down(Input.ButtonB)) {
        simple_renderer.setForegroundPallete(2);
        simple_renderer.drawText("Press Z to Restart", 8, CANVAS_SIZE - 30);
    } else {
        simple_renderer.setForegroundPallete(3);
        simple_renderer.drawText("Press Z to Restart", 8, CANVAS_SIZE - 30);
    }
    if (state.events.hasNextStage()) {
        state.events.reseed();
    }
}

pub fn mainMenu(state: *State, simple_renderer: *SimpleRenderer) void {
    simple_renderer.drawText("WELCOME!", 48, CANVAS_SIZE / 2);
    if (state.input.down(Input.ButtonB)) {
        simple_renderer.setForegroundPallete(1);
    } else {
        simple_renderer.setForegroundPallete(2);
    }
    simple_renderer.drawText("Press Z to Start", 16, CANVAS_SIZE / 2 + 14);
    if (state.events.hasNextStage()) {
        state.events.reseed();
    }
}
