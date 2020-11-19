const sg = @import("sokol/gfx.zig");

pub const Data = struct {
    initialized: bool = false,

    permanent_storage: []u8,
    transient_storage: []u8,
};

pub const Input = struct {
    time: Time = .{},
    frame: usize = 0,
    delta_time: f32,
};

pub const Time = struct {
    init_time: u64 = 0,
    last_frame: u64 = 0,
    current_frame: u64 = 0,
    const Self = @This();

    pub fn diff(new: u64, old: u64) u64 {
        if (new > old) {
            return new - old;
        }
        return 1;
    }

    pub fn since_start(self: *Self) u64 {
        return Time.diff(self.last_frame, self.init_time);
    }

    pub fn since_last_frame(self: *Self) u64 {
        return Time.diff(self.current_frame, self.last_frame);
    }

    pub fn as_sec(ticks: u64) f64 {
        return (@intToFloat(f64, ticks)) / 1000000000.0;
    }

    pub fn as_ms(ticks: u64) f64 {
        return (@intToFloat(f64, ticks)) / 1000000.0;
    }

    pub fn as_us(ticks: u64) f64 {
        return (@intToFloat(f64, ticks)) / 1000.0;
    }

    pub fn as_ns(ticks: u64) f64 {
        return (@intToFloat(f64, ticks));
    }
};

pub const UpdateGame = fn (input: *Input, data: *Data, gfx: *GfxCommandBuffer) void;

pub const MakeBuffer = fn (desc: sg.BufferDesc) sg.Buffer;
pub const MakeShader = fn (desc: sg.ShaderDesc) sg.Shader;
pub const MakePipeline = fn(desc: sg.PipelineDesc) sg.Pipeline;

pub const BeginDefaultPass = fn(pass_action: sg.PassAction, width: i32, height: i32) void;
pub const ApplyPipeline = fn(pip: sg.Pipeline) void;
pub const ApplyBindings = fn(pip: sg.Bindings) void;
pub const DrawCommand = fn(base_element: i32, num_elements: i32, num_instances: i32) void;
pub const EndPass = fn() void;
pub const Commit = fn() void;

pub const GfxCommandBuffer = struct {
    backend: sg.Backend,
    makeBuffer: MakeBuffer,
    makeShader: MakeShader,
    makePipeline: MakePipeline,

    beginDefaultPass: BeginDefaultPass,
    applyPipeline: ApplyPipeline,
    applyBindings: ApplyBindings,
    draw: DrawCommand,
    endPass: EndPass,
    commit: Commit,

};