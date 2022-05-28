const std = @import("std");
const builtin = @import("builtin");

const nk = @import("nuklear");
const sapp = @import("sokol").app;
const sg = @import("sokol").gfx;
const shd = @import("shaders/nk.glsl.zig");
const math = @import("./math.zig");

const Snk = @This();
const NkInputMax = 16;

pub const NkVertex = packed struct {
    position: math.Vec2,
    uv: math.Vec2,
    color: [4]u8,
};

pub const Desc = struct {
    max_vertices: usize = std.math.maxInt(u16),
    color_format: sg.PixelFormat = .DEFAULT,
    depth_format: sg.PixelFormat = .DEFAULT,
    sample_count: i32 = 0,
    dpi_scale: f32 = 1.0,
    no_default_font: bool = false,
};

desc: Desc = .{},
ctx: nk.Context = undefined,
atlas: nk.FontAtlas = undefined,
vs_params: shd.VsParams = undefined,
vertex_buffer_size: usize = 0,
index_buffer_size: usize = 0,
vbuf: sg.Buffer = undefined,
ibuf: sg.Buffer = undefined,
img: sg.Image = undefined,
shd: sg.Shader = undefined,
pip: sg.Pipeline = undefined,
is_osx: bool = false,
mouse_pos: [2]i32 = .{ 0, 0 },
mouse_scroll: [2]f32 = .{ 0, 0 },
mouse_did_move: bool = false,
mouse_did_scroll: bool = false,
btn_down: [nk.c.NK_BUTTON_MAX]bool = std.mem.zeroes([nk.c.NK_BUTTON_MAX]bool),
btn_up: [nk.c.NK_BUTTON_MAX]bool = std.mem.zeroes([nk.c.NK_BUTTON_MAX]bool),
char_buffer_end: usize = 0,
char_buffer: [nk.c.NK_INPUT_MAX]u8 = std.mem.zeroes([nk.c.NK_INPUT_MAX]u8),
keys_down: [nk.c.NK_KEY_MAX]bool = std.mem.zeroes([nk.c.NK_KEY_MAX]bool),
keys_up: [nk.c.NK_KEY_MAX]bool = std.mem.zeroes([nk.c.NK_KEY_MAX]bool),
null_texture: nk.DrawNullTexture = undefined,
nk_cmds: nk.Buffer = undefined,
nk_vbuf: nk.Buffer = undefined,
nk_ebuf: nk.Buffer = undefined,

pub fn setup(alloc: std.mem.Allocator, desc: Snk.Desc) !Snk {
    var out: Snk = .{
        .desc = desc,
        .is_osx = builtin.target.isDarwin(),
    };

    out.atlas = nk.atlas.init(&alloc);
    nk.atlas.begin(&out.atlas);
    const baked = try nk.atlas.bake(&out.atlas, .rgba32);
    var imageDesc: sg.ImageDesc = .{
        .width = @intCast(c_int, baked.w),
        .height = @intCast(c_int, baked.h),
        .pixel_format = sg.PixelFormat.RGBA8,
        .wrap_u = sg.Wrap.CLAMP_TO_EDGE,
        .wrap_v = sg.Wrap.CLAMP_TO_EDGE,
        .min_filter = sg.Filter.LINEAR,
        .mag_filter = sg.Filter.LINEAR,
        .label = "sokol-nuklear-font",
    };
    imageDesc.data.subimage[0][0] = sg.asRange(baked.data[0..(baked.w * baked.h * 4)]);
    out.img = sg.makeImage(imageDesc);
    nk.atlas.end(&out.atlas, nk.rest.nkHandleId(@intCast(c_int, out.img.id)), &out.null_texture);

    out.ctx = nk.init(&alloc, &out.atlas.default_font.*.handle);
    sg.pushDebugGroup("sokol-nuklear");
    defer sg.popDebugGroup();

    out.vertex_buffer_size = out.desc.max_vertices * @sizeOf(shd.VsParams);
    out.vbuf = sg.makeBuffer(.{
        .type = sg.BufferType.VERTEXBUFFER,
        .usage = sg.Usage.STREAM,
        .size = out.vertex_buffer_size,
        .label = "sokol-nuklear-vertices",
    });

    out.index_buffer_size = out.desc.max_vertices * 3 * @sizeOf(u16);
    out.ibuf = sg.makeBuffer(.{
        .type = sg.BufferType.INDEXBUFFER,
        .usage = sg.Usage.STREAM,
        .size = out.index_buffer_size,
        .label = "sokol-nuklear-indices",
    });

    out.shd = sg.makeShader(shd.snukShaderDesc(sg.queryBackend()));
    var pipeline_desc: sg.PipelineDesc = .{
        .index_type = sg.IndexType.UINT16,
        .shader = out.shd,
        .sample_count = out.desc.sample_count,
        .label = "sokol-nuklear-pipeline",
    };
    pipeline_desc.layout.attrs[shd.ATTR_vs_position].format = sg.VertexFormat.FLOAT2;
    pipeline_desc.layout.attrs[shd.ATTR_vs_texcoord0].format = sg.VertexFormat.FLOAT2;
    pipeline_desc.layout.attrs[shd.ATTR_vs_color0].format = sg.VertexFormat.UBYTE4N;
    pipeline_desc.depth.pixel_format = out.desc.depth_format;
    pipeline_desc.colors[0] = .{ .pixel_format = out.desc.color_format, .write_mask = sg.ColorMask.RGB, .blend = .{
        .enabled = true,
        .src_factor_rgb = sg.BlendFactor.SRC_ALPHA,
        .dst_factor_rgb = sg.BlendFactor.ONE_MINUS_SRC_ALPHA,
    } };
    out.pip = sg.makePipeline(pipeline_desc);

    out.nk_cmds = nk.Buffer.init(&alloc, std.mem.page_size);
    out.nk_ebuf = nk.Buffer.init(&alloc, std.mem.page_size);
    out.nk_vbuf = nk.Buffer.init(&alloc, std.mem.page_size);

    return out;
}

pub fn newFrame(self: *Snk) void {
    defer nk.clear(&self.ctx);
    nk.input.begin(&self.ctx);
    defer nk.input.end(&self.ctx);
    if (self.mouse_did_move) {
        nk.input.motion(&self.ctx, self.mouse_pos[0], self.mouse_pos[1]);
        self.mouse_did_move = false;
    }
    if (self.mouse_did_scroll) {
        nk.input.scroll(&self.ctx, nk.c.nk_vec2(self.mouse_scroll[0], self.mouse_scroll[1]));
        self.mouse_did_scroll = false;
    }
    const mouse_x = self.mouse_pos[0];
    const mouse_y = self.mouse_pos[1];
    {
        var i: u32 = 0;
        while (i < nk.c.NK_BUTTON_MAX) : (i += 1) {
            if (self.btn_down[i]) {
                self.btn_down[i] = false;
                nk.input.button(&self.ctx, @intToEnum(nk.input.Buttons, i), mouse_x, mouse_y, true);
            }
            if (self.btn_up[i]) {
                self.btn_up[i] = false;
                nk.input.button(&self.ctx, @intToEnum(nk.input.Buttons, i), mouse_x, mouse_y, false);
            }
        }
    }
    if (self.char_buffer_end > 0) {
        var i: usize = 0;
        while (i < self.char_buffer_end) : (i += 1) {
            nk.input.char(&self.ctx, self.char_buffer[i]);
        }
        self.char_buffer_end = 0;
        self.char_buffer = std.mem.zeroes([nk.c.NK_INPUT_MAX]u8);
    }
    {
        var i: u32 = 0;
        while (i < nk.c.NK_KEY_MAX) : (i += 1) {
            if (self.keys_down[i]) {
                self.keys_down[i] = false;
                nk.input.key(&self.ctx, @intToEnum(nk.input.Keys, i), true);
            }
            if (self.keys_up[i]) {
                self.keys_up[i] = false;
                nk.input.key(&self.ctx, @intToEnum(nk.input.Keys, i), false);
            }
        }
    }
}

pub fn render(self: *Snk, width: i32, height: i32) void {
    const nk_vertex_layout = [_]nk.DrawVertexLayoutElement{
        .{ .attribute = nk.c.NK_VERTEX_POSITION, .format = nk.c.NK_FORMAT_FLOAT, .offset = @offsetOf(NkVertex, "position") },
        .{ .attribute = nk.c.NK_VERTEX_TEXCOORD, .format = nk.c.NK_FORMAT_FLOAT, .offset = @offsetOf(NkVertex, "uv") },
        .{ .attribute = nk.c.NK_VERTEX_COLOR, .format = nk.c.NK_FORMAT_R8G8B8A8, .offset = @offsetOf(NkVertex, "color") },
        .{ .attribute = nk.c.NK_VERTEX_ATTRIBUTE_COUNT, .format = nk.c.NK_FORMAT_COUNT, .offset = 0 },
    };

    self.vs_params.disp_size.x = @intToFloat(f32, width);
    self.vs_params.disp_size.y = @intToFloat(f32, height);
    var cfg = nk.ConvertConfig{
        .shape_AA = nk.c.NK_ANTI_ALIASING_ON,
        .line_AA = nk.c.NK_ANTI_ALIASING_ON,
        .vertex_layout = &nk_vertex_layout,
        .vertex_size = @sizeOf(NkVertex),
        .vertex_alignment = @alignOf(NkVertex),
        .null_ = self.null_texture,
        .circle_segment_count = 22,
        .curve_segment_count = 22,
        .arc_segment_count = 22,
        .global_alpha = 1.0,
    };
    self.nk_cmds.clear();
    self.nk_ebuf.clear();
    self.nk_vbuf.clear();

    _ = nk.vertex.convert(&self.ctx, &self.nk_cmds, &self.nk_vbuf, &self.nk_ebuf, cfg);
    const nk_vbuf_memory = self.nk_vbuf.memory();
    const nk_ebuf_memory = self.nk_ebuf.memory();

    const vbuffer_overflow = nk_vbuf_memory.len > self.vertex_buffer_size;
    const ebuffer_overflow = nk_ebuf_memory.len > self.index_buffer_size;
    const buffer_did_not_overflow = !vbuffer_overflow and !ebuffer_overflow;
    std.debug.assert(buffer_did_not_overflow);
    if (buffer_did_not_overflow) {
        const dpi_scale = self.desc.dpi_scale;
        const fb_width = @floatToInt(i32, self.vs_params.disp_size.x * dpi_scale);
        const fb_height = @floatToInt(i32, self.vs_params.disp_size.y * dpi_scale);
        sg.applyViewport(0, 0, fb_width, fb_height, true);
        sg.applyScissorRect(0, 0, fb_width, fb_height, true);
        sg.applyPipeline(self.pip);
        sg.applyUniforms(sg.ShaderStage.VS, 0, sg.asRange(&self.vs_params));

        sg.updateBuffer(self.vbuf, sg.asRange(nk_vbuf_memory));
        sg.updateBuffer(self.ibuf, sg.asRange(nk_ebuf_memory));

        var it = nk.vertex.iterator(&self.ctx, &self.nk_cmds);
        var idx_offset: i32 = 0;
        while (it.next()) |cmd| {
            if (cmd.*.elem_count > 0) {
                var img: sg.Image = undefined;
                if (cmd.*.texture.id != 0) {
                    img.id = @intCast(u32, cmd.*.texture.id);
                } else {
                    img = self.img;
                }

                var binding: sg.Bindings = .{
                    .index_buffer = self.ibuf,
                    .index_buffer_offset = idx_offset,
                };
                binding.fs_images[0] = img;
                binding.vertex_buffers[0] = self.vbuf;
                binding.vertex_buffer_offsets[0] = 0;
                sg.applyBindings(binding);

                sg.applyScissorRectf(
                    cmd.*.clip_rect.x * dpi_scale,
                    cmd.*.clip_rect.y * dpi_scale,
                    cmd.*.clip_rect.w * dpi_scale,
                    cmd.*.clip_rect.h * dpi_scale,
                    true,
                );
                sg.draw(0, cmd.*.elem_count, 1);
                idx_offset += @intCast(i32, cmd.*.elem_count) * @sizeOf(u16);
            }
        }
        sg.applyScissorRect(0, 0, fb_width, fb_height, true);
    }
}

pub fn handleEvent(self: *Snk, event: *const sapp.Event) void {
    var dpi_scale = self.desc.dpi_scale;

    switch (event.type) {
        .MOUSE_DOWN => {
            self.mouse_pos[0] = @floatToInt(i32, event.mouse_x / dpi_scale);
            self.mouse_pos[1] = @floatToInt(i32, event.mouse_y / dpi_scale);
            switch (event.mouse_button) {
                .LEFT => self.btn_down[nk.c.NK_BUTTON_LEFT] = true,
                .RIGHT => self.btn_down[nk.c.NK_BUTTON_RIGHT] = true,
                .MIDDLE => self.btn_down[nk.c.NK_BUTTON_MIDDLE] = true,
                else => {},
            }
        },
        .MOUSE_UP => {
            self.mouse_pos[0] = @floatToInt(i32, event.mouse_x / dpi_scale);
            self.mouse_pos[1] = @floatToInt(i32, event.mouse_y / dpi_scale);
            switch (event.mouse_button) {
                .LEFT => self.btn_up[nk.c.NK_BUTTON_LEFT] = true,
                .RIGHT => self.btn_up[nk.c.NK_BUTTON_RIGHT] = true,
                .MIDDLE => self.btn_up[nk.c.NK_BUTTON_MIDDLE] = true,
                else => {},
            }
        },
        .MOUSE_MOVE => {
            self.mouse_pos[0] = @floatToInt(i32, event.mouse_x / dpi_scale);
            self.mouse_pos[1] = @floatToInt(i32, event.mouse_y / dpi_scale);
            self.mouse_did_move = true;
        },
        .MOUSE_SCROLL => {
            self.mouse_scroll[0] = event.scroll_x;
            self.mouse_scroll[1] = event.scroll_y;
            self.mouse_did_scroll = true;
        },
        .MOUSE_ENTER, .MOUSE_LEAVE => {
            var i: usize = 0;
            while (i < nk.c.NK_BUTTON_MAX) : (i += 1) {
                self.btn_down[i] = false;
                self.btn_up[i] = false;
            }
        },
        .CHAR => {
            switch (event.char_code) {
                32...127 => {
                    if (0 == (event.modifiers & (sapp.modifier_alt | sapp.modifier_ctrl | sapp.modifier_super))) {
                        if (self.char_buffer_end < self.char_buffer.len) {
                            self.char_buffer[self.char_buffer_end] = @intCast(u8, event.char_code);
                            self.char_buffer_end += 1;
                        }
                    }
                },
                else => {},
            }
        },
        .KEY_DOWN => {
            const is_ctrl = self.snkIsCtrl(event.modifiers);
            if (is_ctrl and event.key_code == .V) return;
            if (is_ctrl and event.key_code == .X) {
                sapp.consumeEvent();
            }
            if (is_ctrl and event.key_code == .C) {
                sapp.consumeEvent();
            }
            const nk_key = snkEventToNuklearKey(self, event);
            if (nk_key != nk.c.NK_KEY_NONE) {
                self.keys_down[nk_key] = true;
            }
        },
        .KEY_UP => {
            const nk_key = snkEventToNuklearKey(self, event);
            if (nk_key != nk.c.NK_KEY_NONE) {
                self.keys_up[nk_key] = true;
            }
        },
        else => {},
    }
}
// const float dpi_scale = _snuklear.desc.dpi_scale;
// switch (ev->type) {
//     case SAPP_EVENTTYPE_TOUCHES_BEGAN:
//         _snuklear.btn_down[NK_BUTTON_LEFT] = true;
//         _snuklear.mouse_pos[0] = (int) (ev->touches[0].pos_x / dpi_scale);
//         _snuklear.mouse_pos[1] = (int) (ev->touches[0].pos_y / dpi_scale);
//         _snuklear.mouse_did_move = true;
//         break;
//     case SAPP_EVENTTYPE_TOUCHES_MOVED:
//         _snuklear.mouse_pos[0] = (int) (ev->touches[0].pos_x / dpi_scale);
//         _snuklear.mouse_pos[1] = (int) (ev->touches[0].pos_y / dpi_scale);
//         _snuklear.mouse_did_move = true;
//         break;
//     case SAPP_EVENTTYPE_TOUCHES_ENDED:
//         _snuklear.btn_up[NK_BUTTON_LEFT] = true;
//         _snuklear.mouse_pos[0] = (int) (ev->touches[0].pos_x / dpi_scale);
//         _snuklear.mouse_pos[1] = (int) (ev->touches[0].pos_y / dpi_scale);
//         _snuklear.mouse_did_move = true;
//         break;
//     case SAPP_EVENTTYPE_TOUCHES_CANCELLED:
//         _snuklear.btn_up[NK_BUTTON_LEFT] = false;
//         _snuklear.btn_down[NK_BUTTON_LEFT] = false;
//         break;
//     case SAPP_EVENTTYPE_CLIPBOARD_PASTED:
//         _snuklear.keys_down[NK_KEY_PASTE] = _snuklear.keys_up[NK_KEY_PASTE] = true;
//         break;
//     default:
//         break;
// }
// }
// fn editString(self: *Snk, ctx: *nk.Context, flags: nk.Flags, memory: []u8, max: i32, filter: nk.Filter) void {
// nk_flags event = nk_edit_string(ctx, flags, memory, len, max, filter);
// if ((event & NK_EDIT_ACTIVATED) && !sapp_keyboard_shown()) {
//     sapp_show_keyboard(true);
// }
// if ((event & NK_EDIT_DEACTIVATED) && sapp_keyboard_shown()) {
//     sapp_show_keyboard(false);
// }
// return event;
// }

pub fn shutdown(self: *Snk) void {
    nk.free(&self.ctx);
    nk.atlas.cleanup(&self.atlas);
    self.nk_cmds.free();
    self.nk_ebuf.free();
    self.nk_vbuf.free();

    {
        sg.pushDebugGroup("sokol-nuklear");
        defer sg.popDebugGroup();
        sg.destroyPipeline(self.pip);
        sg.destroyShader(self.shd);
        sg.destroyImage(self.img);
        sg.destroyBuffer(self.vbuf);
        sg.destroyBuffer(self.ibuf);
    }
}

fn snkEventToNuklearKey(self: *const Snk, event: *const sapp.Event) nk.Keys {
    const shift_modifier = event.modifiers & sapp.modifier_shift > 0;
    switch (event.key_code) {
        .X, .C, .A, .Z => {
            if (!snkIsCtrl(self, event.modifiers)) {
                return nk.c.NK_KEY_NONE;
            }
        },
        else => {},
    }
    if (event.key_code == .Z) {
        if (shift_modifier) {
            return nk.c.NK_KEY_TEXT_REDO;
        } else {
            return nk.c.NK_KEY_TEXT_UNDO;
        }
    }
    return switch (event.key_code) {
        .X => nk.c.NK_KEY_CUT,
        .C => nk.c.NK_KEY_COPY,
        .A => nk.c.NK_KEY_TEXT_SELECT_ALL,
        .DELETE => nk.c.NK_KEY_DEL,
        .ENTER => nk.c.NK_KEY_ENTER,
        .TAB => nk.c.NK_KEY_TAB,
        .BACKSPACE => nk.c.NK_KEY_BACKSPACE,
        .UP => nk.c.NK_KEY_UP,
        .DOWN => nk.c.NK_KEY_DOWN,
        .LEFT => nk.c.NK_KEY_LEFT,
        .RIGHT => nk.c.NK_KEY_RIGHT,
        .LEFT_SHIFT => nk.c.NK_KEY_SHIFT,
        .RIGHT_SHIFT => nk.c.NK_KEY_SHIFT,
        .LEFT_CONTROL => nk.c.NK_KEY_CTRL,
        .RIGHT_CONTROL => nk.c.NK_KEY_CTRL,
        else => nk.c.NK_KEY_NONE,
    };
}

fn snkIsCtrl(self: *const Snk, modifiers: u32) bool {
    if (self.is_osx) {
        return 0 != (modifiers & sapp.modifier_super);
    }
    return 0 != (modifiers & sapp.modifier_ctrl);
}
