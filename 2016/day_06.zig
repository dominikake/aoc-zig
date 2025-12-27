const std = @import("std");

test "part1 example" {
    const sample_input = "eedadn\ndrvtee\neandsr\nraavrd\natevrs\ntsrnev\nsdttsa\nrasrtv\nnssdts\nntnada\nsvetve\ntesnvt\nvntsnd\nvrdear\ndvrsen\nenarar\n";
    const result = try part1(sample_input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("easter", result.?);
}

test "part2 example" {
    const sample_input = "eedadn\ndrvtee\neandsr\nraavrd\natevrs\ntsrnev\nsdttsa\nrasrtv\nnssdts\nntnada\nsvetve\ntesnvt\nvntsnd\nvrdear\ndvrsen\nenarar\n";
    const result = try part2(sample_input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("advent", result.?);
}

pub fn part1(input: []const u8) !?[]const u8 {
    var lines = std.mem.splitScalar(u8, input, '\n');
    var first_line: ?[]const u8 = null;
    var message_len: usize = 0;
    var line_count: usize = 0;

    var line_buffer: [1024][]const u8 = undefined;

    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, "\r");
        if (trimmed.len == 0) continue;

        if (first_line == null) {
            first_line = trimmed;
            message_len = trimmed.len;
        }

        if (trimmed.len == message_len) {
            line_buffer[line_count] = trimmed;
            line_count += 1;
        }
    }

    if (message_len == 0) return null;

    const gpa = std.heap.page_allocator;
    var result = try gpa.alloc(u8, message_len);

    for (0..message_len) |col| {
        var counts: [26]u32 = std.mem.zeroes([26]u32);

        for (0..line_count) |row| {
            const char = line_buffer[row][col];
            if (char >= 'a' and char <= 'z') {
                const idx = char - 'a';
                counts[idx] += 1;
            }
        }

        var max_count: u32 = 0;
        var max_idx: usize = 0;

        for (0..26) |i| {
            if (counts[i] > max_count) {
                max_count = counts[i];
                max_idx = i;
            }
        }

        result[col] = 'a' + @as(u8, @intCast(max_idx));
    }

    return result;
}

pub fn part2(input: []const u8) !?[]const u8 {
    var lines = std.mem.splitScalar(u8, input, '\n');
    var first_line: ?[]const u8 = null;
    var message_len: usize = 0;
    var line_count: usize = 0;

    var line_buffer: [1024][]const u8 = undefined;

    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, "\r");
        if (trimmed.len == 0) continue;

        if (first_line == null) {
            first_line = trimmed;
            message_len = trimmed.len;
        }

        if (trimmed.len == message_len) {
            line_buffer[line_count] = trimmed;
            line_count += 1;
        }
    }

    if (message_len == 0) return null;

    const gpa = std.heap.page_allocator;
    var result = try gpa.alloc(u8, message_len);

    for (0..message_len) |col| {
        var counts: [26]u32 = std.mem.zeroes([26]u32);

        for (0..line_count) |row| {
            const char = line_buffer[row][col];
            if (char >= 'a' and char <= 'z') {
                const idx = char - 'a';
                counts[idx] += 1;
            }
        }

        var min_count: u32 = std.math.maxInt(u32);
        var min_idx: usize = 0;

        for (0..26) |i| {
            if (counts[i] > 0 and counts[i] < min_count) {
                min_count = counts[i];
                min_idx = i;
            }
        }

        result[col] = 'a' + @as(u8, @intCast(min_idx));
    }

    return result;
}
