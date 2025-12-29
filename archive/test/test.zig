const std = @import("std");

const part1 = @import("2015/day_24.zig").part1;
const part2 = @import("2015/day_24.zig").part2;

pub fn main() !void {
    const input = "1\n3\n5\n11\n13\n17\n19\n23\n29\n31\n37\n41\n43\n53\n59\n61\n67\n71\n73\n79\n83\n89\n97\n101\n103\n107\n109\n113";

    if (try part1(input)) |result| {
        const expected1 = "11266889531";
        if (std.mem.eql(u8, result, expected1)) {
            std.debug.print("Part 1: PASS - {s}\n", .{result});
        } else {
            std.debug.print("Part 1: FAIL - got {s}, expected {s}\n", .{ result, expected1 });
        }
    }

    if (try part2(input)) |result| {
        std.debug.print("Part 2: result = {s}\n", .{result});

        // Convert to number for range checking
        const result_num = try std.fmt.parseInt(usize, result, 10);
        if (result_num >= 118000000 and result_num <= 130000000) {
            std.debug.print("Part 2: in expected range\n", .{});
        } else {
            std.debug.print("Part 2: outside expected range (118M-130M)\n", .{});
        }
    }
}
