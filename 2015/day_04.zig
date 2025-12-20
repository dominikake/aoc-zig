const std = @import("std");

// TAOCP: Hash function for proof-of-work (Vol. 3 - Searching and Sorting)
// MD5 is used as a black-box cryptographic primitive for mining AdventCoins

// TAOCP: Efficient prefix checking - early termination for optimization
// For 5 zeros: first 2 bytes must be 0, third byte < 16 (0x0F)
fn startsWithZeros(digest: [16]u8, zero_count: u8) bool {
    switch (zero_count) {
        5 => {
            // Check if first 5 hex digits are zero
            // 5 hex digits = 20 bits = 2.5 bytes
            // First 2 bytes must be 0, third byte must be < 16
            return digest[0] == 0 and digest[1] == 0 and digest[2] < 16;
        },
        6 => {
            // Check if first 6 hex digits are zero
            // 6 hex digits = 24 bits = 3 bytes
            return digest[0] == 0 and digest[1] == 0 and digest[2] == 0;
        },
        else => unreachable,
    }
}

// TAOCP: Brute-force search with sequential candidate generation (Vol. 4A - Combinatorial Algorithms)
// Implements linear scan over integers with minimal operations per iteration
fn findAdventCoin(secret_key: []const u8, zero_count: u8) !u64 {
    // Fixed buffers for performance - no heap allocations in the hot loop
    var buffer: [64]u8 = undefined;
    var digest: [16]u8 = undefined;

    // Copy secret key to buffer once, leaving space for number
    const secret_len = secret_key.len;
    if (secret_len + 20 > buffer.len) return error.SecretKeyTooLong;

    @memcpy(buffer[0..secret_len], secret_key);

    var n: u64 = 1;
    while (n > 0) {
        // TAOCP: Efficient string concatenation using fixed buffer
        const number_str = try std.fmt.bufPrint(buffer[secret_len..], "{}", .{n});
        const full_input = buffer[0 .. secret_len + number_str.len];

        // Compute MD5 hash of secret_key + number
        std.crypto.hash.Md5.hash(full_input, &digest, .{});

        // Early termination check - TAOCP: minimize operations per iteration
        if (startsWithZeros(digest, zero_count)) {
            return n;
        }

        n += 1;
    }

    return error.NotFound;
}

pub fn part1(input: []const u8) !?[]const u8 {
    // TAOCP: Extract secret key from input (trimming whitespace)
    const secret_key = std.mem.trim(u8, input, " \r\t\n");
    if (secret_key.len == 0) return error.EmptySecretKey;

    // Find AdventCoin with 5 leading zeros
    const result = try findAdventCoin(secret_key, 5);

    // Convert result to string for output
    const gpa = std.heap.page_allocator;
    const result_str = try std.fmt.allocPrint(gpa, "{}", .{result});
    return result_str;
}

pub fn part2(input: []const u8) !?[]const u8 {
    // TAOCP: Extract secret key from input (trimming whitespace)
    const secret_key = std.mem.trim(u8, input, " \r\t\n");
    if (secret_key.len == 0) return error.EmptySecretKey;

    // Find AdventCoin with 6 leading zeros
    const result = try findAdventCoin(secret_key, 6);

    // Convert result to string for output
    const gpa = std.heap.page_allocator;
    const result_str = try std.fmt.allocPrint(gpa, "{}", .{result});
    return result_str;
}

// Test with sample input - abcdef should produce 609043
test "part1 sample abcdef" {
    const sample_input = "abcdef";
    const result = try part1(sample_input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("609043", result.?);
}

// Test with sample input - pqrstuv should produce 1048970
test "part1 sample pqrstuv" {
    const sample_input = "pqrstuv";
    const result = try part1(sample_input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("1048970", result.?);
}

// Test hash checking function for 5 zeros
test "startsWithZeros 5 zeros" {
    // Test case where first 5 hex digits are zero: 00000...
    var digest1: [16]u8 = std.mem.zeroes([16]u8);
    digest1[2] = 0x0F; // Binary: 00001111, hex: 0F
    try std.testing.expect(true, startsWithZeros(digest1, 5));

    // Test case where only 4 zeros: 0000x...
    var digest2: [16]u8 = std.mem.zeroes([16]u8);
    digest2[2] = 0x10; // Binary: 00010000, hex: 10
    try std.testing.expect(false, startsWithZeros(digest2, 5));

    // All zeros should pass
    const digest3 = [_]u8{0} ** 16;
    try std.testing.expect(true, startsWithZeros(digest3, 5));
}

// Test hash checking function for 6 zeros
test "startsWithZeros 6 zeros" {
    // Test case where first 6 hex digits are zero: 000000...
    const digest1 = [_]u8{0} ** 16;
    try std.testing.expect(true, startsWithZeros(digest1, 6));

    // Test case where only 5 zeros: 00000x...
    var digest2 = std.mem.zeroes([16]u8);
    digest2[2] = 0x01; // Non-zero in third byte
    try std.testing.expect(false, startsWithZeros(digest2, 6));
}

// Test error handling for empty input
test "empty secret key error" {
    const sample_input = "";
    const result = part1(sample_input);
    try std.testing.expectError(error.EmptySecretKey, result);
}

// Test secret key too long error
test "secret key too long error" {
    // Create a secret key that's too long for our buffer
    var long_key: [65]u8 = undefined;
    std.mem.set(u8, &long_key, 'a');
    const sample_input = &long_key;
    const result = part1(sample_input);
    try std.testing.expectError(error.SecretKeyTooLong, result);
}

// Integration test with known MD5 hash
test "MD5 hash verification" {
    const secret_key = "abcdef";
    const number: u64 = 609043;

    var buffer: [64]u8 = undefined;
    var digest: [16]u8 = undefined;

    const secret_len = secret_key.len;
    @memcpy(buffer[0..secret_len], secret_key);

    const number_str = try std.fmt.bufPrint(buffer[secret_len..], "{}", .{number});
    const full_input = buffer[0 .. secret_len + number_str.len];

    std.crypto.hash.Md5.hash(full_input, &digest, .{});

    // Verify this hash starts with 5 zeros
    try std.testing.expect(true, startsWithZeros(digest, 5));

    // Convert first 3 bytes to hex for verification
    const expected_prefix = "000001";
    var hex_buffer: [6]u8 = undefined;
    _ = std.fmt.bufPrint(&hex_buffer, "{x:0>2}{x:0>2}{x:0>2}", .{ digest[0], digest[1], digest[2] });
    try std.testing.expectEqualStrings(expected_prefix[0..5], hex_buffer[0..5]);
}
