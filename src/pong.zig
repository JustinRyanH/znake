pub const GameDrawBuffer = struct {
    height: i32,
    width: i32,
    pitch: i32,
    memory: *c_void,
};
