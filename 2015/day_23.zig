const std = @import("std");

const Register = enum {
    a,
    b,

    pub fn fromString(str: []const u8) ?Register {
        if (std.mem.eql(u8, str, "a")) return .a;
        if (std.mem.eql(u8, str, "b")) return .b;
        return null;
    }
};

const Opcode = enum {
    hlf, // half register
    tpl, // triple register
    inc, // increment register
    jmp, // jump offset
    jie, // jump if even
    jio, // jump if one

    pub fn fromString(str: []const u8) ?Opcode {
        if (std.mem.eql(u8, str, "hlf")) return .hlf;
        if (std.mem.eql(u8, str, "tpl")) return .tpl;
        if (std.mem.eql(u8, str, "inc")) return .inc;
        if (std.mem.eql(u8, str, "jmp")) return .jmp;
        if (std.mem.eql(u8, str, "jie")) return .jie;
        if (std.mem.eql(u8, str, "jio")) return .jio;
        return null;
    }
};

const Instruction = struct {
    opcode: Opcode,
    reg: ?Register = null,
    offset: i64 = 0,

    pub fn parse(line: []const u8) !Instruction {
        var it = std.mem.tokenizeScalar(u8, line, ' ');
        const opcode_str = it.next().?;
        const opcode = Opcode.fromString(opcode_str) orelse return error.InvalidOpcode;

        switch (opcode) {
            .hlf, .tpl, .inc => {
                const reg_str = it.next().?;
                const reg = Register.fromString(reg_str) orelse return error.InvalidRegister;
                return Instruction{ .opcode = opcode, .reg = reg };
            },
            .jmp => {
                const offset_str = it.next().?;
                const offset = try std.fmt.parseInt(i64, offset_str, 10);
                return Instruction{ .opcode = opcode, .offset = offset };
            },
            .jie, .jio => {
                const reg_with_comma = it.next().?;
                const reg_str = if (reg_with_comma[reg_with_comma.len - 1] == ',')
                    reg_with_comma[0 .. reg_with_comma.len - 1]
                else
                    reg_with_comma;
                const reg = Register.fromString(reg_str) orelse return error.InvalidRegister;

                const offset_str = it.next().?;
                const offset = try std.fmt.parseInt(i64, offset_str, 10);

                return Instruction{ .opcode = opcode, .reg = reg, .offset = offset };
            },
        }
    }
};

const State = struct {
    registers: [2]u64,
    ip: usize,
    instructions: []Instruction,

    pub fn init(instructions: []Instruction, start_a: u64) State {
        return State{
            .registers = .{ start_a, 0 },
            .ip = 0,
            .instructions = instructions,
        };
    }

    pub fn run(self: *State) void {
        while (self.ip < self.instructions.len) {
            const instr = self.instructions[self.ip];

            switch (instr.opcode) {
                .hlf => {
                    const reg_idx = @intFromEnum(instr.reg.?);
                    self.registers[reg_idx] /= 2;
                    self.ip += 1;
                },
                .tpl => {
                    const reg_idx = @intFromEnum(instr.reg.?);
                    self.registers[reg_idx] *= 3;
                    self.ip += 1;
                },
                .inc => {
                    const reg_idx = @intFromEnum(instr.reg.?);
                    self.registers[reg_idx] += 1;
                    self.ip += 1;
                },
                .jmp => {
                    const new_ip = @as(isize, @intCast(self.ip)) + instr.offset;
                    self.ip = @as(usize, @intCast(new_ip));
                },
                .jie => {
                    const reg_idx = @intFromEnum(instr.reg.?);
                    if (self.registers[reg_idx] % 2 == 0) {
                        const new_ip = @as(isize, @intCast(self.ip)) + instr.offset;
                        self.ip = @as(usize, @intCast(new_ip));
                    } else {
                        self.ip += 1;
                    }
                },
                .jio => {
                    const reg_idx = @intFromEnum(instr.reg.?);
                    if (self.registers[reg_idx] == 1) {
                        const new_ip = @as(isize, @intCast(self.ip)) + instr.offset;
                        self.ip = @as(usize, @intCast(new_ip));
                    } else {
                        self.ip += 1;
                    }
                },
            }
        }
    }
};

pub fn part1(input: []const u8) !?[]const u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var instructions = std.ArrayList(Instruction).initCapacity(allocator, 50) catch unreachable;
    defer instructions.deinit(allocator);

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const instr = try Instruction.parse(line);
        try instructions.append(allocator, instr);
    }

    var state = State.init(instructions.items, 0);
    state.run();

    const result = state.registers[@intFromEnum(Register.b)];
    return try std.fmt.allocPrint(allocator, "{}", .{result});
}

pub fn part2(input: []const u8) !?[]const u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var instructions = std.ArrayList(Instruction).initCapacity(allocator, 50) catch unreachable;
    defer instructions.deinit(allocator);

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const instr = try Instruction.parse(line);
        try instructions.append(allocator, instr);
    }

    var state = State.init(instructions.items, 1);
    state.run();

    const result = state.registers[@intFromEnum(Register.b)];
    return try std.fmt.allocPrint(allocator, "{}", .{result});
}
