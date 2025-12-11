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

// TAOCP: Selection algorithm - find k-th smallest element in 3-element set
fn kthSmallest(dim: Dimensions, k: u8) u64 {
    // Create array and sort once
    var dimensions = [_]u64{ dim.l, dim.w, dim.h };
    std.mem.sort(u64, &dimensions, {}, comptime std.sort.asc(u64));

    // k is 1-based (k=1 for smallest, k=2 for second smallest)
    if (k >= 1 and k <= 3) {
        return dimensions[k - 1];
    }
    return dimensions[0]; // fallback to smallest
}

// TAOCP: Geometric calculations - smallest perimeter using 2 smallest dimensions
fn smallestPerimeter(dim: Dimensions) u64 {
    const smallest = kthSmallest(dim, 1);
    const second_smallest = kthSmallest(dim, 2);

    // Perimeter of smallest face: 2 * (smallest + second_smallest)
    return 2 * (smallest + second_smallest);
}

// TAOCP: Volume calculation for bow ribbon
fn volume(dim: Dimensions) u64 {
    return dim.l * dim.w * dim.h;
}

// TAOCP: Total ribbon calculation - wrap + bow
fn ribbonNeeded(dim: Dimensions) u64 {
    const wrap_ribbon = smallestPerimeter(dim);
    const bow_ribbon = volume(dim);
    return wrap_ribbon + bow_ribbon;
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
    // TAOCP: Single-pass streaming algorithm - O(1) additional space
    var total: u64 = 0;
    var valid_lines: u32 = 0;

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');

    while (line_iter.next()) |line| {
        // Skip empty lines
        if (line.len == 0) continue;

        // Parse dimensions and calculate ribbon needed
        const dim = parseDimensions(line) catch |err| switch (err) {
            error.EmptyLine => continue,
            error.InvalidFormat => continue,
            else => return err,
        };

        total += ribbonNeeded(dim);
        valid_lines += 1;
    }

    if (valid_lines == 0) return error.NoValidDimensions;

    // Convert result to string for output
    const gpa = std.heap.page_allocator;
    const result = try std.fmt.allocPrint(gpa, "{}", .{total});
    return result;
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

// Test with sample input - expected answer is 48 (34 + 14)
test "part2 sample input" {
    const sample_input =
        \\2x3x4
        \\1x1x10
    ;
    const result = try part2(sample_input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("48", result.?);
}

// Test individual examples
test "part2 single box 2x3x4" {
    const sample_input = "2x3x4";
    const result = try part2(sample_input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("34", result.?);
}

test "part2 single box 1x1x10" {
    const sample_input = "1x1x10";
    const result = try part2(sample_input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("14", result.?);
}

// Test different input formats for Part 2
test "part2 pipe format" {
    const sample_input =
        \\00001| 2x3x4
        \\00002| 1x1x10
    ;
    const result = try part2(sample_input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("48", result.?);
}

test "part2 numbered format" {
    const sample_input =
        \\1 2x3x4
        \\2 1x1x10
    ;
    const result = try part2(sample_input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("48", result.?);
}

// Test edge cases for Part 2
test "part2 empty lines" {
    const sample_input =
        \\2x3x4
        \\
        \\1x1x10
        \\
    ;
    const result = try part2(sample_input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("48", result.?);
}

test "part2 malformed lines" {
    const sample_input =
        \\2x3x4
        \\invalid
        \\1x1x10
        \\malformed
    ;
    const result = try part2(sample_input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("48", result.?);
}

// Test k-th smallest function
test "kthSmallest function" {
    const dim = Dimensions{ .l = 5, .w = 2, .h = 8 };
    try std.testing.expectEqual(@as(u64, 2), kthSmallest(dim, 1)); // smallest
    try std.testing.expectEqual(@as(u64, 5), kthSmallest(dim, 2)); // second smallest
    try std.testing.expectEqual(@as(u64, 8), kthSmallest(dim, 3)); // largest
}

// Test smallest perimeter function
test "smallestPerimeter function" {
    const dim1 = Dimensions{ .l = 2, .w = 3, .h = 4 };
    try std.testing.expectEqual(@as(u64, 10), smallestPerimeter(dim1)); // 2+2+3+3 = 10

    const dim2 = Dimensions{ .l = 1, .w = 1, .h = 10 };
    try std.testing.expectEqual(@as(u64, 4), smallestPerimeter(dim2)); // 1+1+1+1 = 4
}

// Test volume function
test "volume function" {
    const dim1 = Dimensions{ .l = 2, .w = 3, .h = 4 };
    try std.testing.expectEqual(@as(u64, 24), volume(dim1)); // 2*3*4 = 24

    const dim2 = Dimensions{ .l = 1, .w = 1, .h = 10 };
    try std.testing.expectEqual(@as(u64, 10), volume(dim2)); // 1*1*10 = 10
}

// Test ribbon needed function
test "ribbonNeeded function" {
    const dim1 = Dimensions{ .l = 2, .w = 3, .h = 4 };
    try std.testing.expectEqual(@as(u64, 34), ribbonNeeded(dim1)); // wrap 10 + bow 24 = 34

    const dim2 = Dimensions{ .l = 1, .w = 1, .h = 10 };
    try std.testing.expectEqual(@as(u64, 14), ribbonNeeded(dim2)); // wrap 4 + bow 10 = 14
}
