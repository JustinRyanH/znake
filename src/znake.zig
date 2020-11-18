const std = @import("std");
const game = @import("znake_types.zig");
const Time = game.Time;

export fn update_game(input: *game.Input, data: *game.Data) void {
    if (@mod(input.frame, 10) == 0) {
        std.debug.print("Frame: {}\n", .{input.frame});
        std.debug.print("Total Time: {}\n", .{Time.as_ms(input.time.since_start())});
    }
}
