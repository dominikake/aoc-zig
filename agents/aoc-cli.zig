const std = @import("std");
const workflow_types = @import("workflow-types.zig");
const unified_agent = @import("unified-aoc-agent.zig");

// Future imports (currently unused but available for extensions)
const solution_generator = @import("solution-generator.zig");
const enhanced_learning = @import("enhanced-learning-agent.zig");
const error_handler = @import("error-handler.zig");

pub fn main() !void {
    const gpa = std.heap.page_allocator;
    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    // Suppress unused import warnings for future extensions
    _ = solution_generator;
    _ = enhanced_learning;
    _ = error_handler;

    if (args.len < 2) {
        try printUsage();
        return;
    }

    // Parse single command format: "year=2025, day=1, part=1; provide my conceptual solution"
    const input = args[1];
    const request = try parseWorkflowRequest(input);

    std.debug.print("=== Unified AoC Agent ===\n", .{});
    std.debug.print("Year: {d}, Day: {d}, Part: {d}\n", .{ request.year, request.day, request.part });
    std.debug.print("Concept: {s}\n", .{request.conceptual_solution});

    // Execute unified workflow
    var result = try unified_agent.UnifiedAoCAgent.executeWorkflow(request.year, request.day, request.part, request.conceptual_solution);
    defer result.deinit(gpa);

    // Report results with detailed feedback
    try printWorkflowResult(result);
}

// Print usage information
fn printUsage() !void {
    const usage =
        \\Unified AoC Agent - Complete workflow automation
        \\
        \\Usage:
        \\  aoc-agent "year=2025, day=1, part=1; Use circular arithmetic to track dial position"
        \\
        \\Examples:
        \\  aoc-agent "year=2025, day=1, part=1; Process sequential instructions with state tracking"
        \\  aoc-agent "year=2025, day=2, part=1; Parse 2D grid and find shortest path"
        \\  aoc-agent "year=2025, day=3, part=2; Calculate using modular arithmetic"
        \\
    ;
    std.debug.print("{s}", .{usage});
}

// Parse workflow request from input string
fn parseWorkflowRequest(input: []const u8) !workflow_types.WorkflowRequest {
    var parts = std.mem.splitSequence(u8, input, ";");
    const params_part = parts.next() orelse return error.InvalidFormat;
    const concept_part = parts.rest();

    // Parse parameters: "year=2025, day=1, part=1"
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

// Print workflow results with detailed feedback
fn printWorkflowResult(result: workflow_types.WorkflowResult) !void {
    std.debug.print("\n=== Workflow Results ===\n", .{});

    // Overall status
    const status = if (result.success) "✅ SUCCESS" else "❌ FAILED";
    std.debug.print("Overall Status: {s}\n", .{status});
    std.debug.print("Execution Time: {d}ms\n\n", .{result.execution_time});

    // Step-by-step results
    std.debug.print("Step Results:\n", .{});
    std.debug.print("  Solution Generated: {s}\n", .{if (result.solution_generated) "✅" else "❌"});
    std.debug.print("  Tests Passed: {s}\n", .{if (result.tests_passed) "✅" else "❌"});
    std.debug.print("  Submission Successful: {s}\n", .{if (result.submission_successful) "✅" else "❌"});
    std.debug.print("  Learning Guide Updated: {s}\n\n", .{if (result.learning_guide_updated) "✅" else "❌"});

    // Debug information
    if (workflow_types.AgentConfig.DEBUG_MODE and result.debug_info.steps.items.len > 0) {
        std.debug.print("Debug Steps:\n", .{});
        for (result.debug_info.steps.items) |step| {
            std.debug.print("  • {s}\n", .{step});
        }
        std.debug.print("\n", .{});
    }

    // Performance metrics
    if (result.debug_info.performance_metrics.items.len > 0) {
        std.debug.print("Performance Metrics:\n", .{});
        for (result.debug_info.performance_metrics.items) |metric| {
            std.debug.print("  • {s}\n", .{metric});
        }
        std.debug.print("\n", .{});
    }

    // Errors
    if (result.hasErrors()) {
        std.debug.print("Errors Encountered:\n", .{});
        for (result.errors.items) |error_msg| {
            std.debug.print("  ❌ {s}\n", .{error_msg});
        }
        std.debug.print("\n", .{});
    }

    // Intermediate results
    if (result.debug_info.intermediate_results.items.len > 0) {
        std.debug.print("Intermediate Results:\n", .{});
        for (result.debug_info.intermediate_results.items) |result_item| {
            std.debug.print("  • {s}\n", .{result_item});
        }
        std.debug.print("\n", .{});
    }

    // Next steps guidance
    try printNextSteps(result);
}

// Print next steps based on results
fn printNextSteps(result: workflow_types.WorkflowResult) !void {
    std.debug.print("Next Steps:\n", .{});

    if (result.success) {
        std.debug.print(
            \\  🎉 Workflow completed successfully!
            \\  📚 Check the generated learning guide for educational insights
            \\  🧪 Review the solution code for understanding
            \\  📝 Consider optimizing further for performance
            \\
        , .{});
    } else {
        if (!result.solution_generated) {
            std.debug.print(
                \\  🔧 Check conceptual solution description
                \\  📝 Try alternative phrasing for pattern detection
                \\  🤖 Consider manual solution implementation
                \\
            , .{});
        }

        if (!result.tests_passed) {
            std.debug.print(
                \\  🐛 Review debug output for test failures
                \\  🔍 Check edge cases and input validation
                \\  📊 Analyze intermediate results
                \\
            , .{});
        }

        if (!result.submission_successful) {
            std.debug.print(
                \\  ❌ Review submission response for hints
                \\  🧪 Test with additional sample inputs
                \\  📖 Re-read problem statement carefully
                \\
            , .{});
        }

        std.debug.print(
            \\  🔄 Try running with debug mode for more details
            \\  📞 Consider manual intervention if automated fixes fail
            \\
        , .{});
    }
}
