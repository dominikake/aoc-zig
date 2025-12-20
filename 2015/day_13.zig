const std = @import("std");

// TAOCP Concept: Adjacency matrix for O(1) happiness lookups
const HappinessData = struct {
    guests: std.ArrayList([]const u8),
    matrix: std.ArrayList(std.ArrayList(i32)),
    guest_to_index: std.StringHashMap(usize),
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator) HappinessData {
        return HappinessData{
            .guests = std.ArrayList([]const u8).initCapacity(allocator, 10) catch unreachable,
            .matrix = std.ArrayList(std.ArrayList(i32)).initCapacity(allocator, 10) catch unreachable,
            .guest_to_index = std.StringHashMap(usize).init(allocator),
            .allocator = allocator,
        };
    }

    fn deinit(self: *HappinessData) void {
        self.guests.deinit(self.allocator);
        for (self.matrix.items) |*row| {
            row.deinit(self.allocator);
        }
        self.matrix.deinit(self.allocator);
        self.guest_to_index.deinit();
    }

    fn getGuestIndex(self: *HappinessData, guest: []const u8) !usize {
        if (self.guest_to_index.get(guest)) |index| {
            return index;
        }

        const index = self.guests.items.len;
        try self.guests.append(self.allocator, guest);
        try self.guest_to_index.put(guest, index);

        // Initialize row in matrix
        var row = std.ArrayList(i32).initCapacity(self.allocator, 10) catch unreachable;
        var i: usize = 0;
        while (i < index) : (i += 1) {
            row.appendAssumeCapacity(0);
        }
        row.appendAssumeCapacity(0); // diagonal entry
        try self.matrix.append(self.allocator, row);

        // Update all existing rows to include new guest
        for (self.matrix.items[0..index]) |*existing_row| {
            existing_row.appendAssumeCapacity(0);
        }

        return index;
    }

    fn setHappiness(self: *HappinessData, guest1: []const u8, guest2: []const u8, happiness: i32) !void {
        const idx1 = try self.getGuestIndex(guest1);
        const idx2 = try self.getGuestIndex(guest2);
        self.matrix.items[idx1].items[idx2] = happiness;
    }
};

// TAOCP Concept: Parse input with pattern matching for structured data
fn parseInput(input: []const u8, allocator: std.mem.Allocator) !HappinessData {
    var data = HappinessData.init(allocator);
    errdefer data.deinit();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;

        // Parse: "Alice would gain 2 happiness units by sitting next to Bob."
        var parts = std.mem.tokenizeScalar(u8, line, ' ');

        const guest1 = parts.next() orelse return error.InvalidFormat;
        _ = parts.next(); // "would"
        const sign_str = parts.next() orelse return error.InvalidFormat;
        const value_str = parts.next() orelse return error.InvalidFormat;
        _ = parts.next(); // "happiness"
        _ = parts.next(); // "units"
        _ = parts.next(); // "by"
        _ = parts.next(); // "sitting"
        _ = parts.next(); // "next"
        _ = parts.next(); // "to"
        const guest2_with_period = parts.next() orelse return error.InvalidFormat;

        // Remove trailing period from guest2
        const guest2 = guest2_with_period[0 .. guest2_with_period.len - 1];

        const value = try std.fmt.parseInt(i32, value_str, 10);
        const happiness = if (std.mem.eql(u8, sign_str, "gain")) value else -value;

        try data.setHappiness(guest1, guest2, happiness);
    }

    return data;
}

// TAOCP Concept: Calculate total happiness for circular arrangement
fn calculateHappiness(arrangement: []const usize, data: HappinessData) i32 {
    if (arrangement.len < 2) return 0;

    var total: i32 = 0;

    for (arrangement, 0..) |guest_idx, i| {
        const left_neighbor = arrangement[(i + arrangement.len - 1) % arrangement.len];
        const right_neighbor = arrangement[(i + 1) % arrangement.len];

        total += data.matrix.items[guest_idx].items[left_neighbor];
        total += data.matrix.items[guest_idx].items[right_neighbor];
    }

    return total;
}

// TAOCP Concept: Generate all circular permutations (fix first element)
fn generatePermutations(guests: []usize, data: HappinessData) i32 {
    if (guests.len <= 1) return 0;

    var max_happiness: i32 = std.math.minInt(i32);

    // Fix first guest for circular arrangement to avoid rotational duplicates
    const fixed_first = guests[0];
    const mutable_guests = guests[1..];

    // Use proper Heap's algorithm for generating permutations of remaining guests
    generateAllPermutations(mutable_guests, data, fixed_first, &max_happiness);

    return max_happiness;
}

// Generate all permutations using Heap's algorithm (TAOCP Algorithm P)
fn generateAllPermutations(guests: []usize, data: HappinessData, fixed_first: usize, max_happiness: *i32) void {
    if (guests.len == 0) {
        // Edge case: only fixed guest
        var arrangement = std.ArrayList(usize).initCapacity(std.heap.page_allocator, 1) catch unreachable;
        defer arrangement.deinit(std.heap.page_allocator);
        arrangement.appendAssumeCapacity(fixed_first);
        const happiness = calculateHappiness(arrangement.items, data);
        if (happiness > max_happiness.*) {
            max_happiness.* = happiness;
        }
        return;
    }

    // Generate all permutations and evaluate each one
    permuteAndEvaluate(guests, 0, data, fixed_first, max_happiness);
}

// Core permutation algorithm
fn permuteAndEvaluate(guests: []usize, start: usize, data: HappinessData, fixed_first: usize, max_happiness: *i32) void {
    if (start == guests.len) {
        // Complete permutation found - evaluate arrangement
        var arrangement = std.ArrayList(usize).initCapacity(std.heap.page_allocator, guests.len + 1) catch unreachable;
        defer arrangement.deinit(std.heap.page_allocator);

        arrangement.appendAssumeCapacity(fixed_first);
        arrangement.appendSliceAssumeCapacity(guests);

        const happiness = calculateHappiness(arrangement.items, data);
        if (happiness > max_happiness.*) {
            max_happiness.* = happiness;
        }
        return;
    }

    // Generate permutations through swapping
    for (start..guests.len) |i| {
        std.mem.swap(usize, &guests[start], &guests[i]);
        permuteAndEvaluate(guests, start + 1, data, fixed_first, max_happiness);
        std.mem.swap(usize, &guests[start], &guests[i]);
    }
}

pub fn part1(input: []const u8) !?[]const u8 {
    const allocator = std.heap.page_allocator;

    var data = try parseInput(input, allocator);
    errdefer data.deinit();

    if (data.guests.items.len < 2) return error.InsufficientGuests;

    // Create array of guest indices
    var guest_indices = try allocator.alloc(usize, data.guests.items.len);
    defer allocator.free(guest_indices);

    for (data.guests.items, 0..) |_, i| {
        guest_indices[i] = i;
    }

    const max_happiness = generatePermutations(guest_indices, data);

    return try std.fmt.allocPrint(allocator, "{d}", .{max_happiness});
}

pub fn part2(input: []const u8) !?[]const u8 {
    const allocator = std.heap.page_allocator;

    var data = try parseInput(input, allocator);
    errdefer data.deinit();

    // Add "Me" to the guest list for Part 2
    const me_name = "Me";

    // Get existing guests count
    const original_guest_count = data.guests.items.len;
    _ = try data.getGuestIndex(me_name); // Add Me to data structure

    // Set all happiness values for "Me" to 0
    for (0..original_guest_count) |i| {
        try data.setHappiness(me_name, data.guests.items[i], 0);
        try data.setHappiness(data.guests.items[i], me_name, 0);
    }

    if (data.guests.items.len < 2) return error.InsufficientGuests;

    // Create array of guest indices
    var guest_indices = try allocator.alloc(usize, data.guests.items.len);
    defer allocator.free(guest_indices);

    for (data.guests.items, 0..) |_, i| {
        guest_indices[i] = i;
    }

    const max_happiness = generatePermutations(guest_indices, data);

    return try std.fmt.allocPrint(allocator, "{d}", .{max_happiness});
}

// Test with sample input - expected answer is 330
test "part1 sample input" {
    const sample_input =
        \\Alice would gain 54 happiness units by sitting next to Bob.
        \\Alice would lose 79 happiness units by sitting next to Carol.
        \\Alice would lose 2 happiness units by sitting next to David.
        \\Bob would gain 83 happiness units by sitting next to Alice.
        \\Bob would lose 7 happiness units by sitting next to Carol.
        \\Bob would lose 63 happiness units by sitting next to David.
        \\Carol would lose 62 happiness units by sitting next to Alice.
        \\Carol would gain 60 happiness units by sitting next to Bob.
        \\Carol would gain 55 happiness units by sitting next to David.
        \\David would gain 46 happiness units by sitting next to Alice.
        \\David would lose 7 happiness units by sitting next to Bob.
        \\David would gain 41 happiness units by sitting next to Carol.
    ;
    const result = try part1(sample_input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("330", result.?);
}

// Test part2 with sample input plus "Me" - should handle correctly
test "part2 sample input" {
    const sample_input =
        \\Alice would gain 54 happiness units by sitting next to Bob.
        \\Alice would lose 79 happiness units by sitting next to Carol.
        \\Alice would lose 2 happiness units by sitting next to David.
        \\Bob would gain 83 happiness units by sitting next to Alice.
        \\Bob would lose 7 happiness units by sitting next to Carol.
        \\Bob would lose 63 happiness units by sitting next to David.
        \\Carol would lose 62 happiness units by sitting next to Alice.
        \\Carol would gain 60 happiness units by sitting next to Bob.
        \\Carol would gain 55 happiness units by sitting next to David.
        \\David would gain 46 happiness units by sitting next to Alice.
        \\David would lose 7 happiness units by sitting next to Bob.
        \\David would gain 41 happiness units by sitting next to Carol.
    ;
    const result = try part2(sample_input);
    defer std.heap.page_allocator.free(result.?);
    // Just test that part 2 runs and produces a reasonable result
    try std.testing.expect(result.? != null);
    const value = try std.fmt.parseInt(i32, result.?, 10);
    try std.testing.expect(value > 0); // Should have some positive result
}
