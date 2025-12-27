const std = @import("std");

// TAOCP: String arithmetic operations - increment base-26 representation
fn incrementPassword(password: []u8) []u8 {
    var i = password.len - 1;
    while (true) {
        if (password[i] < 'z') {
            password[i] += 1;
            // Reset all characters to the right to 'a'
            for (i + 1..password.len) |j| {
                password[j] = 'a';
            }
            return password;
        } else {
            password[i] = 'a';
            if (i == 0) break; // All characters wrapped
            i -= 1;
        }
    }
    // If we get here, all characters were 'z', so wrap to all 'a's
    @memset(password, 'a');
    return password;
}

// TAOCP: Pattern matching - forbidden character detection
fn hasForbiddenLetters(password: []const u8) bool {
    for (password) |c| {
        if (c == 'i' or c == 'o' or c == 'l') return true;
    }
    return false;
}

// TAOCP: Sequential pattern detection - find increasing straight of 3 characters
fn hasIncreasingStraight(password: []const u8) bool {
    for (0..password.len - 2) |i| {
        if (password[i] + 1 == password[i + 1] and
            password[i] + 2 == password[i + 2])
        {
            return true;
        }
    }
    return false;
}

// TAOCP: Pattern matching - find non-overlapping repeated pairs
fn hasTwoPairs(password: []const u8) bool {
    var pair_count: u8 = 0;
    var i: usize = 0;
    while (i < password.len - 1) {
        if (password[i] == password[i + 1]) {
            pair_count += 1;
            if (pair_count >= 2) return true;
            i += 2; // Skip overlapping characters
        } else {
            i += 1;
        }
    }
    return false;
}

// TAOCP: Composite validation - all password requirements
fn isValidPassword(password: []const u8) bool {
    return !hasForbiddenLetters(password) and
        hasIncreasingStraight(password) and
        hasTwoPairs(password);
}

pub fn part1(input: []const u8) !?[]const u8 {
    const gpa = std.heap.page_allocator;

    // Get current password from input
    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    const current_password_str = line_iter.next() orelse return error.NoPasswordInput;

    // Create mutable copy of password
    var password = try gpa.dupe(u8, std.mem.trim(u8, current_password_str, " \r\t"));
    defer gpa.free(password);

    while (true) {
        password = incrementPassword(password);
        if (isValidPassword(password)) {
            return try std.fmt.allocPrint(gpa, "{s}", .{password});
        }
    }
}

pub fn part2(input: []const u8) !?[]const u8 {
    const gpa = std.heap.page_allocator;

    // Get current password from input
    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    const current_password_str = line_iter.next() orelse return error.NoPasswordInput;

    // Create mutable copy of password
    var password = try gpa.dupe(u8, std.mem.trim(u8, current_password_str, " \r\t"));
    defer gpa.free(password);

    // Part 2: Find the next valid password after part 1's answer
    // First find the Part 1 answer, then find the next one after that
    var found_first = false;

    while (true) {
        password = incrementPassword(password);
        if (isValidPassword(password)) {
            if (found_first) {
                return try std.fmt.allocPrint(gpa, "{s}", .{password});
            } else {
                found_first = true;
            }
        }
    }
}

// Test cases for password increment function
test "incrementPassword basic" {
    var password = [_]u8{ 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a' };
    _ = incrementPassword(&password);
    try std.testing.expectEqualStrings("aaaaaaab", &password);
}

test "incrementPassword carry over" {
    var password = [_]u8{ 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'z' };
    _ = incrementPassword(&password);
    try std.testing.expectEqualStrings("aaaaaaba", &password);
}

test "incrementPassword multiple carry" {
    var password = [_]u8{ 'a', 'a', 'a', 'a', 'a', 'z', 'z', 'z' };
    _ = incrementPassword(&password);
    try std.testing.expectEqualStrings("aaaabaaa", &password);
}

test "incrementPassword all z" {
    var password = [_]u8{ 'z', 'z', 'z', 'z', 'z', 'z', 'z', 'z' };
    _ = incrementPassword(&password);
    try std.testing.expectEqualStrings("aaaaaaaa", &password);
}

// Test cases for forbidden letters detection
test "hasForbiddenLetters" {
    try std.testing.expect(hasForbiddenLetters("hijklmmn")); // contains i, l
    try std.testing.expect(!hasForbiddenLetters("abcde")); // none
    try std.testing.expect(hasForbiddenLetters("pqrsto")); // contains o
    try std.testing.expect(!hasForbiddenLetters("abcdfg")); // none
}

// Test cases for increasing straight detection
test "hasIncreasingStraight" {
    try std.testing.expect(hasIncreasingStraight("hijklmmn")); // hij
    try std.testing.expect(hasIncreasingStraight("abcdefff")); // abc
    try std.testing.expect(hasIncreasingStraight("xyzabcdd")); // xyz
    try std.testing.expect(hasIncreasingStraight("abcfgh")); // fgh
    try std.testing.expect(!hasIncreasingStraight("abbceffg")); // no straight
}

// Test cases for two pairs detection
test "hasTwoPairs" {
    try std.testing.expect(hasTwoPairs("abbceffg")); // bb, ff
    try std.testing.expect(!hasTwoPairs("abbcegjk")); // only bb
    try std.testing.expect(hasTwoPairs("aabbccdd")); // aa, bb
    try std.testing.expect(hasTwoPairs("aabcddee")); // aa, dd
    try std.testing.expect(!hasTwoPairs("abcdefg")); // no pairs
}

// Test cases for password validation
test "isValidPassword examples" {
    try std.testing.expect(!isValidPassword("hijklmmn")); // forbidden letters i, l
    try std.testing.expect(!isValidPassword("abbceffg")); // no increasing straight
    try std.testing.expect(!isValidPassword("abbcegjk")); // only one pair
    try std.testing.expect(isValidPassword("abcdffaa")); // valid according to problem
    try std.testing.expect(isValidPassword("ghjaabcc")); // valid according to problem
}

// Test cases for part1 with known examples
test "part1 example abcdefgh" {
    const input = "abcdefgh";
    const result = try part1(input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("abcdffaa", result.?);
}

test "part1 example ghijklmn" {
    const input = "ghijklmn";
    const result = try part1(input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("ghjaabcc", result.?);
}

// Test case for part2
test "part2 example" {
    const input = "abcdefgh";
    const result = try part2(input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("abcdffbb", result.?); // Next valid after abcdffaa
}
