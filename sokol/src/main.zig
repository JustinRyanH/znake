const std = @import("std");

const sg = @import("sokol").gfx;
const sapp = @import("sokol").app;
const sgapp = @import("sokol").app_gfx_glue;

const Game = @import("game.zig");

var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
var prng = std.rand.DefaultPrng.init(0);

const gpa = general_purpose_allocator.allocator();
const global_random = prng.random();

const GameInput = Game.Input;

pub const Color = sg.Color;

const ColorPallete = [_]Color{
    .{ .r = 225.0 / 255.0, .g = 248.0 / 255.0, .b = 207.0 / 255.0, .a = 1 },
    .{ .r = 108.0 / 255.0, .g = 192.0 / 255.0, .b = 108.0 / 255.0, .a = 1 },
    .{ .r = 80.0 / 255.0, .g = 104.0 / 255.0, .b = 80.0 / 255.0, .a = 1 },
    .{ .r = 7.0 / 255.0, .g = 24.0 / 255.0, .b = 33.0 / 255.0, .a = 1 },
};

pub const Renderer = struct {
    pass_action: sg.PassAction = .{},
};

var renderer: Renderer = .{};

var game: *Game.State = undefined;
var input: GameInput = .{};

fn drawGame(gm: *Game.State, rdr: *Renderer) void {
    _ = gm;
    sg.beginDefaultPass(rdr.pass_action, sapp.width(), sapp.height());
    sg.endPass();
    sg.commit();
}

export fn init() void {
    sg.setup(.{
        .context = sgapp.context(),
    });

    var color = ColorPallete[0];
    std.debug.print("r: {}, b: {}, g: {}, a: {}", .{ color.r, color.b, color.g, color.a });
    renderer.pass_action.colors[0] = .{ .action = .CLEAR, .value = color };

    game = Game.State.allocAndInit(gpa, .{
        .y_min = 0,
        .y_max = 40,
        .x_min = 0,
        .x_max = 40,
        .step_stride = 5,
        .random = global_random,
    });
}

export fn frame() void {
    game.frame += 1;
    drawGame(game, &renderer);
    input.swap();
}

export fn sokol_input(event: ?*const sapp.Event) void {
    const ev = event.?;
    switch (ev.type) {
        .KEY_DOWN, .KEY_UP => {
            const key_down = ev.type == .KEY_DOWN;
            switch (ev.key_code) {
                .LEFT => if (key_down) input.setDown(GameInput.Left) else input.setUp(GameInput.Left),
                .RIGHT => if (key_down) input.setDown(GameInput.Right) else input.setUp(GameInput.Right),
                .UP => if (key_down) input.setDown(GameInput.Up) else input.setUp(GameInput.Up),
                .DOWN => if (key_down) input.setDown(GameInput.Down) else input.setUp(GameInput.Down),
                .Z => if (key_down) input.setDown(GameInput.ButtonA) else input.setUp(GameInput.ButtonA),
                .X => if (key_down) input.setDown(GameInput.ButtonB) else input.setUp(GameInput.ButtonB),
                else => {},
            }
        },
        else => {},
    }
}

export fn cleanup() void {
    std.debug.assert(!general_purpose_allocator.deinit());
}

pub fn main() void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .event_cb = sokol_input,
        .width = 480,
        .height = 480,
        .icon = .{
            .sokol_default = true,
        },
        .window_title = "Znake",
    });
}
