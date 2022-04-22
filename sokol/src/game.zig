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

pub const Segment = struct {
    const SegmentType = enum {
        Head,
        Body,
        Tail,
    };

    previous_entity: ?ecs.Entity = null,
    next_entity: ?ecs.Entity = null,
    direction: Direction,
    segment_type: SegmentType,

    pub fn nextPosition(self: *const Segment, position: Vec2) Vec2 {
        return position.add(self.direction.to_vec2());
    }

    pub fn go(self: *Segment, direction: Direction) void {
        if (self.direction == direction.opposite()) {
            return;
        }
        self.direction = direction;
    }
};

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
                var snake_head_segment = self.snakeHeadSegment();
                if (self.input.justPressed(Input.Left)) {
                    if (snake_head_segment.direction.opposite() != .Left) {
                        self.maybe_next_direction = .Left;
                    }
                }
                if (self.input.justPressed(Input.Right)) {
                    if (snake_head_segment.direction.opposite() != .Right) {
                        self.maybe_next_direction = .Right;
                    }
                }
                if (self.input.justPressed(Input.Up)) {
                    if (snake_head_segment.direction.opposite() != .Up) {
                        self.maybe_next_direction = .Up;
                    }
                }
                if (self.input.justPressed(Input.Down)) {
                    if (snake_head_segment.direction.opposite() != .Down) {
                        self.maybe_next_direction = .Down;
                    }
                }
                if (self.shouldTick()) {
                    self.events.ticked();
                    {
                        var view = self.registery.view(.{Segment}, .{});
                        var head = view.get(self.snake_head.?);
                        head.*.direction = self.maybe_next_direction;
                    }
                    if (self.willBeOutOfBounds() or self.willCollideWithSelf()) {
                        self.events.died();
                        self.game_state = .GameOver;
                    } else if (self.fruit.missing()) {
                        {
                            var tail = self.snake_tail.?;
                            var view = self.registery.view(.{ Segment, PositionComponent }, .{});
                            var tail_segment = view.get(Segment, tail).*;
                            var tail_pos = view.get(PositionComponent, tail).*;
                            self.updateSegments();
                            var tail_entity = self.addTail(self.snake_tail.?, tail_segment.direction, tail_pos);
                            self.snake_tail = tail_entity;
                        }
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
            var view = self.registery.view(.{ Segment, PositionComponent }, .{});
            var iter = view.iterator();
            while (iter.next()) |entity| {
                self.registery.destroy(entity);
            }
            self.snake_head = null;
            self.snake_tail = null;
        }

        self.maybe_next_direction = .Up;

        const x = (self.x_max - self.x_min) / 2 - 1;
        const y = (self.y_max - self.y_min) / 2 - 1;
        const StartPosition = Vec2{ .x = x, .y = y };
        const head_direction = self.maybe_next_direction;
        const head_position = StartPosition;
        const tail_direction = self.maybe_next_direction;
        const tail_position = head_position.add(Vec2{ .x = 0, .y = 1 });
        var head_entity = self.addHead(head_direction, head_position);
        var tail_entity = self.addTail(head_entity, tail_direction, tail_position);
        self.snake_head = head_entity;
        self.snake_tail = tail_entity;
        self.game_state = .Play;
        self.nextFruit();
    }

    pub fn clearEvents(self: *State) void {
        self.events.clear();
    }

    pub fn willCollideWithSelf(self: *State) bool {
        var head = self.snake_head.?;
        var view = self.registery.view(.{ Segment, PositionComponent }, .{});
        var head_segment = view.get(Segment, head);
        var head_pos = view.get(PositionComponent, head);
        var next_pos = head_segment.nextPosition(head_pos.*);

        var iter = view.iterator();
        while (iter.next()) |entity| {
            if (head == entity) continue;
            var body_segment = view.get(Segment, entity);
            var body_pos = view.get(PositionComponent, entity);
            var body_next_pos = body_segment.nextPosition(body_pos.*);
            if (body_next_pos.equals(next_pos)) {
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

    pub fn snakeHeadPosition(self: *State) *PositionComponent {
        var head = self.snake_head.?;
        var view = self.registery.view(.{PositionComponent}, .{});
        return view.get(head);
    }

    pub fn snakeHeadSegment(self: *State) *Segment {
        var head = self.snake_head.?;
        var view = self.registery.view(.{Segment}, .{});
        return view.get(head);
    }

    pub fn maybEat(self: *State) void {
        var snake_head_position = self.snakeHeadPosition();
        if (!self.fruit.overlaps(snake_head_position.*)) {
            return;
        }
        self.events.eatFruit();
        self.fruit.pos = null;
    }

    pub fn updateSegments(self: *State) void {
        var view = self.registery.view(.{ Segment, PositionComponent }, .{});
        var iter = view.iterator();
        while (iter.next()) |entity| {
            var pos = view.get(PositionComponent, entity);
            var segment = view.get(Segment, entity);
            pos.* = segment.nextPosition(pos.*);
            if (segment.previous_entity) |entt| {
                var previous_segment = view.get(Segment, entt);
                segment.*.direction = previous_segment.direction;
            }
        }
    }

    pub fn addHead(self: *State, direction: Direction, pos: PositionComponent) ecs.Entity {
        var entity = self.registery.create();
        const segment_v2 = Segment{ .direction = direction, .segment_type = .Head };
        self.registery.add(entity, segment_v2);
        self.registery.add(entity, pos);
        return entity;
    }

    pub fn addTail(self: *State, last: ecs.Entity, direction: Direction, pos: PositionComponent) ecs.Entity {
        var entity = self.registery.create();
        const segment_v2 = Segment{ .direction = direction, .previous_entity = last, .segment_type = .Tail };
        self.registery.add(entity, segment_v2);
        self.registery.add(entity, pos);
        {
            var view = self.registery.view(.{Segment}, .{});
            var segment = view.get(last);
            segment.*.next_entity = entity;
            if (segment.*.segment_type == .Tail) {
                segment.*.segment_type = .Body;
            }
        }
        return entity;
    }

    pub fn willBeOutOfBounds(self: *State) bool {
        var head = self.snake_head.?;
        var view = self.registery.view(.{ Segment, PositionComponent }, .{});
        var ecs_segment = view.get(Segment, head);
        var current_position = view.get(PositionComponent, head);

        const position = current_position.add(ecs_segment.direction.to_vec2());
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
        var view = self.registery.view(.{ Segment, PositionComponent }, .{});
        var iter = view.iterator();
        while (iter.next()) |entity| {
            var pos = view.get(PositionComponent, entity);
            const segment = view.get(Segment, entity);

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
