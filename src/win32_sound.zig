pub const SoundOutput = struct {
    loaded: bool = false,
    initialized: bool = false,
};

pub fn getPadding(sound: *SoundOutput) i32 {
    return 0;
}

pub fn load() SoundOutput {
    return SoundOutput{};
}
pub fn init(sound: *SoundOutput) void {}
pub fn deinit(sound: *SoundOutput) void {}
pub fn fillBuffer(sound: *SoundOutput, samples: []f32) void {}
