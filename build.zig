const std = @import("std");
const Builder = std.build.Builder;
const BuildExe = *std.build.LibExeObjStep;

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    var exe: BuildExe = undefined;
    var dll: BuildExe = undefined;
    if (target.isWindows() and target.getAbi() == .msvc) {
        dll = b.addSharedLibrary("game", "src/pong.zig", b.version(0, 0, 1));
        dll.setTarget(target);
        dll.setBuildMode(mode);

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

    dll.install();
    exe.install();
    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
