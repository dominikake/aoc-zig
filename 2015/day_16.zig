const std = @import("std");

const Sue = struct {
    id: u16,
    children: ?u8 = null,
    cats: ?u8 = null,
    samoyeds: ?u8 = null,
    pomeranians: ?u8 = null,
    akitas: ?u8 = null,
    vizslas: ?u8 = null,
    goldfish: ?u8 = null,
    trees: ?u8 = null,
    cars: ?u8 = null,
    perfumes: ?u8 = null,
};

const TargetValues = struct {
    const children: u8 = 3;
    const cats: u8 = 7;
    const samoyeds: u8 = 2;
    const pomeranians: u8 = 3;
    const akitas: u8 = 0;
    const vizslas: u8 = 0;
    const goldfish: u8 = 5;
    const trees: u8 = 3;
    const cars: u8 = 2;
    const perfumes: u8 = 1;
};

inline fn setProperty(sue: *Sue, prop: []const u8, value: u8) void {
    if (std.mem.eql(u8, prop, "children")) sue.children = value else if (std.mem.eql(u8, prop, "cats")) sue.cats = value else if (std.mem.eql(u8, prop, "samoyeds")) sue.samoyeds = value else if (std.mem.eql(u8, prop, "pomeranians")) sue.pomeranians = value else if (std.mem.eql(u8, prop, "akitas")) sue.akitas = value else if (std.mem.eql(u8, prop, "vizslas")) sue.vizslas = value else if (std.mem.eql(u8, prop, "goldfish")) sue.goldfish = value else if (std.mem.eql(u8, prop, "trees")) sue.trees = value else if (std.mem.eql(u8, prop, "cars")) sue.cars = value else if (std.mem.eql(u8, prop, "perfumes")) sue.perfumes = value;
}

fn parseSue(line: []const u8) !Sue {
    var sue = Sue{ .id = 0 }; // Initialize with all fields as null

    // Extract Sue number: "Sue 1: ..."
    const sue_prefix = "Sue ";
    const colon_idx = std.mem.indexOf(u8, line, ":") orelse return error.InvalidFormat;
    const id_str = line[sue_prefix.len..colon_idx];
    sue.id = try std.fmt.parseInt(u16, id_str, 10);

    // Parse properties: "goldfish: 9, cars: 0, samoyeds: 9"
    const props_str = line[colon_idx + 2 ..]; // Skip ": "
    var prop_iter = std.mem.tokenizeScalar(u8, props_str, ',');

    while (prop_iter.next()) |prop_pair| {
        // Find colon in "goldfish: 9"
        const colon_in_pair = std.mem.indexOfScalar(u8, prop_pair, ':') orelse return error.InvalidFormat;
        const prop_name = std.mem.trim(u8, prop_pair[0..colon_in_pair], " ");
        const prop_value_str = std.mem.trim(u8, prop_pair[colon_in_pair + 1 ..], " "); // Skip ":" and trim spaces
        const prop_value = try std.fmt.parseInt(u8, prop_value_str, 10);

        setProperty(&sue, prop_name, prop_value);
    }

    return sue;
}

fn matchesTarget(sue: Sue, part: u8) bool {
    return switch (part) {
        1 => matchesExact(sue),
        2 => matchesConditional(sue), // For part 2 when unlocked
        else => unreachable,
    };
}

fn matchesExact(sue: Sue) bool {
    if (sue.children) |v| {
        if (v != TargetValues.children) {
            // std.debug.print("Sue {}: children {} != {}\n", .{ sue.id, v, TargetValues.children });
            return false;
        }
    }
    if (sue.cats) |v| {
        if (v != TargetValues.cats) {
            // std.debug.print("Sue {}: cats {} != {}\n", .{ sue.id, v, TargetValues.cats });
            return false;
        }
    }
    if (sue.samoyeds) |v| {
        if (v != TargetValues.samoyeds) {
            // std.debug.print("Sue {}: samoyeds {} != {}\n", .{ sue.id, v, TargetValues.samoyeds });
            return false;
        }
    }
    if (sue.pomeranians) |v| {
        if (v != TargetValues.pomeranians) {
            // std.debug.print("Sue {}: pomeranians {} != {}\n", .{ sue.id, v, TargetValues.pomeranians });
            return false;
        }
    }
    if (sue.akitas) |v| {
        if (v != TargetValues.akitas) {
            // std.debug.print("Sue {}: akitas {} != {}\n", .{ sue.id, v, TargetValues.akitas });
            return false;
        }
    }
    if (sue.vizslas) |v| {
        if (v != TargetValues.vizslas) {
            // std.debug.print("Sue {}: vizslas {} != {}\n", .{ sue.id, v, TargetValues.vizslas });
            return false;
        }
    }
    if (sue.goldfish) |v| {
        if (v != TargetValues.goldfish) {
            // std.debug.print("Sue {}: goldfish {} != {}\n", .{ sue.id, v, TargetValues.goldfish });
            return false;
        }
    }
    if (sue.trees) |v| {
        if (v != TargetValues.trees) {
            // std.debug.print("Sue {}: trees {} != {}\n", .{ sue.id, v, TargetValues.trees });
            return false;
        }
    }
    if (sue.cars) |v| {
        if (v != TargetValues.cars) {
            // std.debug.print("Sue {}: cars {} != {}\n", .{ sue.id, v, TargetValues.cars });
            return false;
        }
    }
    if (sue.perfumes) |v| {
        if (v != TargetValues.perfumes) {
            // std.debug.print("Sue {}: perfumes {} != {}\n", .{ sue.id, v, TargetValues.perfumes });
            return false;
        }
    }
    return true;
}

fn matchesConditional(sue: Sue) bool {
    // cats and trees: greater than target
    if (sue.cats) |v| if (v <= TargetValues.cats) return false;
    if (sue.trees) |v| if (v <= TargetValues.trees) return false;

    // pomeranians and goldfish: less than target
    if (sue.pomeranians) |v| if (v >= TargetValues.pomeranians) return false;
    if (sue.goldfish) |v| if (v >= TargetValues.goldfish) return false;

    // all others: exact match
    if (sue.children) |v| if (v != TargetValues.children) return false;
    if (sue.samoyeds) |v| if (v != TargetValues.samoyeds) return false;
    if (sue.akitas) |v| if (v != TargetValues.akitas) return false;
    if (sue.vizslas) |v| if (v != TargetValues.vizslas) return false;
    if (sue.cars) |v| if (v != TargetValues.cars) return false;
    if (sue.perfumes) |v| if (v != TargetValues.perfumes) return false;

    return true;
}

fn testMatching() !void {
    const test_sues = [_]Sue{
        .{ .id = 1, .children = 3, .cats = 7, .samoyeds = 2 }, // Should match
        .{ .id = 2, .children = 3, .cats = 7, .samoyeds = 2 }, // Perfect match
        .{ .id = 3, .children = 4, .cats = 7, .samoyeds = 2 }, // Wrong children
        .{ .id = 4, .children = 3, .cats = 8, .samoyeds = 2 }, // Wrong cats
        .{ .id = 5, .children = 3, .cats = 7, .samoyeds = 2 }, // Perfect match
    };

    // Should find Sue 1 (or any of the matching Sues)
    var found_sue: ?u16 = null;
    for (test_sues) |sue| {
        if (matchesTarget(sue, 1)) {
            found_sue = sue.id;
            break;
        }
    }

    if (found_sue) |id| {
        std.debug.print("Test passed: Found Sue {}\n", .{id});
    } else {
        return error.TestFailed;
    }
}

pub fn part1(input: []const u8) !?[]const u8 {
    // Run test first
    try testMatching();

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        const sue = try parseSue(line);
        if (matchesTarget(sue, 1)) {
            const allocator = std.heap.page_allocator;
            const result = try std.fmt.allocPrint(allocator, "{}", .{sue.id});
            return result;
        }
    }

    return null;
}

pub fn part2(input: []const u8) !?[]const u8 {
    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        const sue = try parseSue(line);
        if (matchesTarget(sue, 2)) {
            const allocator = std.heap.page_allocator;
            const result = try std.fmt.allocPrint(allocator, "{}", .{sue.id});
            return result;
        }
    }

    return null;
}
