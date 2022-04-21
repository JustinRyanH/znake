const std = @import("std");

const sg = @import("sokol").gfx;
const sapp = @import("sokol").app;
const stime = @import("sokol").time;
const sgapp = @import("sokol").app_gfx_glue;
const shd = @import("shaders/tex.glsl.zig");

const Game = @import("game.zig");
const RendererVals = @import("renderer_vals.zig");
const SimpleRender = @import("simple_renderer.zig");

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
const SnakeSize = 8;
const WorldWidth = CANVAS_SIZE / SnakeSize;
const WorldHeight = (CANVAS_SIZE - TitleBarSize) / SnakeSize;
const SnakeSizeHalf = SnakeSize / 2;
const TopBarSize = SnakeSize * TitleBarSize;
const StepStride = 10;

const SnakeYMin = TitleBarSize;
const SnakeYMax = WorldHeight;
const SnakeXMin = 0;
const SnakeXMax = WorldWidth;

const Pixel = RendererVals.Pixel;
fn pixelFromSokolColor(color: sg.Color) Pixel {
    return Pixel{
        .r = @floatToInt(u8, color.r * 255.0),
        .g = @floatToInt(u8, color.g * 255.0),
        .b = @floatToInt(u8, color.b * 255.0),
        .a = @floatToInt(u8, color.a * 255.0),
    };
}

const Vertex = packed struct { x: f32, y: f32, u: f32, v: f32 };

const ColorPallete = [_]Color{
    .{ .r = 225.0 / 255.0, .g = 248.0 / 255.0, .b = 207.0 / 255.0, .a = 1 },
    .{ .r = 108.0 / 255.0, .g = 192.0 / 255.0, .b = 108.0 / 255.0, .a = 1 },
    .{ .r = 80.0 / 255.0, .g = 104.0 / 255.0, .b = 80.0 / 255.0, .a = 1 },
    .{ .r = 7.0 / 255.0, .g = 24.0 / 255.0, .b = 33.0 / 255.0, .a = 1 },
};

pub const Renderer = struct {
    const Self = @This();

    width: usize,
    height: usize,
    pallete: Color,
    backgroundPallete: ?Color = null,
    allocator: std.mem.Allocator,
    frame_buffer: []Pixel,

    // Sokol GFX
    pass_action: sg.PassAction = .{},
    pip: sg.Pipeline = .{},
    bind: sg.Bindings = .{},

    pub fn simpleRenderer(self: *Renderer) SimpleRender {
        return SimpleRender.init(self, setPixel, setBackgroundPixel, setFrontendPallete, setBackgroundPallete, getWidth, getHeight);
    }

    pub fn init(allocator: std.mem.Allocator, size: usize) !*Renderer {
        var out = try allocator.create(Renderer);
        errdefer allocator.destroy(out);
        var frame_buffer = try allocator.alloc(Pixel, size * size);

        out.* = Renderer{
            .frame_buffer = frame_buffer,
            .width = size,
            .height = size,
            .allocator = allocator,
            .pallete = ColorPallete[0],
        };

        out.setupGfx();

        var simple_renderer = out.simpleRenderer();
        simple_renderer.reset();

        return out;
    }

    pub fn getWidth(self: *Renderer) i32 {
        return @intCast(i32, self.width);
    }

    pub fn getHeight(self: *Renderer) i32 {
        return @intCast(i32, self.height);
    }

    fn setupGfx(self: *Renderer) void {
        self.bind.vertex_buffers[0] = sg.makeBuffer(.{
            .data = sg.asRange([_]Vertex{
                .{ .x = 1.0, .y = 1.0, .u = 1.0, .v = 0.0 },
                .{ .x = 1.0, .y = -1.0, .u = 1.0, .v = 1.0 },
                .{ .x = -1.0, .y = -1.0, .u = 0.0, .v = 1.0 },
                .{ .x = -1.0, .y = 1.0, .u = 0.0, .v = 0.0 },
            }),
        });
        self.bind.index_buffer = sg.makeBuffer(.{ .type = .INDEXBUFFER, .data = sg.asRange([_]u16{ 0, 1, 3, 1, 2, 3 }) });
        var img_desc = sg.ImageDesc{
            .usage = .STREAM,
            .width = @intCast(i32, self.width),
            .height = @intCast(i32, self.height),
            .pixel_format = .RGBA8,
        };
        self.bind.fs_images[shd.SLOT_tex] = sg.makeImage(img_desc);

        var pip_desc: sg.PipelineDesc = .{
            .index_type = .UINT16,
            .shader = sg.makeShader(shd.texcubeShaderDesc(sg.queryBackend())),
        };
        pip_desc.layout.attrs[shd.ATTR_vs_pos].format = .FLOAT2;
        pip_desc.layout.attrs[shd.ATTR_vs_texcoord0].format = .FLOAT2;
        self.pip = sg.makePipeline(pip_desc);
        self.pass_action.colors[0] = .{ .action = .CLEAR, .value = ColorPallete[0] };
    }

    pub fn deinit(self: *Renderer) !void {
        return self.allocator.free(self.frame_buffer);
    }

    fn updateImage(self: *Renderer) void {
        var img_data: sg.ImageData = .{};
        img_data.subimage[0][0] = sg.asRange(self.frame_buffer);
        sg.updateImage(self.bind.fs_images[shd.SLOT_tex], img_data);
    }

    fn draw(self: *Renderer) void {
        sg.beginDefaultPass(self.pass_action, sapp.width(), sapp.height());
        sg.applyPipeline(self.pip);
        sg.applyBindings(self.bind);
        sg.draw(0, 6, 1);
        sg.endPass();
        sg.commit();
    }

    pub fn setFrontendPallete(self: *Renderer, color: u2) void {
        self.pallete = ColorPallete[color];
    }

    pub fn setBackgroundPallete(self: *Renderer, color: ?u2) void {
        if (color) |c| {
            self.backgroundPallete = ColorPallete[c];
        } else {
            self.backgroundPallete = null;
        }
    }

    pub fn setPixel(self: *Self, x: i32, y: i32) void {
        const ux = @intCast(usize, x);
        const uy = @intCast(usize, y);
        self.frame_buffer[self.width * uy + ux] = pixelFromSokolColor(self.pallete);
    }

    pub fn setBackgroundPixel(self: *Renderer, x: i32, y: i32) void {
        const ux = @intCast(usize, x);
        const uy = @intCast(usize, y);
        if (self.backgroundPallete) |pallete| {
            self.frame_buffer[self.width * uy + ux] = pixelFromSokolColor(pallete);
        }
    }
};

var renderer: *Renderer = undefined;
var game: *Game.State = undefined;
var frame_rate: FixedFrameRate = .{};
var input: GameInput = .{};

export fn init() void {
    sg.setup(.{
        .context = sgapp.context(),
    });
    stime.setup();

    renderer = Renderer.init(gpa, CANVAS_SIZE) catch @panic("Failed to Create Renderer");

    game = Game.State.allocAndInit(gpa, .{
        .y_min = SnakeYMin,
        .y_max = SnakeYMax,
        .x_min = SnakeXMin,
        .x_max = SnakeXMax,
        .step_stride = 5,
        .random = global_random,
    });
}

fn mainMenu() void {
    var simple_renderer = renderer.simpleRenderer();
    simple_renderer.drawText("WELCOME!", 48, CANVAS_SIZE / 2);
    if (input.down(GameInput.ButtonB)) {
        simple_renderer.setForegroundPallete(1);
    } else {
        simple_renderer.setForegroundPallete(2);
    }
    simple_renderer.drawText("Press Z to Start", 16, CANVAS_SIZE / 2 + 14);
    if (game.events.hasNextStage()) {
        prng.seed(game.frame);
    }
}

pub fn drawSegment(segment: *const Game.Segment, simple_renderer: *SimpleRender) void {
    const x = (segment.position.x * SnakeSize);
    const y = (segment.position.y * SnakeSize);
    simple_renderer.setForegroundPallete(1);
    simple_renderer.drawRect(x, y, SnakeSize, SnakeSize);
}

pub fn drawSegmentSmall(segment: *const Game.Segment, simple_renderer: *SimpleRender) void {
    const dir = segment.direction.to_vec2();
    var x = (segment.position.x * SnakeSize);
    var y = (segment.position.y * SnakeSize);

    if (dir.x == 0) {
        x += SnakeSizeHalf / 2;
    }

    if (dir.y > 0) {
        y += SnakeSizeHalf;
    }

    if (dir.x > 0) {
        x += SnakeSizeHalf;
    }

    if (dir.y == 0) {
        y += SnakeSizeHalf / 2;
    }

    simple_renderer.setForegroundPallete(1);
    simple_renderer.drawRect(x, y, SnakeSizeHalf, SnakeSizeHalf);
}

pub fn drawFruit(fruit: *const Game.Fruit) void {
    var simple_renderer = renderer.simpleRenderer();
    if (fruit.pos) |pos| {
        const x = (pos.x * SnakeSize);
        const y = (pos.y * SnakeSize);
        simple_renderer.setForegroundPallete(3);
        simple_renderer.drawRect(x + SnakeSizeHalf / 2, y + SnakeSizeHalf / 2, SnakeSizeHalf, SnakeSizeHalf);
    }
}

pub fn drawState(st: *const Game.State, simple_renderer: *SimpleRender) void {
    _ = simple_renderer;
    var i: usize = 1;
    const segments = st.segments.items;
    drawSegment(&segments[0], simple_renderer);
    while (i < segments.len) : (i += 1) {
        if (i == segments.len - 1) {
            drawSegmentSmall(&segments[i], simple_renderer);
        } else {
            drawSegment(&segments[i], simple_renderer);
        }
    }
    drawFruit(&st.fruit);
}

fn play(state: *Game.State, simple_renderer: *SimpleRender) void {
    const tick_happened = state.events.hasTicked();
    const has_eaten = state.events.hasEatenFruit();

    if (tick_happened) {
        if (has_eaten) {
            // Print Sound
        } else {
            // Sound
        }
    }
    drawState(state, simple_renderer);
}

fn gameOver(state: *Game.State, simple_renderer: *SimpleRender) void {
    simple_renderer.setForegroundPallete(1);
    simple_renderer.drawText("GAME OVER", 42, CANVAS_SIZE - 15);

    if (state.input.down(GameInput.ButtonB)) {
        simple_renderer.setForegroundPallete(2);
        simple_renderer.drawText("Press Z to Restart", 8, CANVAS_SIZE - 30);
    } else {
        simple_renderer.setForegroundPallete(3);
        simple_renderer.drawText("Press Z to Restart", 8, CANVAS_SIZE - 30);
    }
    if (state.events.hasNextStage()) {
        prng.seed(state.frame);
    }
}

export fn frame() void {
    const time = stime.now();
    var simple_renderer = renderer.simpleRenderer();

    const should_update = frame_rate.shouldTick(stime.sec(time));
    if (should_update) {
        game.update(&input, &simple_renderer);

        switch (game.game_state) {
            .Menu => mainMenu(),
            .Play => play(game, &simple_renderer),
            .GameOver => gameOver(game, &simple_renderer),
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
