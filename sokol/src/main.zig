const std = @import("std");

const sg = @import("sokol").gfx;
const sapp = @import("sokol").app;
const stime = @import("sokol").time;
const sgapp = @import("sokol").app_gfx_glue;
const shd = @import("shaders/tex.glsl.zig");

const Game = @import("game.zig");
const RendererVals = @import("renderer.zig");

var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
var prng = std.rand.DefaultPrng.init(0);

const gpa = general_purpose_allocator.allocator();
const global_random = prng.random();

const CANVAS_SIZE = 160;
const GameInput = Game.Input;

pub const Color = sg.Color;

pub const FONT = RendererVals.FONT;

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
        out.resetFrameBuffer();
        out.setupGfx();

        return out;
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

    fn renderGame(
        self: *Renderer,
        gm: *Game.State,
    ) void {
        var img_data: sg.ImageData = .{};
        img_data.subimage[0][0] = sg.asRange(self.frame_buffer);
        sg.updateImage(self.bind.fs_images[shd.SLOT_tex], img_data);
        _ = gm;
        sg.beginDefaultPass(self.pass_action, sapp.width(), sapp.height());
        sg.applyPipeline(self.pip);
        sg.applyBindings(self.bind);
        sg.draw(0, 6, 1);
        sg.endPass();
        sg.commit();
        self.resetFrameBuffer();
    }

    fn resetFrameBuffer(self: *Renderer) void {
        var x: usize = 0;
        self.setFrontendPallete(0);
        while (x < self.width) : (x += 1) {
            var y: usize = 0;
            while (y < self.height) : (y += 1) {
                self.setPixel(x, y);
            }
        }
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

    pub fn drawRect(self: *Renderer, x: i32, y: i32, width: u16, height: u16) void {
        const realX = std.math.clamp(x, 0, self.width);
        const realY = std.math.clamp(y, 0, self.height);
        const x2 = std.math.clamp(x + width, 0, self.width);
        const y2 = std.math.clamp(y + height, 0, self.height);

        var i = realX;
        while (i < x2) : (i += 1) {
            var j = realY;
            while (j < y2) : (j += 1) {
                self.setPixel(@intCast(usize, i), @intCast(usize, j));
            }
        }
    }

    pub fn drawText(self: *Renderer, text: []const u8, x: u8, y: u8) void {
        var i: u8 = x;
        for (text) |byte| {
            var source_start: usize = (byte - 32);
            source_start = source_start << 3;
            if (i > self.width) return;
            self.blitBytes(&FONT, i, y, 8, 8, source_start, 0);
            i += 8;
        }
    }

    pub fn blitBytes(self: *Renderer, source: []const u8, dst_x: u8, dst_y: u8, width: u8, height: u8, src_x: usize, src_y: usize) void {
        const min_x = std.math.clamp(dst_x, 0, self.width);
        const max_x = std.math.clamp(dst_x + width - 1, 0, self.width);
        const min_y = std.math.clamp(dst_y, 0, self.height);
        const max_y = std.math.clamp(dst_y + height - 1, 0, self.height);
        const source_start = src_y * width + src_x;
        var x: usize = min_x;
        var y: usize = min_y;

        for (source[source_start..]) |byte| {
            const commands = RendererVals.bytemaskToDraws(byte);
            for (commands) |cmd| {
                switch (cmd) {
                    .background => self.setBackgroundPixel(x, y),
                    .foreground => self.setPixel(x, y),
                }
                if (x >= max_x) {
                    y += 1;
                    x = min_x;
                } else {
                    x += 1;
                }
                if (y > max_y) {
                    return;
                }
            }
        }
    }

    pub fn setPixel(self: *Renderer, x: usize, y: usize) void {
        self.frame_buffer[self.width * y + x] = pixelFromSokolColor(self.pallete);
    }

    pub fn setBackgroundPixel(self: *Renderer, x: usize, y: usize) void {
        if (self.backgroundPallete) |pallete| {
            self.frame_buffer[self.width * y + x] = pixelFromSokolColor(pallete);
        }
    }
};

var renderer: *Renderer = undefined;
var game: *Game.State = undefined;
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

fn renderAll() void {
    renderer.setFrontendPallete(3);
    renderer.drawRect(0, 0, CANVAS_SIZE, 16);
    renderer.setFrontendPallete(0);
    renderer.drawText("WASM4 Znake", 34, 4);
}

fn mainMenu() void {
    renderer.drawText("WELCOME!", 48, CANVAS_SIZE / 2);
    if (input.down(GameInput.ButtonB)) {
        renderer.setFrontendPallete(1);
    } else {
        renderer.setFrontendPallete(2);
    }
    renderer.drawText("Press Z to Start", 16, CANVAS_SIZE / 2 + 14);
    if (game.events.hasNextStage()) {
        prng.seed(game.frame);
    }
}

pub fn drawSegment(segment: *const Game.Segment) void {
    const x = (segment.position.x * SnakeSize);
    const y = (segment.position.y * SnakeSize);
    renderer.setFrontendPallete(1);
    renderer.drawRect(x, y, SnakeSize, SnakeSize);
}

pub fn drawSegmentSmall(segment: *const Game.Segment) void {
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

    renderer.setFrontendPallete(1);
    renderer.drawRect(x, y, SnakeSizeHalf, SnakeSizeHalf);
}

pub fn drawFruit(fruit: *const Game.Fruit) void {
    if (fruit.pos) |pos| {
        const x = (pos.x * SnakeSize);
        const y = (pos.y * SnakeSize);
        renderer.setFrontendPallete(3);
        renderer.drawRect(x + SnakeSizeHalf / 2, y + SnakeSizeHalf / 2, SnakeSizeHalf, SnakeSizeHalf);
    }
}

pub fn drawState(st: *const Game.State) void {
    var i: usize = 1;
    const segments = st.segments.items;
    drawSegment(&segments[0]);
    while (i < segments.len) : (i += 1) {
        if (i == segments.len - 1) {
            drawSegmentSmall(&segments[i]);
        } else {
            drawSegment(&segments[i]);
        }
    }
    drawFruit(&st.fruit);
}

fn play() void {
    const tick_happened = game.events.hasTicked();
    const has_eaten = game.events.hasEatenFruit();

    if (tick_happened) {
        if (has_eaten) {
            // Print Sound
        } else {
            // Sound
        }
    }
    drawState(game);
}

fn gameOver() void {
    renderer.setFrontendPallete(1);
    renderer.drawText("GAME OVER", 42, CANVAS_SIZE - 15);

    if (game.input.down(GameInput.ButtonB)) {
        renderer.setFrontendPallete(2);
        renderer.drawText("Press Z to Restart", 8, CANVAS_SIZE - 30);
    } else {
        renderer.setFrontendPallete(3);
        renderer.drawText("Press Z to Restart", 8, CANVAS_SIZE - 30);
    }
    if (game.events.hasNextStage()) {
        prng.seed(game.frame);
    }
}

export fn frame() void {
    const time = stime.now();
    game.update(input, stime.sec(time));
    renderAll();

    // game.updateGame();
    // switch (game.game_state) {
    //     .Menu => mainMenu(),
    //     .Play => play(),
    //     .GameOver => gameOver(),
    // }
    renderer.renderGame(game);
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
