const std = @import("std");

// TAOCP Concepts Applied:
// - String Processing and Pattern Matching (Vol 3, §6.1-6.3): Fixed-size sliding windows for ABBA/ABA detection
// - Set Operations (Vol 2, §4.6): Part 2 uses ABA set intersection with BAB patterns
// - Linear Search Algorithms: O(n) per address is optimal for fixed-size patterns

/// Check if a string contains an ABBA pattern using 4-character sliding window
/// TAOCP Vol 3: Basic string search with fixed pattern size - O(n) optimal
fn hasABBA(sequence: []const u8) bool {
    if (sequence.len < 4) return false;

    for (0..sequence.len - 3) |i| {
        // ABBA pattern: seq[i] == seq[i+3] and seq[i+1] == seq[i+2] and seq[i] != seq[i+1]
        if (sequence[i] == sequence[i + 3] and 
            sequence[i + 1] == sequence[i + 2] and 
            sequence[i] != sequence[i + 1]) {
            return true;
        }
    }
    return false;
}

/// Check if a string contains an ABA pattern using 3-character sliding window
fn hasABA(sequence: []const u8) bool {
    if (sequence.len < 3) return false;

    for (0..sequence.len - 2) |i| {
        // ABA pattern: seq[i] == seq[i+2] and seq[i] != seq[i+1]
        if (sequence[i] == sequence[i + 2] and sequence[i] != sequence[i + 1]) {
            return true;
        }
    }
    return false;
}

/// Convert ABA pattern to corresponding BAB pattern
fn abaToBAB(aba: [3]u8) [3]u8 {
    return [3]u8{ aba[1], aba[0], aba[1] };
}

/// Check if string contains a specific 3-character pattern
fn containsPattern(sequence: []const u8, pattern: [3]u8) bool {
    if (sequence.len < 3) return false;

    for (0..sequence.len - 2) |i| {
        if (sequence[i] == pattern[0] and 
            sequence[i + 1] == pattern[1] and 
            sequence[i + 2] == pattern[2]) {
            return true;
        }
    }
    return false;
}

/// Parse IPv7 address to check for TLS support
/// TLS: ABBA in supernet AND NO ABBA in hypernet
fn supportsTLS(address: []const u8, allocator: std.mem.Allocator) !bool {
    var supernet_segments = std.ArrayList([]const u8).initCapacity(allocator, 10) catch unreachable;
    defer supernet_segments.deinit(allocator);
    
    var hypernet_segments = std.ArrayList([]const u8).initCapacity(allocator, 10) catch unreachable;
    defer hypernet_segments.deinit(allocator);

    var start: usize = 0;
    var in_bracket = false;

    for (address, 0..) |c, i| {
        if (c == '[') {
            // Add segment before bracket to supernet
            try supernet_segments.append(allocator, address[start..i]);
            start = i + 1;
            in_bracket = true;
        } else if (c == ']') {
            // Add segment inside brackets to hypernet
            try hypernet_segments.append(allocator, address[start..i]);
            start = i + 1;
            in_bracket = false;
        }
    }

    // Handle final segment
    if (start < address.len) {
        if (in_bracket) {
            try hypernet_segments.append(allocator, address[start..]);
        } else {
            try supernet_segments.append(allocator, address[start..]);
        }
    }

    // Check for ABBA in any hypernet segment - immediate failure if found
    for (hypernet_segments.items) |segment| {
        if (hasABBA(segment)) {
            return false;
        }
    }

    // Check for ABBA in any supernet segment
    for (supernet_segments.items) |segment| {
        if (hasABBA(segment)) {
            return true;
        }
    }

    return false;
}

/// Parse IPv7 address to check for SSL support  
/// SSL: ABA in supernet AND corresponding BAB in hypernet
fn supportsSSL(address: []const u8, allocator: std.mem.Allocator) !bool {
    var supernet_segments = std.ArrayList([]const u8).initCapacity(allocator, 10) catch unreachable;
    defer supernet_segments.deinit(allocator);
    
    var hypernet_segments = std.ArrayList([]const u8).initCapacity(allocator, 10) catch unreachable;
    defer hypernet_segments.deinit(allocator);

    var start: usize = 0;
    var in_bracket = false;

    for (address, 0..) |c, i| {
        if (c == '[') {
            // Add segment before bracket to supernet
            try supernet_segments.append(allocator, address[start..i]);
            start = i + 1;
            in_bracket = true;
        } else if (c == ']') {
            // Add segment inside brackets to hypernet
            try hypernet_segments.append(allocator, address[start..i]);
            start = i + 1;
            in_bracket = false;
        }
    }

    // Handle final segment
    if (start < address.len) {
        if (in_bracket) {
            try hypernet_segments.append(allocator, address[start..]);
        } else {
            try supernet_segments.append(allocator, address[start..]);
        }
    }

    // Use HashMap for efficient ABA-to-BAB lookup (TAOCP Vol 2, §4.6)
    var aba_to_bab_set = std.AutoHashMap([3]u8, void).init(allocator);
    defer aba_to_bab_set.deinit();

    // Collect all ABAs from supernet segments
    for (supernet_segments.items) |segment| {
        for (0..segment.len - 2) |i| {
            if (segment[i] == segment[i + 2] and segment[i] != segment[i + 1]) {
                const aba = [3]u8{ segment[i], segment[i + 1], segment[i + 2] };
                try aba_to_bab_set.put(aba, {});
            }
        }
    }

    // Check if any corresponding BAB exists in hypernet segments
    var aba_it = aba_to_bab_set.iterator();
    while (aba_it.next()) |aba_entry| {
        const aba = aba_entry.key_ptr.*;
        const bab = abaToBAB(aba);
        
        for (hypernet_segments.items) |segment| {
            if (containsPattern(segment, bab)) {
                return true; // Found matching ABA-BAB pair
            }
        }
    }

    return false;
}

pub fn part1(input: []const u8) !?[]const u8 {
    const allocator = std.heap.page_allocator;
    
    var tls_count: usize = 0;
    var iter = std.mem.tokenizeScalar(u8, input, '\n');
    
    while (iter.next()) |line| {
        if (try supportsTLS(line, allocator)) {
            tls_count += 1;
        }
    }

    const result = try std.fmt.allocPrint(allocator, "{d}", .{tls_count});
    return result;
}

pub fn part2(input: []const u8) !?[]const u8 {
    const allocator = std.heap.page_allocator;
    
    var ssl_count: usize = 0;
    var iter = std.mem.tokenizeScalar(u8, input, '\n');
    
    while (iter.next()) |line| {
        if (try supportsSSL(line, allocator)) {
            ssl_count += 1;
        }
    }

    const result = try std.fmt.allocPrint(allocator, "{d}", .{ssl_count});
    return result;
}
