const std = @import("std");

pub fn main() !void {
    const one_second = std.time.ns_per_s;
    std.time.sleep(one_second);
    std.debug.print("Slept for 1 second\n", .{});
}
