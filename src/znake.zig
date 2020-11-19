const std = @import("std");

const zgfx = @import("znake_gfx.zig");
const game = @import("znake_types.zig");

const Time = game.Time;

const Renderer = struct {
    initialized: bool = false,
    pass_action: zgfx.PassAction = .{},
    pipeline: zgfx.Pipeline = .{},
    bindings: zgfx.Bindings = .{},

    const Self = @This();

    pub fn init(self: *Self, gfx: *zgfx.CommandBuffer) void {
        if (self.initialized) return;
        self.initialized = true;
        const vertices = [_]f32{
            -0.5, 0.5,  0.5, 1.0, 0.0, 0.0, 1.0,
            0.5,  0.5,  0.5, 0.0, 1.0, 0.0, 1.0,
            0.5,  -0.5, 0.5, 0.0, 0.0, 1.0, 1.0,
            -0.5, -0.5, 0.5, 1.0, 1.0, 0.0, 1.0,
        };

        self.bindings.vertex_buffers[0] = gfx.makeBuffer(.{
            .size = vertices.len * @sizeOf(f32),
            .content = &vertices[0],
            .type = .VERTEXBUFFER,
        });

        const indices = [_]u16{ 0, 1, 2, 0, 2, 3 };
        self.bindings.index_buffer = gfx.makeBuffer(.{
            .type = .INDEXBUFFER,
            .content = &indices,
            .size = @sizeOf(@TypeOf(indices)),
        });

        const shd = gfx.makeShader(shaderDesc(gfx));
        var pipe_desc: zgfx.PipelineDesc = .{
            .index_type = .UINT16,
            .shader = shd,
        };

        pipe_desc.layout.attrs[0].format = .FLOAT3;
        pipe_desc.layout.attrs[1].format = .FLOAT4;
        self.pipeline = gfx.makePipeline(pipe_desc);
        self.pass_action.colors[0] = .{
            .action = .CLEAR,
            .val = .{ 0.2, 0.2, 0.2, 1.0 },
        };
    }

    pub fn render(self: *Self, gfx: *zgfx.CommandBuffer) void {
        gfx.beginDefaultPass(self.pass_action, 640, 640);
        gfx.applyPipeline(self.pipeline);
        gfx.applyBindings(self.bindings);
        gfx.draw(0, 6, 1);
        gfx.endPass();
        gfx.commit();
    }
};

const GameState = struct {
    renderer: Renderer = .{},
    x: f32 = 16.,
    y: f32 = 16.,
    const Self = @This();
    pub fn get(data: *game.Data, gfx: *zgfx.CommandBuffer) *Self {
        var state = &std.mem.bytesAsSlice(Self, @alignCast(@alignOf(Self), data.permanent_storage[0..@sizeOf(Self)]))[0];
        if (!data.initialized) {
            state.* = GameState{};
            data.initialized = true;
        }

        return state;
    }
};

export fn update_game(input: *game.Input, data: *game.Data, gfx: *zgfx.CommandBuffer) void {
    var game_state = GameState.get(data, gfx);
    game_state.renderer.init(gfx);
    game_state.renderer.render(gfx);

    if (@mod(input.frame, 10) == 0) {
        std.debug.print("Head Positon:\n\tx: {}\n\ty: {}\n", .{ game_state.x, game_state.y });
    }
}

// build a backend-specific ShaderDesc struct
fn shaderDesc(buffer: *zgfx.CommandBuffer) zgfx.ShaderDesc {
    var desc: zgfx.ShaderDesc = .{};
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
