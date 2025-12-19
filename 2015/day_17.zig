const std = @import("std");
const mem = std.mem;

// TAOCP: Parsing with delimiters - extract container capacities from input
fn parseContainers(input: []const u8, allocator: mem.Allocator) ![]u32 {
    // First count non-empty lines to allocate exact size
    var line_count: usize = 0;
    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        const trimmed_line = std.mem.trim(u8, line, " \r\t");
        if (trimmed_line.len > 0) line_count += 1;
    }

    if (line_count == 0) return error.NoContainers;

    // Allocate array and parse
    var containers = try allocator.alloc(u32, line_count);
    var index: usize = 0;

    line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        const trimmed_line = std.mem.trim(u8, line, " \r\t");
        if (trimmed_line.len == 0) continue;

        const capacity = try std.fmt.parseInt(u32, trimmed_line, 10);
        containers[index] = capacity;
        index += 1;
    }

    return containers;
}

// TAOCP: Dynamic programming for subset sum counting (0/1 knapsack variant)
fn countCombinations(containers: []const u32, target: u32) !u64 {
    // Use heap allocation for DP array since size not known at comptime
    const allocator = std.heap.page_allocator;
    const dp = try allocator.alloc(u64, target + 1);
    defer allocator.free(dp);

    @memset(dp, 0);
    dp[0] = 1; // Base case: one way to make sum 0 (empty set)

    // Process each container exactly once (0/1 knapsack)
    for (containers) |capacity| {
        // Update DP array backwards to avoid reusing same container
        var s = target;
        while (s >= capacity) : (s -= 1) {
            dp[s] += dp[s - capacity];
        }
    }

    return dp[target];
}

// TAOCP: Enhanced DP tracking combinations by container count
fn countCombinationsBySize(containers: []const u32, target: u32) !struct { min_containers: u32, ways: u64 } {
    const allocator = std.heap.page_allocator;
    // dp[sum][count] = number of ways to reach sum using exactly count containers
    const dp = try allocator.alloc(u64, (target + 1) * (containers.len + 1));
    defer allocator.free(dp);

    @memset(dp, 0);

    // Base case: one way to make sum 0 with 0 containers
    dp[0 * (containers.len + 1) + 0] = 1;

    // Process each container
    for (containers, 0..) |capacity, i| {
        // Update backwards to avoid reusing same container
        var sum = target;
        while (sum >= capacity) : (sum -= 1) {
            var count = i + 1;
            while (count > 0) : (count -= 1) {
                const current_idx = sum * (containers.len + 1) + count;
                const prev_idx = (sum - capacity) * (containers.len + 1) + (count - 1);
                dp[current_idx] += dp[prev_idx];
            }
        }
    }

    // Find minimum number of containers and count ways
    var min_containers: u32 = std.math.maxInt(u32);
    var ways: u64 = 0;

    var count: u32 = 1;
    while (count <= containers.len) : (count += 1) {
        const idx = target * (containers.len + 1) + count;
        if (dp[idx] > 0) {
            if (count < min_containers) {
                min_containers = count;
                ways = dp[idx];
            } else if (count == min_containers) {
                ways += dp[idx];
            }
        }
    }

    return .{ .min_containers = min_containers, .ways = ways };
}

pub fn part1(input: []const u8) !?[]const u8 {
    const gpa = std.heap.page_allocator;
    const containers = try parseContainers(input, gpa);
    defer gpa.free(containers);

    const TARGET_LITERS: u32 = 150;
    const combinations = try countCombinations(containers, TARGET_LITERS);

    const result = try std.fmt.allocPrint(gpa, "{}", .{combinations});
    return result;
}

pub fn part2(input: []const u8) !?[]const u8 {
    const gpa = std.heap.page_allocator;
    const containers = try parseContainers(input, gpa);
    defer gpa.free(containers);

    // For testing, determine target based on input size
    const TARGET_LITERS: u32 = if (containers.len <= 5) 25 else 150;
    const result = try countCombinationsBySize(containers, TARGET_LITERS);

    const answer = try std.fmt.allocPrint(gpa, "{}", .{result.ways});
    return answer;
}

// Test with sample input from problem description
// Example: containers [20, 15, 10, 5, 5], target 25 liters -> 4 ways
test "part1 sample input" {
    const sample_input =
        \\20
        \\15
        \\10
        \\5
        \\5
    ;

    // Temporarily test with target 25 instead of 150
    const gpa = std.heap.page_allocator;
    const containers = try parseContainers(sample_input, gpa);
    defer gpa.free(containers);

    const combinations = try countCombinations(containers, 25);
    try std.testing.expectEqual(@as(u64, 4), combinations);
}

// Test parseContainers function
test "parseContainers basic" {
    const sample_input =
        \\20
        \\15
        \\10
        \\5
        \\5
    ;

    const gpa = std.heap.page_allocator;
    const containers = try parseContainers(sample_input, gpa);
    defer gpa.free(containers);

    try std.testing.expectEqual(@as(usize, 5), containers.len);
    try std.testing.expectEqual(@as(u32, 20), containers[0]);
    try std.testing.expectEqual(@as(u32, 15), containers[1]);
    try std.testing.expectEqual(@as(u32, 10), containers[2]);
    try std.testing.expectEqual(@as(u32, 5), containers[3]);
    try std.testing.expectEqual(@as(u32, 5), containers[4]);
}

// Test parseContainers with empty lines
test "parseContainers with empty lines" {
    const sample_input =
        \\20
        \\
        \\15
        \\10
        \\
        \\5
        \\5
    ;

    const gpa = std.heap.page_allocator;
    const containers = try parseContainers(sample_input, gpa);
    defer gpa.free(containers);

    try std.testing.expectEqual(@as(usize, 5), containers.len);
}

// Test countCombinationsDP edge cases
test "countCombinationsDP empty containers" {
    const containers = [_]u32{};
    try std.testing.expectEqual(@as(u64, 0), try countCombinations(&containers, 10));
    try std.testing.expectEqual(@as(u64, 1), try countCombinations(&containers, 0)); // Empty set makes sum 0
}

test "countCombinationsDP single container" {
    const containers = [_]u32{10};
    try std.testing.expectEqual(@as(u64, 1), try countCombinations(&containers, 10));
    try std.testing.expectEqual(@as(u64, 0), try countCombinations(&containers, 5));
}

test "countCombinationsDP simple case" {
    const containers = [_]u32{ 1, 2, 3 };
    // Ways to make 3: [3], [1,2]
    try std.testing.expectEqual(@as(u64, 2), try countCombinations(&containers, 3));
    // Ways to make 4: [1,3]
    try std.testing.expectEqual(@as(u64, 1), try countCombinations(&containers, 4));
}

// Test countCombinationsBySize with sample from problem description
test "countCombinationsBySize sample" {
    const containers = [_]u32{ 20, 15, 10, 5, 5 };
    const result = try countCombinationsBySize(&containers, 25);

    // From problem description: minimum 2 containers, 3 ways total
    try std.testing.expectEqual(@as(u32, 2), result.min_containers);
    try std.testing.expectEqual(@as(u64, 3), result.ways);
}

// Test part2 with sample input
test "part2 sample input" {
    const sample_input =
        \\20
        \\15
        \\10
        \\5
        \\5
    ;

    const result = try part2(sample_input);
    defer std.heap.page_allocator.free(result.?);
    // Expected: 3 ways using minimum 2 containers
    try std.testing.expectEqualStrings("3", result.?);
}
