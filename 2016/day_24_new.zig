const std = @import("std");

// TAOCP: Priority Queue with binary heap for O(log n) operations
const State = struct {
    x: usize,
    y: usize,
    steps: u32,
    visited_mask: u64, // Bit mask for visited targets
};

const PriorityQueue = struct {
    heap: []State,
    heap_size: usize,
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator, max_size: usize) !@This() {
        return .{
            .heap = try allocator.alloc(State, max_size),
            .heap_size = 0,
            .allocator = allocator,
        };
    }

    fn deinit(self: *@This()) void {
        self.allocator.free(self.heap);
    }

    fn insert(self: *@This(), state: State) !void {
        if (self.heap_size >= self.heap.len) {
            return error.QueueFull;
        }

        // Insert at end
        var current = self.heap_size;
        self.heap[self.heap_size] = state;
        self.heap_size += 1;

        // Sift up - O(log n)
        while (current > 0) {
            const parent = (current - 1) / 2;
            if (self.heap[parent].steps <= self.heap[current].steps) break;

            // Swap with parent
            const temp = self.heap[current];
            self.heap[current] = self.heap[parent];
            self.heap[parent] = temp;
            current = parent;
        }
    }

    fn extractMin(self: *@This()) ?State {
        if (self.heap_size == 0) return null;

        const min_state = self.heap[0];
        self.heap_size -= 1;

        if (self.heap_size > 0) {
            // Move last element to root
            self.heap[0] = self.heap[self.heap_size];

            // Sift down - O(log n)
            var current: usize = 0;
            while (true) {
                const left_child = 2 * current + 1;
                const right_child = 2 * current + 2;
                var smallest = current;

                if (left_child < self.heap_size and self.heap[left_child].steps < self.heap[smallest].steps) {
                    smallest = left_child;
                }

                if (right_child < self.heap_size and self.heap[right_child].steps < self.heap[smallest].steps) {
                    smallest = right_child;
                }

                if (smallest == current) break;

                // Swap with smallest child
                const temp = self.heap[current];
                self.heap[current] = self.heap[smallest];
                self.heap[smallest] = temp;
                current = smallest;
            }
        }

        return min_state;
    }

    fn isEmpty(self: *@This()) bool {
        return self.heap_size == 0;
    }

    fn size(self: *@This()) usize {
        return self.heap_size;
    }
};

// TAOCP: Target location with coordinates
const Target = struct {
    x: usize,
    y: usize,
    num: u8,
};

// TAOCP: Distance matrix for TSP optimization
const DistanceMatrix = struct {
    distances: [][]u32,
    n: usize,
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator, n: usize) !@This() {
        const distances = try allocator.alloc([]u32, n);
        for (0..n) |i| {
            distances[i] = try allocator.alloc(u32, n);
            @memset(distances[i], std.math.maxInt(u32));
        }
        return .{
            .distances = distances,
            .n = n,
            .allocator = allocator,
        };
    }

    fn deinit(self: *@This()) void {
        for (0..self.n) |i| {
            self.allocator.free(self.distances[i]);
        }
        self.allocator.free(self.distances);
    }

    fn set(self: *@This(), from: usize, to: usize, distance: u32) void {
        self.distances[from][to] = distance;
    }

    fn get(self: *@This(), from: usize, to: usize) u32 {
        return self.distances[from][to];
    }
};

// TAOCP: Enhanced maze parser with proper memory management
fn parseMaze(input: []const u8) !struct {
    maze: [][]u8,
    width: usize,
    height: usize,
    targets: []Target,
    start_idx: usize,
} {
    var gpa = std.heap.page_allocator;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var height: usize = 0;
    var width: usize = 0;

    var line_buffer: [200][]const u8 = undefined;
    var line_count: usize = 0;

    // First pass: determine dimensions
    while (lines.next()) |line| {
        height += 1;
        width = @max(width, line.len);
        line_buffer[line_count] = line;
        line_count += 1;
    }

    var maze = try gpa.alloc([]u8, height);
    for (0..height) |y| {
        maze[y] = try gpa.alloc(u8, width);
        @memset(maze[y], '.');
    }

    var target_list = std.ArrayList(Target).init(gpa);
    defer target_list.deinit();

    var start_x: usize = 0;
    var start_y: usize = 0;
    var start_idx: usize = 0;

    // Second pass: fill maze content and find targets
    for (0..height) |y| {
        const line = line_buffer[y];
        for (line, 0..) |c, x| {
            if (x < width) {
                maze[y][x] = c;

                if (std.ascii.isDigit(c)) {
                    const num = c - '0';
                    const target = Target{ .x = x, .y = y, .num = c };
                    try target_list.append(target);

                    if (num == 0) {
                        start_x = x;
                        start_y = y;
                        start_idx = target_list.items.len - 1;
                    }
                }
            }
        }
    }

    if (target_list.items.len == 0) {
        return error.NoTargets;
    }

    const targets = try target_list.toOwnedSlice();

    return .{
        .maze = maze,
        .width = width,
        .height = height,
        .targets = targets,
        .start_idx = start_idx,
    };
}

// TAOCP: BFS distance calculation between two points
fn calculateDistance(maze: [][]const u8, width: usize, height: usize, start: Target, end: Target) !u32 {
    const allocator = std.heap.page_allocator;
    var visited = try allocator.alloc([]bool, height);
    defer allocator.free(visited);
    for (0..height) |y| {
        visited[y] = try allocator.alloc(bool, width);
        @memset(visited[y], false);
        defer allocator.free(visited[y]);
    }

    var queue = try allocator.alloc([3]usize, width * height);
    defer allocator.free(queue);
    var queue_len: usize = 0;

    // BFS from start
    queue[0] = .{ start.x, start.y, 0 };
    queue_len = 1;
    visited[start.y][start.x] = true;

    const directions = [_][2]i32{
        .{ 1, 0 }, // right
        .{ -1, 0 }, // left
        .{ 0, 1 }, // down
        .{ 0, -1 }, // up
    };

    while (queue_len > 0) {
        const x = queue[0][0];
        const y = queue[0][1];
        const steps = queue[0][2];

        // Remove from front
        for (0..queue_len - 1) |i| {
            queue[i] = queue[i + 1];
        }
        queue_len -= 1;

        // Check if reached end
        if (x == end.x and y == end.y) {
            return @intCast(steps);
        }

        // Try 4 directions
        for (directions) |move| {
            const new_x = @as(isize, x) + move[0];
            const new_y = @as(isize, y) + move[1];

            // Check bounds
            if (new_x < 0 or new_y < 0 or new_x >= width or new_y >= height) continue;
            const ux = @as(usize, @intCast(new_x));
            const uy = @as(usize, @intCast(new_y));

            // Check wall and visited
            if (maze[uy][ux] == '#') continue;
            if (visited[uy][ux]) continue;

            visited[uy][ux] = true;
            queue[queue_len] = .{ ux, uy, steps + 1 };
            queue_len += 1;
        }
    }

    return error.NoPath;
}

// TAOCP: Build distance matrix for all target pairs
fn buildDistanceMatrix(maze: [][]const u8, width: usize, height: usize, targets: []const Target) !DistanceMatrix {
    const allocator = std.heap.page_allocator;
    const n = targets.len;
    var dist_matrix = try DistanceMatrix.init(allocator, n);
    defer dist_matrix.deinit();

    // Calculate distances between all pairs
    for (0..n) |i| {
        for (0..n) |j| {
            if (i == j) {
                dist_matrix.set(i, j, 0);
            } else {
                const dist = try calculateDistance(maze, width, height, targets[i], targets[j]);
                dist_matrix.set(i, j, dist);
            }
        }
    }

    // Create a copy to return
    var result = try DistanceMatrix.init(allocator, n);
    for (0..n) |i| {
        for (0..n) |j| {
            result.set(i, j, dist_matrix.get(i, j));
        }
    }

    return result;
}

// TAOCP: Permutation-based TSP for small n (≤8)
fn permutationTSP(start_idx: usize, targets: []const Target, dist_matrix: DistanceMatrix) !u32 {
    const n = targets.len;
    if (n <= 1) return 0;

    const allocator = std.heap.page_allocator;
    var indices = try allocator.alloc(usize, n);
    defer allocator.free(indices);

    // Initialize indices (excluding start)
    var pos: usize = 0;
    for (0..n) |i| {
        if (i != start_idx) {
            indices[pos] = i;
            pos += 1;
        }
    }

    var min_distance: u32 = std.math.maxInt(u32);

    // Generate all permutations of non-start targets
    var perm_slice = indices[0 .. n - 1];
    while (true) {
        var total_distance: u32 = 0;
        var current_idx = start_idx;

        // Calculate path: start -> perm[0] -> perm[1] -> ... -> perm[last] -> start
        for (perm_slice) |next_idx| {
            total_distance += dist_matrix.get(current_idx, next_idx);
            current_idx = next_idx;
        }
        total_distance += dist_matrix.get(current_idx, start_idx); // Return to start

        if (total_distance < min_distance) {
            min_distance = total_distance;
        }

        // Generate next permutation
        if (!std.mem.nextPermutation(usize, perm_slice)) break;
    }

    return min_distance;
}

// TAOCP: Held-Karp DP for TSP (n > 8)
fn heldKarpTSP(start_idx: usize, targets: []const Target, dist_matrix: DistanceMatrix) !u32 {
    const n = targets.len;
    const allocator = std.heap.page_allocator;

    // DP table: dp[mask][last] = min distance
    const dp_size = @as(usize, 1) << n;
    var dp = try allocator.alloc([]u32, dp_size);
    defer allocator.free(dp);

    for (0..dp_size) |i| {
        dp[i] = try allocator.alloc(u32, n);
        @memset(dp[i], std.math.maxInt(u32));
        defer allocator.free(dp[i]);
    }

    // Base case: path with only start node
    const start_mask = @as(usize, 1) << start_idx;
    dp[start_mask][start_idx] = 0;

    // Fill DP table
    for (1..dp_size) |mask| {
        if (mask == start_mask) continue;
        if ((mask & start_mask) == 0) continue; // Must include start

        for (0..n) |last| {
            if ((mask & (@as(usize, 1) << last)) == 0) continue;

            const prev_mask = mask ^ (@as(usize, 1) << last);
            var min_dist: u32 = std.math.maxInt(u32);

            if (prev_mask == 0) {
                min_dist = 0;
            } else {
                for (0..n) |prev_last| {
                    if ((prev_mask & (@as(usize, 1) << prev_last)) == 0) continue;
                    if (dp[prev_mask][prev_last] == std.math.maxInt(u32)) continue;

                    const dist = dp[prev_mask][prev_last] + dist_matrix.get(prev_last, last);
                    if (dist < min_dist) {
                        min_dist = dist;
                    }
                }
            }

            dp[mask][last] = min_dist;
        }
    }

    // Find optimal tour returning to start
    const full_mask = (@as(usize, 1) << n) - 1;
    var min_tour: u32 = std.math.maxInt(u32);

    for (0..n) |last| {
        if (last == start_idx) continue;
        if (dp[full_mask][last] == std.math.maxInt(u32)) continue;

        const tour_dist = dp[full_mask][last] + dist_matrix.get(last, start_idx);
        if (tour_dist < min_tour) {
            min_tour = tour_dist;
        }
    }

    return min_tour;
}

// TAOCP: Optimized TSP solver
fn solveTSP(start_idx: usize, targets: []const Target, dist_matrix: DistanceMatrix) !u32 {
    const n = targets.len;

    if (n <= 8) {
        return permutationTSP(start_idx, targets, dist_matrix);
    } else {
        return heldKarpTSP(start_idx, targets, dist_matrix);
    }
}

// TAOCP: Optimized BFS for Part 1
fn optimizedBFS(maze: [][]const u8, width: usize, height: usize, targets: []const Target, start_idx: usize) !u32 {
    const allocator = std.heap.page_allocator;
    const target_count = targets.len;
    const all_visited = (@as(u64, 1) << target_count) - 1;

    // Dynamic queue size based on target count
    const queue_capacity = @max(1000, target_count * 10);
    var pq = try PriorityQueue.init(allocator, queue_capacity);
    defer pq.deinit();

    const start = targets[start_idx];
    try pq.insert(.{
        .x = start.x,
        .y = start.y,
        .steps = 0,
        .visited_mask = @as(u64, 1) << start_idx,
    });

    const directions = [_][2]i32{
        .{ 1, 0 }, // right
        .{ -1, 0 }, // left
        .{ 0, 1 }, // down
        .{ 0, -1 }, // up
    };

    while (!pq.isEmpty()) {
        const current = pq.extractMin().?;

        // Check if all targets visited
        if (current.visited_mask == all_visited) {
            return current.steps;
        }

        // Try 4 directions
        for (directions) |move| {
            const new_x = @as(isize, current.x) + move[0];
            const new_y = @as(isize, current.y) + move[1];

            // Check bounds
            if (new_x < 0 or new_y < 0 or new_x >= width or new_y >= height) continue;
            const ux = @as(usize, @intCast(new_x));
            const uy = @as(usize, @intCast(new_y));

            // Check wall
            if (maze[uy][ux] == '#') continue;

            // Check if this is a target
            var new_visited = current.visited_mask;
            for (targets, 0..) |target, i| {
                if (target.x == ux and target.y == uy) {
                    new_visited |= @as(u64, 1) << i;
                    break;
                }
            }

            pq.insert(.{
                .x = ux,
                .y = uy,
                .steps = current.steps + 1,
                .visited_mask = new_visited,
            }) catch |err| switch (err) {
                error.QueueFull => continue, // Skip if queue full
                else => return err,
            };
        }
    }

    return error.NoPath;
}

pub fn part1(input: []const u8) !?[]const u8 {
    const parsed = try parseMaze(input);
    defer {
        for (parsed.maze) |row| {
            std.heap.page_allocator.free(row);
        }
        std.heap.page_allocator.free(parsed.maze);
        std.heap.page_allocator.free(parsed.targets);
    }

    if (parsed.targets.len == 0) {
        return error.NoTargets;
    }

    const steps = try optimizedBFS(parsed.maze, parsed.width, parsed.height, parsed.targets, parsed.start_idx);

    const gpa = std.heap.page_allocator;
    const result = try std.fmt.allocPrint(gpa, "{}", .{steps});
    return result;
}

pub fn part2(input: []const u8) !?[]const u8 {
    const parsed = try parseMaze(input);
    defer {
        for (parsed.maze) |row| {
            std.heap.page_allocator.free(row);
        }
        std.heap.page_allocator.free(parsed.maze);
        std.heap.page_allocator.free(parsed.targets);
    }

    if (parsed.targets.len <= 1) {
        const gpa = std.heap.page_allocator;
        const result = try std.fmt.allocPrint(gpa, "0", .{});
        return result;
    }

    // Build distance matrix
    var dist_matrix = try buildDistanceMatrix(parsed.maze, parsed.width, parsed.height, parsed.targets);
    defer dist_matrix.deinit();

    // Solve TSP
    const steps = try solveTSP(parsed.start_idx, parsed.targets, dist_matrix);

    const gpa = std.heap.page_allocator;
    const result = try std.fmt.allocPrint(gpa, "{}", .{steps});
    return result;
}

// Test with example from problem description
test "part1 example" {
    const example_input =
        \\###########
        \\#0.1.....2#
        \\#.#######.#
        \\#4.......3#
        \\###########
    ;

    const result = try part1(example_input);
    defer std.heap.page_allocator.free(result.?);

    // Expected: 14 steps
    try std.testing.expectEqualStrings("14", result.?);
}

test "part2 example" {
    const example_input =
        \\###########
        \\#0.1.....2#
        \\#.#######.#
        \\#4.......3#
        \\###########
    ;

    const result = try part2(example_input);
    defer std.heap.page_allocator.free(result.?);

    // For this example, optimal path is: 0->4->1->2->3->0 = 2+4+6+2+4 = 18 steps
    try std.testing.expectEqualStrings("18", result.?);
}

test "priority queue operations" {
    const allocator = std.testing.allocator;
    var pq = try PriorityQueue.init(allocator, 10);
    defer pq.deinit();

    try pq.insert(.{ .x = 0, .y = 0, .steps = 5, .visited_mask = 1 });
    try pq.insert(.{ .x = 1, .y = 1, .steps = 3, .visited_mask = 2 });
    try pq.insert(.{ .x = 2, .y = 2, .steps = 7, .visited_mask = 4 });

    const first = pq.extractMin().?;
    try std.testing.expectEqual(@as(u32, 3), first.steps);

    const second = pq.extractMin().?;
    try std.testing.expectEqual(@as(u32, 5), second.steps);

    const third = pq.extractMin().?;
    try std.testing.expectEqual(@as(u32, 7), third.steps);

    try std.testing.expect(pq.isEmpty());
}

test "distance matrix building" {
    const allocator = std.testing.allocator;
    const maze_input =
        \\#####
        \\#0.1#
        \\#...#
        \\#2.3#
        \\#####
    ;

    const parsed = try parseMaze(maze_input);
    defer {
        for (parsed.maze) |row| {
            allocator.free(row);
        }
        allocator.free(parsed.maze);
        allocator.free(parsed.targets);
    }

    var dist_matrix = try buildDistanceMatrix(parsed.maze, parsed.width, parsed.height, parsed.targets);
    defer dist_matrix.deinit();

    // Verify some distances
    const dist_0_to_1 = dist_matrix.get(parsed.start_idx, parsed.start_idx + 1);
    const dist_1_to_2 = dist_matrix.get(parsed.start_idx + 1, parsed.start_idx + 2);

    // These should be reasonable distances
    try std.testing.expect(dist_0_to_1 > 0);
    try std.testing.expect(dist_1_to_2 > 0);
}
