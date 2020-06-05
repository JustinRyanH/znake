const std = @import("std");
const windows = std.os.windows;
const win32 = @import("win32.zig");
const wasapi = @import("wasapi.zig");
const DynLib = std.DynLib;

pub const REFTIMES_PER_SEC = 10000000;
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
    const request_sound_duration = REFTIMES_PER_SEC * 2;
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

    const samples_per_second = 48000;
    const format = wasapi.WaveFormat.PCM;
    const channels = 2;
    const bits_per_sample = 16;
    const block_align = 4;
    const average_bytes_per_second = 192000;
    const cb_size = 0;

    var wave_format = wasapi.WAVEFORMATEX{
        .wFormatTag = @enumToInt(format),
        .nChannels = channels,
        .nSamplesPerSec = samples_per_second,
        .nAvgBytesPerSec = average_bytes_per_second,
        .nBlockAlign = block_align,
        .wBitsPerSample = bits_per_sample,
        .cbSize = 0,
    };

    if (audio_client.lpVtbl.*.Initialize) |initialize| {
        result = initialize(
            audio_client,
            wasapi.AUDCLNT_SHAREMODE.AUDCLNT_SHAREMODE_SHARED,
            wasapi.AUDCLNT_STREAMFLAGS_RATEADJUST | wasapi.AUDCLNT_STREAMFLAGS_AUTOCONVERTPCM | wasapi.AUDCLNT_STREAMFLAGS_SRC_DEFAULT_QUALITY,
            request_sound_duration,
            0,
            &wave_format,
            0,
        );
        if (result != 0) {
            return SoundError.GenericError;
        }
    }

    return SoundOutput{};
}
pub fn deinit(sound: *SoundOutput) void {}
pub fn fillBuffer(sound: *SoundOutput, samples: []f32) void {}
