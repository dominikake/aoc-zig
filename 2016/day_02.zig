const std = @import("std");

/// Navigate a 3x3 keypad following U/D/L/R instructions to find bathroom code
/// TAOCP Concepts: Finite state machine, 2D coordinate system, boundary checking
pub fn part1(input: []const u8) !?[]const u8 {
    const allocator = std.heap.page_allocator;

    // Count lines to allocate exact size
    var line_count: usize = 0;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |_| {
        line_count += 1;
    }

    var result = try allocator.alloc(u8, line_count);

    // Reset iterator
    lines = std.mem.tokenizeScalar(u8, input, '\n');
    var i: usize = 0;

    while (lines.next()) |line| {
        var x: usize = 1; // Start at 5 (middle of 3x3 grid)
        var y: usize = 1;

        for (line) |ch| {
            switch (ch) {
                'U' => {
                    if (y > 0) y = y - 1;
                },
                'D' => {
                    if (y < 2) y = y + 1;
                },
                'L' => {
                    if (x > 0) x = x - 1;
                },
                'R' => {
                    if (x < 2) x = x + 1;
                },
                else => unreachable,
            }
        }

        // Convert position to button number
        result[i] = '1' + @as(u8, @intCast(y * 3 + x));
        i += 1;
    }

    return result;
}

/// Navigate a diamond-shaped keypad with complex layout for enhanced bathroom security
/// TAOCP Concepts: Advanced state machine, irregular data structures, spatial reasoning
pub fn part2(input: []const u8) !?[]const u8 {
    const allocator = std.heap.page_allocator;

    // Count lines to allocate exact size
    var line_count: usize = 0;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |_| {
        line_count += 1;
    }

    var result = try allocator.alloc(u8, line_count);

    // Define the diamond-shaped keypad layout
    //  1
    // 2 3 4
    //5 6 7 8 9
    // A B C D
    //    5
    const keypad = [5][5]?u8{
        .{ null, null, '1', null, null },
        .{ null, '2', '3', '4', null },
        .{ '5', '6', '7', '8', '9' },
        .{ null, 'A', 'B', 'C', null },
        .{ null, null, 'D', null, null },
    };

    // Reset iterator
    lines = std.mem.tokenizeScalar(u8, input, '\n');
    var i: usize = 0;

    while (lines.next()) |line| {
        var x: usize = 0; // Start at '5'
        var y: usize = 2;

        for (line) |ch| {
            switch (ch) {
                'U' => {
                    if (y > 0 and keypad[y - 1][x] != null) y = y - 1;
                },
                'D' => {
                    if (y < 4 and keypad[y + 1][x] != null) y = y + 1;
                },
                'L' => {
                    if (x > 0 and keypad[y][x - 1] != null) x = x - 1;
                },
                'R' => {
                    if (x < 4 and keypad[y][x + 1] != null) x = x + 1;
                },
                else => unreachable,
            }
        }

        result[i] = keypad[y][x].?;
        i += 1;
    }

    return result;
}
