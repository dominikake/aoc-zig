const std = @import("std");

const MAX_LOCATIONS = 10;

pub fn part1(input: []const u8) !?[]const u8 {
    const gpa = std.heap.page_allocator;

    // Parse locations and distances
    var locations = std.ArrayList([]const u8).initCapacity(gpa, 0) catch unreachable;
    defer {
        for (locations.items) |name| {
            gpa.free(name);
        }
        locations.deinit(gpa);
    }

    var distances: [MAX_LOCATIONS][MAX_LOCATIONS]usize = undefined;
    for (0..MAX_LOCATIONS) |i| {
        @memset(&distances[i], ~@as(usize, 0));
    }

    // First pass: identify all unique locations
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;

        var parts = std.mem.tokenizeScalar(u8, line, ' ');
        const loc1 = parts.next().?;
        _ = parts.next(); // "to"
        const loc2 = parts.next().?;
        _ = parts.next(); // "="
        _ = parts.next().?; // distance

        // Add new locations
        if (!locationExists(locations.items, loc1)) {
            try locations.append(gpa, try gpa.dupe(u8, loc1));
        }
        if (!locationExists(locations.items, loc2)) {
            try locations.append(gpa, try gpa.dupe(u8, loc2));
        }
    }

    // Second pass: fill distance matrix
    lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;

        var parts = std.mem.tokenizeScalar(u8, line, ' ');
        const loc1 = parts.next().?;
        _ = parts.next(); // "to"
        const loc2 = parts.next().?;
        _ = parts.next(); // "="
        const distance = try std.fmt.parseInt(usize, parts.next().?, 10);

        const idx1 = findLocationIndex(locations.items, loc1).?;
        const idx2 = findLocationIndex(locations.items, loc2).?;

        distances[idx1][idx2] = distance;
        distances[idx2][idx1] = distance;
        distances[idx1][idx1] = 0;
        distances[idx2][idx2] = 0;
    }

    const num_locations = locations.items.len;

    // Generate all permutations and find minimum distance
    var indices: [MAX_LOCATIONS]usize = undefined;
    for (0..num_locations) |i| {
        indices[i] = i;
    }

    var used: [MAX_LOCATIONS]bool = undefined;
    @memset(&used, false);

    var current_route: [MAX_LOCATIONS]usize = undefined;

    var min_distance: usize = ~@as(usize, 0);
    try generatePermutationsMin(indices[0..num_locations], used[0..num_locations], current_route[0..num_locations], 0, distances, &min_distance);

    const result = try std.fmt.allocPrint(gpa, "{}", .{min_distance});
    return result;
}

pub fn part2(input: []const u8) !?[]const u8 {
    const gpa = std.heap.page_allocator;

    // Parse locations and distances
    var locations = std.ArrayList([]const u8).initCapacity(gpa, 0) catch unreachable;
    defer {
        for (locations.items) |name| {
            gpa.free(name);
        }
        locations.deinit(gpa);
    }

    var distances: [MAX_LOCATIONS][MAX_LOCATIONS]usize = undefined;
    for (0..MAX_LOCATIONS) |i| {
        @memset(&distances[i], 0);
    }

    // First pass: identify all unique locations
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;

        var parts = std.mem.tokenizeScalar(u8, line, ' ');
        const loc1 = parts.next().?;
        _ = parts.next(); // "to"
        const loc2 = parts.next().?;
        _ = parts.next(); // "="
        _ = parts.next().?; // distance

        // Add new locations
        if (!locationExists(locations.items, loc1)) {
            try locations.append(gpa, try gpa.dupe(u8, loc1));
        }
        if (!locationExists(locations.items, loc2)) {
            try locations.append(gpa, try gpa.dupe(u8, loc2));
        }
    }

    // Second pass: fill distance matrix
    lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;

        var parts = std.mem.tokenizeScalar(u8, line, ' ');
        const loc1 = parts.next().?;
        _ = parts.next(); // "to"
        const loc2 = parts.next().?;
        _ = parts.next(); // "="
        const distance = try std.fmt.parseInt(usize, parts.next().?, 10);

        const idx1 = findLocationIndex(locations.items, loc1).?;
        const idx2 = findLocationIndex(locations.items, loc2).?;

        distances[idx1][idx2] = distance;
        distances[idx2][idx1] = distance;
        distances[idx1][idx1] = 0;
        distances[idx2][idx2] = 0;
    }

    const num_locations = locations.items.len;

    // Generate all permutations and find maximum distance
    var indices: [MAX_LOCATIONS]usize = undefined;
    for (0..num_locations) |i| {
        indices[i] = i;
    }

    var used: [MAX_LOCATIONS]bool = undefined;
    @memset(&used, false);

    var current_route: [MAX_LOCATIONS]usize = undefined;

    var max_distance: usize = 0;
    try generatePermutationsMax(indices[0..num_locations], used[0..num_locations], current_route[0..num_locations], 0, distances, &max_distance);

    const result = try std.fmt.allocPrint(gpa, "{}", .{max_distance});
    return result;
}

fn locationExists(locations: [][]const u8, target: []const u8) bool {
    for (locations) |loc| {
        if (std.mem.eql(u8, loc, target)) {
            return true;
        }
    }
    return false;
}

fn findLocationIndex(locations: [][]const u8, target: []const u8) ?usize {
    for (locations, 0..) |loc, i| {
        if (std.mem.eql(u8, loc, target)) {
            return i;
        }
    }
    return null;
}

fn generatePermutationsMin(
    items: []usize,
    used: []bool,
    current: []usize,
    depth: usize,
    distances: [MAX_LOCATIONS][MAX_LOCATIONS]usize,
    min_distance: *usize,
) !void {
    if (depth == items.len) {
        const route_distance = calculateRouteDistance(current, distances);
        if (route_distance < min_distance.*) {
            min_distance.* = route_distance;
        }
        return;
    }

    for (0..items.len) |i| {
        if (!used[i]) {
            used[i] = true;
            current[depth] = items[i];
            try generatePermutationsMin(items, used, current, depth + 1, distances, min_distance);
            used[i] = false;
        }
    }
}

fn generatePermutationsMax(
    items: []usize,
    used: []bool,
    current: []usize,
    depth: usize,
    distances: [MAX_LOCATIONS][MAX_LOCATIONS]usize,
    max_distance: *usize,
) !void {
    if (depth == items.len) {
        const route_distance = calculateRouteDistance(current, distances);
        if (route_distance > max_distance.*) {
            max_distance.* = route_distance;
        }
        return;
    }

    for (0..items.len) |i| {
        if (!used[i]) {
            used[i] = true;
            current[depth] = items[i];
            try generatePermutationsMax(items, used, current, depth + 1, distances, max_distance);
            used[i] = false;
        }
    }
}

fn calculateRouteDistance(route: []const usize, distances: [MAX_LOCATIONS][MAX_LOCATIONS]usize) usize {
    var total_distance: usize = 0;
    for (0..route.len - 1) |i| {
        const from = route[i];
        const to = route[i + 1];
        total_distance += distances[from][to];
    }
    return total_distance;
}
