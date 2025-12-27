const std = @import("std");

// TAOCP: Run-length encoding - implement look-and-say sequence transformation
fn lookAndSay(input: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    if (input.len == 0) return "";

    var result = std.ArrayList(u8).initCapacity(allocator, 16) catch unreachable;
    defer result.deinit(allocator);

    var i: usize = 0;
    while (i < input.len) {
        const current_digit = input[i];
        var count: usize = 1;

        // Count consecutive identical digits
        while (i + count < input.len and input[i + count] == current_digit) {
            count += 1;
        }

        // Append count and digit
        const count_str = try std.fmt.allocPrint(allocator, "{}", .{count});
        defer allocator.free(count_str);
        try result.appendSlice(allocator, count_str);
        try result.append(allocator, current_digit);

        i += count;
    }

    return result.toOwnedSlice(allocator);
}

// TAOCP: Iterative transformation - apply look-and-say for N iterations
fn getSequenceLength(start: []const u8, iterations: usize, allocator: std.mem.Allocator) !usize {
    var current = try allocator.dupe(u8, start);
    defer allocator.free(current);

    var i: usize = 0;
    while (i < iterations) {
        const next = try lookAndSay(current, allocator);
        allocator.free(current);
        current = try allocator.dupe(u8, next);
        allocator.free(next);
        i += 1;
    }

    const result = current.len;
    return result;
}

pub fn part1(input: []const u8) !?[]const u8 {
    const gpa = std.heap.page_allocator;

    // TAOCP: Input parsing - handle different formats
    const trimmed = std.mem.trim(u8, input, " \r\t\n");
    if (trimmed.len == 0) return error.EmptyInput;

    // Extract sequence part if pipe format
    const sequence = blk: {
        if (std.mem.indexOfScalar(u8, trimmed, '|')) |pipe_pos| {
            if (pipe_pos + 1 >= trimmed.len) return error.InvalidFormat;
            break :blk std.mem.trim(u8, trimmed[pipe_pos + 1 ..], " \r\t\n");
        } else if (std.mem.indexOfScalar(u8, trimmed, ' ')) |space_pos| {
            // Handle numbered format: "1 1113222113"
            if (space_pos + 1 >= trimmed.len) return error.InvalidFormat;
            break :blk std.mem.trim(u8, trimmed[space_pos + 1 ..], " \r\t\n");
        } else {
            break :blk trimmed;
        }
    };

    if (sequence.len == 0) return error.EmptyInput;

    const length = try getSequenceLength(sequence, 40, gpa);
    const result = try std.fmt.allocPrint(gpa, "{}", .{length});
    return result;
}

pub fn part2(input: []const u8) !?[]const u8 {
    const gpa = std.heap.page_allocator;

    // TAOCP: Input parsing - handle different formats
    const trimmed = std.mem.trim(u8, input, " \r\t\n");
    if (trimmed.len == 0) return error.EmptyInput;

    // Extract sequence part if pipe format
    const sequence = blk: {
        if (std.mem.indexOfScalar(u8, trimmed, '|')) |pipe_pos| {
            if (pipe_pos + 1 >= trimmed.len) return error.InvalidFormat;
            break :blk std.mem.trim(u8, trimmed[pipe_pos + 1 ..], " \r\t\n");
        } else if (std.mem.indexOfScalar(u8, trimmed, ' ')) |space_pos| {
            // Handle numbered format: "1 1113222113"
            if (space_pos + 1 >= trimmed.len) return error.InvalidFormat;
            break :blk std.mem.trim(u8, trimmed[space_pos + 1 ..], " \r\t\n");
        } else {
            break :blk trimmed;
        }
    };

    if (sequence.len == 0) return error.EmptyInput;

    const length = try getSequenceLength(sequence, 50, gpa);
    const result = try std.fmt.allocPrint(gpa, "{}", .{length});
    return result;
}

// TAOCP: Test individual transformations
test "lookAndSay basic transformations" {
    const gpa = std.testing.allocator;

    // Test: 1 -> 11
    const result1 = try lookAndSay("1", gpa);
    defer gpa.free(result1);
    try std.testing.expectEqualStrings("11", result1);

    // Test: 11 -> 21
    const result2 = try lookAndSay("11", gpa);
    defer gpa.free(result2);
    try std.testing.expectEqualStrings("21", result2);

    // Test: 21 -> 1211
    const result3 = try lookAndSay("21", gpa);
    defer gpa.free(result3);
    try std.testing.expectEqualStrings("1211", result3);

    // Test: 1211 -> 111221
    const result4 = try lookAndSay("1211", gpa);
    defer gpa.free(result4);
    try std.testing.expectEqualStrings("111221", result4);

    // Test: 111221 -> 312211
    const result5 = try lookAndSay("111221", gpa);
    defer gpa.free(result5);
    try std.testing.expectEqualStrings("312211", result5);
}

// Test multiple iterations
test "getSequenceLength multiple iterations" {
    const gpa = std.testing.allocator;

    // Test 5 iterations starting from 1
    const length = try getSequenceLength("1", 5, gpa);
    try std.testing.expectEqual(@as(usize, 6), length); // 312211 has 6 digits
}

// Test edge cases
test "lookAndSay edge cases" {
    const gpa = std.testing.allocator;

    // Test empty input
    const result_empty = try lookAndSay("", gpa);
    defer gpa.free(result_empty);
    try std.testing.expectEqualStrings("", result_empty);

    // Test single digit repeated
    const result_single = try lookAndSay("1", gpa);
    defer gpa.free(result_single);
    try std.testing.expectEqualStrings("11", result_single);

    // Test mixed digits
    const result_mixed = try lookAndSay("312211", gpa);
    defer gpa.free(result_mixed);
    try std.testing.expectEqualStrings("13112221", result_mixed);
}

// Test part1 with sample input
test "part1 sample input" {
    const sample_input = "1113222113";
    const result = try part1(sample_input);
    defer std.heap.page_allocator.free(result.?);
    // We expect a valid number string result
    try std.testing.expect(result != null);
    const result_length = try std.fmt.parseInt(usize, result.?, 10);
    try std.testing.expect(result_length > 0);
}

// Test part2 with sample input
test "part2 sample input" {
    const sample_input = "1113222113";
    const result = try part2(sample_input);
    defer std.heap.page_allocator.free(result.?);
    // We expect a valid number string result
    try std.testing.expect(result != null);
    const result_length = try std.fmt.parseInt(usize, result.?, 10);
    try std.testing.expect(result_length > 0);
}

// Test different input formats
test "part1 pipe format" {
    const sample_input = "00001| 1113222113";
    const result = try part1(sample_input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expect(result != null);
    const result_length = try std.fmt.parseInt(usize, result.?, 10);
    try std.testing.expect(result_length > 0);
}

test "part1 numbered format" {
    const sample_input = "1 1113222113";
    const result = try part1(sample_input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expect(result != null);
    const result_length = try std.fmt.parseInt(usize, result.?, 10);
    try std.testing.expect(result_length > 0);
}

test "part1 empty input" {
    const sample_input = "";
    const result = part1(sample_input);
    try std.testing.expectError(error.EmptyInput, result);
}

test "part2 empty input" {
    const sample_input = "";
    const result = part2(sample_input);
    try std.testing.expectError(error.EmptyInput, result);
}
