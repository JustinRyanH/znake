const testing = @import("std").testing;

const Self = @This();
pub const ButtonA = 1;
pub const ButtonB = 2;
pub const Left = 16;
pub const Right = 32;
pub const Up = 64;
pub const Down = 128;

frame: u8 = 0,
last_frame: u8 = 0,

pub fn down(self: *const Self, button: u8) bool {
    return self.frame & button != 0;
}

pub fn up(self: *const Self, button: u8) bool {
    return !self.down(button);
}

pub fn justReleased(self: *const Self, button: u8) bool {
    const last_down = self.last_frame_down(button);
    return last_down and self.up(button);
}

pub fn justPressed(self: *const Self, button: u8) bool {
    const last_up = !self.last_frame_down(button);
    return last_up and self.down(button);
}

pub fn setDown(self: *Self, button: u8) void {
    self.frame = self.frame | button;
}
pub fn setUp(self: *Self, button: u8) void {
    self.frame = self.frame & ~button;
}

pub fn process(self: *Self, current: u8) void {
    self.frame = current;
}

pub fn swap(self: *Self) void {
    self.last_frame = self.frame;
}

fn last_frame_down(self: *const Self, button: u8) bool {
    return self.last_frame & button != 0;
}

test "Input" {
    const Input = Self;
    var input: Input = .{};
    try testing.expect(input.frame == 0);
    input.setDown(Input.Left);
    input.setDown(Input.ButtonA);
    input.setDown(Input.ButtonB);
    try testing.expect(input.down(Input.Left) == true);
    try testing.expect(input.down(Input.ButtonA) == true);
    try testing.expect(input.justPressed(Input.Left));

    input.setUp(Input.ButtonA);
    try testing.expect(input.up(Input.ButtonA) == true);
    try testing.expect(input.down(Input.Left) == true);

    input.swap();
    input.setUp(Input.Left);
    try testing.expect(input.justReleased(Input.Left) == true);
    try testing.expect(input.up(Input.Left) == true);
}
