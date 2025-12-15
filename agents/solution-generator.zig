const std = @import("std");
const workflow_types = @import("workflow-types.zig");

pub const SolutionGenerator = struct {
    const Self = @This();
    const gpa = std.heap.page_allocator;

    // Rule-based pattern detection
    pub const ProblemPattern = workflow_types.ProblemPattern;

    // Pattern detection rules
    pub fn detectPattern(conceptual_solution: []const u8) !ProblemPattern {
        // Convert to lowercase for case-insensitive matching
        const lower_solution = try toLowercase(conceptual_solution);
        defer gpa.free(lower_solution);

        // Sequential processing patterns (like Day 1)
        if (containsKeywords(lower_solution, &[_][]const u8{ "dial", "position", "rotate", "circular", "sequence", "step by step", "instructions" })) {
            return .sequential_processing;
        }

        // Grid processing patterns
        if (containsKeywords(lower_solution, &[_][]const u8{ "grid", "matrix", "2d", "neighbors", "adjacent", "rows", "columns", "coordinates" })) {
            return .grid_processing;
        }

        // Graph algorithm patterns
        if (containsKeywords(lower_solution, &[_][]const u8{ "graph", "nodes", "edges", "path", "connected", "traverse", "dfs", "bfs", "shortest path" })) {
            return .graph_algorithms;
        }

        // Mathematical patterns
        if (containsKeywords(lower_solution, &[_][]const u8{ "calculate", "formula", "equation", "arithmetic", "modular", "prime", "factors", "sequence" })) {
            return .mathematical;
        }

        // Combinatorial patterns
        if (containsKeywords(lower_solution, &[_][]const u8{ "permutations", "combinations", "arrangements", "backtrack", "possibilities", "all possible" })) {
            return .combinatorial;
        }

        // Complex parsing patterns
        if (containsKeywords(lower_solution, &[_][]const u8{ "parse", "extract", "format", "complex input", "multiple formats", "tokens" })) {
            return .parsing_complex;
        }

        // Optimization patterns
        if (containsKeywords(lower_solution, &[_][]const u8{ "optimize", "minimum", "maximum", "best", "efficient", "dynamic programming", "greedy" })) {
            return .optimization;
        }

        // String processing patterns
        if (containsKeywords(lower_solution, &[_][]const u8{ "string", "pattern", "match", "replace", "substring", "characters", "text" })) {
            return .string_processing;
        }

        // Simulation patterns
        if (containsKeywords(lower_solution, &[_][]const u8{ "simulate", "model", "process", "time steps", "iterations", "evolve" })) {
            return .simulation;
        }

        // Data transformation patterns
        if (containsKeywords(lower_solution, &[_][]const u8{ "transform", "convert", "map", "reduce", "filter", "reformat" })) {
            return .data_transformation;
        }

        // Default to sequential processing
        return .sequential_processing;
    }

    // Generate solution based on pattern
    pub fn generateSolution(pattern: ProblemPattern, conceptual_solution: []const u8, year: u32, day: u32, part: u32) !workflow_types.SolutionResult {
        const template = try getTemplateForPattern(pattern);
        defer gpa.free(template);

        const solution_code = try fillTemplate(template, .{
            .conceptual_solution = conceptual_solution,
            .year = year,
            .day = day,
            .part = part,
            .pattern = pattern,
        });

        return workflow_types.SolutionResult{
            .success = true,
            .solution_code = solution_code,
            .compilation_output = "",
            .errors = &[_][]const u8{},
        };
    }

    // Helper function to check if text contains any keywords
    fn containsKeywords(text: []const u8, keywords: []const []const u8) bool {
        for (keywords) |keyword| {
            if (std.mem.indexOf(u8, text, keyword) != null) {
                return true;
            }
        }
        return false;
    }

    // Convert string to lowercase
    fn toLowercase(str: []const u8) ![]const u8 {
        const result = try gpa.alloc(u8, str.len);
        for (str, 0..) |c, i| {
            result[i] = if (c >= 'A' and c <= 'Z') c + 32 else c;
        }
        return result;
    }

    // Get template for specific pattern
    fn getTemplateForPattern(pattern: ProblemPattern) ![]const u8 {
        return switch (pattern) {
            .sequential_processing => getSequentialProcessingTemplate(),
            .grid_processing => getGridProcessingTemplate(),
            .graph_algorithms => getGraphAlgorithmsTemplate(),
            .mathematical => getMathematicalTemplate(),
            .combinatorial => getCombinatorialTemplate(),
            .parsing_complex => getParsingComplexTemplate(),
            .optimization => getOptimizationTemplate(),
            .string_processing => getStringProcessingTemplate(),
            .simulation => getSimulationTemplate(),
            .data_transformation => getDataTransformationTemplate(),
        };
    }

    // Template filler
    fn fillTemplate(template: []const u8, context: anytype) ![]const u8 {
        // Simple template filling - in a real implementation, this would be more sophisticated
        var result = try gpa.dupe(u8, template);

        // Replace placeholders
        if (std.mem.indexOf(u8, result, "{conceptual_solution}")) |_| {
            const new_result = try std.mem.replaceOwned(u8, gpa, result, "{conceptual_solution}", @TypeOf(context.conceptual_solution));
            gpa.free(result);
            result = new_result;
        }

        return result;
    }

    // Sequential processing template (like Day 1)
    fn getSequentialProcessingTemplate() ![]const u8 {
        return try std.fmt.allocPrint(gpa,
            \\const std = @import("std");
            \\
            \\// TAOCP: State Machine with immutable state updates
            \\const State = struct {{
            \\    // Define state fields based on problem requirements
            \\    position: u32, // Example field
            \\    count: u32,    // Example field
            \\
            \\    // Apply instruction and return new state
            \\    fn applyInstruction(self: State, instruction: Instruction) State {{
            \\        // TAOCP: Process instruction with state transition
            \\        _ = instruction; // TODO: Implement based on {conceptual_solution}
            \\        return self; // TODO: Return updated state
            \\    }}
            \\}};
            \\
            \\// Parsed instruction from input
            \\const Instruction = struct {{
            \\    // Define instruction fields based on input format
            \\    operation: []const u8,
            \\    value: u32,
            \\}};
            \\
            \\// Parse instruction from input line
            \\fn parseInstruction(line: []const u8) !Instruction {{
            \\    // TODO: Implement parsing based on input format
            \\    _ = line;
            \\    return Instruction{{
            \\        .operation = "",
            \\        .value = 0,
            \\    }};
            \\}}
            \\
            \\pub fn part1(input: []const u8) !?[]const u8 {{
            \\    // TAOCP: Initialize state
            \\    var state = State{{ .position = 0, .count = 0 }};
            \\
            \\    // TAOCP: Process input line by line
            \\    var line_iter = std.mem.tokenizeScalar(u8, input, '\\n');
            \\
            \\    while (line_iter.next()) |line| {{
            \\        if (line.len == 0) continue;
            \\
            \\        const trimmed_line = std.mem.trim(u8, line, " \\r\\t");
            \\        if (trimmed_line.len == 0) continue;
            \\
            \\        const instruction = try parseInstruction(trimmed_line);
            \\        state = state.applyInstruction(instruction); // TAOCP: State transition
            \\    }}
            \\
            \\    // Convert result to string
            \\    const gpa = std.heap.page_allocator;
            \\    const result = try std.fmt.allocPrint(gpa, "{{}}", .{{state.count}});
            \\    return result;
            \\}}
            \\
            \\pub fn part2(input: []const u8) !?[]const u8 {{
            \\    // TODO: Implement part 2 based on {conceptual_solution}
            \\    _ = input;
            \\    return null;
            \\}}
        , .{});
    }

    // Grid processing template
    fn getGridProcessingTemplate() ![]const u8 {
        return try std.fmt.allocPrint(gpa,
            \\const std = @import("std");
            \\
            \\// TAOCP: 2D Array processing with neighbor calculations
            \\const Grid = struct {{
            \\    width: usize,
            \\    height: usize,
            \\    data: []u8,
            \\    allocator: std.mem.Allocator,
            \\
            \\    fn init(allocator: std.mem.Allocator, width: usize, height: usize) !Grid {{
            \\        return Grid{{
            \\            .width = width,
            \\            .height = height,
            \\            .data = try allocator.alloc(u8, width * height),
            \\            .allocator = allocator,
            \\        }};
            \\    }}
            \\
            \\    fn deinit(self: Grid) void {{
            \\        self.allocator.free(self.data);
            \\    }}
            \\
            \\    fn get(self: Grid, x: usize, y: usize) u8 {{
            \\        return self.data[y * self.width + x];
            \\    }}
            \\
            \\    fn set(self: Grid, x: usize, y: usize, value: u8) void {{
            \\        self.data[y * self.width + x] = value;
            \\    }}
            \\
            \\    fn getNeighbors(self: Grid, x: usize, y: usize) [4]?[2]usize {{
            \\        // TAOCP: Boundary checking and neighbor enumeration
            \\        var neighbors: [4]?[2]usize = .{{ null, null, null, null }};
            \\        var count: usize = 0;
            \\
            \\        // Up
            \\        if (y > 0) {{
            \\            neighbors[count] = .{{ x, y - 1 }};
            \\            count += 1;
            \\        }}
            \\        // Right
            \\        if (x < self.width - 1) {{
            \\            neighbors[count] = .{{ x + 1, y }};
            \\            count += 1;
            \\        }}
            \\        // Down
            \\        if (y < self.height - 1) {{
            \\            neighbors[count] = .{{ x, y + 1 }};
            \\            count += 1;
            \\        }}
            \\        // Left
            \\        if (x > 0) {{
            \\            neighbors[count] = .{{ x - 1, y }};
            \\            count += 1;
            \\        }}
            \\
            \\        return neighbors;
            \\    }}
            \\}};
            \\
            \\pub fn part1(input: []const u8) !?[]const u8 {{
            \\    // TODO: Parse grid from input based on {conceptual_solution}
            \\    _ = input;
            \\    return null;
            \\}}
            \\
            \\pub fn part2(input: []const u8) !?[]const u8 {{
            \\    // TODO: Implement part 2
            \\    _ = input;
            \\    return null;
            \\}}
        , .{});
    }

    // Mathematical template
    fn getMathematicalTemplate() ![]const u8 {
        return try std.fmt.allocPrint(gpa,
            \\const std = @import("std");
            \\
            \\// TAOCP: Mathematical functions and algorithms
            \\pub fn part1(input: []const u8) !?[]const u8 {{
            \\    // TODO: Implement mathematical solution based on {conceptual_solution}
            \\    // Consider: modular arithmetic, prime numbers, sequences, etc.
            \\    _ = input;
            \\    return null;
            \\}}
            \\
            \\pub fn part2(input: []const u8) !?[]const u8 {{
            \\    // TODO: Implement part 2
            \\    _ = input;
            \\    return null;
            \\}}
        , .{});
    }

    // Placeholder templates for other patterns
    fn getGraphAlgorithmsTemplate() ![]const u8 {
        return getSequentialProcessingTemplate(); // Fallback
    }

    fn getCombinatorialTemplate() ![]const u8 {
        return getSequentialProcessingTemplate(); // Fallback
    }

    fn getParsingComplexTemplate() ![]const u8 {
        return getSequentialProcessingTemplate(); // Fallback
    }

    fn getOptimizationTemplate() ![]const u8 {
        return getSequentialProcessingTemplate(); // Fallback
    }

    fn getStringProcessingTemplate() ![]const u8 {
        return getSequentialProcessingTemplate(); // Fallback
    }

    fn getSimulationTemplate() ![]const u8 {
        return getSequentialProcessingTemplate(); // Fallback
    }

    fn getDataTransformationTemplate() ![]const u8 {
        return getSequentialProcessingTemplate(); // Fallback
    }
};
