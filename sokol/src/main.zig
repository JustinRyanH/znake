const std = @import("std");

const sg = @import("sokol").gfx;
const sapp = @import("sokol").app;
const stime = @import("sokol").time;
const sgapp = @import("sokol").app_gfx_glue;

const Game = @import("game.zig");
const RendererVals = @import("renderer_vals.zig");
const SimpleRenderer = @import("simple_renderer.zig");

var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
var prng = std.rand.DefaultPrng.init(0);

const gpa = general_purpose_allocator.allocator();
const global_random = prng.random();

const CANVAS_SIZE = Game.CANVAS_SIZE;
const GameInput = Game.Input;

pub const Color = sg.Color;

const FixedFrameRate = struct {
    const FRAMES_PER_SECOND = 30.0;
    next_update_state: f64 = 0.0,
    tick_frame: bool = false,

    pub fn shouldTick(self: *FixedFrameRate, time: f64) bool {
        if (time > self.next_update_state) {
            self.next_update_state = time + (1.0 / FRAMES_PER_SECOND);
            self.tick_frame = true;
            return true;
        } else {
            self.tick_frame = false;
            return false;
        }
    }
};

const TitleBarSize = 2;
const StepStride = 10;

const SnakeSize = Game.SNAKE_SIZE;
const WorldWidth = CANVAS_SIZE / SnakeSize;
const WorldHeight = (CANVAS_SIZE - TitleBarSize) / SnakeSize;
const SnakeSizeHalf = SnakeSize / 2;
const TopBarSize = SnakeSize * TitleBarSize;

const SnakeYMin = TitleBarSize;
const SnakeYMax = WorldHeight;
const SnakeXMin = 0;
const SnakeXMax = WorldWidth;

pub const SimpleSokolRenderer = @import("./simple_sokol_renderer.zig");

var renderer: *SimpleSokolRenderer = undefined;
var game: *Game.State = undefined;
var frame_rate: FixedFrameRate = .{};
var input: GameInput = .{};

export fn init() void {
    sg.setup(.{
        .context = sgapp.context(),
    });
    stime.setup();

    renderer = SimpleSokolRenderer.init(gpa, CANVAS_SIZE) catch @panic("Failed to Create Renderer");

    game = Game.State.allocAndInit(gpa, .{
        .y_min = SnakeYMin,
        .y_max = SnakeYMax,
        .x_min = SnakeXMin,
        .x_max = SnakeXMax,
        .step_stride = 5,
        .random = global_random,
    });
}

export fn frame() void {
    const time = stime.now();
    var simple_renderer = renderer.simpleRenderer();

    const should_update = frame_rate.shouldTick(stime.sec(time));
    if (should_update) {
        game.update(&input, &simple_renderer);
        if (game.registery.singletons().getConst(Game.SnakeGame).events.shouldReseed()) {
            prng.seed(game.registery.singletons().getConst(Game.FrameInput).frame);
        }

        renderer.updateImage();
    }
    renderer.draw();
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
                .Z => if (key_down) input.setDown(GameInput.ButtonB) else input.setUp(GameInput.ButtonB),
                .X => if (key_down) input.setDown(GameInput.ButtonA) else input.setUp(GameInput.ButtonA),
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
