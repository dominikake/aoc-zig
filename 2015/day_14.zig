const std = @import("std");

pub fn part1(input: []const u8) !?[]const u8 {
    const RACE_TIME = 2503;
    var max_distance: u32 = 0;

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;

        var parts = std.mem.tokenizeScalar(u8, line, ' ');
        _ = parts.next(); // Skip name
        _ = parts.next(); // Skip "can"
        _ = parts.next(); // Skip "fly"

        const speed = try std.fmt.parseInt(u32, parts.next().?, 10);
        _ = parts.next(); // Skip "km/s"
        _ = parts.next(); // Skip "for"

        const fly_time = try std.fmt.parseInt(u32, parts.next().?, 10);
        _ = parts.next(); // Skip "seconds,"
        _ = parts.next(); // Skip "but"
        _ = parts.next(); // Skip "then"
        _ = parts.next(); // Skip "must"
        _ = parts.next(); // Skip "rest"
        _ = parts.next(); // Skip "for"

        const rest_time = try std.fmt.parseInt(u32, parts.next().?, 10);

        const cycle_time = fly_time + rest_time;
        const full_cycles = RACE_TIME / cycle_time;
        const remaining_time = RACE_TIME % cycle_time;
        const actual_fly_time = @min(remaining_time, fly_time);

        const distance = full_cycles * fly_time * speed + actual_fly_time * speed;
        if (distance > max_distance) {
            max_distance = distance;
        }
    }

    return try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{max_distance});
}

pub fn part2(input: []const u8) !?[]const u8 {
    const RACE_TIME = 2503;
    const allocator = std.heap.page_allocator;

    var reindeers = std.ArrayList(Reindeer).initCapacity(allocator, 10) catch unreachable;
    defer reindeers.deinit(allocator);

    // Parse input
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;

        var parts = std.mem.tokenizeScalar(u8, line, ' ');
        _ = parts.next(); // Skip name
        _ = parts.next(); // Skip "can"
        _ = parts.next(); // Skip "fly"

        const speed = try std.fmt.parseInt(u32, parts.next().?, 10);
        _ = parts.next(); // Skip "km/s"
        _ = parts.next(); // Skip "for"

        const fly_time = try std.fmt.parseInt(u32, parts.next().?, 10);
        _ = parts.next(); // Skip "seconds,"
        _ = parts.next(); // Skip "but"
        _ = parts.next(); // Skip "then"
        _ = parts.next(); // Skip "must"
        _ = parts.next(); // Skip "rest"
        _ = parts.next(); // Skip "for"

        const rest_time = try std.fmt.parseInt(u32, parts.next().?, 10);

        try reindeers.append(allocator, Reindeer{
            .speed = speed,
            .fly_time = fly_time,
            .rest_time = rest_time,
            .distance = 0,
            .score = 0,
            .time_in_state = 0,
            .flying = true,
        });
    }

    // Simulate race
    var second: u32 = 0;
    while (second < RACE_TIME) : (second += 1) {
        // Update positions
        for (reindeers.items) |*reindeer| {
            if (reindeer.flying) {
                reindeer.distance += reindeer.speed;
                reindeer.time_in_state += 1;
                if (reindeer.time_in_state == reindeer.fly_time) {
                    reindeer.flying = false;
                    reindeer.time_in_state = 0;
                }
            } else {
                reindeer.time_in_state += 1;
                if (reindeer.time_in_state == reindeer.rest_time) {
                    reindeer.flying = true;
                    reindeer.time_in_state = 0;
                }
            }
        }

        // Award points to leaders
        var max_distance: u32 = 0;
        for (reindeers.items) |reindeer| {
            if (reindeer.distance > max_distance) {
                max_distance = reindeer.distance;
            }
        }

        for (reindeers.items) |*reindeer| {
            if (reindeer.distance == max_distance) {
                reindeer.score += 1;
            }
        }
    }

    // Find max score
    var max_score: u32 = 0;
    for (reindeers.items) |reindeer| {
        if (reindeer.score > max_score) {
            max_score = reindeer.score;
        }
    }

    return try std.fmt.allocPrint(allocator, "{d}", .{max_score});
}

const Reindeer = struct {
    speed: u32,
    fly_time: u32,
    rest_time: u32,
    distance: u32,
    score: u32,
    time_in_state: u32,
    flying: bool,
};
