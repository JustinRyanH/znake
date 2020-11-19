const std = @import("std");

const sg = @import("sokol").gfx;
const sapp = @import("sokol").app;
const sgapp = @import("sokol").app_gfx_glue;
const stm = @import("sokol").time;

const utils = @import("utils.zig");
const game = @import("znake_types.zig");
const SokolGame = @import("platform_code_loader.zig").SokolGame;

var exe_dir: []const u8 = undefined;
var game_code: SokolGame = undefined;

var data: game.Data = undefined;
var input = game.Input{
    .delta_time = 0.0,
};

const State = struct {
    pass_action: sg.PassAction = .{},
    pipeline: sg.Pipeline = .{},
    bindings: sg.Bindings = .{},
};
var state = State{};
var gfx_buffer: game.GfxCommandBuffer = undefined;

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

fn createGameData() !game.Data {
    const allocator = std.heap.page_allocator;
    const permament_storage_size = utils.megabytes(8);
    const transient_storage_size = utils.megabytes(128);

    var memory = try allocator.alloc(u8, permament_storage_size + transient_storage_size);

    return game.Data{
        .permanent_storage = memory[0..permament_storage_size],
        .transient_storage = memory[permament_storage_size..(transient_storage_size + permament_storage_size)],
    };
}

// Sokol Specific Code
export fn init() void {
    sg.setup(.{
        .context = sgapp.context(),
    });

    gfx_buffer = game.GfxCommandBuffer{
        .backend = sg.queryBackend(),
        .makeBuffer = sg.makeBuffer,
        .makeShader = sg.makeShader,
        .makePipeline = sg.makePipeline,
        .beginDefaultPass = sg.beginDefaultPass,
        .applyBindings = sg.applyBindings,
        .applyPipeline = sg.applyPipeline,
        .draw = sg.draw,
        .endPass = sg.endPass,
        .commit = sg.commit,
    };
}

export fn frame() void {
    input.frame += 1;

    if (game_code.hasChanged()) {
        game_code.reload() catch std.debug.print("Failed to Reload the code\n", .{});
    }

    tickTime(&input.time);
    if (game_code.update) |update_game| {
        update_game(&input, &data, &gfx_buffer);
    }
}

export fn cleanup() void {
    sg.shutdown();
}

pub fn main() anyerror!void {
    
    data = createGameData() catch |err| @panic("Failed to allocate initial memory for game");
    var buffer: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    initTime(&input.time);

    var pathBuffer = std.fs.selfExePathAlloc(&fba.allocator) catch |err| @panic("Failed to get Exe Path");
    if (std.fs.path.dirname(pathBuffer)) |path| {
        exe_dir = path[0..path.len];
    } else {
        @panic("Failed to get EXE Directory");
    }

    const source_dll = try std.fs.path.join(&fba.allocator, &[_][]const u8{ exe_dir, DLL_NAME });
    const temp_dll = try std.fs.path.join(&fba.allocator, &[_][]const u8{ exe_dir, DLL_TEMP_NAME });

    game_code = try SokolGame.load(source_dll, temp_dll);

    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .width = 640,
        .height = 640,
        .window_title = "zsnake.zig",
    });
}