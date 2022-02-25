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
    width: usize,
    height: usize,
    pallete: Color,
    allocator: std.mem.Allocator,
    frame_buffer: []f32,
    pass_action: sg.PassAction = .{},

    pub fn init(allocator: std.mem.Allocator, size: usize) !*Renderer {
        var out = try allocator.create(Renderer);
        errdefer allocator.destroy(out);
        var frame_buffer = try allocator.alloc(f32, size * size * 4);
        out.frame_buffer = frame_buffer;
        out.width = size;
        out.height = size;
        out.allocator = allocator;
        return out;
    }

    pub fn deinit(self: *Renderer) !void {
        return self.allocator.free(self.frame_buffer);
    }

    fn drawGame(
        self: *Renderer,
        gm: *Game.State,
    ) void {
        _ = gm;
        sg.beginDefaultPass(self.pass_action, sapp.width(), sapp.height());
        sg.endPass();
        sg.commit();
        self.reset_frame_buffer();
    }

    fn reset_frame_buffer(self: *Renderer) void {
        var i: usize = 0;
        while (i < self.frame_buffer.len) : (i += 1) {
            self.frame_buffer[i] = 0;
        }
    }

    pub fn set_pallete(self: *Renderer, color: u2) void {
        self.pallete = ColorPallete[color];
    }

    pub fn draw_rect(self: *Renderer, x: u8, y: u8, width: u16, height: u16) void {
        const realX = std.math.clamp(x, 0, self.width);
        const realY = std.math.clamp(y, 0, self.height);
        const x2 = std.math.clamp(x + width, 0, self.width);
        const y2 = std.math.clamp(y + height, 0, self.height);

        var i = realX;
        while (i < x2) : (i += 1) {
            var j = realY;
            while (j < y2) : (j += 1) {
                self.pixel(i, j);
            }
        }
    }

    fn pixel(self: *Renderer, x: usize, y: usize) void {
        _ = self;
        _ = x;
        _ = y;
    }
};

var renderer: *Renderer = undefined;
var game: *Game.State = undefined;
var input: GameInput = .{};

export fn init() void {
    renderer = Renderer.init(gpa, 160) catch @panic("Failed to Create Renderer");
    sg.setup(.{
        .context = sgapp.context(),
    });

    var color = ColorPallete[0];
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
    renderer.set_pallete(1);
    renderer.draw_rect(0, 0, 40, 40);
    renderer.drawGame(game);
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
    renderer.deinit() catch @panic("Failed to clean up renderer");
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
