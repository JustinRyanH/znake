const std = @import("std");

const sg = @import("sokol").gfx;
const sapp = @import("sokol").app;
const sgapp = @import("sokol").app_gfx_glue;

var pass_action: sg.Action = .{};

export fn init() void {}

export fn frame() void {}

export fn cleanup() void {}

pub fn main() void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .width = 480,
        .height = 480,
        .icon = .{
            .sokol_default = true,
        },
        .window_title = "Znake",
    });
}
