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
mouse_scroll: [2]i32 = .{ 0, 0 },
mouse_did_move: bool = false,
mouse_did_scroll: bool = false,
btn_down: [nk.c.NK_BUTTON_MAX]bool = std.mem.zeroes([nk.c.NK_BUTTON_MAX]bool),
btn_up: [nk.c.NK_BUTTON_MAX]bool = std.mem.zeroes([nk.c.NK_BUTTON_MAX]bool),
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
// fn newFrame(self: *Snk) nk.Context {
// #if !defined(SOKOL_NUKLEAR_NO_SOKOL_APP)
// nk_input_begin(&_snuklear.ctx);
// if (_snuklear.mouse_did_move) {
//     nk_input_motion(&_snuklear.ctx, _snuklear.mouse_pos[0], _snuklear.mouse_pos[1]);
//     _snuklear.mouse_did_move = false;
// }
// if (_snuklear.mouse_did_scroll) {
//     nk_input_scroll(&_snuklear.ctx, nk_vec2(_snuklear.mouse_scroll[0], _snuklear.mouse_scroll[1]));
//     _snuklear.mouse_did_scroll = false;
// }    // struct nk_convert_config cfg = {
//     .shape_AA = NK_ANTI_ALIASING_ON,
//     .line_AA = NK_ANTI_ALIASING_ON,
//     .vertex_layout = vertex_layout,
//     .vertex_size = sizeof(_snk_vertex_t),
//     .vertex_alignment = 4,
//     .circle_segment_count = 22,
//     .curve_segment_count = 22,
//     .arc_segment_count = 22,
//     .global_alpha = 1.0f
// };

// _snuklear.vs_params.disp_size[0] = (float)width;
// _snuklear.vs_params.disp_size[1] = (float)height;
// for (int i = 0; i < NK_BUTTON_MAX; i++) {
//     if (_snuklear.btn_down[i]) {
//         _snuklear.btn_down[i] = false;
//         nk_input_button(&_snuklear.ctx, (enum nk_buttons)i, _snuklear.mouse_pos[0], _snuklear.mouse_pos[1], 1);
//     }
//     else if (_snuklear.btn_up[i]) {
//         _snuklear.btn_up[i] = false;
//         nk_input_button(&_snuklear.ctx, (enum nk_buttons)i, _s    // struct nk_convert_config cfg = {
//     .shape_AA = NK_ANTI_ALIASING_ON,
//     .line_AA = NK_ANTI_ALIASING_ON,
//     .vertex_layout = vertex_layout,
//     .vertex_size = sizeof(_snk_vertex_t),
//     .vertex_alignment = 4,
//     .circle_segment_count = 22,
//     .curve_segment_count = 22,
//     .arc_segment_count = 22,
//     .global_alpha = 1.0f
// };

// _snuklear.vs_params.disp_size[0] = (float)width;
// _snuklear.vs_params.disp_size[1] = (float)height;nuklear.mouse_pos[0], _snuklear.mouse_pos[1], 0);
//     }
// }
// const size_t char_buffer_len = strlen(_snuklear.char_buffer);
// if (char_buffer_len > 0) {
//     for (size_t i = 0; i < char_buffer_len; i++) {    // struct nk_convert_config cfg = {
//     .shape_AA = NK_ANTI_ALIASING_ON,
//     .line_AA = NK_ANTI_ALIASING_ON,
//     .vertex_layout = vertex_layout,
//     .vertex_size = sizeof(_snk_vertex_t),
//     .vertex_alignment = 4,
//     .circle_segment_count = 22,
//     .curve_segment_count = 22,
//     .arc_segment_count = 22,
//     .global_alpha = 1.0f
// };

// _snuklear.vs_params.disp_size[0] = (float)width;
// _snuklear.vs_params.disp_size[1] = (float)height;
//         nk_input_char(&_snuklear.ctx, _snuklear.char_buffer[i]);
//     }
//     memset(_snuklear.char_buffer, 0, NK_INPUT_MAX);
// }
// for (int i = 0; i < NK_KEY_MAX; i++) {
//     if (_snuklear.keys_down[i]) {
//         nk_input_key(&_snuklear.ctx, (enum nk_keys)i, true);
//         _snuklear.keys_down[i] = 0;
//     }
//     if (_snuklear.keys_up[i]) {
//         nk_input_key(&_snuklear.ctx, (enum nk_keys)i, false);
//         _snuklear.keys_up[i] = 0;
//     }
// }
// nk_input_end(&_snuklear.ctx);
// struct nk_convert_config cfg = {
//     .shape_AA = NK_ANTI_ALIASING_ON,
//     .line_AA = NK_ANTI_ALIASING_ON,
//     .vertex_layout = vertex_layout,
//     .vertex_size = sizeof(_snk_vertex_t),
//     .vertex_alignment = 4,
//     .circle_segment_count = 22,
//     .curve_segment_count = 22,
//     .arc_segment_count = 22,
//     .global_alpha = 1.0f
// };

// _snuklear.vs_params.disp_size[0] = (float)width;
// _snuklear.vs_params.disp_size[1] = (float)height;
// #endif

// nk_clear(&_snuklear.ctx);    // struct nk_convert_config cfg = {
//     .shape_AA = NK_ANTI_ALIASING_ON,
//     .line_AA = NK_ANTI_ALIASING_ON,
//     .vertex_layout = vertex_layout,
//     .vertex_size = sizeof(_snk_vertex_t),
//     .vertex_alignment = 4,
//     .circle_segment_count = 22,
//     .curve_segment_count = 22,
//     .arc_segment_count = 22,
//     .global_alpha = 1.0f
// };

// _snuklear.vs_params.disp_size[0] = (float)width;
// _snuklear.vs_params.disp_size[1] = (float)height;kkkj
// return &_snuklear.ctx;
// }

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
    nk.clear(&self.ctx);
}

// /* Setup vert/index buffers and convert */
// struct nk_buffer cmds, verts, idx;
// nk_buffer_init_default(&cmds);
// nk_buffer_init_default(&verts);
// nk_buffer_init_default(&idx);
// nk_convert(&_snuklear.ctx, &cmds, &verts, &idx, &cfg);

// /* Check for vertex- and index-buffer overflow, assert in debug-mode,
//    otherwise silently skip rendering
// */
// const bool vertex_buffer_overflow = nk_buffer_total(&verts) > _snuklear.vertex_buffer_size;
// const bool index_buffer_overflow = nk_buffer_total(&idx) > _snuklear.index_buffer_size;
// SOKOL_ASSERT(!vertex_buffer_overflow && !index_buffer_overflow);
// if (!vertex_buffer_overflow && !index_buffer_overflow) {

//     /* Setup rendering */
//     const float dpi_scale = _snuklear.desc.dpi_scale;
//     const int fb_width = (int)(_snuklear.vs_params.disp_size[0] * dpi_scale);
//     const int fb_height = (int)(_snuklear.vs_params.disp_size[1] * dpi_scale);
//     sg_apply_viewport(0, 0, fb_width, fb_height, true);
//     sg_apply_scissor_rect(0, 0, fb_width, fb_height, true);
//     sg_apply_pipeline(_snuklear.pip);
//     sg_apply_uniforms(SG_SHADERSTAGE_VS, 0, &SG_RANGE(_snuklear.vs_params));
//     sg_update_buffer(_snuklear.vbuf, &(sg_range){ nk_buffer_memory_const(&verts), nk_buffer_total(&verts) });
//     sg_update_buffer(_snuklear.ibuf, &(sg_range){ nk_buffer_memory_const(&idx), nk_buffer_total(&idx) });

//     /* Iterate through the command list, rendering each one */
//     const struct nk_draw_command* cmd = NULL;
//     int idx_offset = 0;
//     nk_draw_foreach(cmd, &_snuklear.ctx, &cmds) {
//         if (cmd->elem_count > 0) {
//             sg_image img;
//             if (cmd->texture.id != 0) {
//                 img = (sg_image){ .id = (uint32_t) cmd->texture.id };
//             }
//             else {
//                 img = _snuklear.img;
//             }
//             sg_apply_bindings(&(sg_bindings){
//                 .fs_images[0] = img,
//                 .vertex_buffers[0] = _snuklear.vbuf,
//                 .index_buffer = _snuklear.ibuf,
//                 .vertex_buffer_offsets[0] = 0,
//                 .index_buffer_offset = idx_offset
//             });
//             sg_apply_scissor_rectf(cmd->clip_rect.x * dpi_scale,
//                                    cmd->clip_rect.y * dpi_scale,
//                                    cmd->clip_rect.w * dpi_scale,
//                                    cmd->clip_rect.h * dpi_scale,
//                                    true);
//             sg_draw(0, (int)cmd->elem_count, 1);
//             idx_offset += (int)cmd->elem_count * (int)sizeof(uint16_t);
//         }
//     }
//     sg_apply_scissor_rect(0, 0, fb_width, fb_height, true);
// }

// /* Cleanup */
// nk_buffer_free(&cmds);
// nk_buffer_free(&verts);
// nk_buffer_free(&idx);
// }
// fn handleEvent(self: *Snk, event: *sapp.Event) void {

// const float dpi_scale = _snuklear.desc.dpi_scale;
// switch (ev->type) {
//     case SAPP_EVENTTYPE_MOUSE_DOWN:
//         _snuklear.mouse_pos[0] = (int) (ev->mouse_x / dpi_scale);
//         _snuklear.mouse_pos[1] = (int) (ev->mouse_y / dpi_scale);
//         switch (ev->mouse_button) {
//             case SAPP_MOUSEBUTTON_LEFT:
//                 _snuklear.btn_down[NK_BUTTON_LEFT] = true;
//                 break;
//             case SAPP_MOUSEBUTTON_RIGHT:
//                 _snuklear.btn_down[NK_BUTTON_RIGHT] = true;
//                 break;
//             case SAPP_MOUSEBUTTON_MIDDLE:
//                 _snuklear.btn_down[NK_BUTTON_MIDDLE] = true;
//                 break;
//             default:
//                 break;
//         }
//         break;
//     case SAPP_EVENTTYPE_MOUSE_UP:
//         _snuklear.mouse_pos[0] = (int) (ev->mouse_x / dpi_scale);
//         _snuklear.mouse_pos[1] = (int) (ev->mouse_y / dpi_scale);
//         switch (ev->mouse_button) {
//             case SAPP_MOUSEBUTTON_LEFT:
//                 _snuklear.btn_up[NK_BUTTON_LEFT] = true;
//                 break;
//             case SAPP_MOUSEBUTTON_RIGHT:
//                 _snuklear.btn_up[NK_BUTTON_RIGHT] = true;
//                 break;
//             case SAPP_MOUSEBUTTON_MIDDLE:
//                 _snuklear.btn_up[NK_BUTTON_MIDDLE] = true;
//                 break;
//             default:
//                 break;
//         }
//         break;
//     case SAPP_EVENTTYPE_MOUSE_MOVE:
//         _snuklear.mouse_pos[0] = (int) (ev->mouse_x / dpi_scale);
//         _snuklear.mouse_pos[1] = (int) (ev->mouse_y / dpi_scale);
//         _snuklear.mouse_did_move = true;
//         break;
//     case SAPP_EVENTTYPE_MOUSE_ENTER:
//     case SAPP_EVENTTYPE_MOUSE_LEAVE:
//         for (int i = 0; i < NK_BUTTON_MAX; i++) {
//             _snuklear.btn_down[i] = false;
//             _snuklear.btn_up[i] = false;
//         }
//         break;
//     case SAPP_EVENTTYPE_MOUSE_SCROLL:
//         _snuklear.mouse_scroll[0] = ev->scroll_x;
//         _snuklear.mouse_scroll[1] = ev->scroll_y;
//         _snuklear.mouse_did_scroll = true;
//         break;
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
//     case SAPP_EVENTTYPE_KEY_DOWN:
//         /* intercept Ctrl-V, this is handled via EVENTTYPE_CLIPBOARD_PASTED */
//         if (_snk_is_ctrl(ev->modifiers) && (ev->key_code == SAPP_KEYCODE_V)) {
//             break;
//         }
//         /* on web platform, don't forward Ctrl-X, Ctrl-V to the browser */
//         if (_snk_is_ctrl(ev->modifiers) && (ev->key_code == SAPP_KEYCODE_X)) {
//             sapp_consume_event();
//         }
//         if (_snk_is_ctrl(ev->modifiers) && (ev->key_code == SAPP_KEYCODE_C)) {
//             sapp_consume_event();
//         }
//         _snuklear.keys_down[_snk_event_to_nuklearkey(ev)] = true;
//         break;
//     case SAPP_EVENTTYPE_KEY_UP:
//         /* intercept Ctrl-V, this is handled via EVENTTYPE_CLIPBOARD_PASTED */
//         if (_snk_is_ctrl(ev->modifiers) && (ev->key_code == SAPP_KEYCODE_V)) {
//             break;
//         }
//         /* on web platform, don't forward Ctrl-X, Ctrl-V to the browser */
//         if (_snk_is_ctrl(ev->modifiers) && (ev->key_code == SAPP_KEYCODE_X)) {
//             sapp_consume_event();
//         }
//         if (_snk_is_ctrl(ev->modifiers) && (ev->key_code == SAPP_KEYCODE_C)) {
//             sapp_consume_event();
//         }
//         _snuklear.keys_up[_snk_event_to_nuklearkey(ev)] = true;
//         break;
//     case SAPP_EVENTTYPE_CHAR:
//         if ((ev->char_code >= 32) &&
//             (ev->char_code != 127) &&
//             (0 == (ev->modifiers & (SAPP_MODIFIER_ALT|SAPP_MODIFIER_CTRL|SAPP_MODIFIER_SUPER))))
//         {
//             _snk_append_char(ev->char_code);
//         }
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

    // /* NOTE: it's valid to call the destroy funcs with SG_INVALID_ID */
    // sg_push_debug_group("sokol-nuklear");
    // sg_destroy_pipeline(_snuklear.pip);
    // sg_destroy_shader(_snuklear.shd);
    // sg_destroy_image(_snuklear.img);
    // sg_destroy_buffer(_snuklear.ibuf);
    // sg_destroy_buffer(_snuklear.vbuf);
    // sg_pop_debug_group();
}
