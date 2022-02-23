const std = @import("std");

const sg = @import("sokol").gfx;
const sapp = @import("sokol").app;
const sgapp = @import("sokol").app_gfx_glue;

var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
var prng = std.rand.DefaultPrng.init(0);

const gpa = general_purpose_allocator.allocator();
const global_random = prng.random();

const Game = @import("game.zig");

var pass_action: sg.Action = .{};

var game: *Game.State = undefined;
var input: Game.Input = .{};

export fn init() void {
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
    input.frame += 1;
}

export fn sokol_input(event: ?*const sapp.Event) void {
    const ev = event.?;
    switch (ev.type) {
        .KEY_DOWN, .KEY_UP => {
            // const key_down = ev.type == .KEY_DOWN;
            switch (ev.key_code) {
                .LEFT => {},
                .RIGHT => {},
                .UP => {},
                .DOWN => {},
                .Z => {},
                .X => {},
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
