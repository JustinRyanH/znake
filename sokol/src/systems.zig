const std = @import("std");
const Types = @import("./types.zig");
const Input = @import("./input.zig");
const ecs = @import("ecs");

pub const CANVAS_SIZE = 160;
pub const SNAKE_SIZE = 8;

const SNAKE_HALF_SIZE = SNAKE_SIZE / 2;

const PositionComponent = Vec2;

pub const Bounds = Types.Bounds;
pub const Direction = Types.Direction;
pub const FrameInput = Types.FrameInput;
pub const FruitTag = Types.FruitTag;
pub const GameEvents = Types.GameEvents;
pub const GameState = Types.GameState;
pub const HeadDirection = Types.HeadDirection;
pub const RandomGenerators = Types.RandomGenerators;
pub const SegmentComponent = Types.SegmentComponent;
pub const SnakeEdges = Types.SnakeEdges;
pub const SnakeGame = Types.SnakeGame;
pub const Sprite = Types.Sprite;
pub const Vec2 = Types.Vec2;

fn willCollideWithSelf(registery: *ecs.Registry) bool {
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

fn willBeOutOfBounds(registery: *ecs.Registry) bool {
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

pub fn willCollide(registery: *ecs.Registry) bool {
    return willBeOutOfBounds(registery) or willCollideWithSelf(registery);
}

pub fn updateSegmentPositionSystem(registery: *ecs.Registry) void {
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

pub fn appendTail(registery: *ecs.Registry, parent: ecs.Entity) ecs.Entity {
    var view = registery.view(.{ SegmentComponent, PositionComponent, Sprite }, .{});
    var parent_segment = view.get(SegmentComponent, parent);
    var parent_sprite = view.get(Sprite, parent);
    if (parent_segment.segment_type != .Head) {
        parent_segment.segment_type = .Body;
        parent_sprite.kind = .Body;
    }

    var parent_position = view.getConst(PositionComponent, parent);
    var entity = registery.create();

    const tail_segment = SegmentComponent{ .direction = parent_segment.direction, .previous_entity = parent, .segment_type = .Tail };
    const tail_position: PositionComponent = parent_position.add(parent_segment.direction.opposite().to_vec2());
    registery.add(entity, tail_segment);
    registery.add(entity, tail_position);
    registery.add(entity, Sprite{ .kind = .Tail });
    return entity;
}

pub fn growTailSystem(registery: *ecs.Registry) void {
    if (willCollide(registery)) return;
    var events = registery.singletons().get(SnakeGame).events;
    if (!events.hasEatenFruit()) {
        return;
    }
    var edges = registery.singletons().get(SnakeEdges);
    var new_tail = appendTail(registery, edges.tail);
    edges.tail = new_tail;
}

pub fn createHead(registery: *ecs.Registry, direction: Direction, position: Vec2) ecs.Entity {
    var entity = registery.create();
    const segment = SegmentComponent{ .direction = direction, .segment_type = .Head };
    registery.add(entity, segment);
    registery.add(entity, position);
    registery.add(entity, Sprite{ .kind = .Head });
    return entity;
}

pub fn spriteDirectionSystem(registery: *ecs.Registry) void {
    var view = registery.view(.{ SegmentComponent, PositionComponent, Sprite }, .{});
    var iter = view.iterator();
    while (iter.next()) |entity| {
        const segment = view.getConst(SegmentComponent, entity);
        var sprite = view.get(Sprite, entity);
        if (segment.segment_type == .Tail) {
            const next_segment = view.getConst(SegmentComponent, segment.previous_entity.?);
            sprite.direction = next_segment.direction;
        } else {
            sprite.direction = segment.direction;
        }
    }
}

pub fn getHeadPosition(registery: *ecs.Registry) PositionComponent {
    var head = registery.singletons().getConst(SnakeEdges).head;
    var view = registery.view(.{PositionComponent}, .{});
    return view.getConst(head);
}

pub fn menuStageInputSystem(registery: *ecs.Registry) void {
    const frame_data = registery.singletons().getConst(FrameInput);
    if (!frame_data.input.justReleased(Input.ButtonB)) return;
    registery.singletons().get(SnakeGame).events.nextStage();
    registery.singletons().get(SnakeGame).events.reseed();
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

pub fn headDirectionChangeSystem(registery: *ecs.Registry) void {
    var next_direction = &registery.singletons().get(SnakeGame).head_direction;
    var head = registery.singletons().getConst(SnakeEdges).head;
    var view = registery.view(.{SegmentComponent}, .{});
    view.get(head).go(next_direction.direction);
    next_direction.swap();
}

pub fn cleanupSnakeSystem(registery: *ecs.Registry) void {
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
    registery.add(entity, Sprite{ .direction = .Up, .kind = .Fruit });
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
