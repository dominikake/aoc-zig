const std = @import("std");
const workflow_types = @import("workflow-types.zig");

pub const EnhancedLearningAgent = struct {
    const Self = @This();
    const gpa = std.heap.page_allocator;

    // High-level TAOCP concept mapping
    pub const TAOCP_CONCEPTS = struct {
        pub const FUNDAMENTAL_ALGORITHMS = [_][]const u8{
            "Data Structures - Arrays, lists, stacks, queues",
            "Information Structures - Trees, graphs, networks",
            "Machine Algorithms - State machines, transducers",
            "Arithmetic - Random numbers, integer arithmetic",
        };

        pub const SEMINUMERICAL_ALGORITHMS = [_][]const u8{
            "Random Numbers - Generation, testing",
            "Arithmetic - Multiple precision, floating point",
            "Polynomial Arithmetic - Manipulation, evaluation",
        };

        pub const SORTING_SEARCHING = [_][]const u8{
            "Internal Sorting - Various sorting algorithms",
            "External Sorting - Large dataset handling",
            "Searching - Sequential, binary, hash methods",
            "Optimization - Dynamic programming, greedy",
        };

        pub const COMBINATORIAL_ALGORITHMS = [_][]const u8{
            "Generation - Tuples, permutations, combinations",
            "Graph Algorithms - Traversal, connectivity, flows",
            "Backtracking - Constraint satisfaction, dancing links",
            "Recursion - Divide and conquer, dynamic programming",
        };
    };

    // Concept analysis structure
    pub const ConceptAnalysis = struct {
        problem_pattern: workflow_types.ProblemPattern,
        taocp_concepts: std.ArrayList([]const u8),
        programming_concepts: std.ArrayList([]const u8),
        zig_concepts: std.ArrayList([]const u8),
        problem_breakdown: std.ArrayList([]const u8),
        key_insights: std.ArrayList([]const u8),

        pub fn init(allocator: std.mem.Allocator) ConceptAnalysis {
            return ConceptAnalysis{
                .problem_pattern = .sequential_processing,
                .taocp_concepts = std.ArrayList([]const u8).init(allocator),
                .programming_concepts = std.ArrayList([]const u8).init(allocator),
                .zig_concepts = std.ArrayList([]const u8).init(allocator),
                .problem_breakdown = std.ArrayList([]const u8).init(allocator),
                .key_insights = std.ArrayList([]const u8).init(allocator),
            };
        }

        pub fn deinit(self: *ConceptAnalysis) void {
            self.taocp_concepts.deinit();
            self.programming_concepts.deinit();
            self.zig_concepts.deinit();
            self.problem_breakdown.deinit();
            self.key_insights.deinit();
        }

        pub fn addTAOCPConcept(self: *ConceptAnalysis, concept: []const u8) !void {
            try self.taocp_concepts.append(concept);
        }

        pub fn addProgrammingConcept(self: *ConceptAnalysis, concept: []const u8) !void {
            try self.programming_concepts.append(concept);
        }

        pub fn addZigConcept(self: *ConceptAnalysis, concept: []const u8) !void {
            try self.zig_concepts.append(concept);
        }

        pub fn addProblemBreakdown(self: *ConceptAnalysis, breakdown: []const u8) !void {
            try self.problem_breakdown.append(breakdown);
        }

        pub fn addKeyInsight(self: *ConceptAnalysis, insight: []const u8) !void {
            try self.key_insights.append(insight);
        }
    };

    // Dynamic analysis of solution code
    pub fn analyzeSolutionCode(solution_code: []const u8) !ConceptAnalysis {
        var analysis = ConceptAnalysis.init(gpa);
        errdefer analysis.deinit();

        // Detect problem pattern
        analysis.problem_pattern = try detectProblemPattern(solution_code);

        // Extract TAOCP concepts based on code patterns
        try extractTAOCPConcepts(&analysis, solution_code);

        // Extract programming concepts
        try extractProgrammingConcepts(&analysis, solution_code);

        // Extract Zig-specific concepts
        try extractZigConcepts(&analysis, solution_code);

        // Generate problem breakdown
        try generateProblemBreakdown(&analysis, solution_code);

        // Extract key insights
        try extractKeyInsights(&analysis, solution_code);

        return analysis;
    }

    // Detect problem pattern from solution code
    fn detectProblemPattern(solution_code: []const u8) !workflow_types.ProblemPattern {
        const lower_code = try toLowercase(solution_code);
        defer gpa.free(lower_code);

        if (std.mem.indexOf(u8, lower_code, "state") != null and
            std.mem.indexOf(u8, lower_code, "applyinstruction") != null)
        {
            return .sequential_processing;
        }

        if (std.mem.indexOf(u8, lower_code, "grid") != null or
            std.mem.indexOf(u8, lower_code, "neighbors") != null)
        {
            return .grid_processing;
        }

        if (std.mem.indexOf(u8, lower_code, "graph") != null or
            std.mem.indexOf(u8, lower_code, "dfs") != null or
            std.mem.indexOf(u8, lower_code, "bfs") != null)
        {
            return .graph_algorithms;
        }

        if (std.mem.indexOf(u8, lower_code, "@mod") != null or
            std.mem.indexOf(u8, lower_code, "formula") != null)
        {
            return .mathematical;
        }

        if (std.mem.indexOf(u8, lower_code, "permutation") != null or
            std.mem.indexOf(u8, lower_code, "combination") != null)
        {
            return .combinatorial;
        }

        return .sequential_processing; // Default
    }

    // Extract TAOCP concepts from code
    fn extractTAOCPConcepts(analysis: *ConceptAnalysis, solution_code: []const u8) !void {
        const lower_code = try toLowercase(solution_code);
        defer gpa.free(lower_code);

        // State machine patterns
        if (std.mem.indexOf(u8, lower_code, "state") != null) {
            try analysis.addTAOCPConcept("Machine Algorithms - State machines");
        }

        // Modular arithmetic
        if (std.mem.indexOf(u8, lower_code, "@mod") != null) {
            try analysis.addTAOCPConcept("Arithmetic - Modular arithmetic");
        }

        // Data structures
        if (std.mem.indexOf(u8, lower_code, "arraylist") != null) {
            try analysis.addTAOCPConcept("Data Structures - Dynamic arrays");
        }

        if (std.mem.indexOf(u8, lower_code, "tokenize") != null) {
            try analysis.addTAOCPConcept("Information Structures - String processing");
        }

        // Graph algorithms
        if (std.mem.indexOf(u8, lower_code, "neighbors") != null) {
            try analysis.addTAOCPConcept("Graph Algorithms - Traversal");
        }

        // Mathematical operations
        if (std.mem.indexOf(u8, lower_code, "calculate") != null or
            std.mem.indexOf(u8, lower_code, "formula") != null)
        {
            try analysis.addTAOCPConcept("Arithmetic - Mathematical functions");
        }

        // Optimization patterns
        if (std.mem.indexOf(u8, lower_code, "o(1)") != null or
            std.mem.indexOf(u8, lower_code, "optimize") != null)
        {
            try analysis.addTAOCPConcept("Optimization - Algorithm analysis");
        }
    }

    // Extract programming concepts
    fn extractProgrammingConcepts(analysis: *ConceptAnalysis, solution_code: []const u8) !void {
        const lower_code = try toLowercase(solution_code);
        defer gpa.free(lower_code);

        if (std.mem.indexOf(u8, lower_code, "state") != null) {
            try analysis.addProgrammingConcept("State machines and state management");
        }

        if (std.mem.indexOf(u8, lower_code, "tokenize") != null) {
            try analysis.addProgrammingConcept("Input parsing and tokenization");
        }

        if (std.mem.indexOf(u8, lower_code, "iterator") != null) {
            try analysis.addProgrammingConcept("Iterator patterns and streaming");
        }

        if (std.mem.indexOf(u8, lower_code, "modular") != null) {
            try analysis.addProgrammingConcept("Modular arithmetic");
        }

        if (std.mem.indexOf(u8, lower_code, "neighbors") != null) {
            try analysis.addProgrammingConcept("Grid traversal and neighbor calculations");
        }

        if (std.mem.indexOf(u8, lower_code, "error") != null) {
            try analysis.addProgrammingConcept("Error handling patterns");
        }

        if (std.mem.indexOf(u8, lower_code, "alloc") != null) {
            try analysis.addProgrammingConcept("Memory management");
        }
    }

    // Extract Zig-specific concepts
    fn extractZigConcepts(analysis: *ConceptAnalysis, solution_code: []const u8) !void {
        const lower_code = try toLowercase(solution_code);
        defer gpa.free(lower_code);

        if (std.mem.indexOf(u8, lower_code, "try") != null) {
            try analysis.addZigConcept("Error handling with try/catch");
        }

        if (std.mem.indexOf(u8, lower_code, "switch") != null) {
            try analysis.addZigConcept("Pattern matching with switch statements");
        }

        if (std.mem.indexOf(u8, lower_code, "@intcast") != null) {
            try analysis.addZigConcept("Type casting with @intCast");
        }

        if (std.mem.indexOf(u8, lower_code, "allocator") != null) {
            try analysis.addZigConcept("Memory management with allocators");
        }

        if (std.mem.indexOf(u8, lower_code, "struct") != null) {
            try analysis.addZigConcept("Struct-based data structures");
        }

        if (std.mem.indexOf(u8, lower_code, "enum") != null) {
            try analysis.addZigConcept("Enum-based type safety");
        }

        if (std.mem.indexOf(u8, lower_code, "defer") != null) {
            try analysis.addZigConcept("Resource cleanup with defer");
        }

        if (std.mem.indexOf(u8, lower_code, "comptime") != null) {
            try analysis.addZigConcept("Compile-time computation");
        }
    }

    // Generate problem breakdown
    fn generateProblemBreakdown(analysis: *ConceptAnalysis, solution_code: []const u8) !void {
        const lower_code = try toLowercase(solution_code);
        defer gpa.free(lower_code);

        switch (analysis.problem_pattern) {
            .sequential_processing => {
                try analysis.addProblemBreakdown("Process input sequentially with state transitions");
                try analysis.addProblemBreakdown("Track state changes through instruction sequence");
            },
            .grid_processing => {
                try analysis.addProblemBreakdown("Parse 2D grid from input format");
                try analysis.addProblemBreakdown("Process grid cells with neighbor calculations");
            },
            .graph_algorithms => {
                try analysis.addProblemBreakdown("Build graph structure from input");
                try analysis.addProblemBreakdown("Apply graph traversal algorithms");
            },
            .mathematical => {
                try analysis.addProblemBreakdown("Extract numerical data from input");
                try analysis.addProblemBreakdown("Apply mathematical formulas or sequences");
            },
            else => {
                try analysis.addProblemBreakdown("Parse and process input data");
                try analysis.addProblemBreakdown("Apply appropriate algorithmic solution");
            },
        }
    }

    // Extract key insights
    fn extractKeyInsights(analysis: *ConceptAnalysis, solution_code: []const u8) !void {
        const lower_code = try toLowercase(solution_code);
        defer gpa.free(lower_code);

        // Performance insights
        if (std.mem.indexOf(u8, lower_code, "o(1)") != null) {
            try analysis.addKeyInsight("O(1) optimization beats brute-force approaches");
        }

        if (std.mem.indexOf(u8, lower_code, "@mod") != null) {
            try analysis.addKeyInsight("Modular arithmetic handles circular/wrapping behavior");
        }

        // State management insights
        if (std.mem.indexOf(u8, lower_code, "state") != null) {
            try analysis.addKeyInsight("Immutable state updates prevent side effects");
        }

        // Memory management insights
        if (std.mem.indexOf(u8, lower_code, "defer") != null) {
            try analysis.addKeyInsight("Defer ensures proper resource cleanup");
        }

        // Error handling insights
        if (std.mem.indexOf(u8, lower_code, "try") != null) {
            try analysis.addKeyInsight("Explicit error handling prevents silent failures");
        }

        // Pattern-specific insights
        switch (analysis.problem_pattern) {
            .sequential_processing => {
                try analysis.addKeyInsight("Each instruction can be processed independently");
            },
            .grid_processing => {
                try analysis.addKeyInsight("Boundary checking is essential for grid operations");
            },
            .graph_algorithms => {
                try analysis.addKeyInsight("Visited tracking prevents infinite loops");
            },
            else => {},
        }
    }

    // Generate learning guide content
    pub fn generateLearningGuide(year: u32, day: u32, analysis: ConceptAnalysis) ![]const u8 {
        _ = year; // Currently unused, but kept for future use
        const exercises = try generateExercises(analysis);
        defer gpa.free(exercises);

        var content_buffer = std.ArrayList(u8).init(gpa);
        defer content_buffer.deinit();

        try content_buffer.writer().print(
            \\# Day {d:0>2} Learning Guide
            \\
            \\## Problem Breakdown
            \\
        , .{day});

        for (analysis.problem_breakdown.items) |breakdown| {
            try content_buffer.writer().print("- {s}\n", .{breakdown});
        }

        try content_buffer.writer().print(
            \\
            \\## TAOCP Concepts Applied
            \\
        , .{});

        for (analysis.taocp_concepts.items) |concept| {
            try content_buffer.writer().print("- {s}\n", .{concept});
        }

        try content_buffer.writer().print(
            \\
            \\## Programming Concepts
            \\
        , .{});

        for (analysis.programming_concepts.items) |concept| {
            try content_buffer.writer().print("- {s}\n", .{concept});
        }

        try content_buffer.writer().print(
            \\
            \\## Zig-Specific Concepts
            \\
        , .{});

        for (analysis.zig_concepts.items) |concept| {
            try content_buffer.writer().print("- {s}\n", .{concept});
        }

        try content_buffer.writer().print(
            \\
            \\## Learning Exercises
            \\
            \\{s}
            \\
            \\## Key Insights
            \\
        , .{exercises});

        for (analysis.key_insights.items) |insight| {
            try content_buffer.writer().print("- **{s}**\n", .{insight});
        }

        try content_buffer.writer().print("\n", .{});

        return content_buffer.toOwnedSlice();
    }

    // Generate exercises based on analysis
    fn generateExercises(analysis: ConceptAnalysis) ![]const u8 {
        var exercises = std.ArrayList([]const u8).init(gpa);
        defer exercises.deinit();

        // Rule-based exercise generation
        for (analysis.taocp_concepts.items) |concept| {
            if (std.mem.indexOf(u8, concept, "State machine") != null) {
                try exercises.append("1. Implement a simple state machine for a traffic light system");
            }
            if (std.mem.indexOf(u8, concept, "Modular arithmetic") != null) {
                try exercises.append("2. Create a circular buffer using modular arithmetic");
            }
            if (std.mem.indexOf(u8, concept, "Data Structures") != null) {
                try exercises.append("3. Build a dynamic array that automatically resizes");
            }
        }

        for (analysis.zig_concepts.items) |concept| {
            if (std.mem.indexOf(u8, concept, "Error handling") != null) {
                try exercises.append("4. Practice error handling patterns with file operations");
            }
            if (std.mem.indexOf(u8, concept, "Memory management") != null) {
                try exercises.append("5. Implement a custom allocator with usage tracking");
            }
        }

        // Add pattern-specific exercises
        switch (analysis.problem_pattern) {
            .sequential_processing => {
                try exercises.append("6. Process a sequence of instructions with state tracking");
            },
            .grid_processing => {
                try exercises.append("7. Implement pathfinding in a 2D grid with obstacles");
            },
            .graph_algorithms => {
                try exercises.append("8. Build a graph and implement BFS/DFS traversal");
            },
            .mathematical => {
                try exercises.append("9. Solve number theory problems using modular arithmetic");
            },
            else => {
                try exercises.append("10. Analyze and optimize an existing algorithm");
            },
        }

        // Join exercises into single string
        var result = std.ArrayList(u8).init(gpa);
        defer result.deinit();

        for (exercises.items) |exercise| {
            try result.appendSlice(exercise);
            try result.append('\n');
        }

        return result.toOwnedSlice();
    }

    // Update learning guide file
    pub fn updateDay(year: u32, day: u32, solution_file: []const u8) !void {
        // Read solution file
        const file = try std.fs.cwd().openFile(solution_file, .{});
        defer file.close();

        const solution_content = try file.readToEndAlloc(gpa, workflow_types.AgentConfig.MAX_SOLUTION_SIZE);
        defer gpa.free(solution_content);

        // Analyze solution
        const analysis = try analyzeSolutionCode(solution_content);
        defer analysis.deinit();

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

        const guide_file = try std.fs.cwd().createFile(file_path, .{});
        defer guide_file.close();

        try guide_file.writeAll(content);

        std.debug.print("Learning guide updated: {s}\n", .{file_path});
    }

    // Helper function to convert string to lowercase
    fn toLowercase(str: []const u8) ![]const u8 {
        const result = try gpa.alloc(u8, str.len);
        for (str, 0..) |c, i| {
            result[i] = if (c >= 'A' and c <= 'Z') c + 32 else c;
        }
        return result;
    }
};
