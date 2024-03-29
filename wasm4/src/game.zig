const mem = @import("std").mem;
const rand = @import("std").rand;

const ArrayList = @import("std").ArrayList;

pub const GameEvent = enum {
    EatFruit,
    TickHappened,
    Died,
    NextStage,
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
    game_state: GameState = .GameOver,

    pub fn updateInput(self: *State, input: Input) void {
        self.input = input;
    }

    pub fn updateGame(self: *State) void {
        switch (self.game_state) {
            .GameOver => {
                if (self.input.just_released(Input.ButtonB)) {
                    self.events.nextStage();
                    self.reset();
                }
            },
            .Menu => {
                if (self.input.just_released(Input.ButtonB)) {
                    self.events.nextStage();
                    self.reset();
                }
            },
            .Play => {
                var snake_head = self.snakeHead();
                if (self.input.just_pressed(Input.Left)) {
                    if (snake_head.direction.opposite() != .Left) {
                        self.maybe_next_direction = .Left;
                    }
                }
                if (self.input.just_pressed(Input.Right)) {
                    if (snake_head.direction.opposite() != .Right) {
                        self.maybe_next_direction = .Right;
                    }
                }
                if (self.input.just_pressed(Input.Up)) {
                    if (snake_head.direction.opposite() != .Up) {
                        self.maybe_next_direction = .Up;
                    }
                }
                if (self.input.just_pressed(Input.Down)) {
                    if (snake_head.direction.opposite() != .Down) {
                        self.maybe_next_direction = .Down;
                    }
                }
                if (self.shouldTick()) {
                    self.events.ticked();
                    snake_head.direction = self.maybe_next_direction;
                    if (self.willBeOutOfBounds(snake_head) or self.willCollideWithSelf()) {
                        self.events.died();
                        self.game_state = .GameOver;
                    } else if (self.fruit.missing()) {
                        var segments = self.segments.items;
                        const last_segment = segments[segments.len - 1];
                        self.updateSegments();
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
        self.segments.clearAndFree();
        self.maybe_next_direction = .Up;

        const x = (self.x_max - self.x_min) / 2 - 1;
        const y = (self.y_max - self.y_min) / 2 - 1;
        const StartPosition = Vec2{ .x = x, .y = y };
        const starting_segment = Segment{ .direction = self.maybe_next_direction, .position = StartPosition };
        const starting_tail = Segment{ .direction = self.maybe_next_direction, .position = starting_segment.position.add(Vec2{ .x = 0, .y = 1 }) };
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
