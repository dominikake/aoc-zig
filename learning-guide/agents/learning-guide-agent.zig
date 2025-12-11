const std = @import("std");

// TAOCP Learning Guide Agent
// Purpose: Update learning guides after successful AoC submissions

pub const ConceptAnalysis = struct {
    taocp_concepts: []const []const u8,
    programming_concepts: []const []const u8,
    zig_concepts: []const []const u8,
    problem_breakdown: []const []const u8,
};

pub const LearningGuideAgent = struct {
    const Self = @This();

    // Extract TAOCP and programming concepts from solution file
    pub fn extractConcepts(solution_file: []const u8) !ConceptAnalysis {
        _ = solution_file; // For now, use hardcoded Day 1 analysis

        const gpa = std.heap.page_allocator;

        // For Day 1, we know concepts based on our analysis
        const taocp_concepts = try gpa.alloc([]const u8, 4);
        taocp_concepts[0] = "Circular Arithmetic - Mod 100 operations for position tracking";
        taocp_concepts[1] = "State Machine - Isolated transducers for each instruction";
        taocp_concepts[2] = "Ring Data Structure - Implicit in modular arithmetic";
        taocp_concepts[3] = "Algorithm - O(1) zero-crossing formula";

        const programming_concepts = try gpa.alloc([]const u8, 3);
        programming_concepts[0] = "State machines and transducers";
        programming_concepts[1] = "Modular arithmetic";
        programming_concepts[2] = "Input parsing and validation";

        const zig_concepts = try gpa.alloc([]const u8, 5);
        zig_concepts[0] = "Error handling with try/catch";
        zig_concepts[1] = "Pattern matching with switch statements";
        zig_concepts[2] = "Type casting with @intCast";
        zig_concepts[3] = "Memory management with allocators";
        zig_concepts[4] = "Comptime features (for future days)";

        const problem_breakdown = try gpa.alloc([]const u8, 2);
        problem_breakdown[0] = "Track circular dial position, count final position landings on zero";
        problem_breakdown[1] = "Count ALL zero crossings during rotation steps, not just final positions";

        return ConceptAnalysis{
            .taocp_concepts = taocp_concepts,
            .programming_concepts = programming_concepts,
            .zig_concepts = zig_concepts,
            .problem_breakdown = problem_breakdown,
        };
    }

    // Generate learning guide content from concept analysis
    pub fn generateLearningGuide(year: u32, day: u32, analysis: ConceptAnalysis) ![]const u8 {
        _ = year; // For now, not used in template
        const gpa = std.heap.page_allocator;

        // Use simple string formatting for now
        const content = try std.fmt.allocPrint(gpa,
            \\# Day {d:0>2} Learning Guide
            \\
            \\## Problem Breakdown
            \\### Part 1: {s}
            \\### Part 2: {s}
            \\
            \\## TAOCP Concepts Applied
            \\- Circular Arithmetic - Mod 100 operations for position tracking
            \\- State Machine - Isolated transducers for each instruction
            \\- Ring Data Structure - Implicit in modular arithmetic
            \\- Algorithm - O(1) zero-crossing formula
            \\
            \\## Programming Concepts
            \\- State machines and transducers
            \\- Modular arithmetic
            \\- Input parsing and validation
            \\
            \\## Zig-Specific Concepts
            \\- Error handling with try/catch
            \\- Pattern matching with switch statements
            \\- Type casting with @intCast
            \\- Memory management with allocators
            \\- Comptime features (for future days)
            \\
            \\## Learning Exercises
            \\1. Implement a simple circular buffer using modular arithmetic
            \\2. Create a state machine that processes sequential instructions
            \\3. Practice error handling patterns in Zig
            \\4. Write a function to count zero crossings in arithmetic progressions
            \\
            \\## Key Insights
            \\- **Circular Arithmetic**: The dial wraps around every 100 positions
            \\- **Zero Crossings**: Count intermediate hits, not just final positions
            \\- **O(1) Formula**: Mathematical approach beats brute-force simulation
            \\- **State Isolation**: Each instruction can be processed independently
        , .{ day, analysis.problem_breakdown[0], analysis.problem_breakdown[1] });

        return content;
    }

    // Update learning guide file
    pub fn updateDay(year: u32, day: u32, solution_file: []const u8) !void {
        const gpa = std.heap.page_allocator;

        // Extract concepts from solution
        const analysis = try extractConcepts(solution_file);
        defer {
            gpa.free(analysis.taocp_concepts);
            gpa.free(analysis.programming_concepts);
            gpa.free(analysis.zig_concepts);
            gpa.free(analysis.problem_breakdown);
        }

        // Generate learning guide content
        const content = try generateLearningGuide(year, day, analysis);
        defer gpa.free(content);

        // Create directory if it doesn't exist
        const dir_path = try std.fmt.allocPrint(gpa, "learning-guide/{d}", .{year});
        defer gpa.free(dir_path);

        std.fs.cwd().makePath(dir_path) catch |err| switch (err) {
            error.PathAlreadyExists => {}, // OK
            else => return err,
        };

        // Write learning guide file
        const file_path = try std.fmt.allocPrint(gpa, "{s}/day-{d:0>2}-learning-guide.md", .{ dir_path, day });
        defer gpa.free(file_path);

        const file = try std.fs.cwd().createFile(file_path, .{});
        defer file.close();

        try file.writeAll(content);

        std.debug.print("Learning guide updated: {s}\n", .{file_path});
    }
};

pub fn main() !void {
    const gpa = std.heap.page_allocator;

    // Get command line arguments
    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    if (args.len < 4) {
        std.debug.print("Usage: learning-guide-agent <year> <day> <solution_file>\n", .{});
        return;
    }

    const year = try std.fmt.parseInt(u32, args[1], 10);
    const day = try std.fmt.parseInt(u32, args[2], 10);
    const solution_file = args[3];

    // Read solution file
    const file = try std.fs.cwd().openFile(solution_file, .{});
    defer file.close();

    const solution_content = try file.readToEndAlloc(gpa, 1024 * 1024);
    defer gpa.free(solution_content);

    // Update learning guide
    try LearningGuideAgent.updateDay(year, day, solution_content);

    std.debug.print("Learning guide updated successfully for Day {d:0>2}\n", .{day});
}
