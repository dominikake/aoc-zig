const std = @import("std");

// TAOCP Concept: Instruction set architecture - defines operations for simple register machine
const Opcode = enum { cpy, inc, dec, jnz, out };

// TAOCP: Value representation - can be immediate constant or register reference
const Value = union(enum) { reg: usize, imm: i64 };

// TAOCP: Instruction format - opcode with operands
const Instruction = struct {
    opcode: Opcode,
    x: Value,
    y: ?Value = null, // Only used by cpy/jnz for destination/offset
};

// TAOCP: Machine state - registers and instruction pointer
const State = struct {
    regs: [4]i64 = [_]i64{ 0, 0, 0, 0 },
    ip: usize = 0,
};

// TAOCP: Register lookup table for parsing
fn registerIndex(str: []const u8) ?usize {
    if (str.len != 1) return null;
    switch (str[0]) {
        'a' => return 0,
        'b' => return 1,
        'c' => return 2,
        'd' => return 3,
        else => return null,
    }
}

// TAOCP: Lexical analysis - parse instruction from text
fn parseInstruction(line: []const u8) !Instruction {
    var it = std.mem.tokenizeScalar(u8, line, ' ');
    const opcode_str = it.next() orelse return error.InvalidOpcode;

    const opcode: Opcode = if (std.mem.eql(u8, opcode_str, "cpy"))
        .cpy
    else if (std.mem.eql(u8, opcode_str, "inc"))
        .inc
    else if (std.mem.eql(u8, opcode_str, "dec"))
        .dec
    else if (std.mem.eql(u8, opcode_str, "jnz"))
        .jnz
    else if (std.mem.eql(u8, opcode_str, "out"))
        .out
    else
        return error.InvalidOpcode;

    const x_str = it.next() orelse return error.MissingOperand;
    const x = if (registerIndex(x_str)) |idx| Value{ .reg = idx } else Value{ .imm = try std.fmt.parseInt(i64, x_str, 10) };

    const y_str = it.next();
    const y: ?Value = if (y_str) |ys| if (registerIndex(ys)) |idx| Value{ .reg = idx } else Value{ .imm = try std.fmt.parseInt(i64, ys, 10) } else null;

    return Instruction{ .opcode = opcode, .x = x, .y = y };
}

// TAOCP: Get value - resolves Value to actual number (register or immediate)
fn getValue(state: State, v: Value) i64 {
    return switch (v) {
        .reg => |idx| state.regs[idx],
        .imm => |val| val,
    };
}

// TAOCP: Execute single instruction - step in simulation
fn execute(state: *State, instr: Instruction) !?u8 {
    switch (instr.opcode) {
        .cpy => {
            const src_val = getValue(state.*, instr.x);
            // cpy x y: copy x to y (y must be a register)
            if (instr.y) |dest| {
                if (dest == .reg) {
                    state.regs[dest.reg] = src_val;
                    state.ip += 1;
                } else {
                    // Skip if destination is not a register (e.g., "cpy 5 5")
                    state.ip += 1;
                }
            } else {
                return error.MissingDestination;
            }
        },
        .inc => {
            // inc x: increment register x
            if (instr.x == .reg) {
                state.regs[instr.x.reg] += 1;
                state.ip += 1;
            } else {
                return error.InvalidRegister;
            }
        },
        .dec => {
            // dec x: decrement register x
            if (instr.x == .reg) {
                state.regs[instr.x.reg] -= 1;
                state.ip += 1;
            } else {
                return error.InvalidRegister;
            }
        },
        .jnz => {
            // jnz x y: jump offset y if x != 0
            const test_val = getValue(state.*, instr.x);
            if (instr.y) |offset| {
                if (test_val != 0) {
                    const offset_val = switch (offset) {
                        .reg => |idx| state.regs[idx],
                        .imm => |val| val,
                    };
                    const new_ip: isize = @intCast(state.ip);
                    state.ip = @intCast(new_ip + offset_val);
                } else {
                    state.ip += 1;
                }
            } else {
                return error.MissingOffset;
            }
        },
        .out => {
            // out x: transmit value of x (must be 0 or 1)
            const val = getValue(state.*, instr.x);
            state.ip += 1;
            return @intCast(val);
        },
    }
    return null;
}

// TAOCP: Pattern matching - verify output alternates 0,1,0,1,...
fn simulateWithPatternCheck(instructions: []Instruction, initial_a: i64, expected_outputs: usize) !bool {
    var state = State{ .regs = .{ initial_a, 0, 0, 0 } };
    var output_count: usize = 0;
    var expected_next: u8 = 0; // First output should be 0

    while (output_count < expected_outputs) {
        if (state.ip >= instructions.len) return false; // Program ended prematurely

        const instr = instructions[state.ip];
        const output = try execute(&state, instr);

        if (output) |out_val| {
            // Check if output matches expected pattern
            if (out_val != expected_next) {
                return false; // Pattern broken
            }
            output_count += 1;
            expected_next = 1 - expected_next; // Flip 0↔1
        }

        // Safety cap: prevent infinite loops on bad inputs
        if (output_count > expected_outputs * 10) return false;
    }

    return true; // All outputs matched pattern
}

// TAOCP: Exhaustive search - find smallest a that produces correct output
fn findSmallestA(instructions: []Instruction) !i64 {
    var a: i64 = 1;
    while (true) : (a += 1) {
        if (try simulateWithPatternCheck(instructions, a, 100)) {
            return a;
        }
    }
}

pub fn part1(input: []const u8) !?[]const u8 {
    // TAOCP: Parse and assemble program
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var instructions = std.ArrayList(Instruction).initCapacity(allocator, 50) catch unreachable;
    defer instructions.deinit(allocator);

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const instr = try parseInstruction(line);
        try instructions.append(allocator, instr);
    }

    // TAOCP: Search for smallest initial value producing alternating output
    const result = try findSmallestA(instructions.items);

    return try std.fmt.allocPrint(std.heap.page_allocator, "{}", .{result});
}

pub fn part2(input: []const u8) !?[]const u8 {
    _ = input;
    return null;
}

// Test instruction parsing
test "parseInstruction cpy" {
    const instr = try parseInstruction("cpy 41 a");
    try std.testing.expectEqual(Opcode.cpy, instr.opcode);
    try std.testing.expectEqual(@as(i64, 41), getValue(State{}, instr.x));
    try std.testing.expectEqual(@as(usize, 0), instr.y.?.reg);
}

test "parseInstruction inc" {
    const instr = try parseInstruction("inc a");
    try std.testing.expectEqual(Opcode.inc, instr.opcode);
    try std.testing.expectEqual(@as(usize, 0), instr.x.reg);
}

test "parseInstruction dec" {
    const instr = try parseInstruction("dec b");
    try std.testing.expectEqual(Opcode.dec, instr.opcode);
    try std.testing.expectEqual(@as(usize, 1), instr.x.reg);
}

test "parseInstruction jnz" {
    const instr = try parseInstruction("jnz a 2");
    try std.testing.expectEqual(Opcode.jnz, instr.opcode);
    try std.testing.expectEqual(@as(usize, 0), instr.x.reg);
    try std.testing.expectEqual(@as(i64, 2), instr.y.?.imm);
}

test "parseInstruction out" {
    const instr = try parseInstruction("out a");
    try std.testing.expectEqual(Opcode.out, instr.opcode);
    try std.testing.expectEqual(@as(usize, 0), instr.x.reg);
}

test "execute cpy" {
    var state = State{ .regs = .{ 0, 0, 0, 0 } };
    const instr = Instruction{ .opcode = .cpy, .x = Value{ .imm = 42 }, .y = Value{ .reg = 0 } };
    _ = try execute(&state, instr);
    try std.testing.expectEqual(@as(i64, 42), state.regs[0]);
    try std.testing.expectEqual(@as(usize, 1), state.ip);
}

test "execute inc" {
    var state = State{ .regs = .{ 5, 0, 0, 0 } };
    const instr = Instruction{ .opcode = .inc, .x = Value{ .reg = 0 } };
    _ = try execute(&state, instr);
    try std.testing.expectEqual(@as(i64, 6), state.regs[0]);
    try std.testing.expectEqual(@as(usize, 1), state.ip);
}

test "execute dec" {
    var state = State{ .regs = .{ 5, 0, 0, 0 } };
    const instr = Instruction{ .opcode = .dec, .x = Value{ .reg = 0 } };
    _ = try execute(&state, instr);
    try std.testing.expectEqual(@as(i64, 4), state.regs[0]);
    try std.testing.expectEqual(@as(usize, 1), state.ip);
}

test "execute jnz taken" {
    var state = State{ .regs = .{ 5, 0, 0, 0 } };
    const instr = Instruction{ .opcode = .jnz, .x = Value{ .reg = 0 }, .y = Value{ .imm = 2 } };
    _ = try execute(&state, instr);
    try std.testing.expectEqual(@as(usize, 2), state.ip);
}

test "execute jnz not taken" {
    var state = State{ .regs = .{ 0, 0, 0, 0 } };
    const instr = Instruction{ .opcode = .jnz, .x = Value{ .reg = 0 }, .y = Value{ .imm = 2 } };
    _ = try execute(&state, instr);
    try std.testing.expectEqual(@as(usize, 1), state.ip);
}

test "execute out" {
    var state = State{ .regs = .{ 1, 0, 0, 0 } };
    const instr = Instruction{ .opcode = .out, .x = Value{ .reg = 0 } };
    const output = try execute(&state, instr);
    try std.testing.expectEqual(@as(u8, 1), output.?);
    try std.testing.expectEqual(@as(usize, 1), state.ip);
}

test "registerIndex" {
    try std.testing.expectEqual(@as(?usize, 0), registerIndex("a"));
    try std.testing.expectEqual(@as(?usize, 1), registerIndex("b"));
    try std.testing.expectEqual(@as(?usize, 2), registerIndex("c"));
    try std.testing.expectEqual(@as(?usize, 3), registerIndex("d"));
    try std.testing.expectEqual(@as(?usize, null), registerIndex("e"));
    try std.testing.expectEqual(@as(?usize, null), registerIndex("ab"));
}

test "getValue immediate" {
    const v = Value{ .imm = 42 };
    try std.testing.expectEqual(@as(i64, 42), getValue(State{}, v));
}

test "getValue register" {
    const v = Value{ .reg = 1 };
    const state = State{ .regs = .{ 0, 7, 0, 0 } };
    try std.testing.expectEqual(@as(i64, 7), getValue(state, v));
}
