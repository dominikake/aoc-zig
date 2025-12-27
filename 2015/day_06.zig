const std = @import("std");
const GRID_SIZE = 1000;

pub fn part1(input: []const u8) !?[]const u8 {
    const gpa = std.heap.page_allocator;
    const grid = try gpa.alloc(bool, GRID_SIZE * GRID_SIZE);
    defer gpa.free(grid);
    @memset(grid, false);

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const instruction = try parseInstruction(line);
        applyInstructionPart1(grid, instruction);
    }

    var lights_on: u32 = 0;
    for (grid) |light| {
        if (light) lights_on += 1;
    }

    return try std.fmt.allocPrint(gpa, "{d}", .{lights_on});
}

pub fn part2(input: []const u8) !?[]const u8 {
    const gpa = std.heap.page_allocator;
    const grid = try gpa.alloc(u32, GRID_SIZE * GRID_SIZE);
    defer gpa.free(grid);
    @memset(grid, 0);

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const instruction = try parseInstruction(line);
        applyInstructionPart2(grid, instruction);
    }

    var total_brightness: u64 = 0;
    for (grid) |brightness| {
        total_brightness += brightness;
    }

    return try std.fmt.allocPrint(gpa, "{d}", .{total_brightness});
}

const CommandType = enum {
    turn_on,
    turn_off,
    toggle,
};

const Instruction = struct {
    command: CommandType,
    x1: usize,
    y1: usize,
    x2: usize,
    y2: usize,
};

pub fn parseInstruction(line: []const u8) !Instruction {
    if (std.mem.startsWith(u8, line, "turn on ")) {
        const coords = line["turn on ".len..];
        const parts = try parseCoordinates(coords);
        return Instruction{
            .command = .turn_on,
            .x1 = parts[0],
            .y1 = parts[1],
            .x2 = parts[2],
            .y2 = parts[3],
        };
    } else if (std.mem.startsWith(u8, line, "turn off ")) {
        const coords = line["turn off ".len..];
        const parts = try parseCoordinates(coords);
        return Instruction{
            .command = .turn_off,
            .x1 = parts[0],
            .y1 = parts[1],
            .x2 = parts[2],
            .y2 = parts[3],
        };
    } else if (std.mem.startsWith(u8, line, "toggle ")) {
        const coords = line["toggle ".len..];
        const parts = try parseCoordinates(coords);
        return Instruction{
            .command = .toggle,
            .x1 = parts[0],
            .y1 = parts[1],
            .x2 = parts[2],
            .y2 = parts[3],
        };
    } else {
        return error.InvalidInstruction;
    }
}

fn parseCoordinates(coords: []const u8) ![4]usize {
    var it = std.mem.tokenizeScalar(u8, coords, ' ');
    const first = it.next() orelse return error.InvalidCoordinates;
    const through = it.next(); // should be "through"
    const second = it.next() orelse return error.InvalidCoordinates;

    if (through == null or !std.mem.eql(u8, through.?, "through")) {
        return error.InvalidCoordinates;
    }

    const first_parts = try parseIntPair(first);
    const second_parts = try parseIntPair(second);

    return [4]usize{ first_parts[0], first_parts[1], second_parts[0], second_parts[1] };
}

fn parseIntPair(pair: []const u8) ![2]usize {
    var it = std.mem.tokenizeScalar(u8, pair, ',');
    const first_str = it.next() orelse return error.InvalidNumber;
    const second_str = it.next() orelse return error.InvalidNumber;

    const first = try std.fmt.parseInt(usize, first_str, 10);
    const second = try std.fmt.parseInt(usize, second_str, 10);

    return [2]usize{ first, second };
}

fn applyInstructionPart1(grid: []bool, instruction: Instruction) void {
    for (instruction.y1..instruction.y2 + 1) |y| {
        for (instruction.x1..instruction.x2 + 1) |x| {
            const index = y * GRID_SIZE + x;
            switch (instruction.command) {
                .turn_on => grid[index] = true,
                .turn_off => grid[index] = false,
                .toggle => grid[index] = !grid[index],
            }
        }
    }
}

fn applyInstructionPart2(grid: []u32, instruction: Instruction) void {
    for (instruction.y1..instruction.y2 + 1) |y| {
        for (instruction.x1..instruction.x2 + 1) |x| {
            const index = y * GRID_SIZE + x;
            switch (instruction.command) {
                .turn_on => grid[index] += 1,
                .turn_off => {
                    if (grid[index] > 0) grid[index] -= 1;
                },
                .toggle => grid[index] += 2,
            }
        }
    }
}

test "parseInstruction" {
    const line1 = "turn on 0,0 through 999,999";
    const instruction1 = try parseInstruction(line1);
    try std.testing.expectEqual(CommandType.turn_on, instruction1.command);
    try std.testing.expectEqual(@as(usize, 0), instruction1.x1);
    try std.testing.expectEqual(@as(usize, 0), instruction1.y1);
    try std.testing.expectEqual(@as(usize, 999), instruction1.x2);
    try std.testing.expectEqual(@as(usize, 999), instruction1.y2);

    const line2 = "toggle 499,499 through 500,500";
    const instruction2 = try parseInstruction(line2);
    try std.testing.expectEqual(CommandType.toggle, instruction2.command);
    try std.testing.expectEqual(@as(usize, 499), instruction2.x1);
    try std.testing.expectEqual(@as(usize, 499), instruction2.y1);
    try std.testing.expectEqual(@as(usize, 500), instruction2.x2);
    try std.testing.expectEqual(@as(usize, 500), instruction2.y2);
}
