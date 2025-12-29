const std = @import("std");
const workflow_types = @import("workflow-types.zig");

/// WorkflowGuard ensures critical workflow steps are executed and not skipped
pub const WorkflowGuard = struct {
    const Self = @This();

    /// Tracks executed workflow steps to prevent skipping
    pub const StepTracker = struct {
        allocator: std.mem.Allocator,
        executed_steps: std.ArrayListUnmanaged(workflow_types.WorkflowStep),

        pub fn init(allocator: std.mem.Allocator) StepTracker {
            return StepTracker{
                .allocator = allocator,
                .executed_steps = .{},
            };
        }

        pub fn deinit(self: *StepTracker) void {
            self.executed_steps.deinit(self.allocator);
        }

        /// Record a step as executed
        pub fn recordStep(self: *StepTracker, step: workflow_types.WorkflowStep) !void {
            // Check for duplicates (steps should not be executed twice)
            for (self.executed_steps.items) |executed| {
                if (executed == step) {
                    return error.StepAlreadyExecuted;
                }
            }
            try self.executed_steps.append(self.allocator, step);
        }

        /// Check if a step can be executed (all prerequisites met)
        pub fn canExecuteStep(self: *const StepTracker, step: workflow_types.WorkflowStep) bool {
            return switch (step) {
                .not_started => true, // Always can start
                .directories_setup => true, // Can always setup directories
                .input_fetched => self.hasExecuted(.directories_setup),
                .solution_generated => self.hasExecuted(.input_fetched),
                .tests_run => self.hasExecuted(.solution_generated),
                .answer_submitted => self.hasExecuted(.tests_run),
                .learning_guide_updated => self.hasExecuted(.answer_submitted),
                .completed => self.hasExecuted(.learning_guide_updated),
            };
        }

        /// Check if a step has been executed
        pub fn hasExecuted(self: *const StepTracker, step: workflow_types.WorkflowStep) bool {
            for (self.executed_steps.items) |executed| {
                if (executed == step) return true;
            }
            return false;
        }

        /// Validate workflow completion
        pub fn validateWorkflowComplete(self: *const StepTracker) bool {
            const required_steps = [_]workflow_types.WorkflowStep{
                .directories_setup,
                .input_fetched,
                .solution_generated,
                .tests_run,
                .answer_submitted,
                .learning_guide_updated,
                .completed,
            };

            for (required_steps) |step| {
                if (!self.hasExecuted(step)) return false;
            }
            return true;
        }
    };

    /// Guard execution of a workflow step
    pub fn guardStep(
        tracker: *StepTracker,
        step: workflow_types.WorkflowStep,
    ) !void {
        if (!tracker.canExecuteStep(step)) {
            return error.WorkflowStepSkipped;
        }

        try tracker.recordStep(step);
    }

    /// Validate workflow completion and provide feedback
    pub fn validateCompletion(tracker: *const StepTracker) !bool {
        const is_complete = tracker.validateWorkflowComplete();
        if (!is_complete) {
            // Provide feedback on missing steps
            var missing_steps = std.ArrayListUnmanaged([]const u8){};
            defer missing_steps.deinit(tracker.allocator);

            const all_steps = [_]workflow_types.WorkflowStep{
                .directories_setup,
                .input_fetched,
                .solution_generated,
                .tests_run,
                .answer_submitted,
                .learning_guide_updated,
                .completed,
            };

            for (all_steps) |step| {
                if (!tracker.hasExecuted(step)) {
                    const step_name = switch (step) {
                        .not_started => "initialization",
                        .directories_setup => "directory setup",
                        .input_fetched => "input fetching",
                        .solution_generated => "solution generation",
                        .tests_run => "test execution",
                        .answer_submitted => "answer submission",
                        .learning_guide_updated => "learning guide update",
                        .completed => "workflow completion",
                    };
                    try missing_steps.append(tracker.allocator, step_name);
                }
            }

            const missing_str = try std.mem.join(tracker.allocator, ", ", missing_steps.items);
            defer tracker.allocator.free(missing_str);

            std.debug.print("Workflow incomplete. Missing steps: {s}\n", .{missing_str});
        }
        return is_complete;
    }
};
