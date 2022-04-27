const std = @import("std");
const Types = @import("./types.zig");
const ecs = @import("ecs");

pub const CANVAS_SIZE = 160;
pub const SNAKE_SIZE = 8;

const SNAKE_HALF_SIZE = SNAKE_SIZE / 2;

const PositionComponent = Vec2;

pub const FrameInput = Types.FrameInput;
pub const FruitTag = Types.FruitTag;
pub const GameEvents = Types.GameEvents;
pub const Vec2 = Types.Vec2;
pub const Direction = Types.Direction;
pub const Bounds = Types.Bounds;
pub const SnakeEdges = Types.SnakeEdges;
pub const SegmentComponent = Types.SegmentComponent;
pub const GameState = Types.GameState;
pub const HeadDirection = Types.HeadDirection;
pub const RandomGenerators = Types.RandomGenerators;
pub const SnakeGame = Types.SnakeGame;


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
    return entity;
}

pub fn getHeadPosition(registery: *ecs.Registry) PositionComponent {
    var head = registery.singletons().getConst(SnakeEdges).head;
    var view = registery.view(.{PositionComponent}, .{});
    return view.getConst(head);
}
