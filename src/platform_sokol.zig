const std = @import("std");

const sg = @import("sokol").gfx;
const sapp = @import("sokol").app;
const sgapp = @import("sokol").app_gfx_glue;
const stm = @import("sokol").time;

const game = @import("game_types.zig");
const SokolGame = @import("platform_code_loader.zig").SokolGame;

var exe_dir: []const u8 = undefined;
var game_code: SokolGame = undefined;

var data: game.Data = undefined;
var input = game.Input{
    .delta_time = 0.0,
};

const State = struct {
    pass_action: sg.PassAction = .{},
    pipeline: sg.Pipeline = .{},
    bindings: sg.Bindings = .{},
};
var state = State{};

const DLL_NAME = "game.dll";
const DLL_TEMP_NAME = "game_temp.dll";

fn initTime(time: *game.Time) void {
    stm.setup();
    time.init_time = stm.now();
}

fn tickTime(time: *game.Time) void {
    time.last_frame = time.current_frame;
    time.current_frame = stm.now();
}

export fn init() void {
    sg.setup(.{
        .context = sgapp.context(),
    });

    const vertices = [_]f32{
            -0.5,  0.5, 0.5,     1.0, 0.0, 0.0, 1.0,
            0.5,  0.5, 0.5,     0.0, 1.0, 0.0, 1.0,
            0.5, -0.5, 0.5,     0.0, 0.0, 1.0, 1.0,
            -0.5, -0.5, 0.5,     1.0, 1.0, 0.0, 1.0,
    };

    state.bindings.vertex_buffers[0] = sg.makeBuffer(.{
        .size = vertices.len * @sizeOf(f32),
        .content = &vertices[0],
        .type = .VERTEXBUFFER,
    });

    const indices = [_]u16 { 0, 1, 2, 0, 2, 3 };
    state.bindings.index_buffer = sg.makeBuffer(.{
        .type = .INDEXBUFFER,
        .content = &indices,
        .size = @sizeOf(@TypeOf(indices)),
    });

    const shd = sg.makeShader(shaderDesc());
    var pipe_desc: sg.PipelineDesc = .{
        .index_type = .UINT16,
        .shader = shd,
    };

    pipe_desc.layout.attrs[0].format = .FLOAT3;
    pipe_desc.layout.attrs[1].format = .FLOAT4;

    state.pipeline = sg.makePipeline(pipe_desc);
    state.pass_action.colors[0] = .{
        .action = .CLEAR,
        .val = .{ 0.2, 0.2, 0.2, 1.0 },
    };
}

export fn frame() void {
    input.frame += 1;

    if (game_code.hasChanged()) {
        game_code.reload() catch std.debug.print("Failed to Reload the code\n", .{});
    }

    tickTime(&input.time);
    if (game_code.update) |update_game| {
        update_game(&input, &data);
    }

    sg.beginDefaultPass(state.pass_action, sapp.width(), sapp.height());
    sg.applyPipeline(state.pipeline);
    sg.applyBindings(state.bindings);
    sg.draw(0, 6, 1);
    sg.endPass();
    sg.commit();
}

export fn cleanup() void {
    sg.shutdown();
}

pub fn main() anyerror!void {
    var buffer: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    var allocator = &fba.allocator;
    initTime(&input.time);

    var pathBuffer = std.fs.selfExePathAlloc(allocator) catch |err| @panic("Failed to get Exe Path");
    if (std.fs.path.dirname(pathBuffer)) |path| {
        exe_dir = path[0..path.len];
    } else {
        @panic("Failed to get EXE Directory");
    }

    const source_dll = try std.fs.path.join(allocator, &[_][]const u8{ exe_dir, DLL_NAME });
    const temp_dll = try std.fs.path.join(allocator, &[_][]const u8{ exe_dir, DLL_TEMP_NAME });

    game_code = try SokolGame.load(source_dll, temp_dll);

    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .width = 640,
        .height = 640,
        .window_title = "zsnake.zig",
    });
}

// build a backend-specific ShaderDesc struct
fn shaderDesc() sg.ShaderDesc {
    var desc: sg.ShaderDesc = .{};
    switch (sg.queryBackend()) {
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
        else => {}
    }
    return desc;
}