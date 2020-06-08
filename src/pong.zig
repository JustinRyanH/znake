const std = @import("std");
const win32 = @import("win32.zig");
const assert = @import("utils.zig").assert;
usingnamespace @import("pong_types.zig");

fn debugFillBuffer(draw_buffer: *DrawBuffer, x_offset: u32, y_offset: u32) void {
    assert(draw_buffer.memory.len == draw_buffer.height * draw_buffer.pitch);
    var y_index: usize = 0;
    var pixels = std.mem.bytesAsSlice(Pixel, draw_buffer.memory);
    assert(pixels.len == draw_buffer.height * draw_buffer.width);

    while (y_index < draw_buffer.height) {
        const start = y_index * draw_buffer.width;
        const end = start + draw_buffer.width;
        for (pixels[start..end]) |*pixel, x_index| {
            pixel.*.blue = @truncate(u8, x_index + x_offset);
            pixel.*.green = @truncate(u8, y_index + y_offset);
        }
        y_index += 1;
    }
}

fn getDebugData(data: *Data) *DebugData {
    return @ptrCast(*DebugData, @alignCast(@alignOf(DebugData), data.permanent_storage[0..@sizeOf(DebugData)]));
}

export fn updateGame(input: *Input, data: *Data, draw_buffer: *DrawBuffer) void {
    var debug_data = getDebugData(data);

    if (!data.initialized) {
        data.initialized = true;
        debug_data.tone_hz = 440;
    }

    const keyboard = input.keyboard;
    if (keyboard.letter.w == .Down or keyboard.special.up_arrow == .Down) {
        debug_data.*.y_offset = debug_data.y_offset +% 25;
    } else if (keyboard.letter.s == .Down or keyboard.special.down_arrow == .Down) {
        debug_data.*.y_offset = debug_data.y_offset -% 25;
    }

    if (keyboard.letter.a == .Down or keyboard.special.up_arrow == .Down) {
        debug_data.*.x_offset = debug_data.x_offset +% 1;
    } else if (keyboard.letter.d == .Down or keyboard.special.down_arrow == .Down) {
        debug_data.*.x_offset = debug_data.x_offset -% 1;
    }
    debugFillBuffer(draw_buffer, debug_data.x_offset, debug_data.y_offset);
}

export fn updateSound(game_data: *Data, sound: *Sound) void {
    if (sound.sample_slice.len == 0) {
        return;
    }
    var debug_data = getDebugData(game_data);
    const tone_hz = debug_data.tone_hz;
    var local_sine = debug_data.sine_time;
    debug_data.wave_period = sound.samples_per_second / tone_hz;

    var index: u32 = 0;
    while (index < sound.sample_slice.len) : (index += 2) {
        const sine_value = std.math.sin(local_sine);
        sound.sample_slice[index] = @floatToInt(i16, sine_value * 3000);
        sound.sample_slice[index + 1] = @floatToInt(i16, sine_value * 3000);

        local_sine += 2.0 * std.math.pi / @intToFloat(f32, debug_data.wave_period);
    }
    local_sine = @rem(local_sine, 2.0 * std.math.pi);
    var last_one = sound.sample_slice[sound.sample_slice.len - 1];
    debug_data.sine_time = local_sine;
}
