const std = @import("std");

// TAOCP Concept: State Machine with immutable state updates
const State = struct {
    position: u8, // Current dial position (0-99)
    zero_count: u32, // Number of times we've landed on position 0

    // Apply a rotation instruction and return new state
    fn applyRotation(self: State, instruction: Instruction) State {
        // TAOCP: Circular arithmetic - handle large distances with modulo 100
        const effective_distance = @mod(instruction.distance, 100);
        const new_position: u8 = switch (instruction.direction) {
            'L' => @intCast((self.position + 100 - effective_distance) % 100),
            'R' => @intCast((self.position + effective_distance) % 100),
            else => unreachable, // Should never happen with valid input
        };

        const new_zero_count = if (new_position == 0) self.zero_count + 1 else self.zero_count;

        return State{
            .position = new_position,
            .zero_count = new_zero_count,
        };
    }
};

// Parsed instruction from input line
const Instruction = struct {
    direction: u8, // 'L' or 'R'
    distance: u16, // Distance to rotate (can be larger than 255)
};

// Parse a single instruction line like "L29" or "R48"
fn parseInstruction(line: []const u8) !Instruction {
    if (line.len < 2) return error.InvalidInstruction;

    const direction = line[0];
    if (direction != 'L' and direction != 'R') return error.InvalidDirection;

    const distance_str = line[1..];
    const distance = try std.fmt.parseInt(u16, distance_str, 10);
    if (distance == 0) return error.InvalidDistance;

    return Instruction{
        .direction = direction,
        .distance = distance,
    };
}

pub fn part1(input: []const u8) !?[]const u8 {
    // TAOCP: Ring data structure - we only track the index, not the full ring
    var state = State{ .position = 50, .zero_count = 0 }; // Start at position 50

    // TAOCP: Parsing with delimiters - split by lines first, then extract instructions
    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');

    while (line_iter.next()) |line| {
        // Skip empty lines
        if (line.len == 0) continue;

        // Remove any trailing whitespace first
        const trimmed_line = std.mem.trim(u8, line, " \r\t");
        if (trimmed_line.len == 0) continue;

        // Handle different input formats:
        // 1. Sample format: "L68"
        // 2. Line number format: "1 L68"
        // 3. Pipe format: "00001| L68"

        var instruction_part: []const u8 = undefined;

        // Try to find pipe first
        if (std.mem.indexOfScalar(u8, trimmed_line, '|')) |pipe_pos| {
            // Format: "00001| L68"
            if (pipe_pos + 1 >= trimmed_line.len) continue;
            instruction_part = trimmed_line[pipe_pos + 1 ..];
        } else if (std.mem.indexOfScalar(u8, trimmed_line, ' ')) |space_pos| {
            // Format: "1 L68"
            if (space_pos + 1 >= trimmed_line.len) continue;
            instruction_part = trimmed_line[space_pos + 1 ..];
        } else {
            // Format: "L68" (sample format)
            instruction_part = trimmed_line;
        }

        // Final trim of instruction part
        const trimmed_instruction = std.mem.trim(u8, instruction_part, " \r\t");
        if (trimmed_instruction.len == 0) continue;

        const instruction = try parseInstruction(trimmed_instruction);
        state = state.applyRotation(instruction); // TAOCP: State machine transition
    }

    // Convert result to string for output
    const gpa = std.heap.page_allocator;
    const result = try std.fmt.allocPrint(gpa, "{}", .{state.zero_count});
    return result;
}

pub fn part2(input: []const u8) !?[]const u8 {
    _ = input;
    // TODO: Implement part 2 solution
    return null;
}

// Test with sample input - expected answer is 3
test "part1 sample input" {
    const sample_input =
        \\L68
        \\L30
        \\R48
        \\L5
        \\R60
        \\L55
        \\L1
        \\L99
        \\R14
        \\L82
    ;
    const result = try part1(sample_input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("3", result.?);
}
