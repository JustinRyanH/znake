const std = @import("std");

const sg = @import("sokol").gfx;
const sapp = @import("sokol").app;
const sgapp = @import("sokol").app_gfx_glue;
const stm = @import("sokol").time;

const game = @import("game_types.zig");
const SokolGameCode = @import("loader.zig").SokolGameCode;

var pass_action: sg.PassAction = .{};
var exe_dir: []const u8 = undefined;
var game_code: SokolGameCode = undefined;

var data: game.Data = undefined;
var input = game.Input{
    .delta_time = 0.0,
};

const DLL_NAME = "game.dll";
const DLL_TEMP_NAME = "game_temp.dll";

fn initTime(time: *game.Time) void {
    stm.setup();
    time.init_time = stm.now();
}

fn tickTime(time: *game.Time) void {
    time.last_frame = time.current_frame;
    time.current_frame = stm.now();
}

export fn init() void {
    sg.setup(.{
        .context = sgapp.context(),
    });
    pass_action.colors[0] = .{
        .action = .CLEAR,
        .val = .{ 1.0, 1.0, 0.0, 1.0 },
    };
}

export fn frame() void {
    const g = pass_action.colors[0].val[1] + 0.0;
    input.frame += 1;

    if (game_code.hasChanged()) {
        game_code.reload() catch std.debug.print("Failed to Reload the code\n", .{});
    }

    tickTime(&input.time);
    if (game_code.update) |update_game| {
        update_game(&input, &data);
    }

    sg.beginDefaultPass(pass_action, sapp.width(), sapp.height());
    sg.endPass();
    sg.commit();
}

export fn cleanup() void {
    sg.shutdown();
}

pub fn main() anyerror!void {
    var buffer: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    var allocator = &fba.allocator;
    initTime(&input.time);

    var pathBuffer = std.fs.selfExePathAlloc(allocator) catch |err| @panic("Failed to get Exe Path");
    if (std.fs.path.dirname(pathBuffer)) |path| {
        exe_dir = path[0..path.len];
    } else {
        @panic("Failed to get EXE Directory");
    }

    const source_dll = try std.fs.path.join(allocator, &[_][]const u8{ exe_dir, DLL_NAME });
    const temp_dll = try std.fs.path.join(allocator, &[_][]const u8{ exe_dir, DLL_TEMP_NAME });

    game_code = try SokolGameCode.load(source_dll, temp_dll);

    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .width = 640,
        .height = 640,
        .window_title = "zsnake.zig",
    });
}
