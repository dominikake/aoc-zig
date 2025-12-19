const std = @import("std");
const unified_agent = @import("unified-aoc-agent.zig");
const workflow_types = @import("workflow-types.zig");

pub fn main() !void {
    const gpa = std.heap.page_allocator;

    // Get command line arguments
    var args = std.process.args();
    _ = args.next() orelse return error.MissingExe;

    const year_str = args.next() orelse {
        std.debug.print("Usage: agent <year> <day> <conceptual_solution>\n", .{});
        return error.MissingArguments;
    };
    const day_str = args.next() orelse {
        std.debug.print("Usage: agent <year> <day> <conceptual_solution>\n", .{});
        return error.MissingArguments;
    };
    const conceptual_solution = args.next() orelse {
        std.debug.print("Usage: agent <year> <day> <conceptual_solution>\n", .{});
        return error.MissingArguments;
    };

    const year = try std.fmt.parseInt(u32, year_str, 10);
    const day = try std.fmt.parseInt(u32, day_str, 10);

    std.debug.print("Starting AoC Agent for Year {d}, Day {d}\n", .{ year, day });
    std.debug.print("Concept: {s}\n", .{conceptual_solution});

    // Execute full workflow (both parts)
    const result = try unified_agent.UnifiedAoCAgent.executeFullWorkflow(year, day, conceptual_solution);
    defer result.deinit(gpa);

    // Print results
    std.debug.print("\n=== WORKFLOW RESULTS ===\n", .{});
    std.debug.print("Success: {}\n", .{result.success});
    std.debug.print("Solution Generated: {}\n", .{result.solution_generated});
    std.debug.print("Tests Passed: {}\n", .{result.tests_passed});
    std.debug.print("Submission Successful: {}\n", .{result.submission_successful});
    std.debug.print("Learning Guide Updated: {}\n", .{result.learning_guide_updated});
    std.debug.print("Execution Time: {d}ms\n", .{result.execution_time});

    if (result.hasErrors()) {
        std.debug.print("\n=== ERRORS ===\n", .{});
        for (result.errors.items) |error_msg| {
            std.debug.print("Error: {s}\n", .{error_msg});
        }
    }

    std.debug.print("\n=== DEBUG STEPS ===\n", .{});
    for (result.debug_info.steps.items) |step| {
        std.debug.print("Step: {s}\n", .{step});
    }

    if (result.success) {
        std.debug.print("\n✅ Workflow completed successfully!\n", .{});
        std.process.exit(0);
    } else {
        std.debug.print("\n❌ Workflow failed!\n", .{});
        std.process.exit(1);
    }
}
