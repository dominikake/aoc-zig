const std = @import("std");

// TAOCP Concept: Finite state machine with 4 states representing compass directions
const Direction = enum(u2) { North = 0, East = 1, South = 2, West = 3 };

// TAOCP Concept: 2D coordinate system for taxicab geometry
const Position = struct { x: i32, y: i32 };

// TAOCP: Modular arithmetic for circular direction changes
fn turn(direction: Direction, turn_dir: u8) Direction {
    return switch (direction) {
        .North => if (turn_dir == 'R') Direction.East else Direction.West,
        .East => if (turn_dir == 'R') Direction.South else Direction.North,
        .South => if (turn_dir == 'R') Direction.West else Direction.East,
        .West => if (turn_dir == 'R') Direction.North else Direction.South,
    };
}

// TAOCP: Vector addition for coordinate movement in 2D space
fn walk(pos: Position, direction: Direction, distance: i32) Position {
    return switch (direction) {
        .North => Position{ .x = pos.x, .y = pos.y + distance },
        .East => Position{ .x = pos.x + distance, .y = pos.y },
        .South => Position{ .x = pos.x, .y = pos.y - distance },
        .West => Position{ .x = pos.x - distance, .y = pos.y },
    };
}

// TAOCP: Step-by-step movement with position tracking for duplicate detection
fn walkStepByStep(pos: Position, direction: Direction, distance: i32, visited: *std.AutoHashMap(Position, void)) !?Position {
    var current_pos = pos;

    for (0..@abs(distance)) |_| {
        current_pos = switch (direction) {
            .North => Position{ .x = current_pos.x, .y = current_pos.y + 1 },
            .East => Position{ .x = current_pos.x + 1, .y = current_pos.y },
            .South => Position{ .x = current_pos.x, .y = current_pos.y - 1 },
            .West => Position{ .x = current_pos.x - 1, .y = current_pos.y },
        };

        // Check if this position was already visited
        if (visited.contains(current_pos)) {
            return current_pos; // First duplicate found
        }

        // Mark this position as visited
        try visited.put(current_pos, {});
    }

    return null; // No duplicate found in this segment
}

// TAOCP: Manhattan distance calculation in L1 norm
fn manhattanDistance(pos: Position) i32 {
    return @intCast(@abs(pos.x) + @abs(pos.y));
}

// TAOCP: Hash function for Position struct - uses Cantor pairing
pub const PositionContext = struct {
    pub fn hash(self: @This(), key: Position) u64 {
        _ = self;
        // Simple, safe hash using direct integer conversion
        const a = @as(u64, @intCast(key.x)) +% 0x80000000;
        const b = @as(u64, @intCast(key.y)) +% 0x80000000;
        return a ^ (b << 3);
    }

    pub fn eql(self: @This(), a: Position, b: Position) bool {
        _ = self;
        return a.x == b.x and a.y == b.y;
    }
};

pub fn part1(input: []const u8) !?[]const u8 {
    // TAOCP: Single-pass streaming algorithm with O(1) additional space
    var pos = Position{ .x = 0, .y = 0 };
    var direction = Direction.North;

    var instruction_iter = std.mem.tokenizeAny(u8, input, ", \n\r");

    while (instruction_iter.next()) |instruction| {
        if (instruction.len < 2) return error.InvalidInstruction;

        const turn_dir = instruction[0];
        const distance_str = instruction[1..];

        // Validate turn direction
        if (turn_dir != 'L' and turn_dir != 'R') return error.InvalidTurnDirection;

        // Parse distance
        const distance = try std.fmt.parseInt(i32, distance_str, 10);

        // Update state: turn then walk
        direction = turn(direction, turn_dir);
        pos = walk(pos, direction, distance);
    }

    // Calculate final Manhattan distance from origin
    const final_distance = manhattanDistance(pos);

    // Convert result to string for output
    const gpa = std.heap.page_allocator;
    const result = try std.fmt.allocPrint(gpa, "{}", .{final_distance});
    return result;
}

pub fn part2(input: []const u8) !?[]const u8 {
    // TAOCP: Single-pass algorithm with hash set for cycle detection
    const gpa = std.heap.page_allocator;
    var visited = std.AutoHashMap(Position, void).init(gpa);
    defer visited.deinit();

    var pos = Position{ .x = 0, .y = 0 };
    var direction = Direction.North;

    // Mark starting position as visited
    try visited.put(pos, {});

    var instruction_iter = std.mem.tokenizeAny(u8, input, ", \n\r");

    while (instruction_iter.next()) |instruction| {
        if (instruction.len < 2) return error.InvalidInstruction;

        const turn_dir = instruction[0];
        const distance_str = instruction[1..];

        // Validate turn direction
        if (turn_dir != 'L' and turn_dir != 'R') return error.InvalidTurnDirection;

        // Parse distance
        const distance = try std.fmt.parseInt(i32, distance_str, 10);

        // Update direction
        direction = turn(direction, turn_dir);

        // Walk step by step, checking for duplicates
        if (try walkStepByStep(pos, direction, distance, &visited)) |duplicate_pos| {
            const dup_distance = manhattanDistance(duplicate_pos);
            const result = try std.fmt.allocPrint(gpa, "{}", .{dup_distance});
            return result;
        }

        // Update final position
        pos = walk(pos, direction, distance);
    }

    return error.NoDuplicateFound;
}

// Test provided examples from problem description
test "part1 example R2,L3" {
    const sample_input = "R2, L3";
    const result = try part1(sample_input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("5", result.?);
}

test "part1 example R2,R2,R2" {
    const sample_input = "R2, R2, R2";
    const result = try part1(sample_input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("2", result.?);
}

test "part1 example R5,L5,R5,R3" {
    const sample_input = "R5, L5, R5, R3";
    const result = try part1(sample_input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("12", result.?);
}

// Test individual component functions
test "turn function" {
    // Test right turns
    try std.testing.expectEqual(Direction.East, turn(Direction.North, 'R'));
    try std.testing.expectEqual(Direction.South, turn(Direction.East, 'R'));
    try std.testing.expectEqual(Direction.West, turn(Direction.South, 'R'));
    try std.testing.expectEqual(Direction.North, turn(Direction.West, 'R'));

    // Test left turns
    try std.testing.expectEqual(Direction.West, turn(Direction.North, 'L'));
    try std.testing.expectEqual(Direction.North, turn(Direction.East, 'L'));
    try std.testing.expectEqual(Direction.East, turn(Direction.South, 'L'));
    try std.testing.expectEqual(Direction.South, turn(Direction.West, 'L'));
}

test "walk function" {
    const start_pos = Position{ .x = 0, .y = 0 };

    // Test walking in each direction
    try std.testing.expectEqual(Position{ .x = 0, .y = 5 }, walk(start_pos, Direction.North, 5));
    try std.testing.expectEqual(Position{ .x = 3, .y = 0 }, walk(start_pos, Direction.East, 3));
    try std.testing.expectEqual(Position{ .x = 0, .y = -4 }, walk(start_pos, Direction.South, 4));
    try std.testing.expectEqual(Position{ .x = -2, .y = 0 }, walk(start_pos, Direction.West, 2));
}

test "manhattanDistance function" {
    try std.testing.expectEqual(@as(i32, 0), manhattanDistance(Position{ .x = 0, .y = 0 }));
    try std.testing.expectEqual(@as(i32, 5), manhattanDistance(Position{ .x = 2, .y = 3 }));
    try std.testing.expectEqual(@as(i32, 7), manhattanDistance(Position{ .x = -4, .y = 3 }));
    try std.testing.expectEqual(@as(i32, 10), manhattanDistance(Position{ .x = -6, .y = -4 }));
}

// Test edge cases
test "part1 empty input" {
    const sample_input = "";
    const result = try part1(sample_input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("0", result.?);
}

test "part1 single instruction" {
    const sample_input = "R10";
    const result = try part1(sample_input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("10", result.?);
}

test "part1 complex path returning to origin" {
    const sample_input = "R2, R2, R2, R2";
    const result = try part1(sample_input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("0", result.?);
}

// Test part 2 scenarios
test "part2 example R8,R4,R4,R8" {
    const sample_input = "R8, R4, R4, R8";
    const result = try part2(sample_input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("4", result.?);
}

test "part2 create loop back to origin" {
    const sample_input = "R2, R2, R2, R2";
    const result = try part2(sample_input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("0", result.?); // Back to (0,0)
}

test "PositionHash function" {
    const context = PositionContext{};

    const pos1 = Position{ .x = 1, .y = 2 };
    const pos2 = Position{ .x = 1, .y = 2 };
    const pos3 = Position{ .x = 3, .y = 4 };

    try std.testing.expect(context.eql(pos1, pos2));
    try std.testing.expect(!context.eql(pos1, pos3));

    // Hash should be consistent
    const hash1 = context.hash(pos1);
    const hash2 = context.hash(pos2);
    const hash3 = context.hash(pos3);

    try std.testing.expectEqual(hash1, hash2);
    try std.testing.expect(hash1 != hash3);
}

test "walkStepByStep function" {
    const gpa = std.testing.allocator;
    var visited = std.AutoHashMap(Position, void).init(gpa);
    defer visited.deinit();

    const start_pos = Position{ .x = 0, .y = 0 };
    try visited.put(start_pos, {});

    // Walk 2 steps north, should not find duplicate
    const result1 = try walkStepByStep(start_pos, Direction.North, 2, &visited);
    try std.testing.expectEqual(@as(?Position, null), result1);

    // Walk 2 steps south back to start, should find duplicate at (0,0)
    const current_pos = Position{ .x = 0, .y = 2 };
    const result2 = try walkStepByStep(current_pos, Direction.South, 2, &visited);
    try std.testing.expect(result2 != null);
    try std.testing.expectEqual(Position{ .x = 0, .y = 1 }, result2.?); // First duplicate is (0,1) then (0,0)
}
