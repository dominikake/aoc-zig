const std = @import("std");
const workflow_types = @import("workflow-types.zig");
const unified_agent = @import("unified-aoc-agent.zig");
const solution_generator = @import("solution-generator.zig");
const enhanced_learning = @import("enhanced-learning-agent.zig");
const error_handler = @import("error-handler.zig");

const gpa = std.heap.page_allocator;

pub fn main() !void {
    // Suppress unused import warnings for testing
    _ = solution_generator;
    _ = enhanced_learning;
    _ = error_handler;

    std.debug.print("=== Running Unified AoC Agent Tests ===\n", .{});

    // Test 1: Workflow request parsing
    try testWorkflowRequestParsing();

    // Test 2: Pattern detection
    try testPatternDetection();

    // Test 3: Solution generation
    try testSolutionGeneration();

    // Test 4: Learning guide analysis
    try testLearningGuideAnalysis();

    // Test 5: Error handling
    try testErrorHandling();

    // Test 6: Template engine
    try testTemplateEngine();

    // Test 7: Full workflow integration
    try testFullWorkflow();

    std.debug.print("=== All Tests Completed ===\n", .{});
}

// Test workflow request parsing
fn testWorkflowRequestParsing() !void {
    std.debug.print("\n--- Test 1: Workflow Request Parsing ---\n", .{});

    const test_input = "year=2025, day=1, part=1; Use circular arithmetic to track dial position";
    const request = try parseWorkflowRequest(test_input);

    std.debug.assert(request.year == 2025);
    std.debug.assert(request.day == 1);
    std.debug.assert(request.part == 1);
    std.debug.assert(std.mem.eql(u8, request.conceptual_solution, "Use circular arithmetic to track dial position"));

    std.debug.print("✅ Workflow request parsing test passed\n", .{});
}

// Test pattern detection
fn testPatternDetection() !void {
    std.debug.print("\n--- Test 2: Pattern Detection ---\n", .{});

    // Test sequential processing detection
    const sequential_input = "Use circular arithmetic to track dial position and rotate";
    const sequential_pattern = try solution_generator.SolutionGenerator.detectPattern(sequential_input);
    std.debug.assert(sequential_pattern == .sequential_processing);

    // Test grid processing detection
    const grid_input = "Process 2D grid to find shortest path between neighbors";
    const grid_pattern = try solution_generator.SolutionGenerator.detectPattern(grid_input);
    std.debug.assert(grid_pattern == .grid_processing);

    // Test mathematical detection
    const math_input = "Calculate using modular arithmetic and prime number formulas";
    const math_pattern = try solution_generator.SolutionGenerator.detectPattern(math_input);
    std.debug.assert(math_pattern == .mathematical);

    std.debug.print("✅ Pattern detection test passed\n", .{});
}

// Test solution generation
fn testSolutionGeneration() !void {
    std.debug.print("\n--- Test 3: Solution Generation ---\n", .{});

    const concept = "Use circular arithmetic to track dial position";
    const pattern = workflow_types.ProblemPattern.sequential_processing;

    const result = try solution_generator.SolutionGenerator.generateSolution(pattern, concept, 2025, 1, 1);
    defer result.deinit(gpa);

    std.debug.assert(result.success);
    std.debug.assert(result.solution_code.len > 0);
    std.debug.assert(std.mem.indexOf(u8, result.solution_code, "State") != null);

    std.debug.print("✅ Solution generation test passed\n", .{});
}

// Test learning guide analysis
fn testLearningGuideAnalysis() !void {
    std.debug.print("\n--- Test 4: Learning Guide Analysis ---\n", .{});

    const sample_solution =
        \\const std = @import("std");
        \\
        \\const State = struct {
        \\    position: u32,
        \\    count: u32,
        \\};
        \\
        \\pub fn part1(input: []const u8) !?[]const u8 {
        \\    var state = State{ .position = 0, .count = 0 };
        \\    // Process with try and @mod
        \\    return null;
        \\}
    ;

    const analysis = try enhanced_learning.EnhancedLearningAgent.analyzeSolutionCode(sample_solution);
    defer analysis.deinit();

    std.debug.assert(analysis.problem_pattern == .sequential_processing);
    std.debug.assert(analysis.taocp_concepts.items.len > 0);
    std.debug.assert(analysis.zig_concepts.items.len > 0);

    std.debug.print("✅ Learning guide analysis test passed\n", .{});
}

// Test error handling
fn testErrorHandling() !void {
    std.debug.print("\n--- Test 5: Error Handling ---\n", .{});

    const context = workflow_types.ErrorContext{
        .error_type = .CompilationFailed,
        .workflow_request = undefined,
        .solution_code = "invalid code",
        .test_input = "",
        .expected_output = "",
        .actual_output = "",
        .compilation_output = "syntax error",
    };

    const recovery = try error_handler.ErrorHandler.handleSolutionError(.CompilationFailed, context);
    defer recovery.deinit(gpa);

    std.debug.assert(recovery.strategy == .step_by_step_execution);
    std.debug.assert(recovery.max_retries > 0);

    std.debug.print("✅ Error handling test passed\n", .{});
}

// Test template engine
fn testTemplateEngine() !void {
    std.debug.print("\n--- Test 6: Template Engine ---\n", .{});

    const template_engine = @import("template-engine.zig");

    // Test template filling
    const template = "Hello {name}, Day {day:0>2}!";
    const context = struct {
        name: []const u8,
        day: u32,
    }{ .name = "AoC", .day = 1 };

    const result = try template_engine.TemplateEngine.fillTemplate(template, context);
    defer gpa.free(result);

    std.debug.assert(std.mem.indexOf(u8, result, "Hello AoC") != null);
    std.debug.assert(std.mem.indexOf(u8, result, "Day 01") != null);

    std.debug.print("✅ Template engine test passed\n", .{});
}

// Test full workflow integration
fn testFullWorkflow() !void {
    std.debug.print("\n--- Test 7: Full Workflow Integration ---\n", .{});

    // This is a simplified integration test
    // In a real scenario, this would test the complete workflow
    const year: u32 = 2025;
    const day: u32 = 1;
    const part: u32 = 1;
    const concept = "Use circular arithmetic to track dial position";

    // Test individual components work together
    const pattern = try solution_generator.SolutionGenerator.detectPattern(concept);
    std.debug.assert(pattern == .sequential_processing);

    const solution_result = try solution_generator.SolutionGenerator.generateSolution(pattern, concept, year, day, part);
    defer solution_result.deinit(gpa);
    std.debug.assert(solution_result.success);

    const analysis = try enhanced_learning.EnhancedLearningAgent.analyzeSolutionCode(solution_result.solution_code);
    defer analysis.deinit();
    std.debug.assert(analysis.taocp_concepts.items.len > 0);

    std.debug.print("✅ Full workflow integration test passed\n", .{});
}

// Helper function to parse workflow request (copied from aoc-cli.zig)
fn parseWorkflowRequest(input: []const u8) !workflow_types.WorkflowRequest {
    var parts = std.mem.splitSequence(u8, input, ";");
    const params_part = parts.next() orelse return error.InvalidFormat;
    const concept_part = parts.rest();

    var year: u32 = 0;
    var day: u32 = 0;
    var part: u32 = 0;

    var param_iter = std.mem.tokenizeScalar(u8, params_part, ',');
    while (param_iter.next()) |param| {
        var kv = std.mem.splitScalar(u8, param, '=');
        const key = kv.next() orelse continue;
        const value = kv.next() orelse continue;

        const trimmed_key = std.mem.trim(u8, key, " \t");
        const trimmed_value = std.mem.trim(u8, value, " \t");

        if (std.mem.eql(u8, trimmed_key, "year")) {
            year = try std.fmt.parseInt(u32, trimmed_value, 10);
        } else if (std.mem.eql(u8, trimmed_key, "day")) {
            day = try std.fmt.parseInt(u32, trimmed_value, 10);
        } else if (std.mem.eql(u8, trimmed_key, "part")) {
            part = try std.fmt.parseInt(u32, trimmed_value, 10);
        }
    }

    if (year == 0 or day == 0 or part == 0) {
        return error.InvalidFormat;
    }

    return workflow_types.WorkflowRequest{
        .year = year,
        .day = day,
        .part = part,
        .conceptual_solution = std.mem.trim(u8, concept_part, " \t\n\r"),
    };
}
