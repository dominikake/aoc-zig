const std = @import("std");

// TAOCP Section 5.1: Frequency counting using optimal direct array approach
const LetterFrequency = struct {
    letter: u8,
    count: u32,
};

// TAOCP Section 5.3.1: Custom comparator implementing sorting by frequency desc, letter asc
fn frequencyCompare(_: void, a: LetterFrequency, b: LetterFrequency) bool {
    // Primary key: frequency (descending)
    if (a.count != b.count) return a.count > b.count;
    // Secondary key: letter (ascending) - alphabetical tie-breaker
    return a.letter < b.letter;
}

// TAOCP Section 5.1: Count letters using direct array indexing - optimal for fixed alphabet
fn countLetters(name: []const u8) [26]u32 {
    var counts = [_]u32{0} ** 26;
    for (name) |c| {
        if (c >= 'a' and c <= 'z') {
            counts[c - 'a'] += 1;
        }
    }
    return counts;
}

// TAOCP Section 5.3.1: Generate checksum from frequency counts using custom sort
fn generateChecksum(counts: [26]u32) [5]u8 {
    var frequencies: [26]LetterFrequency = undefined;

    // Build frequency array
    for (0..26) |i| {
        frequencies[i] = LetterFrequency{
            .letter = @as(u8, @intCast(i)) + 'a',
            .count = counts[i],
        };
    }

    // Sort using TAOCP Section 5.3.1 principles
    std.sort.block(LetterFrequency, &frequencies, {}, frequencyCompare);

    // Extract top 5 letters for checksum
    var checksum: [5]u8 = undefined;
    for (0..5) |i| {
        checksum[i] = frequencies[i].letter;
    }

    return checksum;
}

// TAOCP: Validate room by comparing computed checksum vs provided checksum
fn validateRoom(name: []const u8, checksum: []const u8) bool {
    const expected_checksum = generateChecksum(countLetters(name));

    for (0..5) |i| {
        if (checksum[i] != expected_checksum[i]) {
            return false;
        }
    }

    return true;
}

// TAOCP Section 6.1: Caesar cipher using modular arithmetic
fn decryptName(encrypted: []const u8, sector_id: u32, decrypted: []u8) void {
    const rotation = sector_id % 26;
    for (encrypted, 0..) |c, i| {
        if (c == '-') {
            decrypted[i] = ' ';
        } else if (c >= 'a' and c <= 'z') {
            const offset = c - 'a';
            const rotated = @as(u8, (offset + @as(u8, @intCast(rotation))) % 26);
            decrypted[i] = rotated + 'a';
        } else {
            decrypted[i] = c;
        }
    }
}

// TAOCP: Parse room entry into components
fn parseRoom(line: []const u8) ?struct { name: []const u8, sector_id: u32, checksum: []const u8 } {
    const bracket_idx = std.mem.indexOfScalar(u8, line, '[') orelse return null;
    const close_bracket = std.mem.indexOfScalar(u8, line, ']') orelse return null;
    const last_hyphen = std.mem.lastIndexOfScalar(u8, line[0..bracket_idx], '-') orelse return null;

    const name = line[0..last_hyphen];
    const sector_str = line[last_hyphen + 1 .. bracket_idx];
    const sector_id = std.fmt.parseInt(u32, sector_str, 10) catch return null;
    const checksum = line[bracket_idx + 1 .. close_bracket];

    return .{ .name = name, .sector_id = sector_id, .checksum = checksum };
}

pub fn part1(input: []const u8) !?[]const u8 {
    var sum: u32 = 0;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    while (lines.next()) |line| {
        if (line.len == 0) continue;

        if (parseRoom(line)) |room| {
            if (validateRoom(room.name, room.checksum)) {
                sum += room.sector_id;
            }
        }
    }

    return try std.fmt.allocPrint(std.heap.page_allocator, "{}", .{sum});
}

pub fn part2(input: []const u8) !?[]const u8 {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    while (lines.next()) |line| {
        if (line.len == 0) continue;

        if (parseRoom(line)) |room| {
            if (!validateRoom(room.name, room.checksum)) continue;

            // Decrypt room name
            const decrypted = try std.heap.page_allocator.alloc(u8, room.name.len);
            defer std.heap.page_allocator.free(decrypted);

            decryptName(room.name, room.sector_id, decrypted);

            // Check for northpole object storage
            if (std.mem.indexOf(u8, decrypted, "northpole") != null) {
                return try std.fmt.allocPrint(std.heap.page_allocator, "{}", .{room.sector_id});
            }
        }
    }

    return null;
}

// Tests for TAOCP algorithm verification
test "countLetters" {
    const counts = countLetters("aaaaa-bbb-z-y-x");

    try std.testing.expectEqual(@as(u32, 5), counts['a' - 'a']);
    try std.testing.expectEqual(@as(u32, 3), counts[1]); // b index
    try std.testing.expectEqual(@as(u32, 1), counts['x' - 'a']);
    try std.testing.expectEqual(@as(u32, 1), counts['y' - 'a']);
    try std.testing.expectEqual(@as(u32, 1), counts['z' - 'a']);
}

test "generateChecksum" {
    var counts = [_]u32{0} ** 26;
    counts[0] = 5; // a=5
    counts[1] = 3; // b=3
    counts[23] = 1; // x=1
    counts[24] = 1; // y=1
    counts[25] = 1; // z=1
    const checksum = generateChecksum(counts);

    try std.testing.expectEqual(@as(u8, 'a'), checksum[0]);
    try std.testing.expectEqual(@as(u8, 'b'), checksum[1]);
    try std.testing.expectEqual(@as(u8, 'x'), checksum[2]);
    try std.testing.expectEqual(@as(u8, 'y'), checksum[3]);
    try std.testing.expectEqual(@as(u8, 'z'), checksum[4]);
}

test "validateRoom" {
    const name = "aaaaa-bbb-z-y-x";
    const checksum = "abxyz";
    try std.testing.expect(validateRoom(name, checksum));

    const invalid_checksum = "abxzz";
    try std.testing.expect(!validateRoom(name, invalid_checksum));
}

test "decryptName" {
    const encrypted = "qzmt-zixmtkozy-ivhz";
    const sector_id: u32 = 343;
    var decrypted: [25]u8 = undefined;

    decryptName(encrypted, sector_id, &decrypted);
    const expected = "very encrypted name";

    try std.testing.expectEqualStrings(expected, decrypted[0..expected.len]);
}

test "parseRoom" {
    const line = "aaaaa-bbb-z-y-x-123[abxyz]";
    const room = parseRoom(line).?;

    try std.testing.expectEqualStrings("aaaaa-bbb-z-y-x", room.name);
    try std.testing.expectEqual(@as(u32, 123), room.sector_id);
    try std.testing.expectEqualStrings("abxyz", room.checksum);
}
