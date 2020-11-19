const std = @import("std");

const sg = @import("sokol/gfx.zig");
const game = @import("znake_types.zig");

const Time = game.Time;

const State = struct {
    pass_action: sg.PassAction = .{},
    pipeline: sg.Pipeline = .{},
    bindings: sg.Bindings = .{},
};

const GameState = struct {
    state: State = .{},
    x: f32 = 16.,
    y: f32 = 16.,
    const Self = @This();
    pub fn get(data: *game.Data, gfx: *game.GfxCommandBuffer) *Self {
        var state = &std.mem.bytesAsSlice(Self, @alignCast(@alignOf(Self), data.permanent_storage[0..@sizeOf(Self)]))[0];
        if (!data.initialized) {
            state.* = GameState{};
            state.initGfx(gfx);
            data.initialized = true;
        }

        return state;
    }

    pub fn initGfx(self: *Self, gfx: *game.GfxCommandBuffer) void {
        const vertices = [_]f32{
            -0.5, 0.5,  0.5, 1.0, 0.0, 0.0, 1.0,
            0.5,  0.5,  0.5, 0.0, 1.0, 0.0, 1.0,
            0.5,  -0.5, 0.5, 0.0, 0.0, 1.0, 1.0,
            -0.5, -0.5, 0.5, 1.0, 1.0, 0.0, 1.0,
        };

        self.state.bindings.vertex_buffers[0] = gfx.makeBuffer(.{
            .size = vertices.len * @sizeOf(f32),
            .content = &vertices[0],
            .type = .VERTEXBUFFER,
        });

        const indices = [_]u16{ 0, 1, 2, 0, 2, 3 };
        self.state.bindings.index_buffer = gfx.makeBuffer(.{
            .type = .INDEXBUFFER,
            .content = &indices,
            .size = @sizeOf(@TypeOf(indices)),
        });

        const shd = gfx.makeShader(shaderDesc(gfx));
        var pipe_desc: sg.PipelineDesc = .{
            .index_type = .UINT16,
            .shader = shd,
        };

        pipe_desc.layout.attrs[0].format = .FLOAT3;
        pipe_desc.layout.attrs[1].format = .FLOAT4;
        self.state.pipeline = gfx.makePipeline(pipe_desc);
        self.state.pass_action.colors[0] = .{
            .action = .CLEAR,
            .val = .{ 0.2, 0.2, 0.2, 1.0 },
        };
    }
};

export fn update_game(input: *game.Input, data: *game.Data, gfx: *game.GfxCommandBuffer) void {
    var game_state = GameState.get(data, gfx);

    gfx.beginDefaultPass(game_state.state.pass_action, 640, 640);
    gfx.applyPipeline(game_state.state.pipeline);
    gfx.applyBindings(game_state.state.bindings);
    gfx.draw(0, 6, 1);
    gfx.endPass();
    gfx.commit();


    if (@mod(input.frame, 10) == 0) {
        std.debug.print("Head Positon:\n\tx: {}\n\ty: {}\n", .{ game_state.x, game_state.y });
    }
}

// build a backend-specific ShaderDesc struct
fn shaderDesc(buffer: *game.GfxCommandBuffer) sg.ShaderDesc {
    var desc: sg.ShaderDesc = .{};
    switch (buffer.backend) {
        .D3D11 => {
            desc.attrs[0].sem_name = "POS";
            desc.attrs[1].sem_name = "COLOR";
            desc.vs.source =
                \\struct vs_in {
                \\  float4 pos: POS;
                \\  float4 color: COLOR;
                \\};
                \\struct vs_out {
                \\  float4 color: COLOR0;
                \\  float4 pos: SV_Position;
                \\};
                \\vs_out main(vs_in inp) {
                \\  vs_out outp;
                \\  outp.pos = inp.pos;
                \\  outp.color = inp.color;
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
            desc.attrs[1].name = "color0";
            desc.vs.source =
                \\ #version 330
                \\ in vec4 position;
                \\ in vec4 color0;
                \\ out vec4 color;
                \\ void main() {
                \\   gl_Position = position;
                \\   color = color0;
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
