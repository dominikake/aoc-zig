const std = @import("std");
pub fn main() !void {
    const input = "year=2025, day=1, part=1; Process sequential instructions";
    var parts = std.mem.splitSequence(u8, input, ";");
    const params_part = parts.next() orelse {
        std.debug.print("ERROR: No semicolon found\n", .{});
        return error.InvalidFormat;
    };
    const concept_part = parts.rest();
    std.debug.print("SUCCESS: Found semicolon, params={s}, concept={s}\n", .{ params_part, concept_part });
}
