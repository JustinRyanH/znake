const sg = @import("sokol/gfx.zig");

pub const PassAction = sg.PassAction;
pub const Pipeline = sg.Pipeline;
pub const Bindings = sg.Bindings;
pub const ShaderDesc = sg.ShaderDesc;
pub const ShaderStage = sg.ShaderStage;
pub const PipelineDesc = sg.PipelineDesc;
pub const Backend = sg.Backend;

pub const MakeBuffer = fn (desc: sg.BufferDesc) sg.Buffer;
pub const MakeShader = fn (desc: sg.ShaderDesc) sg.Shader;
pub const MakePipeline = fn(desc: sg.PipelineDesc) sg.Pipeline;

pub const BeginDefaultPass = fn(pass_action: sg.PassAction, width: i32, height: i32) void;
pub const ApplyPipeline = fn(pip: sg.Pipeline) void;
pub const ApplyBindings = fn(pip: sg.Bindings) void;
pub const ApplyUniforms = fn(stage: sg.ShaderStage, ub_index: i32, data: ?*const c_void, num_bytes: i32) void;
pub const DrawCommand = fn(base_element: i32, num_elements: i32, num_instances: i32) void;
pub const EndPass = fn() void;
pub const Commit = fn() void;

pub const CommandBuffer = struct {
    backend: Backend,
    makeBuffer: MakeBuffer,
    makeShader: MakeShader,
    makePipeline: MakePipeline,

    beginDefaultPass: BeginDefaultPass,
    applyPipeline: ApplyPipeline,
    applyBindings: ApplyBindings,
    applyUniforms: ApplyUniforms,
    draw: DrawCommand,
    endPass: EndPass,
    commit: Commit,
};