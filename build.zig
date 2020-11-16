const std = @import("std");
const builtin = @import("builtin");

const Builder = std.build.Builder;
const CrossTarget = std.zig.CrossTarget;
const BuildMode = builtin.Mode;
const LibExeObjStep = std.build.LibExeObjStep;


const is_windows = std.Target.current.os.tag == .windows;

pub fn buildExe(b: *Builder, target: CrossTarget, mode: BuildMode) *LibExeObjStep {
    const exe = b.addExecutable("sokol-zsnake", "src/platform_sokol.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.addPackagePath("sokol", "src/sokol/sokol.zig");
    exe.addCSourceFile("src/sokol/sokol.c", &[_][]const u8{"-std=c99"});
    exe.linkSystemLibrary("c");
    return exe;
}

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const exe = buildExe(b, target, mode);
    exe.install();

    const cflags = [_][]const u8{"-std=c99"};

    if (is_windows) {
        exe.linkSystemLibrary("user32");
        exe.linkSystemLibrary("gdi32");
    }

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
