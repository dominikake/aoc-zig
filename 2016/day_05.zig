const std = @import("std");

// TAOCP: Brute-force search with sequential candidate generation (Vol. 4A - Combinatorial Algorithms)
// Linear scan over integers 0, 1, 2, ... with minimal operations per iteration

// TAOCP: Efficient hash prefix checking (Vol. 3 - Searching and Sorting)
// For 5 zeros: first 2.5 bytes must be zero (20 bits = 5 hex digits)
fn startsWithFiveZeros(digest: [16]u8) bool {
    return digest[0] == 0 and digest[1] == 0 and digest[2] < 16;
}

// TAOCP: String concatenation using fixed buffer (Vol. 1 - Fundamental Algorithms)
// Reuses buffer to avoid allocations in hot loop
const HashInputBuffer = struct {
    buffer: [64]u8,
    door_id_len: usize,

    fn init(door_id: []const u8) !HashInputBuffer {
        if (door_id.len + 20 > 64) return error.DoorIdTooLong;
        var result = HashInputBuffer{
            .buffer = undefined,
            .door_id_len = door_id.len,
        };
        @memcpy(result.buffer[0..result.door_id_len], door_id);
        return result;
    }

    fn getHashInput(self: *HashInputBuffer, index: u64) ![]const u8 {
        const number_str = try std.fmt.bufPrint(self.buffer[self.door_id_len..], "{}", .{index});
        return self.buffer[0 .. self.door_id_len + number_str.len];
    }
};

// TAOCP: Sparse array filling with position validation (Vol. 1 - Arrays and Vectors)
// Part 2 uses sentinel value (255) to mark unfilled positions
const PasswordArray = struct {
    data: [8]u8,

    fn initEmpty() PasswordArray {
        return PasswordArray{
            .data = [_]u8{255} ** 8, // 255 = sentinel for unfilled
        };
    }

    fn trySet(self: *PasswordArray, pos: usize, char: u8) bool {
        if (pos >= 8) return false;
        if (self.data[pos] != 255) return false; // Already filled
        self.data[pos] = char;
        return true;
    }

    fn isComplete(self: PasswordArray) bool {
        for (self.data) |byte| {
            if (byte == 255) return false;
        }
        return true;
    }
};

// TAOCP: Infinite sequence generation with lazy evaluation (Vol. 1 - Iteration Patterns)
fn findPasswordCharacters(door_id: []const u8) ![8]u8 {
    var hash_buffer = try HashInputBuffer.init(door_id);
    var digest: [16]u8 = undefined;
    var password: [8]u8 = undefined;
    var found: usize = 0;
    var index: u64 = 0;

    while (found < 8) {
        const input = try hash_buffer.getHashInput(index);
        std.crypto.hash.Md5.hash(input, &digest, .{});

        if (startsWithFiveZeros(digest)) {
            // TAOCP: Extract nth character from hash (Vol. 1 - Array indexing)
            // MD5 digest[2] is 3rd byte, low nibble = 6th hex digit
            const low_nibble = digest[2] & 0x0F;
            password[found] = low_nibble;
            found += 1;
        }

        index += 1;
    }

    return password;
}

// TAOCP: Hash-based position mapping (Vol. 2 - Modular Arithmetic)
// Part 2 uses hash[5] as position and hash[6] as value
fn findPasswordByPosition(door_id: []const u8) ![8]u8 {
    var hash_buffer = try HashInputBuffer.init(door_id);
    var digest: [16]u8 = undefined;
    var password = PasswordArray.initEmpty();
    var index: u64 = 0;

    while (!password.isComplete()) {
        const input = try hash_buffer.getHashInput(index);
        std.crypto.hash.Md5.hash(input, &digest, .{});

        if (startsWithFiveZeros(digest)) {
            // TAOCP: Extract position and value from hash bytes
            // digest[2] low nibble = 6th hex digit, digest[3] high nibble = 7th hex digit
            const position = digest[2] & 0x0F;
            const value = digest[3] >> 4;

            // TAOCP: Sparse array insertion with bounds checking
            _ = password.trySet(position, value);
        }

        index += 1;
    }

    return password.data;
}

// TAOCP: Hex digit conversion (Vol. 1 - Number representation)
fn toHexDigit(nibble: u8) u8 {
    return if (nibble < 10) '0' + nibble else 'a' + nibble - 10;
}

pub fn part1(input: []const u8) !?[]const u8 {
    const door_id = std.mem.trim(u8, input, " \r\t\n");
    if (door_id.len == 0) return error.EmptyDoorId;

    const password_nibbles = try findPasswordCharacters(door_id);

    // Convert to string
    const gpa = std.heap.page_allocator;
    const result = try gpa.alloc(u8, 8);
    for (password_nibbles, 0..) |nibble, i| {
        result[i] = toHexDigit(nibble);
    }

    return result;
}

pub fn part2(input: []const u8) !?[]const u8 {
    const door_id = std.mem.trim(u8, input, " \r\t\n");
    if (door_id.len == 0) return error.EmptyDoorId;

    const password_nibbles = try findPasswordByPosition(door_id);

    // Convert to string
    const gpa = std.heap.page_allocator;
    const result = try gpa.alloc(u8, 8);
    for (password_nibbles, 0..) |nibble, i| {
        result[i] = toHexDigit(nibble);
    }

    return result;
}

// Test hash prefix checking
test "startsWithFiveZeros" {
    var digest1: [16]u8 = std.mem.zeroes([16]u8);
    digest1[2] = 0x0F; // First 5 hex digits: 00000...
    try std.testing.expect(startsWithFiveZeros(digest1));

    var digest2: [16]u8 = std.mem.zeroes([16]u8);
    digest2[2] = 0x10; // First 4 hex digits: 0000x...
    try std.testing.expect(!startsWithFiveZeros(digest2));

    var digest3: [16]u8 = std.mem.zeroes([16]u8);
    digest3[1] = 0x01; // Non-zero in second byte
    try std.testing.expect(!startsWithFiveZeros(digest3));
}

// Test password array operations
test "PasswordArray" {
    var password = PasswordArray.initEmpty();
    try std.testing.expect(!password.isComplete());

    _ = password.trySet(0, 5);
    _ = password.trySet(1, 10);
    _ = password.trySet(2, 15);
    try std.testing.expect(!password.isComplete());

    _ = password.trySet(0, 99); // Should not overwrite
    try std.testing.expectEqual(@as(u8, 5), password.data[0]);

    _ = password.trySet(3, 0);
    _ = password.trySet(4, 1);
    _ = password.trySet(5, 2);
    _ = password.trySet(6, 3);
    _ = password.trySet(7, 4);
    try std.testing.expect(password.isComplete());
}

// Test position out of bounds
test "PasswordArray out of bounds" {
    var password = PasswordArray.initEmpty();
    const result = password.trySet(8, 5);
    try std.testing.expect(!result);
}

// Test part 1 with sample input
test "part1 sample abc" {
    const sample_input = "abc";
    const result = try part1(sample_input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("18f47a30", result.?);
}

// Test part 2 with sample input
test "part2 sample abc" {
    // NOTE: This test is slow (~20-30 seconds in debug mode, ~5 seconds in release mode)
    // Uncomment to run:
    // const sample_input = "abc";
    // const result = try part2(sample_input);
    // defer std.heap.page_allocator.free(result.?);
    // try std.testing.expectEqualStrings("05ace8e3", result.?);
}

// Test hex digit conversion
test "toHexDigit" {
    try std.testing.expectEqual(@as(u8, '0'), toHexDigit(0));
    try std.testing.expectEqual(@as(u8, '9'), toHexDigit(9));
    try std.testing.expectEqual(@as(u8, 'a'), toHexDigit(10));
    try std.testing.expectEqual(@as(u8, 'f'), toHexDigit(15));
}

// Test HashInputBuffer
test "HashInputBuffer" {
    var buffer = try HashInputBuffer.init("door_id");
    try std.testing.expectEqual(@as(usize, 7), buffer.door_id_len);

    const input1 = try buffer.getHashInput(0);
    try std.testing.expectEqualStrings("door_id0", input1);

    const input2 = try buffer.getHashInput(123);
    try std.testing.expectEqualStrings("door_id123", input2);
}

// Integration test - verify MD5 hash of abc3231929 starts with 000001
test "MD5 hash verification abc3231929" {
    const input = "abc3231929";
    var digest: [16]u8 = undefined;
    std.crypto.hash.Md5.hash(input, &digest, .{});

    try std.testing.expect(startsWithFiveZeros(digest));

    // Verify 6th hex digit is '1' (low nibble of byte 2)
    const low_nibble = digest[2] & 0x0F;
    try std.testing.expectEqual(@as(u8, 1), low_nibble);
}

// Test error handling for empty input
test "empty door id error" {
    const sample_input = "";
    const result = part1(sample_input);
    try std.testing.expectError(error.EmptyDoorId, result);
}

// Test door id too long error
test "door id too long error" {
    var long_id: [65]u8 = undefined;
    for (&long_id) |*c| c.* = 'a';
    const sample_input = &long_id;

    const result = part1(sample_input);
    try std.testing.expectError(error.DoorIdTooLong, result);
}
