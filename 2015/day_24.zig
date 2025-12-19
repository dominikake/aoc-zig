const std = @import("std");

pub fn part1(input: []const u8) !?[]const u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Parse weights
    var weights = try allocator.alloc(usize, 50);
    defer allocator.free(weights);
    var weight_count: usize = 0;

    var iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (iter.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t\r");
        if (trimmed.len > 0) {
            weights[weight_count] = try std.fmt.parseInt(usize, trimmed, 10);
            weight_count += 1;
        }
    }

    const weights_slice = weights[0..weight_count];
    const total_weight = sum(weights_slice);
    const target_weight = total_weight / 3;

    // Sort descending for better pruning
    std.mem.sort(usize, weights_slice, {}, comptime std.sort.desc(usize));

    // Find minimum package count that can reach target
    var min_packages: usize = 1;
    while (min_packages <= weight_count) : (min_packages += 1) {
        if (hasCombinationOfSize(weights_slice, target_weight, min_packages)) {
            break;
        }
    }

    // Find best quantum entanglement
    var result = try findOptimalQE(allocator, weights_slice, target_weight, min_packages);
    defer result.deinit();
    return try allocator.dupe(u8, try result.toString(allocator, 10, .lower));
}

pub fn part2(input: []const u8) !?[]const u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Parse weights
    var weights = try allocator.alloc(usize, 50);
    defer allocator.free(weights);
    var weight_count: usize = 0;

    var iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (iter.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t\r");
        if (trimmed.len > 0) {
            weights[weight_count] = try std.fmt.parseInt(usize, trimmed, 10);
            weight_count += 1;
        }
    }

    const weights_slice = weights[0..weight_count];
    const total_weight = sum(weights_slice);
    const target_weight = total_weight / 4;

    // Sort descending for better pruning
    std.mem.sort(usize, weights_slice, {}, comptime std.sort.desc(usize));

    // Find minimum package count that can reach target
    var min_packages: usize = 1;
    while (min_packages <= weight_count) : (min_packages += 1) {
        if (hasCombinationOfSize(weights_slice, target_weight, min_packages)) {
            break;
        }
    }

    // Simple brute force: try all combinations of min_packages to find optimal QE
    var best_qe = try findOptimalQESystematic(allocator, weights_slice, target_weight, min_packages);
    defer best_qe.deinit();

    return try allocator.dupe(u8, try best_qe.toString(allocator, 10, .lower));
}

// Helper functions
fn sum(slice: []const usize) usize {
    var total: usize = 0;
    for (slice) |item| {
        total += item;
    }
    return total;
}

fn hasCombinationOfSize(
    weights: []const usize,
    target: usize,
    max_items: usize,
) bool {
    return hasCombinationOfSizeRec(weights, target, max_items, 0, 0, 0);
}

fn hasCombinationOfSizeRec(
    weights: []const usize,
    target: usize,
    max_items: usize,
    index: usize,
    current_sum: usize,
    current_count: usize,
) bool {
    if (current_sum == target and current_count <= max_items) {
        return true;
    }
    if (current_sum > target or current_count > max_items or index >= weights.len) {
        return false;
    }

    // Try including current weight
    if (hasCombinationOfSizeRec(weights, target, max_items, index + 1, current_sum + weights[index], current_count + 1)) {
        return true;
    }

    // Try excluding current weight
    return hasCombinationOfSizeRec(weights, target, max_items, index + 1, current_sum, current_count);
}

// Find optimal quantum entanglement for Part 1
fn findOptimalQE(
    allocator: std.mem.Allocator,
    weights: []const usize,
    target: usize,
    min_packages: usize,
) !std.math.big.int.Managed {
    var best_qe = try std.math.big.int.Managed.init(allocator);
    try best_qe.set(std.math.maxInt(usize));

    var current_qe = try std.math.big.int.Managed.init(allocator);
    try current_qe.set(1);

    try searchOptimal(allocator, weights, target, min_packages, 0, 0, 0, &current_qe, &best_qe, 0);

    return best_qe;
}

// More systematic approach: generate combinations using indexes
fn findOptimalQESystematic(
    allocator: std.mem.Allocator,
    weights: []const usize,
    target: usize,
    required_packages: usize,
) !std.math.big.int.Managed {
    var best_qe = try std.math.big.int.Managed.init(allocator);
    try best_qe.set(std.math.maxInt(usize));

    // Generate combinations systematically
    const combo = try allocator.alloc(usize, required_packages);
    defer allocator.free(combo);

    try generateCombinations(allocator, weights, target, required_packages, 0, combo, 0, &best_qe);

    return best_qe;
}

fn generateCombinations(
    allocator: std.mem.Allocator,
    weights: []const usize,
    target: usize,
    required_packages: usize,
    start_idx: usize,
    combo: []usize,
    combo_len: usize,
    best_qe: *std.math.big.int.Managed,
) !void {
    if (combo_len == required_packages) {
        // Check if this combination sums to target
        var combo_sum: usize = 0;
        for (combo[0..combo_len]) |w| {
            combo_sum += w;
        }

        if (combo_sum == target) {
            // Calculate QE using big ints to avoid overflow
            var qe = try std.math.big.int.Managed.init(allocator);
            defer qe.deinit();
            try qe.set(1);

            for (combo[0..combo_len]) |w| {
                var w_big = try std.math.big.int.Managed.init(allocator);
                defer w_big.deinit();
                try w_big.set(w);
                try qe.mul(&qe, &w_big);
            }

            if (qe.order(best_qe.*) == .lt) {
                best_qe.* = try qe.clone();
            }
        }
        return;
    }

    if (start_idx >= weights.len) {
        return;
    }

    var i: usize = start_idx;
    while (i < weights.len) : (i += 1) {
        combo[combo_len] = weights[i];
        try generateCombinations(allocator, weights, target, required_packages, i + 1, combo, combo_len + 1, best_qe);
    }
}

// Search algorithm with validation for Part 1
fn searchOptimal(
    allocator: std.mem.Allocator,
    weights: []const usize,
    target: usize,
    max_packages: usize,
    index: usize,
    current_sum: usize,
    package_count: usize,
    current_qe: *std.math.big.int.Managed,
    best_qe: *std.math.big.int.Managed,
    used_mask: u32,
) !void {
    if (current_sum == target and package_count <= max_packages) {
        // For Part 1: check if remaining items can be split into 2 equal groups
        if (canPartitionSimple(weights, target, used_mask)) {
            if (current_qe.order(best_qe.*) == .lt) {
                best_qe.* = try current_qe.clone();
            }
        }
        return;
    }

    if (current_sum > target or package_count > max_packages or index >= weights.len) {
        return;
    }

    if (current_qe.order(best_qe.*) != .lt) {
        return;
    }

    // Try including current weight
    const weight = weights[index];
    if (current_sum + weight <= target) {
        var weight_big = try std.math.big.int.Managed.init(allocator);
        defer weight_big.deinit();
        try weight_big.set(weight);

        var old_qe = try current_qe.clone();
        defer old_qe.deinit();

        try current_qe.mul(current_qe, &weight_big);

        try searchOptimal(
            allocator,
            weights,
            target,
            max_packages,
            index + 1,
            current_sum + weight,
            package_count + 1,
            current_qe,
            best_qe,
            used_mask | (@as(u32, 1) << @intCast(index)),
        );

        current_qe.* = old_qe;
    }

    // Try excluding current weight
    try searchOptimal(
        allocator,
        weights,
        target,
        max_packages,
        index + 1,
        current_sum,
        package_count,
        current_qe,
        best_qe,
        used_mask,
    );
}

// Simple validation for Part 1 (check if remaining can be split into 2 equal groups)
fn canPartitionSimple(
    weights: []const usize,
    target: usize,
    used_mask: u32,
) bool {
    const total_weight = sum(weights);
    const used_weight = getSumFromMask(weights, used_mask);
    const remaining_weight = total_weight - used_weight;

    // Simple check: can remaining be divided into 2 groups of target weight?
    return remaining_weight == target * 2;
}

fn getSumFromMask(weights: []const usize, mask: u32) usize {
    var total: usize = 0;
    var i: usize = 0;
    while (i < weights.len) : (i += 1) {
        if ((mask >> @intCast(i)) & 1 == 1) {
            total += weights[i];
        }
    }
    return total;
}
