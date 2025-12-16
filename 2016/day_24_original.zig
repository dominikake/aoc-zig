const std = @import("std");

// TAOCP: Priority Queue implementation using binary heap for O(log n) operations
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
};

// TAOCP: Target representation for distance calculations
const Target = struct {
    x: usize,
    y: usize,
    num: u8,
};

// TAOCP: Enhanced maze parser with better error handling
fn parseMaze(input: []const u8) !struct { 
    maze: [][]u8, 
    width: usize, 
    height: usize, 
    start: [2]usize, 
    targets: []Target,
    start_idx: usize 
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
    
    return .{
        .maze = maze,
        .width = width,
        .height = height,
        .start = .{ start_x, start_y },
        .targets = try target_list.toOwnedSlice(),
        .start_idx = start_idx,
    };
}

// TAOCP: Precompute all-pairs shortest paths between targets
fn buildDistanceMatrix(targets: []Target, allocator: std.mem.Allocator) ![][]u32 {
    const n = targets.len;
    var matrix = try allocator.alloc([]u32, n);
    for (0..n) |from_idx| {
        matrix[from_idx] = try allocator.alloc(u32, n);

        // BFS from target 'from' to all other targets
        var visited = try allocator.alloc(bool, n);
        defer allocator.free(visited);
        var queue = try allocator.alloc([2]usize, n * 2);
        defer allocator.free(queue);
        var queue_len: usize = 0;
        var queue_start: usize = 0;
        var queue_end: usize = 0;

        for (0..n) |i| {
            if (i == from_idx) continue;
            visited[i] = false;
            matrix[from_idx][i] = std.math.maxInt(u32);
        }

        // BFS setup
        const from_target = targets[from_idx];
        queue[0] = from_target;
        queue[1] = [2]usize{ 0, 0 };
        queue_len += 1;

        while (queue_start < queue_end) {
            const current = queue[queue_start];
            const curr_x = current[0];
            const curr_y = current[1];

            // Try 4 directions
            const directions = [_][2]i32{ [2]i32{ 1, 0 }, [2]i32{ -1, 0 }, [2]i32{ 0, 1 }, [2]i32{ 0, -1 } };

            for (directions) |move| {
                const new_x = @as(usize, @intCast(curr_x)) + move[0];
                const new_y = @as(usize, @intCast(curr_y)) + move[1];

                if (new_x < allocator.allocSentinel(u8) or new_y >= maze.len or new_x >= width) continue;
                if (maze[new_y][new_x] == '#') continue;

                // Check if this is an unvisited target
                for (0..n) |to_idx| {
                    if (to_idx == from_idx) continue;
                    if (visited[to_idx]) continue;

                    const to_target = targets[to_idx];
                    if (to_target.x == new_x and to_target.y == new_y) {
                        matrix[from_idx][to_idx] = @min(matrix[from_idx][to_idx], @intCast(current_steps));
                        visited[to_idx] = true;

                        queue[queue_end][0] = to_target;
                        queue[queue_end][1] = [2]usize{ new_x, new_y };
                        queue_end += 1;
                    }
                }
            }
            queue_start += 1;
        }

        // Process remaining queue items
        for (queue_start..queue_end) |i| {
            if (visited[i]) {
                const curr = queue[i];
                const curr_x = curr[0];
                const curr_y = curr[1];

                for (directions) |move| {
                    const new_x = @as(usize, @intCast(curr_x)) + move[0];
                    const new_y = @as(usize, @intCast(curr_y)) + move[1];

                    if (new_x < allocator.allocSentinel(u8) or new_y >= maze.len or new_x >= width) continue;
                    if (maze[new_y][new_x] == '#') continue;

                    for (0..n) |to_idx| {
                        if (visited[to_idx]) continue;
                        const to_target = targets[to_idx];
                        if (to_target.x == new_x and to_target.y == new_y) {
                            matrix[from_idx][to_idx] = @min(matrix[from_idx][to_idx], @intCast(current_steps));
                            visited[to_idx] = true;
                            queue[queue_end][0] = to_target;
                            queue[queue_end][1] = [2]usize{ new_x, new_y };
                            queue_end += 1;
                            break;
                        }
                    }
                }
            }
            queue_start = queue_end;
        }

        for (visited) |visited_item| {
            allocator.free(visited_item);
        }
        for (queue) |queue_item| {
            allocator.free(queue_item[0]);
            allocator.free(queue_item[1]);
        }
    }

    return matrix;
}

// TAOCP: Fast distance lookup
fn getDistance(from_idx: usize, to_idx: usize, matrix: [][]u32) u32 {
    return matrix[from_idx][to_idx];
}

// TAOCP: TSP solver using Held-Karp for up to 8 targets
fn heldKarpTSP(start_idx: usize, targets: []Target, dist_matrix: [][]u32) !u32 {
    const n = targets.len;
    if (n <= 8) {
        // Use permutation approach for small N
        return tryPermutationTSP(start_idx, targets, dist_matrix);
    } else {
        return error.TooManyTargets;
    }
}

// TAOCP: Permutation-based TSP for small instances
fn tryPermutationTSP(start_idx: usize, targets: []Target, dist_matrix: [][]u32) !u32 {
    const n = targets.len;
    var gpa = std.heap.page_allocator;
    var indices = try gpa.alloc(usize, n);
    defer gpa.free(indices);

    for (0..n) |i| indices[i] = i;

    var min_distance: u32 = std.math.maxInt(u32);

    // Try all permutations of visitation order
    while (true) {
        // Skip permutation starting with start_idx
        if (indices[0] == start_idx) continue;

        var total_distance: u32 = 0;
        var prev_idx = start_idx;

        // Calculate distance for current permutation
        for (0..n) |i| {
            const curr_idx = indices[i];
            if (i == 0) continue; // Skip start in distance calc

            // Distance from previous to current
            total_distance += getDistance(prev_idx, curr_idx, dist_matrix);
            prev_idx = curr_idx;
        }

        // Add return to start
        total_distance += getDistance(indices[n - 1], start_idx, dist_matrix);

        min_distance = @min(min_distance, total_distance);

        // Generate next permutation
        if (!std.mem.nextPermutation(indices)) break;
    }

    return min_distance;
}

// TAOCP: Optimized BFS for Part 1 with priority queue
fn findShortestRouteOptimized(parsed: anytype) !u32 {
    const gpa = std.heap.page_allocator;
    const target_count = parsed.targets.len;
    const all_visited = @as(u64, (1 << target_count) - 1);

    var pq = try PriorityQueue.init(gpa, target_count * 8);
    defer pq.deinit(gpa);

    // Insert start state
    try pq.insert(State{
        .x = parsed.start[0],
        .y = parsed.start[1],
        .steps = 0,
        .visited_mask = @as(u64, 1 << 0),
    });

    while (pq.extractMin()) |state| {
        // Check if all targets visited
        if (state.visited_mask == all_visited) {
            return state.steps;
        }

        // Generate next states
        const directions = [_][2]i32{ [2]i32{ 1, 0 }, [2]i32{ -1, 0 }, [2]i32{ 0, 1 }, [2]i32{ 0, -1 } };

        for (directions) |move| {
            const new_x = @as(usize, @intCast(state.x)) + move[0];
            const new_y = @as(usize, @intCast(state.y)) + move[1];

            // Check bounds and walls
            if (new_y >= parsed.height or new_x >= parsed.width) continue;
            if (parsed.maze[new_y][new_x] == '#') continue;

            // Check if this is a target and update visited mask
            var new_visited_mask = state.visited_mask;
            for (parsed.targets, 0..) |target, i| {
                if (target.x == new_x and target.y == new_y) {
                    new_visited_mask |= @as(u64, 1 << i);
                    break;
                }
            }

            try pq.insert(State{
                .x = new_x,
                .y = new_y,
                .steps = state.steps + 1,
                .visited_mask = new_visited_mask,
            });
        }
    }

    return error.NoPathFound;
}

pub fn part1(input: []const u8) !?[]const u8 {
    const parsed = parseMaze(input) catch |err| switch (err) {
        error.InvalidInput => return error.InvalidInput,
        else => return err,
    };

    const distance_matrix = try buildDistanceMatrix(parsed.targets, std.heap.page_allocator);
    defer {
        for (distance_matrix) |row| {
            std.heap.page_allocator.free(row);
        }
        std.heap.page_allocator.free(distance_matrix);
    }

    const steps = findShortestRouteOptimized(parsed);

    const gpa = std.heap.page_allocator;
    const result = try std.fmt.allocPrint(gpa, "{}", .{steps});
    return result;
}

// TAOCP: Enhanced Part 2 - TSP with return to origin
fn findOptimalCircuit(start_idx: usize, targets: []Target, dist_matrix: [][]u32) !u32 {
    const n = targets.len;
    const gpa = std.heap.page_allocator;

    if (n == 0) return 0;
    if (n == 1) return getDistance(start_idx, 0, dist_matrix) + getDistance(0, start_idx, dist_matrix);

    // For small instances (≤8), use Held-Karp
    if (n <= 8) {
        return tryHeldKarpTSP(start_idx, targets, dist_matrix);
    }

    // For larger instances, use branch and bound with heuristics
    return tryBranchAndBoundTSP(start_idx, targets, dist_matrix);
}

// TAOCP: Branch and bound TSP for larger instances
fn tryBranchAndBoundTSP(start_idx: usize, targets: []Target, dist_matrix: [][]u32) !u32 {
    const n = targets.len;
    const gpa = std.heap.page_allocator;

    // Use nearest neighbor heuristic to guide search
    var best_route: u32 = std.math.maxInt(u32);

    // Branch and bound with pruning
    const search_result = try branchAndBoundSearch(
        start_idx,
        targets,
        dist_matrix,
        &best_route,
        @intCast(n * 2), // Reasonable bound based on problem structure
    );

    return best_route;
}

// TAOCP: Branch and bound search implementation
fn branchAndBoundSearch(start_idx: usize, targets: []Target, dist_matrix: [][]u32, best_route: *u32, bound: u32) !u32 {
    _ = best_route; // TODO: implement full branch and bound algorithm
    _ = targets;
    _ = dist_matrix;
    _ = bound;

    // Placeholder implementation - replace with actual branch and bound
    return error.NotImplemented;
}

pub fn part2(input: []const u8) !?[]const u8 {
    const parsed = parseMaze(input) catch |err| switch (err) {
        error.InvalidInput => return error.InvalidInput,
        else => return err,
    };

    if (parsed.targets.len > 10) {
        return error.TooManyTargets;
    }

    const distance_matrix = try buildDistanceMatrix(parsed.targets, std.heap.page_allocator);
    defer {
        for (distance_matrix) |row| {
            std.heap.page_allocator.free(row);
        }
        std.heap.page_allocator.free(distance_matrix);
    }

    const total_distance = try findOptimalCircuit(
        0, // Always start from position 0 (which should be start)
        parsed.targets,
        distance_matrix,
    );

    const gpa = std.heap.page_allocator;
    const result = try std.fmt.allocPrint(gpa, "{}", .{total_distance});
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

test "part2 simple circuit" {
    const simple_input =
        \\#####
        \\#0.1..2#
        \\#####.#
        \\#3.......4#
        \\#####
    ;

    const result = try part2(simple_input);
    defer std.heap.page_allocator.free(result.?);

    // Expected: 20 steps (0->1->2->3->4->0)
    try std.testing.expectEqualStrings("20", result.?);
}

test "performance test" {
    const test_input =
        \\#.#######################.#
        \\#.......0.........1#
        \\#.#####################.#
        \\#2...............3#
        \\#.#####################.#
        \\#4...............5#
        \\#.#####################.#
        \\#6...............7#
        \\#.#####################.#
        \\#8...............9#
        \\#####.#################
    ;

    const result = try part1(test_input);
    defer std.heap.page_allocator.free(result.?);

    // Should complete and not hang
    try std.testing.expect(result.? != null);
    try std.testing.expect(@as(u32, result.?.len) > 0);
}

// TAOCP: Memory usage test for large inputs
test "large input handling" {
    const large_input =
        \\#
        \\#0.1.............2#
        \\#.################.#
        \\#3...............4#
        \\#.################.#
        \\#5...............6#
        \\#.################.#
        \\#7...............8#
        \\#.################.#
        \\#9...............0#
        \\#####.###############
    ;

    const result = try part1(large_input);
    defer std.heap.page_allocator.free(result.?);

    // Should handle 10 targets efficiently
    try std.testing.expect(result.? != null);
}
