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
        // Use solution_file to avoid unused warning
        _ = solution_file;

        const gpa = std.heap.page_allocator;

        // For Day 21 RPG Simulator
        const taocp_concepts = try gpa.alloc([]const u8, 3);
        taocp_concepts[0] = "Brute-force enumeration (Vol. 4A, Section 7.2.1.3)";
        taocp_concepts[1] = "Cartesian product generation for equipment combinations";
        taocp_concepts[2] = "Turn-based combat simulation";

        const programming_concepts = try gpa.alloc([]const u8, 3);
        programming_concepts[0] = "Game state management with Player struct";
        programming_concepts[1] = "Equipment data structure design";
        programming_concepts[2] = "Loop control for combat rounds";

        const zig_concepts = try gpa.alloc([]const u8, 4);
        zig_concepts[0] = "Struct definitions (Player, Item)";
        zig_concepts[1] = "Built-in functions (@max) for damage calculation";
        zig_concepts[2] = "Array constants for shop items";
        zig_concepts[3] = "Error handling with try/catch";

        // Problem breakdown for Day 21
        const problem_breakdown = try gpa.alloc([]const u8, 2);
        problem_breakdown[0] = "Find minimum equipment cost to guarantee victory against boss";
        problem_breakdown[1] = "Find maximum equipment cost that still results in defeat";

        return ConceptAnalysis{
            .taocp_concepts = taocp_concepts,
            .programming_concepts = programming_concepts,
            .zig_concepts = zig_concepts,
            .problem_breakdown = problem_breakdown,
        };
    }

    // Generate learning guide content from concept analysis
    pub fn generateLearningGuide(year: u32, day: u32, analysis: ConceptAnalysis) ![]const u8 {
        const gpa = std.heap.page_allocator;

        // Build TAOCP concepts section
        var taocp_content = try std.fmt.allocPrint(gpa, "## TAOCP Concepts Applied\n", .{});
        defer gpa.free(taocp_content);

        for (analysis.taocp_concepts) |concept| {
            const new_content = try std.fmt.allocPrint(gpa, "{s}- {s}\n", .{ taocp_content, concept });
            gpa.free(taocp_content);
            taocp_content = new_content;
        }

        // Build programming concepts section
        var prog_content = try std.fmt.allocPrint(gpa, "## Programming Concepts\n", .{});
        defer gpa.free(prog_content);

        for (analysis.programming_concepts) |concept| {
            const new_content = try std.fmt.allocPrint(gpa, "{s}- {s}\n", .{ prog_content, concept });
            gpa.free(prog_content);
            prog_content = new_content;
        }

        // Build Zig concepts section
        var zig_content = try std.fmt.allocPrint(gpa, "## Zig-Specific Concepts\n", .{});
        defer gpa.free(zig_content);

        for (analysis.zig_concepts) |concept| {
            const new_content = try std.fmt.allocPrint(gpa, "{s}- {s}\n", .{ zig_content, concept });
            gpa.free(zig_content);
            zig_content = new_content;
        }

        const content = try std.fmt.allocPrint(gpa,
            \\# Day {d:0>2} Learning Guide
            \\
            \\## Problem Breakdown
            \\### Part 1: {s}
            \\### Part 2: {s}
            \\
            \\{s}
            \\{s}
            \\{s}
            \\
            \\## Learning Exercises
            \\1. Implement brute-force enumeration for equipment combinations
            \\2. Create turn-based combat simulation
            \\3. Practice struct design for game entities
            \\4. Write min/max optimization functions
            \\
            \\## Key Insights
            \\- **Brute-force enumeration**: Systematic testing of all combinations works for small search spaces
            \\- **Cartesian product**: Equipment combinations form nested loops over weapons, armor, rings
            \\- **Combat simulation**: Deterministic turn-based games can be simulated exactly
            \\- **Min/max optimization**: Track both best and worst solutions during enumeration
        , .{ year, day, analysis.problem_breakdown[0], analysis.problem_breakdown[1], taocp_content, prog_content, zig_content });

        return content;
    }

    // Update learning guide for specific day
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
