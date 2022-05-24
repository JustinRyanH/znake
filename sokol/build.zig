const std = @import("std");
const sokol = @import("lib/sokol-zig/build.zig");
const zigEcs = @import("lib/zig-ecs/build.zig");
const zigNuklear = @import("/lib/zig-nuklear/build.zig");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();
    const nuklear = zigNuklear.init(b, .{});

    const sokol_build = sokol.buildSokol(b, target, mode, "lib/sokol-zig/");

    const exe = b.addExecutable("znake", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.addPackagePath("sokol", "lib/sokol-zig/src/sokol/sokol.zig");
    exe.addPackage(zigEcs.getPackage("lib/zig-ecs/"));
    nuklear.addTo(exe, .{});
    exe.linkLibrary(sokol_build);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/test.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
