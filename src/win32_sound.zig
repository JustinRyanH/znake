const std = @import("std");
const windows = std.os.windows;
const win32 = @import("win32.zig");
const wasapi = @import("wasapi.zig");

pub extern "ole32" fn CoCreateInstance(wasapi.REFCLSID, ?*wasapi.IUnknown, windows.DWORD, wasapi.REFIID, [*c]windows.LPVOID) callconv(.Stdcall) windows.HRESULT;
pub extern "ole32" fn CoInitializeEx(pvReserved: ?windows.LPVOID, dwCoInit: windows.COINIT) callconv(.Stdcall) windows.HRESULT;

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
    var result = SoundOutput{};
    // if (win32.LoadLibraryA("ole32.dll")) |handle| {
    //     result.loaded = true;
    //     return result;
    // }
    // win32.debug("Failed to Load ole32.dll", .{});
    return result;
}

pub fn init(sound: *SoundOutput) void {
    var success = CoInitializeEx(null, windows.COINIT_SPEED_OVER_MEMORY);
    var result: windows.HRESULT = undefined;
    var device_enum = std.mem.zeroes(wasapi.IMMDeviceEnumerator);

    result = CoCreateInstance(&wasapi.CLSID_MMDeviceEnumerator, null, wasapi.CLSCTX_ALL, &wasapi.IID_IMMDeviceEnumerator, @ptrCast([*c]windows.LPVOID, &device_enum));
    win32.debug("Result: {}", .{result});
}
pub fn deinit(sound: *SoundOutput) void {}
pub fn fillBuffer(sound: *SoundOutput, samples: []f32) void {}
