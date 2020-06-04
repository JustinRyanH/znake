const std = @import("std");
const Builder = std.build.Builder;
const BuildExe = *std.build.LibExeObjStep;

pub fn build(b: *Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    var exe: BuildExe = undefined;
    if (target.isWindows() and target.getAbi() == .msvc) {
        exe = b.addExecutable("zpong", "src/win32_platform.zig");
        exe.setTarget(target);
        exe.setBuildMode(mode);

        exe.linkSystemLibrary("c");
        exe.linkSystemLibrary("gdi32");
        exe.linkSystemLibrary("user32");
        exe.linkSystemLibrary("ole32");
    } else {
        @panic("Unimplemented Platform");
    }

    exe.install();
    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
