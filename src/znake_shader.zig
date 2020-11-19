const std = @import("std");
const zgfx = @import("znake_gfx.zig");
const game = @import("znake_types.zig");

pub fn simple() zgfx.ShaderDesc {
    var desc: zgfx.ShaderDesc = .{};
    desc.attrs[0].name = "position";
    desc.fs.uniform_blocks[0].size = @sizeOf(game.VsParams);
    desc.fs.uniform_blocks[0].uniforms[0] = .{ .name = "ourColor", .type = .FLOAT4, .array_count = 1 };
    desc.vs.source = @embedFile("shaders/simple.vert");
    desc.fs.source = @embedFile("shaders/simple.frag");
    desc.label = "simple";
    return desc;
}
