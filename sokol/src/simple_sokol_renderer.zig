const std = @import("std");
const sg = @import("sokol").gfx;
const shd = @import("shaders/tex.glsl.zig");
const sapp = @import("sokol").app;

const RendererVals = @import("renderer_vals.zig");
const SimpleRenderer = @import("simple_renderer.zig");
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

pub const Color = sg.Color;

const Self = @This();

//TOOD: Make changing the Pallete possible on SimpleRenderer
const ColorPallete = [_]Color{
    .{ .r = 225.0 / 255.0, .g = 248.0 / 255.0, .b = 207.0 / 255.0, .a = 1 },
    .{ .r = 108.0 / 255.0, .g = 192.0 / 255.0, .b = 108.0 / 255.0, .a = 1 },
    .{ .r = 80.0 / 255.0, .g = 104.0 / 255.0, .b = 80.0 / 255.0, .a = 1 },
    .{ .r = 7.0 / 255.0, .g = 24.0 / 255.0, .b = 33.0 / 255.0, .a = 1 },
};

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

pub fn simpleRenderer(self: *Self) SimpleRenderer {
    return SimpleRenderer.init(self, setPixel, setBackgroundPixel, setFrontendPallete, setBackgroundPallete, getWidth, getHeight);
}

pub fn init(allocator: std.mem.Allocator, size: usize) !*Self {
    var out = try allocator.create(Self);
    errdefer allocator.destroy(out);
    var frame_buffer = try allocator.alloc(Pixel, size * size);

    out.* = Self{
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

pub fn getWidth(self: *Self) i32 {
    return @intCast(i32, self.width);
}

pub fn getHeight(self: *Self) i32 {
    return @intCast(i32, self.height);
}

fn setupGfx(self: *Self) void {
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

pub fn deinit(self: *Self) !void {
    return self.allocator.free(self.frame_buffer);
}

pub fn updateImage(self: *Self) void {
    var img_data: sg.ImageData = .{};
    img_data.subimage[0][0] = sg.asRange(self.frame_buffer);
    sg.updateImage(self.bind.fs_images[shd.SLOT_tex], img_data);
}

pub fn draw(self: *Self) void {
    sg.beginDefaultPass(self.pass_action, sapp.width(), sapp.height());
    sg.applyPipeline(self.pip);
    sg.applyBindings(self.bind);
    sg.draw(0, 6, 1);
    sg.endPass();
    sg.commit();
}

pub fn setFrontendPallete(self: *Self, color: u2) void {
    self.pallete = ColorPallete[color];
}

pub fn setBackgroundPallete(self: *Self, color: ?u2) void {
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

pub fn setBackgroundPixel(self: *Self, x: i32, y: i32) void {
    const ux = @intCast(usize, x);
    const uy = @intCast(usize, y);
    if (self.backgroundPallete) |pallete| {
        self.frame_buffer[self.width * uy + ux] = pixelFromSokolColor(pallete);
    }
}
