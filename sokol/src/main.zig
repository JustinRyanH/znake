const std = @import("std");

const sg = @import("sokol").gfx;
const sapp = @import("sokol").app;
const stime = @import("sokol").time;
const sgapp = @import("sokol").app_gfx_glue;
const nk = @import("nuklear");

const Game = @import("game.zig");
const RendererVals = @import("renderer_vals.zig");
const SimpleRenderer = @import("simple_renderer.zig");
const GameInput = @import("./input.zig");

var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
var prng = std.rand.DefaultPrng.init(0);

const gpa = general_purpose_allocator.allocator();
const global_random = prng.random();

const CANVAS_SIZE = Game.CANVAS_SIZE;

pub const Color = sg.Color;

const FixedFrameRate = struct {
    const FRAMES_PER_SECOND = 30.0;
    next_update_state: f64 = 0.0,
    tick_frame: bool = false,

    pub fn shouldTick(self: *FixedFrameRate, time: f64) bool {
        if (time > self.next_update_state) {
            self.next_update_state = time + (1.0 / FRAMES_PER_SECOND);
            self.tick_frame = true;
            return true;
        } else {
            self.tick_frame = false;
            return false;
        }
    }
};

const TitleBarSize = 2;
const StepStride = 10;

const SnakeSize = Game.SNAKE_SIZE;
const WorldWidth = CANVAS_SIZE / SnakeSize;
const WorldHeight = (CANVAS_SIZE - TitleBarSize) / SnakeSize;
const SnakeSizeHalf = SnakeSize / 2;
const TopBarSize = SnakeSize * TitleBarSize;

const SnakeYMin = TitleBarSize;
const SnakeYMax = WorldHeight;
const SnakeXMin = 0;
const SnakeXMax = WorldWidth;

pub const SimpleSokolRenderer = @import("./simple_sokol_renderer.zig");

var renderer: *SimpleSokolRenderer = undefined;
var atlas: nk.FontAtlas = undefined;
var nk_ctx: nk.Context = undefined;
var nk_cmds: nk.Buffer = undefined;
var nk_vbuf: nk.Buffer = undefined;
var nk_ebuf: nk.Buffer = undefined;
var game: *Game.State = undefined;
var frame_rate: FixedFrameRate = .{};
var input: GameInput = .{};
var input_manager: InputManager = undefined;

pub const InputManager = struct {
    file: std.fs.File,
};

pub const InputStream = packed struct {
    frame: usize,
    input: u8,
};

fn uploadAtlas(data: [*]const u8, w: usize, h: usize) sg.Image {
    var img_desc = sg.ImageDesc{
        .width = @intCast(i32, w),
        .height = @intCast(i32, h),
        .min_filter = .LINEAR,
        .mag_filter = .LINEAR,
        .pixel_format = .RGBA8,
    };

    img_desc.data.subimage[0][0] = sg.asRange(data[0..(w * h * 4)]);
    return sg.makeImage(img_desc);
}

fn setupInputRecording() void {
    var all_together: [100]u8 = undefined;
    const all_together_slice = all_together[0..];
    const file_path = std.fmt.bufPrint(all_together_slice, "znake-{}.input", .{std.time.timestamp()}) catch @panic("Failed to create File name");
    var file = std.fs.cwd().createFile(file_path, .{ .read = true }) catch @panic("Failed to Create write file");
    input_manager = .{ .file = file };
}

export fn init() void {
    // setupInputRecording();
    sg.setup(.{
        .context = sgapp.context(),
    });
    stime.setup();
    atlas = nk.atlas.init(&gpa);

    nk.atlas.begin(&atlas);
    const baked = nk.atlas.bake(&atlas, .rgba32) catch @panic("Failed to Create Nuklear Font Atlas");
    const img = uploadAtlas(baked.data, baked.w, baked.h);
    var _null: nk.DrawNullTexture = undefined;
    nk.atlas.end(
        &atlas,
        nk.rest.nkHandleId(@intCast(c_int, img.id)),
        &_null,
    );

    nk_ctx = nk.init(&gpa, &atlas.default_font.*.handle);
    nk_cmds = nk.Buffer.init(&gpa, std.mem.page_size);
    nk_vbuf = nk.Buffer.init(&gpa, std.mem.page_size);
    nk_ebuf = nk.Buffer.init(&gpa, std.mem.page_size);

    renderer = SimpleSokolRenderer.init(gpa, CANVAS_SIZE) catch @panic("Failed to Create Renderer");

    game = Game.State.allocAndInit(gpa, .{
        .y_min = SnakeYMin,
        .y_max = SnakeYMax,
        .x_min = SnakeXMin,
        .x_max = SnakeXMax,
        .step_stride = 5,
        .random = global_random,
    });

    game.registery.singletons().add(Game.FrameInput{});
}

fn recordInput(frame_input: *Game.FrameInput) void {
    const input_stuff = InputStream{
        .frame = frame_input.frame + 1,
        .input = frame_input.input.frame,
    };

    const input_as_bytes = std.mem.asBytes(&input_stuff);
    _ = input_manager.file.write(input_as_bytes) catch @panic("Cannot write Input data");
}

export fn frame() void {
    nk.input.end(&nk_ctx);
    const time = stime.now();
    var simple_renderer = renderer.simpleRenderer();

    const should_update = frame_rate.shouldTick(stime.sec(time));
    if (should_update) {
        var frame_input = game.registery.singletons().get(Game.FrameInput);
        // recordInput(frame_input);

        game.update(&input, &simple_renderer);
        if (game.registery.singletons().getConst(Game.SnakeGame).events.shouldReseed()) {
            prng.seed(frame_input.frame);
        }

        renderer.updateImage();
    }
    renderer.draw();
}

export fn sokol_input(event: ?*const sapp.Event) void {
    const ev = event.?;
    nk.input.begin(&nk_ctx);
    switch (ev.type) {
        .KEY_DOWN, .KEY_UP => {
            const key_down = ev.type == .KEY_DOWN;
            switch (ev.key_code) {
                .DELETE => nk.input.key(&nk_ctx, .del, key_down),
                .ENTER => nk.input.key(&nk_ctx, .enter, key_down),
                .TAB => nk.input.key(&nk_ctx, .tab, key_down),
                .UP => nk.input.key(&nk_ctx, .up, key_down),
                .DOWN => nk.input.key(&nk_ctx, .down, key_down),
                else => {},
            }
        },
        .MOUSE_MOVE => {
            nk.input.motion(&nk_ctx, @floatToInt(c_int, ev.mouse_x), @floatToInt(c_int, ev.mouse_y));
        },
        .MOUSE_DOWN, .MOUSE_UP => {
            const mouse_down = ev.type == .MOUSE_DOWN;
            const x = @floatToInt(c_int, ev.mouse_x);
            const y = @floatToInt(c_int, ev.mouse_y);
            switch (ev.mouse_button) {
                .LEFT => nk.input.button(&nk_ctx, .left, x, y, mouse_down),
                .RIGHT => nk.input.button(&nk_ctx, .right, x, y, mouse_down),
                .MIDDLE => nk.input.button(&nk_ctx, .middle, x, y, mouse_down),
                else => {},
            }
        },
        else => {},
    }
    switch (ev.type) {
        .KEY_DOWN, .KEY_UP => {
            const key_down = ev.type == .KEY_DOWN;
            switch (ev.key_code) {
                .LEFT => if (key_down) input.setDown(GameInput.Left) else input.setUp(GameInput.Left),
                .RIGHT => if (key_down) input.setDown(GameInput.Right) else input.setUp(GameInput.Right),
                .UP => if (key_down) input.setDown(GameInput.Up) else input.setUp(GameInput.Up),
                .DOWN => if (key_down) input.setDown(GameInput.Down) else input.setUp(GameInput.Down),
                .Z => if (key_down) input.setDown(GameInput.ButtonB) else input.setUp(GameInput.ButtonB),
                .X => if (key_down) input.setDown(GameInput.ButtonA) else input.setUp(GameInput.ButtonA),
                else => {},
            }
        },
        else => {},
    }
}

export fn cleanup() void {
    nk.atlas.clear(&atlas);
    nk.free(&nk_ctx);

    nk_cmds.free();
    nk_vbuf.free();
    nk_ebuf.free();

    input_manager.file.close();
    renderer.deinit() catch @panic("Failed to clean up renderer");
    std.debug.assert(!general_purpose_allocator.deinit());
}

pub fn main() void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .event_cb = sokol_input,
        .width = 600,
        .height = 600,
        .icon = .{
            .sokol_default = true,
        },
        .window_title = "Znake",
    });
}
