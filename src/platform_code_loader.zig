const std = @import("std");
const game = @import("znake_types.zig");

pub const SokolGame = struct {
    const OpenFlags = std.fs.File.OpenFlags;
    const CopyFileOptions = std.fs.CopyFileOptions;
    const Self = @This();

    src: []const u8,
    tmp: []const u8,
    code: ?std.DynLib = null,
    update: ?game.UpdateGame = null,
    last_write_time: i128 = -1,

    pub fn load(source: []const u8, tmp: []const u8) !Self {
        var result = SokolGame{
            .src = source,
            .tmp = tmp,

        };
        try result.reload();
        return result;

    }

    pub fn unload(self: *Self) void {
        if (self.code) |*code| {
            self.update = null;
            code.close();
        }
    }

    pub fn reload(self: *Self) !void {
        self.unload();

        self.last_write_time = try getLastWrite(self.src);
        try std.fs.copyFileAbsolute(self.src, self.tmp, CopyFileOptions{});
        self.code = try std.DynLib.open(self.tmp);
        errdefer self.code.close();

        if (self.code) |*dyn_lib| {
            if (dyn_lib.lookup(game.UpdateGame, "update_game")) |update| {
                self.update = update;
            }
        }
    }

    pub fn hasChanged(self: *Self) bool {
        const new_time = getLastWrite(self.src) catch |err| {
            return false;
        };
        return self.last_write_time != new_time;
    }

    fn getLastWrite(source: []const u8) !i128 {
        const file = try std.fs.openFileAbsolute(source, OpenFlags{ .read = true, .write = false });
        defer file.close();

        const stat = try file.stat();
        return stat.mtime;
    }

};