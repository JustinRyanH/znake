const std = @import("std");
const zgfx = @import("../znake_gfx.zig");
pub const types = @import("./types.zig");

pub fn simple() zgfx.ShaderDesc {
    var desc: zgfx.ShaderDesc = .{};
    desc.attrs[0].name = "position";
    desc.fs.uniform_blocks[0].size = @sizeOf(types.VsParams);
    desc.fs.uniform_blocks[0].uniforms[0] = .{ .name = "ourColor", .type = .FLOAT4, .array_count = 1 };
    desc.vs.source = @embedFile("./simple.vert");
    desc.fs.source = @embedFile("./simple.frag");
    desc.label = "simple";
    return desc;
}
