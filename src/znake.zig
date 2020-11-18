const std = @import("std");
const game = @import("znake_types.zig");
const Time = game.Time;


const GameState = struct {
    x: f32 = 0,
    y: f32 = 0,
    const Self = @This();
    pub fn get(data: *game.Data) *Self {
        var state = &std.mem.bytesAsSlice(Self, @alignCast(@alignOf(Self), data.permanent_storage[0..@sizeOf(Self)]))[0];
        if (!data.initialized) {
            state.* = std.mem.zeroes(Self);
            data.initialized = true;
        }

        return state;
    }
};

export fn update_game(input: *game.Input, data: *game.Data) void {
    var game_state = GameState.get(data);

    if (@mod(input.frame, 10) == 0) {
        std.debug.print("Head Positon:\n\tx: {}\n\ty: {}\n", .{game_state.x, game_state.y});
    }
}
