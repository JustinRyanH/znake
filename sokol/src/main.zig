const std = @import("std");

const sg = @import("sokol").gfx;
const sapp = @import("sokol").app;
const sgapp = @import("sokol").app_gfx_glue;
const shd = @import("shaders/tex.glsl.zig");

const Game = @import("game.zig");

var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
var prng = std.rand.DefaultPrng.init(0);

const gpa = general_purpose_allocator.allocator();
const global_random = prng.random();

const GameInput = Game.Input;

pub const Color = sg.Color;

const Pixel = packed struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    pub fn from_sokol_color(color: sg.Color) Pixel {
        return Pixel{
            .r = @floatToInt(u8, color.r * 255.0),
            .g = @floatToInt(u8, color.g * 255.0),
            .b = @floatToInt(u8, color.b * 255.0),
            .a = @floatToInt(u8, color.a * 255.0),
        };
    }
};

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
            .width = @intCast(i32, self.width),
            .height = @intCast(i32, self.height),
            .pixel_format = .RGBA8,
        };
        img_desc.data.subimage[0][0] = sg.asRange(self.frame_buffer);

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
        // var img_data: sg.ImageData = .{};
        // img_data.subimage[0][0] = sg.asRange(self.frame_buffer);
        // sg.updateImage(self.bind.fs_images[shd.SLOT_tex], img_data);
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
        self.setPallete(0);
        while (x < self.width) : (x += 1) {
            var y: usize = 0;
            while (y < self.height) : (y += 1) {
                self.setPixel(x, y);
            }
        }
    }

    pub fn setPallete(self: *Renderer, color: u2) void {
        self.pallete = ColorPallete[color];
    }

    pub fn drawRect(self: *Renderer, x: u8, y: u8, width: u16, height: u16) void {
        const realX = std.math.clamp(x, 0, self.width);
        const realY = std.math.clamp(y, 0, self.height);
        const x2 = std.math.clamp(x + width, 0, self.width);
        const y2 = std.math.clamp(y + height, 0, self.height);

        var i = realX;
        while (i < x2) : (i += 1) {
            var j = realY;
            while (j < y2) : (j += 1) {
                self.setPixel(i, j);
            }
        }
    }

    fn setPixel(self: *Renderer, x: usize, y: usize) void {
        self.frame_buffer[self.width * y + x] = Pixel.from_sokol_color(self.pallete);
    }
};

var renderer: *Renderer = undefined;
var game: *Game.State = undefined;
var input: GameInput = .{};

export fn init() void {
    sg.setup(.{
        .context = sgapp.context(),
    });

    renderer = Renderer.init(gpa, 160) catch @panic("Failed to Create Renderer");

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
    renderer.setPallete(3);
    renderer.drawRect(0, 0, 40, 40);
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
