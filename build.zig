const std = @import("std");
const builtin = @import("builtin");

const Builder = std.build.Builder;
const CrossTarget = std.zig.CrossTarget;
const BuildMode = builtin.Mode;
const LibExeObjStep = std.build.LibExeObjStep;

const build_root = "build";

const is_windows = std.Target.current.os.tag == .windows;

pub fn buildExe(b: *Builder, target: CrossTarget, mode: BuildMode) *LibExeObjStep {
    const exe = b.addExecutable("sokol-zsnake", "src/platform_sokol.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);

    exe.addPackagePath("sokol", "src/sokol/sokol.zig");

    const cflags = [_][]const u8{"-std=c99"};

    exe.addCSourceFile("src/sokol/sokol.c", &cflags);
    exe.linkSystemLibrary("c");


    if (is_windows) {
        exe.linkSystemLibrary("user32");
        exe.linkSystemLibrary("gdi32");
    }

    return exe;
}

pub fn buildDylib(b: *Builder, target: CrossTarget, mode: BuildMode) *LibExeObjStep  {
        const dll = b.addSharedLibrary("game", "src/game.zig", b.version(0, 0, 1));
        dll.setTarget(target);
        dll.setBuildMode(mode);
        dll.setOutputDir(build_root);
        return dll;
}

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const exe = buildExe(b, target, mode);
    exe.install();

    const dll = buildDylib(b, target, mode);

    const all_step = b.step("all", "Build the Game DLL and Platform EXE");
    all_step.dependOn(&dll.step);
    all_step.dependOn(&exe.step);

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const dll_only_step = b.step("dll", "Build just the Game DLL");
    dll_only_step.dependOn(&dll.step);
}
