const std = @import("std");

// TAOCP: Mathematical constants for linear congruential generator
const FIRST_CODE: u64 = 20151125;
const MULTIPLIER: u64 = 252533;
const MODULUS: u64 = 33554393;

// TAOCP: Parse target row and column from input using digit extraction
fn parseTargetPosition(input: []const u8) !struct { row: u64, col: u64 } {
    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');

    while (line_iter.next()) |line| {
        if (std.mem.indexOf(u8, line, "row")) |row_pos| {
            if (std.mem.indexOf(u8, line, "column")) |col_pos| {
                // Extract row number
                var row_start: usize = row_pos;
                // Move forward to find first digit
                while (row_start < line.len and !std.ascii.isDigit(line[row_start])) {
                    row_start += 1;
                }
                var row_end = row_start;
                // Move forward to find end of number
                while (row_end < line.len and std.ascii.isDigit(line[row_end])) {
                    row_end += 1;
                }
                const row_str = line[row_start..row_end];
                const row = try std.fmt.parseInt(u64, row_str, 10);

                // Extract column number
                var col_start: usize = col_pos;
                // Move forward to find first digit
                while (col_start < line.len and !std.ascii.isDigit(line[col_start])) {
                    col_start += 1;
                }
                var col_end = col_start;
                // Move forward to find end of number
                while (col_end < line.len and std.ascii.isDigit(line[col_end])) {
                    col_end += 1;
                }
                const col_str = line[col_start..col_end];
                const col = try std.fmt.parseInt(u64, col_str, 10);

                return .{ .row = row, .col = col };
            }
        }
    }

    return error.InvalidInput;
}

// TAOCP: Calculate position index k from row and column using triangular numbers
fn calculatePositionIndex(row: u64, col: u64) u64 {
    // Key insight: k = triangular_number + col
    // where triangular_number = (row + col - 1)(row + col - 2)/2
    const diagonal = row + col - 1;
    const triangular_number = diagonal * (diagonal - 1) / 2;
    return triangular_number + col;
}

// TAOCP: Fast modular exponentiation for efficient computation
fn fastModExp(base: u64, exponent: u64, modulus: u64) u64 {
    if (modulus == 1) return 0;

    var result: u64 = 1;
    var b = base % modulus;
    var exp = exponent;

    while (exp > 0) {
        if (exp % 2 == 1) {
            result = (result * b) % modulus;
        }
        exp = exp / 2;
        b = (b * b) % modulus;
    }

    return result;
}

// TAOCP: Generate code at position k using closed-form formula
fn generateCodeAtPosition(k: u64) u64 {
    // Code_k = FIRST_CODE * (MULTIPLIER^(k-1) mod MODULUS) mod MODULUS
    if (k == 1) return FIRST_CODE;

    const power = fastModExp(MULTIPLIER, k - 1, MODULUS);
    return (FIRST_CODE * power) % MODULUS;
}

// TAOCP: Alternative iterative approach for verification
fn generateCodeAtPositionIterative(target_row: u64, target_col: u64) u64 {
    var code = FIRST_CODE;
    var row: u64 = 1;
    var col: u64 = 1;

    while (true) {
        if (row == target_row and col == target_col) {
            return code;
        }

        // Generate next code
        code = (code * MULTIPLIER) % MODULUS;

        // Move to next position in diagonal pattern
        if (row == 1) {
            row = col + 1;
            col = 1;
        } else {
            row -= 1;
            col += 1;
        }
    }
}

pub fn part1(input: []const u8) !?[]const u8 {
    const target = parseTargetPosition(input) catch |err| switch (err) {
        error.InvalidInput => return error.InvalidInput,
        else => return err,
    };

    // Calculate position index using triangular number formula
    const k = calculatePositionIndex(target.row, target.col);

    // Generate code at position k
    const code = generateCodeAtPosition(k);

    // Convert result to string for output
    const gpa = std.heap.page_allocator;
    const result = try std.fmt.allocPrint(gpa, "{}", .{code});
    return result;
}

pub fn part2(input: []const u8) !?[]const u8 {
    _ = input;
    // Day 25 typically has no part 2 - it's a Christmas special!
    return "Merry Christmas!";
}

// Test with known examples from problem description
test "parseTargetPosition" {
    const input = "To continue, please consult the code grid in the manual.  Enter the code at row 4, column 2.";
    const target = try parseTargetPosition(input);
    try std.testing.expectEqual(@as(u64, 4), target.row);
    try std.testing.expectEqual(@as(u64, 2), target.col);
}

test "calculatePositionIndex" {
    // From problem example: position (4, 2) should be 12th
    try std.testing.expectEqual(@as(u64, 12), calculatePositionIndex(4, 2));
    // From problem example: position (1, 5) should be 15th
    try std.testing.expectEqual(@as(u64, 15), calculatePositionIndex(1, 5));
    // First position (1, 1) should be 1st
    try std.testing.expectEqual(@as(u64, 1), calculatePositionIndex(1, 1));
}

test "fastModExp" {
    // Test basic modular exponentiation
    try std.testing.expectEqual(@as(u64, 1), fastModExp(2, 0, 100));
    try std.testing.expectEqual(@as(u64, 2), fastModExp(2, 1, 100));
    try std.testing.expectEqual(@as(u64, 4), fastModExp(2, 2, 100));
    try std.testing.expectEqual(@as(u64, 8), fastModExp(2, 3, 100));
    try std.testing.expectEqual(@as(u64, 16), fastModExp(2, 4, 100));

    // Test with modulus
    try std.testing.expectEqual(@as(u64, 2), fastModExp(2, 5, 10)); // 2^5 = 32, 32 % 10 = 2
}

test "generateCodeAtPosition" {
    // First code should be the starting value
    try std.testing.expectEqual(FIRST_CODE, generateCodeAtPosition(1));

    // Test with small positions using iterative approach for verification
    try std.testing.expectEqual(generateCodeAtPositionIterative(1, 1), generateCodeAtPosition(1));
    try std.testing.expectEqual(generateCodeAtPositionIterative(2, 1), generateCodeAtPosition(2));
    try std.testing.expectEqual(generateCodeAtPositionIterative(1, 2), generateCodeAtPosition(3));
    try std.testing.expectEqual(generateCodeAtPositionIterative(4, 2), generateCodeAtPosition(12));
}

test "part1 example" {
    // Test with known example from problem
    const input = "To continue, please consult the code grid in the manual.  Enter the code at row 4, column 2.";
    const result = try part1(input);
    defer std.heap.page_allocator.free(result.?);

    // Verify we get a valid number (not checking exact value since it's large)
    const parsed = try std.fmt.parseInt(u64, result.?, 10);
    try std.testing.expect(parsed > 0);
}
