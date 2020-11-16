const std = @import("std");
const game = @import("game_types.zig");

export fn update_game(input: *game.Input, data: *game.Data) void {
    std.debug.print("Frame: {}\n", .{ input.frame });
}