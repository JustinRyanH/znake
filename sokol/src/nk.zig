const snk = @This();

// typedef struct {
//     snk_desc_t desc;
//     struct nk_context ctx;
//     struct nk_font_atlas atlas;
//     _snk_vs_params_t vs_params;
//     size_t vertex_buffer_size;
//     size_t index_buffer_size;
//     sg_buffer vbuf;
//     sg_buffer ibuf;
//     sg_image img;
//     sg_shader shd;
//     sg_pipeline pip;
//     bool is_osx;    /* return true if running on OSX (or HTML5 OSX), needed for copy/paste */
//     #if !defined(SOKOL_NUKLEAR_NO_SOKOL_APP)
//     int mouse_pos[2];
//     float mouse_scroll[2];
//     bool mouse_did_move;
//     bool mouse_did_scroll;
//     bool btn_down[NK_BUTTON_MAX];
//     bool btn_up[NK_BUTTON_MAX];
//     char char_buffer[NK_INPUT_MAX];
//     bool keys_down[NK_KEY_MAX];
//     bool keys_up[NK_KEY_MAX];
//     #endif
// } _snk_state_t;
// static _snk_state_t _snuklear;