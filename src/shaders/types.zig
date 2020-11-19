pub const Color = packed struct {
    r: f32, b: f32, g: f32, a: f32
};
pub const Vertex = packed struct {
    x: f32, y: f32, z: f32,
};

pub const VsParams = packed struct {
    color: Color,
};