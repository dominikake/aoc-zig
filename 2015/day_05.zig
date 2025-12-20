const std = @import("std");
const mem = std.mem;

// TAOCP: Vowel characters for O(1) membership testing
const VOWELS = "aeiou";

// TAOCP: Comptime forbidden substrings for efficient pattern matching
const FORBIDDEN = [_][]const u8{ "ab", "cd", "pq", "xy" };

/// TAOCP Volume 3, Ch 6: Linear-time string scanning for vowel counting
/// Returns number of vowels in the string
fn countVowels(s: []const u8) usize {
    var count: usize = 0;
    for (s) |c| {
        // TAOCP: Direct character comparison O(1)
        if (c == 'a' or c == 'e' or c == 'i' or c == 'o' or c == 'u') {
            count += 1;
        }
    }
    return count;
}

/// TAOCP: Sliding window pattern matching for double letter detection
/// Returns true if any letter appears twice consecutively
fn hasDoubleLetter(s: []const u8) bool {
    if (s.len < 2) return false;

    // TAOCP: Linear scan with overlapping window of size 2
    for (0..s.len - 1) |i| {
        if (s[i] == s[i + 1]) return true;
    }
    return false;
}

/// TAOCP: Fixed pattern substring search (brute-force approach)
/// Returns true if any forbidden substring is present
fn hasForbiddenSubstring(s: []const u8) bool {
    // TAOCP: Multiple pattern search - small fixed patterns allow simple approach
    for (FORBIDDEN) |pattern| {
        if (mem.indexOf(u8, s, pattern) != null) return true;
    }
    return false;
}

/// TAOCP: Part 1 - Multiple linear passes combining different string analysis rules
/// Returns true if string meets all nice criteria
fn isNicePart1(s: []const u8) bool {
    // TAOCP: Rule combination with short-circuit evaluation
    if (countVowels(s) < 3) return false;
    if (!hasDoubleLetter(s)) return false;
    if (hasForbiddenSubstring(s)) return false;
    return true;
}

/// TAOCP: Advanced pattern matching - non-overlapping pair repeat detection
/// Returns true if any pair of letters appears twice without overlapping
fn hasRepeatedPair(s: []const u8) bool {
    if (s.len < 2) return false;

    // TAOCP: Hash table approach for O(n) pair tracking
    var pairs = std.StringHashMap(usize).init(std.heap.page_allocator);
    defer pairs.deinit();

    // TAOCP: Sliding window with position tracking
    for (0..s.len - 1) |i| {
        const pair = s[i .. i + 2];

        if (pairs.get(pair)) |prev_pos| {
            // TAOCP: Ensure non-overlapping by checking position distance
            if (i > prev_pos + 1) return true;
        } else {
            // TAOCP: Store first occurrence position
            pairs.put(pair, i) catch continue;
        }
    }
    return false;
}

/// TAOCP: Pattern matching with gap - sandwich detection
/// Returns true if any letter repeats with exactly one letter between
fn hasSandwichPattern(s: []const u8) bool {
    if (s.len < 3) return false;

    // TAOCP: Sliding window of size 3 with position comparison
    for (0..s.len - 2) |i| {
        if (s[i] == s[i + 2]) return true;
    }
    return false;
}

/// TAOCP: Part 2 - Advanced string analysis with non-overlapping patterns
/// Returns true if string meets new nice criteria
fn isNicePart2(s: []const u8) bool {
    // TAOCP: Independent rule evaluation
    if (!hasRepeatedPair(s)) return false;
    if (!hasSandwichPattern(s)) return false;
    return true;
}

/// TAOCP: Main solution function - O(N * L) where N is number of strings, L is average length
pub fn part1(input: []const u8) !?[]const u8 {
    var nice_count: usize = 0;
    var iter = mem.tokenizeScalar(u8, input, '\n');

    // TAOCP: Streaming processing with constant additional space
    while (iter.next()) |line| {
        if (isNicePart1(line)) {
            nice_count += 1;
        }
    }

    const result = try std.heap.page_allocator.alloc(u8, 20);
    _ = std.fmt.bufPrint(result, "{d}", .{nice_count}) catch return null;
    return result;
}

/// TAOCP: Main solution function for part 2 - same complexity, different rules
pub fn part2(input: []const u8) !?[]const u8 {
    var nice_count: usize = 0;
    var iter = mem.tokenizeScalar(u8, input, '\n');

    // TAOCP: Streaming processing with enhanced pattern matching
    while (iter.next()) |line| {
        if (isNicePart2(line)) {
            nice_count += 1;
        }
    }

    const result = try std.heap.page_allocator.alloc(u8, 20);
    _ = std.fmt.bufPrint(result, "{d}", .{nice_count}) catch return null;
    return result;
}
