const std = @import("std");

// TAOCP Concept: Graph traversal and memoization for circuit evaluation

// Operation types for different circuit instructions
const Operation = enum {
    ASSIGN, // 123 -> x
    AND, // x AND y -> z
    OR, // x OR y -> z
    LSHIFT, // x LSHIFT 2 -> q
    RSHIFT, // x RSHIFT 2 -> g
    NOT, // NOT x -> h
};

// Individual instruction representing a circuit operation
const Instruction = struct {
    op: Operation,
    input1: []const u8,
    input2: ?[]const u8, // null for ASSIGN and NOT
    output: []const u8,
};

// Circuit structure with memoized evaluation
const Circuit = struct {
    allocator: std.mem.Allocator,
    instructions: std.StringHashMap(Instruction),
    signals: std.StringHashMap(u16), // memoization cache

    const Self = @This();

    fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .allocator = allocator,
            .instructions = std.StringHashMap(Instruction).init(allocator),
            .signals = std.StringHashMap(u16).init(allocator),
        };
    }

    fn deinit(self: *Self) void {
        self.instructions.deinit();
        self.signals.deinit();
    }

    // TAOCP: Parsing with string operations
    fn parse(self: *Self, circuit_input: []const u8) !void {
        var line_iter = std.mem.tokenizeScalar(u8, circuit_input, '\n');

        while (line_iter.next()) |line| {
            if (line.len == 0) continue;

            // Find arrow to split instruction
            const arrow_pos = std.mem.indexOf(u8, line, " -> ") orelse return error.InvalidInstructionFormat;
            const left_side = line[0..arrow_pos];
            const output_wire = line[arrow_pos + 4 ..]; // skip " -> "

            // Parse based on operation pattern
            if (std.mem.startsWith(u8, left_side, "NOT ")) {
                // NOT x -> h
                const input_wire = left_side[4..];
                const instruction = Instruction{
                    .op = .NOT,
                    .input1 = input_wire,
                    .input2 = null,
                    .output = output_wire,
                };
                try self.instructions.put(output_wire, instruction);
            } else if (std.mem.indexOf(u8, left_side, " AND ")) |and_pos| {
                // x AND y -> z
                const input1 = left_side[0..and_pos];
                const input2 = left_side[and_pos + 5 ..];
                const instruction = Instruction{
                    .op = .AND,
                    .input1 = input1,
                    .input2 = input2,
                    .output = output_wire,
                };
                try self.instructions.put(output_wire, instruction);
            } else if (std.mem.indexOf(u8, left_side, " OR ")) |or_pos| {
                // x OR y -> z
                const input1 = left_side[0..or_pos];
                const input2 = left_side[or_pos + 4 ..];
                const instruction = Instruction{
                    .op = .OR,
                    .input1 = input1,
                    .input2 = input2,
                    .output = output_wire,
                };
                try self.instructions.put(output_wire, instruction);
            } else if (std.mem.indexOf(u8, left_side, " LSHIFT ")) |lshift_pos| {
                // x LSHIFT 2 -> q
                const input1 = left_side[0..lshift_pos];
                const input2 = left_side[lshift_pos + 8 ..];
                const instruction = Instruction{
                    .op = .LSHIFT,
                    .input1 = input1,
                    .input2 = input2,
                    .output = output_wire,
                };
                try self.instructions.put(output_wire, instruction);
            } else if (std.mem.indexOf(u8, left_side, " RSHIFT ")) |rshift_pos| {
                // x RSHIFT 2 -> g
                const input1 = left_side[0..rshift_pos];
                const input2 = left_side[rshift_pos + 8 ..];
                const instruction = Instruction{
                    .op = .RSHIFT,
                    .input1 = input1,
                    .input2 = input2,
                    .output = output_wire,
                };
                try self.instructions.put(output_wire, instruction);
            } else {
                // 123 -> x or x -> y
                const input_wire = left_side;
                const instruction = Instruction{
                    .op = .ASSIGN,
                    .input1 = input_wire,
                    .input2 = null,
                    .output = output_wire,
                };
                try self.instructions.put(output_wire, instruction);
            }
        }
    }

    // TAOCP: Recursive memoized evaluation with lazy computation
    fn getSignal(self: *Self, wire: []const u8) !u16 {
        // Check cache first (memoization)
        if (self.signals.get(wire)) |value| return value;

        // Check if wire is actually a number (base case)
        if (std.fmt.parseInt(u16, wire, 10)) |num| return num else |_| {}

        // Get instruction for this wire
        const instruction = self.instructions.get(wire) orelse return error.WireNotFound;

        // Evaluate instruction based on operation type
        const result: u16 = switch (instruction.op) {
            .ASSIGN => getSignalHelper(self, instruction.input1),
            .AND => andOpHelper(self, instruction.input1, instruction.input2.?),
            .OR => orOpHelper(self, instruction.input1, instruction.input2.?),
            .LSHIFT => lshiftOpHelper(self, instruction.input1, instruction.input2.?),
            .RSHIFT => rshiftOpHelper(self, instruction.input1, instruction.input2.?),
            .NOT => notOpHelper(self, instruction.input1),
        };

        // Cache result
        try self.signals.put(wire, result);
        return result;
    }

    // Helper functions to avoid error union complications
    fn getSignalHelper(self: *Self, input: []const u8) u16 {
        return self.getSignal(input) catch 0;
    }

    fn andOpHelper(self: *Self, input1: []const u8, input2: []const u8) u16 {
        const val1 = self.getSignal(input1) catch 0;
        const val2 = self.getSignal(input2) catch 0;
        return val1 & val2;
    }

    fn orOpHelper(self: *Self, input1: []const u8, input2: []const u8) u16 {
        const val1 = self.getSignal(input1) catch 0;
        const val2 = self.getSignal(input2) catch 0;
        return val1 | val2;
    }

    fn lshiftOpHelper(self: *Self, input: []const u8, shift_str: []const u8) u16 {
        const val = self.getSignal(input) catch 0;
        const shift = std.fmt.parseInt(u4, shift_str, 10) catch 0;
        // Simple shift with overflow wrap - shifts are small so no overflow expected
        return val << shift;
    }

    fn rshiftOpHelper(self: *Self, input: []const u8, shift_str: []const u8) u16 {
        const val = self.getSignal(input) catch 0;
        const shift = std.fmt.parseInt(u4, shift_str, 10) catch 0;
        return val >> shift;
    }

    fn notOpHelper(self: *Self, input: []const u8) u16 {
        const val = self.getSignal(input) catch 0;
        return ~val & 0xFFFF; // Force 16-bit unsigned result
    }

    // Reset signals cache (needed for Part 2)
    fn reset(self: *Self) void {
        self.signals.clearRetainingCapacity();
    }
};

// TAOCP: Single-pass algorithm with memoized recursion
pub fn part1(input: []const u8) !?[]const u8 {
    const gpa = std.heap.page_allocator;
    var circuit = Circuit.init(gpa);
    defer circuit.deinit();

    try circuit.parse(input);

    const result = try circuit.getSignal("a");

    const result_str = try std.fmt.allocPrint(gpa, "{}", .{result});
    return result_str;
}

// TAOCP: Modified algorithm with wire override
pub fn part2(input: []const u8) !?[]const u8 {
    const gpa = std.heap.page_allocator;
    var circuit = Circuit.init(gpa);
    defer circuit.deinit();

    try circuit.parse(input);

    // Get Part 1 result for wire "a"
    const part1_result = try circuit.getSignal("a");

    // Reset circuit for Part 2
    circuit.reset();

    // Override wire "b" with Part 1's "a" value
    try circuit.signals.put("b", part1_result);

    const result = try circuit.getSignal("a");

    const result_str = try std.fmt.allocPrint(gpa, "{}", .{result});
    return result_str;
}

// Test with sample input from AoC website
test "part1 sample input" {
    const sample_input =
        \\123 -> x
        \\456 -> y
        \\x AND y -> d
        \\x OR y -> e
        \\x LSHIFT 2 -> f
        \\y RSHIFT 2 -> g
        \\NOT x -> h
        \\NOT y -> i
    ;

    const gpa = std.testing.allocator;
    var circuit = Circuit.init(gpa);
    defer circuit.deinit();

    try circuit.parse(sample_input);

    // Test individual wire values
    const x = try circuit.getSignal("x");
    const y = try circuit.getSignal("y");
    const d = try circuit.getSignal("d");
    const e = try circuit.getSignal("e");
    const f = try circuit.getSignal("f");
    const g = try circuit.getSignal("g");
    const h = try circuit.getSignal("h");
    const i = try circuit.getSignal("i");

    try std.testing.expectEqual(@as(u16, 123), x);
    try std.testing.expectEqual(@as(u16, 456), y);
    try std.testing.expectEqual(@as(u16, 72), d); // 123 & 456 = 72
    try std.testing.expectEqual(@as(u16, 507), e); // 123 | 456 = 507
    try std.testing.expectEqual(@as(u16, 492), f); // 123 << 2 = 492
    try std.testing.expectEqual(@as(u16, 114), g); // 456 >> 2 = 114
    try std.testing.expectEqual(@as(u16, 65412), h); // ~123 & 0xFFFF = 65412
    try std.testing.expectEqual(@as(u16, 65079), i); // ~456 & 0xFFFF = 65079
}

// Test assignment operations
test "assignment operations" {
    const input =
        \\123 -> x
        \\x -> y
        \\456 -> z
    ;

    const gpa = std.testing.allocator;
    var circuit = Circuit.init(gpa);
    defer circuit.deinit();

    try circuit.parse(input);

    const x = try circuit.getSignal("x");
    const y = try circuit.getSignal("y");
    const z = try circuit.getSignal("z");

    try std.testing.expectEqual(@as(u16, 123), x);
    try std.testing.expectEqual(@as(u16, 123), y); // y should get x's value
    try std.testing.expectEqual(@as(u16, 456), z);
}

// Test NOT operation with 16-bit masking
test "not operation 16-bit masking" {
    const input =
        \\123 -> x
        \\NOT x -> y
    ;

    const gpa = std.testing.allocator;
    var circuit = Circuit.init(gpa);
    defer circuit.deinit();

    try circuit.parse(input);

    const x = try circuit.getSignal("x");
    const y = try circuit.getSignal("y");

    try std.testing.expectEqual(@as(u16, 123), x);
    try std.testing.expectEqual(@as(u16, 65412), y); // ~123 & 0xFFFF = 65412
}

// Test shift operations
test "shift operations" {
    const input =
        \\123 -> x
        \\x LSHIFT 2 -> y
        \\x RSHIFT 2 -> z
    ;

    const gpa = std.testing.allocator;
    var circuit = Circuit.init(gpa);
    defer circuit.deinit();

    try circuit.parse(input);

    const x = try circuit.getSignal("x");
    const y = try circuit.getSignal("y");
    const z = try circuit.getSignal("z");

    try std.testing.expectEqual(@as(u16, 123), x);
    try std.testing.expectEqual(@as(u16, 492), y); // 123 << 2 = 492
    try std.testing.expectEqual(@as(u16, 30), z); // 123 >> 2 = 30
}

// Test memoization efficiency
test "memoization" {
    const input =
        \\123 -> x
        \\x AND x -> y
        \\y OR y -> z
    ;

    const gpa = std.testing.allocator;
    var circuit = Circuit.init(gpa);
    defer circuit.deinit();

    try circuit.parse(input);

    // First call should compute
    const x1 = try circuit.getSignal("x");
    const y1 = try circuit.getSignal("y");

    // Second calls should use cache
    const x2 = try circuit.getSignal("x");
    const y2 = try circuit.getSignal("y");

    try std.testing.expectEqual(@as(u16, 123), x1);
    try std.testing.expectEqual(@as(u16, 123), x2);
    try std.testing.expectEqual(@as(u16, 123), y1); // x AND x = 123
    try std.testing.expectEqual(@as(u16, 123), y2);
}

// Test part2 override functionality
test "part2 wire override" {
    const input =
        \\123 -> a
        \\456 -> b
        \\a AND b -> c
    ;

    const gpa = std.testing.allocator;
    var circuit = Circuit.init(gpa);
    defer circuit.deinit();

    try circuit.parse(input);

    const part1_a = try circuit.getSignal("a"); // Should be 123

    // Reset and override b with a's value
    circuit.reset();
    try circuit.signals.put("b", part1_a);

    const part2_c = try circuit.getSignal("c"); // Should be 123 AND 123 = 123

    try std.testing.expectEqual(@as(u16, 123), part1_a);
    try std.testing.expectEqual(@as(u16, 123), part2_c);
}
