pub const Data = struct {
    initialized: bool = false,

    permanent_storage: []u8,
    transient_storage: []u8,
};

pub const Input = struct {
    frame: usize = 0,
    delta_time: f32,

};

pub const UpdateGame = fn (input: *Input, data: *Data) void;