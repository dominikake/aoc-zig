// TAOCP Vol. 1, Section 2.2.2: Sequential allocation of arrays
// TAOCP Vol. 4A, Section 7.1: Zeros and ones (binary patterns)

const std = @import("std");
const GRID_SIZE = 100;
const STEPS = 100;

pub fn part1(input: []const u8) !?[]const u8 {
    const gpa = std.heap.page_allocator;

    // Parse input into grid
    var grid: [GRID_SIZE][GRID_SIZE]bool = undefined;
    try parseGrid(input, &grid);

    // Simulate 100 steps
    var next_grid: [GRID_SIZE][GRID_SIZE]bool = undefined;
    for (0..STEPS) |_| {
        simulateStep(&grid, &next_grid, false);
        // Swap grids (double buffering)
        const temp = grid;
        grid = next_grid;
        next_grid = temp;
    }

    const count = countLightsOn(&grid);
    return try std.fmt.allocPrint(gpa, "{d}", .{count});
}

pub fn part2(input: []const u8) !?[]const u8 {
    const gpa = std.heap.page_allocator;

    // Parse input into grid
    var grid: [GRID_SIZE][GRID_SIZE]bool = undefined;
    try parseGrid(input, &grid);

    // Set corners on permanently for Part 2
    setCornersOn(&grid);

    // Simulate 100 steps with corners stuck on
    var next_grid: [GRID_SIZE][GRID_SIZE]bool = undefined;
    for (0..STEPS) |_| {
        simulateStep(&grid, &next_grid, true);
        setCornersOn(&next_grid); // Ensure corners stay on
        // Swap grids (double buffering)
        const temp = grid;
        grid = next_grid;
        next_grid = temp;
    }

    const count = countLightsOn(&grid);
    return try std.fmt.allocPrint(gpa, "{d}", .{count});
}

// Parse input string into boolean grid
fn parseGrid(input: []const u8, grid: *[GRID_SIZE][GRID_SIZE]bool) !void {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var row: usize = 0;
    while (lines.next()) |line| {
        if (row >= GRID_SIZE) break;
        for (0..GRID_SIZE) |col| {
            grid[row][col] = if (col < line.len and line[col] == '#') true else false;
        }
        row += 1;
    }
}

// Count on neighbors for a given cell (8-directional Moore neighborhood)
fn countNeighbors(grid: *const [GRID_SIZE][GRID_SIZE]bool, row: usize, col: usize) u8 {
    var count: u8 = 0;

    // Iterate over 8 neighboring positions
    const drs = [_]isize{ -1, -1, -1, 0, 0, 1, 1, 1 };
    const dcs = [_]isize{ -1, 0, 1, -1, 1, -1, 0, 1 };

    for (0..8) |i| {
        const dr = drs[i];
        const dc = dcs[i];

        const new_row = @as(isize, @intCast(row)) + dr;
        const new_col = @as(isize, @intCast(col)) + dc;

        // Check bounds
        if (new_row >= 0 and new_row < GRID_SIZE and new_col >= 0 and new_col < GRID_SIZE) {
            if (grid[@intCast(new_row)][@intCast(new_col)]) {
                count += 1;
            }
        }
    }
    return count;
}

// Simulate one step using Game of Life rules
fn simulateStep(current: *[GRID_SIZE][GRID_SIZE]bool, next: *[GRID_SIZE][GRID_SIZE]bool, corners_stuck: bool) void {
    for (0..GRID_SIZE) |row| {
        for (0..GRID_SIZE) |col| {
            // Skip corners if they're stuck on
            if (corners_stuck and isCorner(row, col)) {
                next[row][col] = true;
                continue;
            }

            const neighbors_on = countNeighbors(current, row, col);
            const is_on = current[row][col];

            // Apply Game of Life rules:
            // On stays on with 2 or 3 neighbors, else off
            // Off turns on with exactly 3 neighbors, else off
            next[row][col] = if (is_on) (neighbors_on == 2 or neighbors_on == 3) else (neighbors_on == 3);
        }
    }
}

// Check if position is a corner
fn isCorner(row: usize, col: usize) bool {
    return (row == 0 or row == GRID_SIZE - 1) and (col == 0 or col == GRID_SIZE - 1);
}

// Set all four corners to on
fn setCornersOn(grid: *[GRID_SIZE][GRID_SIZE]bool) void {
    grid[0][0] = true;
    grid[0][GRID_SIZE - 1] = true;
    grid[GRID_SIZE - 1][0] = true;
    grid[GRID_SIZE - 1][GRID_SIZE - 1] = true;
}

// Count total lights that are on
fn countLightsOn(grid: *const [GRID_SIZE][GRID_SIZE]bool) u32 {
    var count: u32 = 0;
    for (0..GRID_SIZE) |row| {
        for (0..GRID_SIZE) |col| {
            if (grid[row][col]) count += 1;
        }
    }
    return count;
}
