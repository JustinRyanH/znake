const win32 = @import("win32.zig");
const wasapi = @import("wasapi.zig");

pub const WasapiConnection = struct {
    device_enum: *wasapi.IMMDeviceEnumerator,
};

pub const SoundOutput = struct {
    loaded: bool = false,
    initialized: bool = false,

    wasapi: ?WasapiConnection = null,
    // device: *wasapi.IMMDevice,
    // audio_client: *wasapi.IAudioClient,
    // audio_render_client: *wasapi.IAudioRenderClient,
    // sound_buffer_duration: wasapi.ReferenceTime,
    // buffer_frame_count: u32,
    // channels: u32,
    // samples_per_second: u32,
    // latency_frame_count: u32,
};

pub fn getPadding(sound: *SoundOutput) i32 {
    return 0;
}

pub fn load() SoundOutput {
    const result = SoundOutput{};
    if (win32.LoadLibraryA("ole32.dll")) |handle| {
        return result;
    }
    win32.debug("Failed to Load ole32.dll", .{});
    return result;
}
pub fn init(sound: *SoundOutput) void {}
pub fn deinit(sound: *SoundOutput) void {}
pub fn fillBuffer(sound: *SoundOutput, samples: []f32) void {}
