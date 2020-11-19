const std = @import("std");

const zgfx = @import("znake_gfx.zig");
const shaders = @import("znake_shader.zig");
const game = @import("znake_types.zig");

const Time = game.Time;

const Vertex = game.Vertex;

const VsParams = game.VsParams;

const Renderer = struct {
    initialized: bool = false,
    pass_action: zgfx.PassAction = .{},
    pipeline: zgfx.Pipeline = .{},
    bindings: zgfx.Bindings = .{},

    const Self = @This();

    pub fn init(self: *Self, gfx: *zgfx.CommandBuffer) void {
        if (self.initialized) return;
        self.initialized = true;

        const ve = [_]Vertex{
            .{ .x = -0.5, .y = 0.5,  .z = 0.5 },
            .{ .x = 0.5,  .y = 0.5,  .z = 0.5 },
            .{ .x = 0.5,  .y = -0.5, .z = 0.5 },
            .{ .x = -0.5, .y = -0.5, .z = 0.5 },
        };

        self.bindings.vertex_buffers[0] = gfx.makeBuffer(.{
            .size = @sizeOf(@TypeOf(ve)),
            .content = &ve[0],
            .type = .VERTEXBUFFER,
        });

        const indices = [_]u16{ 0, 1, 2, 0, 2, 3 };
        self.bindings.index_buffer = gfx.makeBuffer(.{
            .type = .INDEXBUFFER,
            .content = &indices,
            .size = @sizeOf(@TypeOf(indices)),
        });

        const shader_desc = shaders.simple();
        const shd = gfx.makeShader(shader_desc);
        var pipe_desc: zgfx.PipelineDesc = .{
            .index_type = .UINT16,
            .shader = shd,
        };

        pipe_desc.layout.attrs[0].format = .FLOAT3;
        self.pipeline = gfx.makePipeline(pipe_desc);
        self.pass_action.colors[0] = .{
            .action = .CLEAR,
            .val = .{ 0.2, 0.2, 0.2, 1.0 },
        };
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
    var params = VsParams{ .color = .{ .r = 1.0, .b = 0.0, .g = 0.0, .a = 1.0 } };
    game_state.renderer.init(gfx);
    gfx.beginDefaultPass(game_state.renderer.pass_action, input.width, input.height);
    gfx.applyPipeline(game_state.renderer.pipeline);
    gfx.applyBindings(game_state.renderer.bindings);
    gfx.applyUniforms(.FS, 0, &params, @sizeOf(@TypeOf(params)));
    gfx.draw(0, 6, 1);
    gfx.endPass();
    gfx.commit();

    if (@mod(input.frame, 10) == 0) {
        std.debug.print("Head Positon:\n\tx: {}\n\ty: {}\n", .{ game_state.x, game_state.y });
    }
}
