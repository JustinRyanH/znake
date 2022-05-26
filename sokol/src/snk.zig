// TODO: Implement Copy and Paste
const std = @import("std");
const builtin = @import("builtin");

const nk = @import("nuklear");
const sapp = @import("sokol").app;
const sg = @import("sokol").gfx;
const shd = @import("shaders/nk.glsl.zig");

const Snk = @This();
const NkInputMax = 16;

pub const Desc = struct {
    max_vertices: i32 = std.math.maxInt(i32),
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
    var _null: nk.DrawNullTexture = undefined;
    nk.atlas.end(&out.atlas, nk.rest.nkHandleId(@intCast(c_int, out.img.id)), &_null);

    out.ctx = nk.init(&alloc, &out.atlas.default_font.*.handle);
    sg.pushDebugGroup("sokol-nuklear");
    defer sg.popDebugGroup();



    //     /* initialize Nuklear */
    //     nk_bool init_res = nk_init_default(&_snuklear.ctx, 0);
    //     SOKOL_ASSERT(1 == init_res); (void)init_res;    // silence unused warning in release mode
    // #if !defined(SOKOL_NUKLEAR_NO_SOKOL_APP)
    //     _snuklear.ctx.clip.copy = _snk_clipboard_copy;
    //     _snuklear.ctx.clip.paste = _snk_clipboard_paste;
    // #endif

    //     /* create sokol-gfx resources */
    //     sg_push_debug_group("sokol-nuklear");

    //     /* Vertex Buffer */
    //     _snuklear.vertex_buffer_size = (size_t)_snuklear.desc.max_vertices * sizeof(_snk_vertex_t);
    //     _snuklear.vbuf = sg_make_buffer(&(sg_buffer_desc){
    //         .usage = SG_USAGE_STREAM,
    //         .size = _snuklear.vertex_buffer_size,
    //         .label = "sokol-nuklear-vertices"
    //     });

    //     /* Index Buffer */
    //     _snuklear.index_buffer_size = (size_t)_snuklear.desc.max_vertices * 3 * sizeof(uint16_t);
    //     _snuklear.ibuf = sg_make_buffer(&(sg_buffer_desc){
    //         .type = SG_BUFFERTYPE_INDEXBUFFER,
    //         .usage = SG_USAGE_STREAM,
    //         .size = _snuklear.index_buffer_size,
    //         .label = "sokol-nuklear-indices"
    //     });

    //     /* Font Texture */
    //     if (!_snuklear.desc.no_default_font) {
    //         nk_font_atlas_init_default(&_snuklear.atlas);
    //         nk_font_atlas_begin(&_snuklear.atlas);
    //         int font_width = 0, font_height = 0;
    //         const void* pixels = nk_font_atlas_bake(&_snuklear.atlas, &font_width, &font_height, NK_FONT_ATLAS_RGBA32);
    //         SOKOL_ASSERT((font_width > 0) && (font_height > 0));
    //         _snuklear.img = sg_make_image(&(sg_image_desc){
    //             .width = font_width,
    //             .height = font_height,
    //             .pixel_format = SG_PIXELFORMAT_RGBA8,
    //             .wrap_u = SG_WRAP_CLAMP_TO_EDGE,
    //             .wrap_v = SG_WRAP_CLAMP_TO_EDGE,
    //             .min_filter = SG_FILTER_LINEAR,
    //             .mag_filter = SG_FILTER_LINEAR,
    //             .data.subimage[0][0] = {
    //                 .ptr = pixels,
    //                 .size = (size_t)(font_width * font_height) * sizeof(uint32_t)
    //             },
    //             .label = "sokol-nuklear-font"
    //         });
    //         nk_font_atlas_end(&_snuklear.atlas, nk_handle_id((int)_snuklear.img.id), 0);
    //         nk_font_atlas_cleanup(&_snuklear.atlas);
    //         if (_snuklear.atlas.default_font) {
    //             nk_style_set_font(&_snuklear.ctx, &_snuklear.atlas.default_font->handle);
    //         }
    //     }

    //     /* Shader */
    //     #if defined SOKOL_METAL
    //         const char* vs_entry = "main0";
    //         const char* fs_entry = "main0";
    //     #else
    //         const char* vs_entry = "main";
    //         const char* fs_entry = "main";
    //     #endif
    //     sg_range vs_bytecode = { .ptr = 0, .size = 0 };
    //     sg_range fs_bytecode = { .ptr = 0, .size = 0 };
    //     const char* vs_source = 0;
    //     const char* fs_source = 0;
    //     #if defined(SOKOL_GLCORE33)
    //         vs_source = _snk_vs_source_glsl330;
    //         fs_source = _snk_fs_source_glsl330;
    //     #elif defined(SOKOL_GLES2) || defined(SOKOL_GLES3)
    //         vs_source = _snk_vs_source_glsl100;
    //         fs_source = _snk_fs_source_glsl100;
    //     #elif defined(SOKOL_METAL)
    //         switch (sg_query_backend()) {
    //             case SG_BACKEND_METAL_MACOS:
    //                 vs_bytecode = SG_RANGE(_snk_vs_bytecode_metal_macos);
    //                 fs_bytecode = SG_RANGE(_snk_fs_bytecode_metal_macos);
    //                 break;
    //             case SG_BACKEND_METAL_IOS:
    //                 vs_bytecode = SG_RANGE(_snk_vs_bytecode_metal_ios);
    //                 fs_bytecode = SG_RANGE(_snk_fs_bytecode_metal_ios);
    //                 break;
    //             default:
    //                 vs_source = _snk_vs_source_metal_sim;
    //                 fs_source = _snk_fs_source_metal_sim;
    //                 break;
    //         }
    //     #elif defined(SOKOL_D3D11)
    //         vs_bytecode = SG_RANGE(_snk_vs_bytecode_hlsl4);
    //         fs_bytecode = SG_RANGE(_snk_fs_bytecode_hlsl4);
    //     #elif defined(SOKOL_WGPU)
    //         vs_bytecode = SG_RANGE(_snk_vs_bytecode_wgpu);
    //         fs_bytecode = SG_RANGE(_snk_fs_bytecode_wgpu);
    //     #else
    //         vs_source = _snk_vs_source_dummy;
    //         fs_source = _snk_fs_source_dummy;
    //     #endif

    //     /* Shader */
    //     _snuklear.shd = sg_make_shader(&(sg_shader_desc){
    //         .attrs = {
    //             [0] = { .name = "position", .sem_name = "TEXCOORD", .sem_index = 0 },
    //             [1] = { .name = "texcoord0", .sem_name = "TEXCOORD", .sem_index = 1 },
    //             [2] = { .name = "color0", .sem_name = "TEXCOORD", .sem_index = 2 },
    //         },
    //         .vs = {
    //             .source = vs_source,
    //             .bytecode = vs_bytecode,
    //             .entry = vs_entry,
    //             .d3d11_target = "vs_4_0",
    //             .uniform_blocks[0] = {
    //                 .size = sizeof(_snk_vs_params_t),
    //                 .uniforms[0] = {
    //                     .name = "vs_params",
    //                     .type = SG_UNIFORMTYPE_FLOAT4,
    //                     .array_count = 1,
    //                 }
    //             },
    //         },
    //         .fs = {
    //             .source = fs_source,
    //             .bytecode = fs_bytecode,
    //             .entry = fs_entry,
    //             .d3d11_target = "ps_4_0",
    //             .images[0] = { .name = "tex", .image_type = SG_IMAGETYPE_2D, .sampler_type = SG_SAMPLERTYPE_FLOAT },
    //         },
    //         .label = "sokol-nuklear-shader"
    //     });

    //     /* Pipeline */
    //     _snuklear.pip = sg_make_pipeline(&(sg_pipeline_desc){
    //         .layout = {
    //             .attrs = {
    //                 [0] = { .offset = offsetof(_snk_vertex_t, pos), .format=SG_VERTEXFORMAT_FLOAT2 },
    //                 [1] = { .offset = offsetof(_snk_vertex_t, uv), .format=SG_VERTEXFORMAT_FLOAT2 },
    //                 [2] = { .offset = offsetof(_snk_vertex_t, col), .format=SG_VERTEXFORMAT_UBYTE4N }
    //             }
    //         },
    //         .shader = _snuklear.shd,
    //         .index_type = SG_INDEXTYPE_UINT16,
    //         .sample_count = _snuklear.desc.sample_count,
    //         .depth.pixel_format = _snuklear.desc.depth_format,
    //         .colors[0] = {
    //             .pixel_format = _snuklear.desc.color_format,
    //             .write_mask = SG_COLORMASK_RGB,
    //             .blend = {
    //                 .enabled = true,
    //                 .src_factor_rgb = SG_BLENDFACTOR_SRC_ALPHA,
    //                 .dst_factor_rgb = SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
    //             }
    //         },
    //         .label = "sokol-nuklear-pipeline"
    //     });

    //     sg_pop_debug_group();
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
// }
// for (int i = 0; i < NK_BUTTON_MAX; i++) {
//     if (_snuklear.btn_down[i]) {
//         _snuklear.btn_down[i] = false;
//         nk_input_button(&_snuklear.ctx, (enum nk_buttons)i, _snuklear.mouse_pos[0], _snuklear.mouse_pos[1], 1);
//     }
//     else if (_snuklear.btn_up[i]) {
//         _snuklear.btn_up[i] = false;
//         nk_input_button(&_snuklear.ctx, (enum nk_buttons)i, _snuklear.mouse_pos[0], _snuklear.mouse_pos[1], 0);
//     }
// }
// const size_t char_buffer_len = strlen(_snuklear.char_buffer);
// if (char_buffer_len > 0) {
//     for (size_t i = 0; i < char_buffer_len; i++) {
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
// #endif

// nk_clear(&_snuklear.ctx);
// return &_snuklear.ctx;
// }
// fn render(self: *Snk, width: i32, height: i32) void {

// static const struct nk_draw_vertex_layout_element vertex_layout[] = {
//     {NK_VERTEX_POSITION, NK_FORMAT_FLOAT, NK_OFFSETOF(struct _snk_vertex_t, pos)},
//     {NK_VERTEX_TEXCOORD, NK_FORMAT_FLOAT, NK_OFFSETOF(struct _snk_vertex_t, uv)},
//     {NK_VERTEX_COLOR, NK_FORMAT_R8G8B8A8, NK_OFFSETOF(struct _snk_vertex_t, col)},
//     {NK_VERTEX_LAYOUT_END}
// };
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

    // /* NOTE: it's valid to call the destroy funcs with SG_INVALID_ID */
    // sg_push_debug_group("sokol-nuklear");
    // sg_destroy_pipeline(_snuklear.pip);
    // sg_destroy_shader(_snuklear.shd);
    // sg_destroy_image(_snuklear.img);
    // sg_destroy_buffer(_snuklear.ibuf);
    // sg_destroy_buffer(_snuklear.vbuf);
    // sg_pop_debug_group();
}
