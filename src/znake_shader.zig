const std = @import("std");
const zgfx = @import("znake_gfx.zig");
const game = @import("znake_types.zig");

pub fn simple(buffer: *zgfx.CommandBuffer) zgfx.ShaderDesc {
    var desc: zgfx.ShaderDesc = .{};
    desc.vs.uniform_blocks[0].size = @sizeOf(game.VsParams);
    switch (buffer.backend) {
        .D3D11 => {
            desc.attrs[0].sem_name = "POSITION";
            desc.vs.source =
                \\cbuffer params: register(b0) {
                \\  float4 color;
                \\}
                \\struct vs_in {
                \\  float4 pos: POSITION;
                \\};
                \\struct vs_out {
                \\  float4 color: COLOR0;
                \\  float4 pos: SV_Position;
                \\};
                \\vs_out main(vs_in inp) {
                \\  vs_out outp;
                \\  outp.pos = inp.pos;
                \\  outp.color = color;
                \\  return outp;
                \\}
            ;
            desc.fs.source =
                \\float4 main(float4 color: COLOR0): SV_Target0 {
                \\  return color;
                \\}
            ;
        },
        .GLCORE33 => {
            desc.attrs[0].name = "position";
            desc.vs.source =
                \\ #version 330
                \\ uniform vec4 inColor;
                \\ layout(location = 0) in vec4 position;
                \\ out vec4 color;
                \\ void main() {
                \\   gl_Position = position;
                \\   color = inColor
                \\ }
            ;
            desc.fs.source =
                \\ #version 330
                \\ in vec4 color;
                \\ out vec4 frag_color;
                \\ void main() {
                \\   frag_color = color;
                \\ }
            ;
        },
        else => {},
    }
    return desc;
}
