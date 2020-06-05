const std = @import("std");
const windows = std.os.windows;
const win32 = @import("win32.zig");
const wasapi = @import("wasapi.zig");
const DynLib = std.DynLib;

pub extern "ole32" fn CoCreateInstance(wasapi.REFCLSID, ?*wasapi.IUnknown, windows.DWORD, wasapi.REFIID, [*c]windows.LPVOID) callconv(.C) windows.HRESULT;
pub extern "ole32" fn CoInitializeEx(?windows.LPVOID, windows.COINIT) callconv(.C) windows.HRESULT;
pub extern "kernel32" fn LoadLibraryA([*:0]const u8) ?HMODULE;
pub const SoundError = error{GenericError};

pub const SoundOutput = struct {
    initialized: bool = false,
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

pub fn init() SoundError!SoundOutput {
    var device_enum: *wasapi.IMMDeviceEnumerator = undefined;
    var device: *wasapi.IMMDevice = undefined;
    var audio_client: *wasapi.IAudioClient = undefined;
    var audio_render_client: *wasapi.IAudioRenderClient = undefined;

    _ = CoInitializeEx(null, windows.COINIT.COINIT_SPEED_OVER_MEMORY);
    var result: windows.HRESULT = undefined;
    result = CoCreateInstance(&wasapi.CLSID_MMDeviceEnumerator, null, wasapi.CLSCTX_ALL, &wasapi.IID_IMMDeviceEnumerator, @ptrCast(*windows.LPVOID, &device_enum));
    if (result != 0) {
        return SoundError.GenericError;
    }
    errdefer {
        if (device_enum.lpVtbl.*.Release) |release| {
            _ = release(device_enum);
        }
    }

    if (device_enum.lpVtbl.*.GetDefaultAudioEndpoint) |default_audio_endpoint| {
        var tmp: ?*wasapi.IMMDevice = undefined;
        result = default_audio_endpoint(
            device_enum,
            wasapi.EDataFlow.eRender,
            wasapi.ERole.eConsole,
            &tmp,
        );
        if (result != 0) {
            return SoundError.GenericError;
        }
        if (tmp) |d| {
            device = d;
        } else {
            return SoundError.GenericError;
        }
    }
    errdefer {
        if (device.lpVtbl.*.Release) |release| {
            _ = release(device);
        }
    }

    if (device.lpVtbl.*.Activate) |activate| {
        var tmp_client: ?*wasapi.IAudioClient = undefined;
        result = activate(device, &wasapi.IID_IAudioClient, wasapi.CLSCTX_ALL, 0, @ptrCast([*c]?*c_void, &tmp_client));
        if (result != 0) {
            return SoundError.GenericError;
        }
        if (tmp_client) |client| {
            audio_client = client;
        }
    }
    errdefer {
        if (audio_client.lpVtbl.*.Release) |release| {
            _ = release(audio_client);
        }
    }

    return SoundOutput{};
}
pub fn deinit(sound: *SoundOutput) void {}
pub fn fillBuffer(sound: *SoundOutput, samples: []f32) void {}
