const std = @import("std");

// TAOCP Concept: Tuple data structure for 3-dimensional geometry
const Dimensions = struct { l: u64, w: u64, h: u64 };

// TAOCP: Parsing with delimiters - extract dimensions from "l×w×h" format
fn parseDimensions(line: []const u8) !Dimensions {
    // Handle different input formats like Day 1: pipe, numbered, or basic
    var trimmed_line = std.mem.trim(u8, line, " \r\t");
    if (trimmed_line.len == 0) return error.EmptyLine;

    // Extract dimensions part if pipe format
    if (std.mem.indexOfScalar(u8, trimmed_line, '|')) |pipe_pos| {
        if (pipe_pos + 1 >= trimmed_line.len) return error.InvalidFormat;
        trimmed_line = std.mem.trim(u8, trimmed_line[pipe_pos + 1 ..], " \r\t");
        if (trimmed_line.len == 0) return error.EmptyLine;
    } else if (std.mem.indexOfScalar(u8, trimmed_line, ' ')) |space_pos| {
        // Handle numbered format: "1 2x3x4"
        if (space_pos + 1 >= trimmed_line.len) return error.InvalidFormat;
        trimmed_line = std.mem.trim(u8, trimmed_line[space_pos + 1 ..], " \r\t");
        if (trimmed_line.len == 0) return error.EmptyLine;
    }

    // Split by 'x' character
    var iter = std.mem.tokenizeScalar(u8, trimmed_line, 'x');

    const l_str = iter.next() orelse return error.InvalidFormat;
    const w_str = iter.next() orelse return error.InvalidFormat;
    const h_str = iter.next() orelse return error.InvalidFormat;

    // Parse as u64 to prevent overflow
    const l = try std.fmt.parseInt(u64, l_str, 10);
    const w = try std.fmt.parseInt(u64, w_str, 10);
    const h = try std.fmt.parseInt(u64, h_str, 10);

    return Dimensions{ .l = l, .w = w, .h = h };
}

// TAOCP: Mathematical functions - find smallest side area using min/max
fn smallestSideArea(dim: Dimensions) u64 {
    const area1 = dim.l * dim.w;
    const area2 = dim.w * dim.h;
    const area3 = dim.h * dim.l;

    // Use @min builtin for efficiency
    return @min(@min(area1, area2), area3);
}

// TAOCP: Surface area calculation for rectangular prisms
fn wrappingPaperNeeded(dim: Dimensions) u64 {
    const surface_area = 2 * dim.l * dim.w + 2 * dim.w * dim.h + 2 * dim.h * dim.l;
    const slack = smallestSideArea(dim);
    return surface_area + slack;
}

pub fn part1(input: []const u8) !?[]const u8 {
    // TAOCP: Single-pass streaming algorithm - O(1) additional space
    var total: u64 = 0;
    var valid_lines: u32 = 0;

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');

    while (line_iter.next()) |line| {
        // Skip empty lines
        if (line.len == 0) continue;

        // Parse dimensions and calculate paper needed
        const dim = parseDimensions(line) catch |err| switch (err) {
            error.EmptyLine => continue,
            error.InvalidFormat => continue,
            else => return err,
        };

        total += wrappingPaperNeeded(dim);
        valid_lines += 1;
    }

    if (valid_lines == 0) return error.NoValidDimensions;

    // Convert result to string for output
    const gpa = std.heap.page_allocator;
    const result = try std.fmt.allocPrint(gpa, "{}", .{total});
    return result;
}

pub fn part2(input: []const u8) !?[]const u8 {
    _ = input;
    // TODO: Complete part 1 first to unlock part 2
    return null;
}

// Test with sample input - expected answer is 101 (58 + 43)
test "part1 sample input" {
    const sample_input =
        \\2x3x4
        \\1x1x10
    ;
    const result = try part1(sample_input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("101", result.?);
}

// Test individual examples
test "part1 single box 2x3x4" {
    const sample_input = "2x3x4";
    const result = try part1(sample_input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("58", result.?);
}

test "part1 single box 1x1x10" {
    const sample_input = "1x1x10";
    const result = try part1(sample_input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("43", result.?);
}

// Test different input formats
test "part1 pipe format" {
    const sample_input =
        \\00001| 2x3x4
        \\00002| 1x1x10
    ;
    const result = try part1(sample_input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("101", result.?);
}

test "part1 numbered format" {
    const sample_input =
        \\1 2x3x4
        \\2 1x1x10
    ;
    const result = try part1(sample_input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("101", result.?);
}

// Test edge cases
test "part1 empty lines" {
    const sample_input =
        \\2x3x4
        \\
        \\1x1x10
        \\
    ;
    const result = try part1(sample_input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("101", result.?);
}

test "part1 malformed lines" {
    const sample_input =
        \\2x3x4
        \\invalid
        \\1x1x10
        \\malformed
    ;
    const result = try part1(sample_input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("101", result.?);
}
