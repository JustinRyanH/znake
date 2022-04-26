const std = @import("std");
const SimpleRenderer = @import("simple_renderer.zig");
const ecs = @import("ecs");
const Input = @import("./input.zig");
const mem = std.mem;
const rand = std.rand;
const ArrayList = std.ArrayList;

pub const CANVAS_SIZE = 160;
pub const SNAKE_SIZE = 8;

const SNAKE_HALF_SIZE = SNAKE_SIZE / 2;
const PositionComponent = Vec2;

pub const FrameInput = struct {
    frame: usize = 0,
    input: Input = .{},
};

pub const FruitTag = struct {};

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

pub const Bounds = struct {
    x_min: i32,
    x_max: i32,
    y_min: i32,
    y_max: i32,
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

pub const Fruit = struct {
    pos: ?Vec2 = null,

    pub fn missing(self: *const Fruit) bool {
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

pub const HeadDirection = struct {
    direction: Direction = .Up,
    current_direction: Direction = .Up,

    pub fn go(self: *HeadDirection, direction: Direction) void {
        if (self.current_direction.opposite() != direction) {
            self.direction = direction;
        }
    }

    pub fn swap(self: *HeadDirection) void {
        self.current_direction = self.direction;
    }
};
pub const RandomGenerators = struct {
    fruit_random: rand.Random,
};
pub const StateSetup = struct {
    y_min: u8,
    y_max: u8,
    x_min: u8,
    x_max: u8,
    step_stride: u32,
    random: rand.Random,
};

pub const SnakeGame = struct {
    bounds: Bounds,
    events: GameEvents,
    head_direction: HeadDirection,
    randoms: RandomGenerators,
    step_stride: u32,
    game_state: GameState = .Menu,
};

pub const State = struct {
    allocator: mem.Allocator,
    registery: ecs.Registry,

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
        var existing_input = self.registery.singletons().getOrAdd(FrameInput);
        const old_input = existing_input.*;
        existing_input.* = FrameInput{
            .frame = old_input.frame + 1,
            .input = input.*,
        };
        var events = &self.registery.singletons().get(SnakeGame).events;
        events.clear();
        self.registery.singletons().get(SnakeGame).events.clear();
        self.updateGame();
        self.render(renderer);
        input.swap();

        const snake_game = self.registery.singletons().getConst(SnakeGame);
        switch (snake_game.game_state) {
            .Menu => mainMenu(self, renderer),
            .Play => play(self, renderer),
            .GameOver => gameOver(self, renderer),
        }
    }

    pub fn updateGame(self: *State) void {
        const snake_game = self.registery.singletons().get(SnakeGame);
        switch (snake_game.game_state) {
            .GameOver, .Menu => {
                menuStageInput(&self.registery);
                if (snake_game.events.hasNextStage()) {
                    cleanupSnakeSystem(&self.registery);
                    createSnakeSystem(&self.registery);
                    fruitGenerationSystem(&self.registery);
                }
            },
            .Play => {
                inputSystem(&self.registery);
                if (self.shouldTick()) {
                    self.registery.singletons().get(SnakeGame).events.ticked();
                    headDirectionChangeSystem(&self.registery);

                    collideSystems(&self.registery);
                    if (self.registery.singletons().get(SnakeGame).events.hasDied()) {
                        self.registery.singletons().get(SnakeGame).game_state = .GameOver;
                    }

                    maybeEatFruitSystem(&self.registery);
                    growTailSystem(&self.registery);
                    updateSegmentPositionSystem(&self.registery);
                    fruitGenerationSystem(&self.registery);
                }
            },
        }
    }

    pub fn allocAndInit(allocator: mem.Allocator, config: StateSetup) *State {
        var state = allocator.create(State) catch @panic("Could not Allocate Game Data");
        const bounds: Bounds = .{
            .y_min = config.y_min,
            .y_max = config.y_max,
            .x_min = config.x_min,
            .x_max = config.x_max,
        };
        const randoms: RandomGenerators = .{
            .fruit_random = config.random,
        };
        const events = GameEvents.init(allocator);

        state.* = .{
            .registery = ecs.Registry.init(allocator),
            .allocator = allocator,
        };
        const snake_game = SnakeGame{
            .step_stride = config.step_stride,
            .bounds = bounds,
            .events = events,
            .randoms = randoms,
            .head_direction = HeadDirection{},
        };
        state.registery.singletons().add(snake_game);
        return state;
    }

    pub fn shouldTick(self: *State) bool {
        const frame_data = self.registery.singletons().getConst(FrameInput);
        const snake_game = self.registery.singletons().getConst(SnakeGame);
        return @mod(frame_data.frame, snake_game.step_stride) == 0;
    }

    pub fn snakeHeadPosition(self: *State) *PositionComponent {
        var head = self.registery.singletons().getConst(SnakeEdges).head;
        var view = self.registery.view(.{PositionComponent}, .{});
        return view.get(head);
    }

    pub fn snakeHeadSegment(self: *State) *SegmentComponent {
        var head = self.registery.singletons().getConst(SnakeEdges).head;
        var view = self.registery.view(.{SegmentComponent}, .{});
        return view.get(head);
    }

    pub fn addTail(self: *State, last: ecs.Entity, direction: Direction, pos: PositionComponent) ecs.Entity {
        var entity = self.registery.create();
        const segment_v2 = SegmentComponent{ .direction = direction, .previous_entity = last, .segment_type = .Tail };
        self.registery.add(entity, segment_v2);
        self.registery.add(entity, pos);
        {
            var view = self.registery.view(.{SegmentComponent}, .{});
            var segment = view.get(last);
            segment.*.next_entity = entity;
            if (segment.*.segment_type == .Tail) {
                segment.*.segment_type = .Body;
            }
        }
        return entity;
    }
};

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

pub fn drawState(registery: *ecs.Registry, simple_renderer: *SimpleRenderer) void {
    {
        var view = registery.view(.{ FruitTag, PositionComponent }, .{});
        var iter = view.iterator();
        while (iter.next()) |entity| {
            var pos = view.getConst(PositionComponent, entity);

            const x = (pos.x * SNAKE_SIZE);
            const y = (pos.y * SNAKE_SIZE);
            simple_renderer.setForegroundPallete(3);
            simple_renderer.drawRect(x + SNAKE_HALF_SIZE / 2, y + SNAKE_HALF_SIZE / 2, SNAKE_HALF_SIZE, SNAKE_HALF_SIZE);
        }
    }
    {
        var view = registery.view(.{ SegmentComponent, PositionComponent }, .{});
        var iter = view.iterator();
        while (iter.next()) |entity| {
            var pos = view.get(PositionComponent, entity);
            const segment = view.get(SegmentComponent, entity);

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
}

pub fn play(state: *State, simple_renderer: *SimpleRenderer) void {
    const snake_game = state.registery.singletons().get(SnakeGame);
    const tick_happened = snake_game.events.hasTicked();
    const has_eaten = snake_game.events.hasEatenFruit();

    if (tick_happened) {
        if (has_eaten) {
            // Print Sound
        } else {
            // Sound
        }
    }
    drawState(&state.registery, simple_renderer);
}

pub fn gameOver(state: *State, simple_renderer: *SimpleRenderer) void {
    const frame_data = state.registery.singletons().getConst(FrameInput);
    simple_renderer.setForegroundPallete(1);
    simple_renderer.drawText("GAME OVER", 42, CANVAS_SIZE - 15);

    if (frame_data.input.down(Input.ButtonB)) {
        simple_renderer.setForegroundPallete(2);
        simple_renderer.drawText("Press Z to Restart", 8, CANVAS_SIZE - 30);
    } else {
        simple_renderer.setForegroundPallete(3);
        simple_renderer.drawText("Press Z to Restart", 8, CANVAS_SIZE - 30);
    }
}

pub fn mainMenu(state: *State, simple_renderer: *SimpleRenderer) void {
    const frame_data = state.registery.singletons().getConst(FrameInput);
    simple_renderer.drawText("WELCOME!", 48, CANVAS_SIZE / 2);
    if (frame_data.input.down(Input.ButtonB)) {
        simple_renderer.setForegroundPallete(1);
    } else {
        simple_renderer.setForegroundPallete(2);
    }
    simple_renderer.drawText("Press Z to Start", 16, CANVAS_SIZE / 2 + 14);
}

fn updateSegmentPositionSystem(registery: *ecs.Registry) void {
    if (willCollide(registery)) return;
    var view = registery.view(.{ SegmentComponent, PositionComponent }, .{});
    var iter = view.iterator();
    while (iter.next()) |entity| {
        var pos = view.get(PositionComponent, entity);
        var segment = view.get(SegmentComponent, entity);
        pos.* = segment.nextPosition(pos.*);
        if (segment.previous_entity) |entt| {
            var previous_segment = view.get(SegmentComponent, entt);
            segment.*.direction = previous_segment.direction;
        }
    }
}

fn headDirectionChangeSystem(registery: *ecs.Registry) void {
    var next_direction = &registery.singletons().get(SnakeGame).head_direction;
    var head = registery.singletons().getConst(SnakeEdges).head;
    var view = registery.view(.{SegmentComponent}, .{});
    view.get(head).go(next_direction.direction);
    next_direction.swap();
}

fn growTailSystem(registery: *ecs.Registry) void {
    if (willCollide(registery)) return;
    var events = registery.singletons().get(SnakeGame).events;
    if (!events.hasEatenFruit()) {
        return;
    }
    var edges = registery.singletons().get(SnakeEdges);
    var new_tail = appendTail(registery, edges.tail);
    edges.tail = new_tail;
}

fn cleanupSnakeSystem(registery: *ecs.Registry) void {
    var view = registery.view(.{ SegmentComponent, PositionComponent }, .{});
    var iter = view.iterator();
    while (iter.next()) |entity| {
        registery.destroy(entity);
    }
    registery.singletons().remove(SnakeEdges);
}

pub fn fruitGenerationSystem(registery: *ecs.Registry) void {
    if (willCollide(registery)) return;
    var view = registery.view(.{ PositionComponent, FruitTag }, .{});
    if (view.registry.len(FruitTag) > 0) return;

    const snake_game = registery.singletons().getConst(SnakeGame);
    const bounds = snake_game.bounds;
    const fruit_random = snake_game.randoms.fruit_random;

    var entity = registery.create();
    const position: PositionComponent = Vec2{
        .x = fruit_random.intRangeLessThan(i32, bounds.x_min, bounds.x_max),
        .y = fruit_random.intRangeLessThan(i32, bounds.y_min + 1, bounds.y_max),
    };
    registery.add(entity, FruitTag{});
    registery.add(entity, position);
}

pub fn collideSystems(registery: *ecs.Registry) void {
    if (!willCollide(registery)) {
        return;
    }
    registery.singletons().get(SnakeGame).events.died();
}

pub fn createSnakeSystem(registery: *ecs.Registry) void {
    var snake_game = registery.singletons().get(SnakeGame);
    snake_game.head_direction.direction = .Up;
    snake_game.game_state = .Play;

    const bounds = snake_game.bounds;
    const x = @divTrunc((bounds.x_max - bounds.x_min), 2) - 1;
    const y = @divTrunc((bounds.y_max - bounds.y_min), 2) - 1;
    const head_direction = snake_game.head_direction.direction;
    const head_position = Vec2{ .x = x, .y = y };

    var head_entity = createHead(registery, head_direction, head_position);
    var tail_entity = appendTail(registery, head_entity);
    const snake_edges = registery.singletons().getOrAdd(SnakeEdges);
    snake_edges.head = head_entity;
    snake_edges.tail = tail_entity;
}

pub fn inputSystem(registery: *ecs.Registry) void {
    const frame_data = registery.singletons().getConst(FrameInput);
    var next_direction = &registery.singletons().get(SnakeGame).head_direction;
    if (frame_data.input.justPressed(Input.Left)) {
        next_direction.go(.Left);
    }
    if (frame_data.input.justPressed(Input.Right)) {
        next_direction.go(.Right);
    }
    if (frame_data.input.justPressed(Input.Up)) {
        next_direction.go(.Up);
    }
    if (frame_data.input.justPressed(Input.Down)) {
        next_direction.go(.Down);
    }
}

pub fn menuStageInput(registery: *ecs.Registry) void {
    const frame_data = registery.singletons().getConst(FrameInput);
    if (!frame_data.input.justReleased(Input.ButtonB)) return;
    registery.singletons().get(SnakeGame).events.nextStage();
    registery.singletons().get(SnakeGame).events.reseed();
}

fn createHead(registery: *ecs.Registry, direction: Direction, position: Vec2) ecs.Entity {
    var entity = registery.create();
    const segment = SegmentComponent{ .direction = direction, .segment_type = .Head };
    registery.add(entity, segment);
    registery.add(entity, position);
    return entity;
}

pub fn getHeadPosition(registery: *ecs.Registry) PositionComponent {
    var head = registery.singletons().getConst(SnakeEdges).head;
    var view = registery.view(.{PositionComponent}, .{});
    return view.getConst(head);
}

fn appendTail(registery: *ecs.Registry, parent: ecs.Entity) ecs.Entity {
    var view = registery.view(.{ SegmentComponent, PositionComponent }, .{});
    var parent_segment = view.get(SegmentComponent, parent);
    parent_segment.segment_type = .Body;
    var parent_position = view.getConst(PositionComponent, parent);
    var entity = registery.create();

    const tail_segment = SegmentComponent{ .direction = parent_segment.direction, .previous_entity = parent, .segment_type = .Tail };
    const tail_position: PositionComponent = parent_position.add(parent_segment.direction.opposite().to_vec2());
    registery.add(entity, tail_segment);
    registery.add(entity, tail_position);
    return entity;
}

pub fn maybeEatFruitSystem(registery: *ecs.Registry) void {
    var snake_head_position = getHeadPosition(registery);
    var view = registery.view(.{ PositionComponent, FruitTag }, .{});
    var iter = view.iterator();
    while (iter.next()) |entity| {
        const position = view.getConst(PositionComponent, entity);
        if (position.equals(snake_head_position)) {
            registery.removeAll(entity);
            registery.singletons().get(SnakeGame).events.eatFruit();
        }
    }
}

pub fn willCollide(registery: *ecs.Registry) bool {
    return willBeOutOfBounds(registery) or willCollideWithSelf(registery);
}

pub fn willCollideWithSelf(registery: *ecs.Registry) bool {
    var head = registery.singletons().getConst(SnakeEdges).head;
    var view = registery.view(.{ SegmentComponent, PositionComponent }, .{});
    var head_segment = view.get(SegmentComponent, head);
    var head_pos = view.get(PositionComponent, head);
    var next_pos = head_segment.nextPosition(head_pos.*);

    var iter = view.iterator();
    while (iter.next()) |entity| {
        if (head == entity) continue;
        var body_segment = view.get(SegmentComponent, entity);
        var body_pos = view.get(PositionComponent, entity);
        var body_next_pos = body_segment.nextPosition(body_pos.*);
        if (body_next_pos.equals(next_pos)) {
            return true;
        }
    }
    return false;
}

pub fn willBeOutOfBounds(registery: *ecs.Registry) bool {
    const bounds = registery.singletons().getConst(SnakeGame).bounds;
    var head = registery.singletons().getConst(SnakeEdges).head;
    var view = registery.view(.{ SegmentComponent, PositionComponent }, .{});
    var ecs_segment = view.get(SegmentComponent, head);
    var current_position = view.get(PositionComponent, head);

    const position = current_position.add(ecs_segment.direction.to_vec2());
    if (position.y < bounds.y_min or position.y > bounds.y_max) {
        return true;
    }
    if (position.x < bounds.x_min or position.x >= bounds.x_max) {
        return true;
    }
    return false;
}
