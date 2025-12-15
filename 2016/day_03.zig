const std = @import("std");
const Allocator = std.mem.Allocator;

// TAOCP: Triangle data structure for geometric validation
const Triangle = struct { a: u32, b: u32, c: u32 };

// TAOCP: Triangle inequality theorem - sum of any two sides must exceed the third
fn isValidTriangle(a: u32, b: u32, c: u32) bool {
    return a + b > c and a + c > b and b + c > a;
}

// TAOCP: Robust input parsing with error handling for malformed data
fn parseLine(line: []const u8) !Triangle {
    var numbers = std.mem.tokenizeScalar(u8, std.mem.trim(u8, line, " \t\r\n"), ' ');

    const a_str = numbers.next() orelse return error.MissingNumber;
    const b_str = numbers.next() orelse return error.MissingNumber;
    const c_str = numbers.next() orelse return error.MissingNumber;

    const a = try std.fmt.parseInt(u32, a_str, 10);
    const b = try std.fmt.parseInt(u32, b_str, 10);
    const c = try std.fmt.parseInt(u32, c_str, 10);

    return Triangle{ .a = a, .b = b, .c = c };
}

// TAOCP: Single-pass algorithm with O(1) additional space
fn countValidTrianglesHorizontal(input: []const u8) !usize {
    var valid_count: usize = 0;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    while (lines.next()) |line| {
        if (line.len == 0) continue; // Skip empty lines

        const triangle = parseLine(line) catch |err| {
            std.log.warn("Failed to parse line '{s}': {}", .{ line, err });
            continue;
        };

        if (isValidTriangle(triangle.a, triangle.b, triangle.c)) {
            valid_count += 1;
        }
    }

    return valid_count;
}

// TAOCP: Multi-pass algorithm with 2D array processing for vertical analysis
fn countValidTrianglesVertical(input: []const u8) !usize {
    const allocator = std.heap.page_allocator;

    // First pass: Count lines to allocate exact size
    var line_count: usize = 0;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len > 0) line_count += 1;
    }

    // Allocate array of triangles
    const triangles = try allocator.alloc(Triangle, line_count);
    defer allocator.free(triangles);

    // Second pass: Parse all triangles into array
    var i: usize = 0;
    lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;

        const triangle = parseLine(line) catch |err| {
            std.log.warn("Failed to parse line '{s}': {}", .{ line, err });
            continue;
        };

        triangles[i] = triangle;
        i += 1;
    }

    // Third pass: Process vertical triangles in groups of 3 rows
    var valid_count: usize = 0;
    var row_idx: usize = 0;
    while (row_idx + 2 < triangles.len) : (row_idx += 3) {
        // Process first column
        if (isValidTriangle(triangles[row_idx].a, triangles[row_idx + 1].a, triangles[row_idx + 2].a)) {
            valid_count += 1;
        }

        // Process second column
        if (isValidTriangle(triangles[row_idx].b, triangles[row_idx + 1].b, triangles[row_idx + 2].b)) {
            valid_count += 1;
        }

        // Process third column
        if (isValidTriangle(triangles[row_idx].c, triangles[row_idx + 1].c, triangles[row_idx + 2].c)) {
            valid_count += 1;
        }
    }

    return valid_count;
}

pub fn part1(input: []const u8) !?[]const u8 {
    const valid_count = try countValidTrianglesHorizontal(input);

    const gpa = std.heap.page_allocator;
    const result = try std.fmt.allocPrint(gpa, "{}", .{valid_count});
    return result;
}

pub fn part2(input: []const u8) !?[]const u8 {
    const valid_count = try countValidTrianglesVertical(input);

    const gpa = std.heap.page_allocator;
    const result = try std.fmt.allocPrint(gpa, "{}", .{valid_count});
    return result;
}

// Test core triangle validation function
test "isValidTriangle function" {
    // Valid triangles
    try std.testing.expect(isValidTriangle(3, 4, 5));
    try std.testing.expect(isValidTriangle(5, 10, 14));
    try std.testing.expect(isValidTriangle(1, 1, 1));

    // Invalid triangles
    try std.testing.expect(!isValidTriangle(5, 10, 25));
    try std.testing.expect(!isValidTriangle(1, 2, 3));
    try std.testing.expect(!isValidTriangle(0, 1, 1));
}

// Test line parsing function
test "parseLine function" {
    const triangle1 = try parseLine("3 4 5");
    try std.testing.expectEqual(@as(u32, 3), triangle1.a);
    try std.testing.expectEqual(@as(u32, 4), triangle1.b);
    try std.testing.expectEqual(@as(u32, 5), triangle1.c);

    const triangle2 = try parseLine("  827  272  126  ");
    try std.testing.expectEqual(@as(u32, 827), triangle2.a);
    try std.testing.expectEqual(@as(u32, 272), triangle2.b);
    try std.testing.expectEqual(@as(u32, 126), triangle2.c);
}

// Test parsing errors
test "parseLine errors" {
    try std.testing.expectError(error.MissingNumber, parseLine(""));
    try std.testing.expectError(error.MissingNumber, parseLine("3 4"));
    try std.testing.expectError(error.InvalidCharacter, parseLine("3 a 5"));
}

// Test horizontal triangle counting
test "countValidTrianglesHorizontal" {
    const input1 = "3 4 5\n5 10 25\n6 6 6";
    const count1 = try countValidTrianglesHorizontal(input1);
    try std.testing.expectEqual(@as(usize, 2), count1);

    const input2 = "1 1 1\n2 2 3\n5 5 5";
    const count2 = try countValidTrianglesHorizontal(input2);
    try std.testing.expectEqual(@as(usize, 3), count2);

    // Test with empty lines
    const input3 = "3 4 5\n\n5 10 25\n";
    const count3 = try countValidTrianglesHorizontal(input3);
    try std.testing.expectEqual(@as(usize, 1), count3);
}

// Test vertical triangle counting
test "countValidTrianglesVertical" {
    const input =
        \\3 4 5
        \\6 7 8
        \\9 10 11
        \\1 1 1
        \\2 2 2
        \\3 3 3
    ;

    const count = try countValidTrianglesVertical(input);

    // First group of 3 rows (triangles: 3-6-9, 4-7-10, 5-8-11)
    // Only 3-6-9 and 4-7-10 are valid, 5-8-11 is not (5+8=13 which is not > 11)
    // Second group of 3 rows (triangles: 1-2-3, 1-2-3, 1-2-3)
    // Only 1-2-3 is invalid (1+2=3 is not > 3)
    try std.testing.expectEqual(@as(usize, 2), count);
}

// Test part1 with sample input
test "part1 example" {
    const input = "3 4 5\n5 10 25";
    const result = try part1(input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("1", result.?);
}

// Test part2 with sample input
test "part2 example" {
    const input =
        \\3 4 5
        \\6 7 8
        \\9 10 11
    ;
    const result = try part2(input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("2", result.?); // Only 3-6-9 and 4-7-10 are valid
}

// Test edge cases
test "edge cases" {
    // Minimum valid triangle
    try std.testing.expect(isValidTriangle(1, 1, 1));

    // Large valid triangle
    try std.testing.expect(isValidTriangle(1000, 1001, 1999));

    // Edge case where sum equals third side (invalid)
    try std.testing.expect(!isValidTriangle(1, 2, 3));

    // Single digit triangle
    try std.testing.expect(isValidTriangle(2, 2, 3));
}

// Test with actual input format from file
test "actual input format" {
    const input =
        \\  541  588  421
        \\  827  272  126
        \\  660  514  367
    ;

    // Should parse correctly despite leading spaces
    const count_h = try countValidTrianglesHorizontal(input);
    try std.testing.expectEqual(@as(usize, 2), count_h); // 541-588-421 and 660-514-367 are valid

    const count_v = try countValidTrianglesVertical(input);
    try std.testing.expectEqual(@as(usize, 3), count_v); // 541-827-660, 588-272-514, and 421-126-367 are valid
}
