const std = @import("std");
const workflow_types = @import("workflow-types.zig");
const workflow_guard = @import("workflow-guard.zig");

pub const UnifiedAoCAgent = struct {
    const Self = @This();
    const gpa = std.heap.page_allocator;

    // Generic retry helper with exponential backoff
    fn executeWithRetry(
        allocator: std.mem.Allocator,
        result: *workflow_types.WorkflowResult,
        operation_name: []const u8,
        comptime func: anytype,
        args: anytype,
    ) !void {
        const MAX_RETRIES = 3;
        var retry_count: u32 = 0;

        while (retry_count < MAX_RETRIES) {
            func(args) catch |err| {
                retry_count += 1;

                if (retry_count >= MAX_RETRIES) {
                    const error_msg = try std.fmt.allocPrint(allocator, "{s} failed after {d} retries: {}", .{ operation_name, MAX_RETRIES, err });
                    try result.addError(allocator, error_msg);
                    return err;
                }

                // Log retry attempt
                const retry_msg = try std.fmt.allocPrint(allocator, "{s} failed (attempt {d}/{d}), retrying...", .{ operation_name, retry_count, MAX_RETRIES });
                try result.debug_info.addStep(allocator, retry_msg);

                // Exponential backoff (simplified without sleep for now)
                const delay_ms = std.time.ms_per_s * @as(u64, 1) << @intCast(retry_count - 1);
                const delay_metric = try std.fmt.allocPrint(allocator, "Retry delay: {d}ms", .{delay_ms});
                try result.debug_info.addMetric(allocator, delay_metric);

                // TODO: Add sleep back when API is available
                // For now, just continue without delay (not ideal but functional)
                continue;
            };

            // Success
            const success_msg = try std.fmt.allocPrint(allocator, "{s} succeeded", .{operation_name});
            try result.debug_info.addStep(allocator, success_msg);
            break;
        }
    }

    // Enhanced error handling with AgentError types and recovery strategies
    fn handleError(
        allocator: std.mem.Allocator,
        result: *workflow_types.WorkflowResult,
        agent_error: workflow_types.AgentError,
    ) !void {
        const error_context = try std.fmt.allocPrint(allocator, "Agent Error: {}", .{agent_error});
        try result.debug_info.addResult(allocator, error_context);

        // Add recovery suggestions based on error type
        const recovery_suggestion = switch (agent_error) {
            workflow_types.AgentError.NetworkError => "Check internet connection and AoC session cookie",
            workflow_types.AgentError.FileSystemError => "Check file permissions and disk space",
            workflow_types.AgentError.CompilationFailed => "Review generated solution code for syntax errors",
            workflow_types.AgentError.TestFailed => "Analyze test output and debug intermediate results",
            workflow_types.AgentError.SubmissionFailed => "Check AoC session validity and rate limiting",
            workflow_types.AgentError.LearningGuideUpdateFailed => "Verify learning guide system is properly built",
            else => "Review detailed error output and consider manual intervention",
        };

        const suggestion_msg = try std.fmt.allocPrint(allocator, "Recovery suggestion: {s}", .{recovery_suggestion});
        try result.debug_info.addResult(allocator, suggestion_msg);
    }

    // Checkpoint management for workflow state
    fn saveCheckpoint(
        year: u32,
        day: u32,
        part: u32,
        step: workflow_types.WorkflowStep,
    ) !void {
        const state = workflow_types.WorkflowState{
            .year = year,
            .day = day,
            .current_part = part,
            .step = step,
            .timestamp = std.time.milliTimestamp(),
        };

        const state_data = try state.save(gpa);
        defer gpa.free(state_data);

        // Save to checkpoint file
        const checkpoint_file = try std.fmt.allocPrint(gpa, ".cache/aoc-agent/checkpoint_{d}_{d}.json", .{ year, day });
        defer gpa.free(checkpoint_file);

        // Create cache directory if needed
        std.fs.cwd().makePath(".cache/aoc-agent") catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        };

        const file = try std.fs.cwd().createFile(checkpoint_file, .{});
        defer file.close();

        try file.writeAll(state_data);
    }

    fn loadCheckpoint(
        year: u32,
        day: u32,
    ) ?workflow_types.WorkflowState {
        const checkpoint_file = try std.fmt.allocPrint(gpa, ".cache/aoc-agent/checkpoint_{d}_{d}.json", .{ year, day });
        defer gpa.free(checkpoint_file);

        if (std.fs.cwd().openFile(checkpoint_file, .{})) |file| {
            defer file.close();
            const data = try file.readToEndAlloc(gpa, 1024);
            defer gpa.free(data);

            return workflow_types.WorkflowState.load(data) catch null;
        } else |_| {
            return null;
        }
    }

    fn clearCheckpoint(
        year: u32,
        day: u32,
    ) !void {
        const checkpoint_file = try std.fmt.allocPrint(gpa, ".cache/aoc-agent/checkpoint_{d}_{d}.json", .{ year, day });
        defer gpa.free(checkpoint_file);

        std.fs.cwd().deleteFile(checkpoint_file) catch {};
    }

    // Main workflow orchestrator
    pub fn executeWorkflow(year: u32, day: u32, part: u32, conceptual_solution: []const u8) !workflow_types.WorkflowResult {
        const start_time = std.time.milliTimestamp();

        var result = workflow_types.WorkflowResult.init(gpa);
        errdefer result.deinit(gpa);

        // Initialize workflow guard
        var step_tracker = workflow_guard.WorkflowGuard.StepTracker.init(gpa);
        defer step_tracker.deinit();

        try result.debug_info.addStep(gpa, "Starting unified AoC workflow");
        const metric_str = try std.fmt.allocPrint(gpa, "Year: {d}, Day: {d}, Part: {d}", .{ year, day, part });
        try result.debug_info.addMetric(gpa, metric_str);

        // Save initial checkpoint
        saveCheckpoint(year, day, 1, .not_started) catch {}; // Always use part 1 for full workflow

        // Step 1: Setup directories
        workflow_guard.WorkflowGuard.guardStep(&step_tracker, .directories_setup) catch {
            const error_msg = "Workflow guard: directory setup step cannot be executed - prerequisites not met";
            try result.addError(gpa, error_msg);
            return result;
        };
        try result.debug_info.addStep(gpa, "Setting up directories");
        setupDirectories(year, day) catch |err| {
            const error_msg = try std.fmt.allocPrint(gpa, "Directory setup failed: {}", .{err});
            try result.addError(gpa, error_msg);
            try handleError(gpa, &result, workflow_types.AgentError.FileSystemError);
            return result;
        };

        // Checkpoint after directory setup
        saveCheckpoint(year, day, 1, .directories_setup) catch {};

        // Step 2: Fetch input with retry logic
        workflow_guard.WorkflowGuard.guardStep(&step_tracker, .input_fetched) catch {
            const error_msg = "Workflow guard: input fetching step cannot be executed - prerequisites not met";
            try result.addError(gpa, error_msg);
            return result;
        };
        try result.debug_info.addStep(gpa, "Fetching input");
        fetchInput(year, day) catch |err| {
            const error_msg = try std.fmt.allocPrint(gpa, "Input fetch failed: {}", .{err});
            try result.addError(gpa, error_msg);
            try handleError(gpa, &result, workflow_types.AgentError.NetworkError);
            return result;
        };

        // Step 3: Generate solution
        workflow_guard.WorkflowGuard.guardStep(&step_tracker, .solution_generated) catch {
            const error_msg = "Workflow guard: solution generation step cannot be executed - prerequisites not met";
            try result.addError(gpa, error_msg);
            return result;
        };
        try result.debug_info.addStep(gpa, "Generating solution from concept");
        var solution_result = try generateSolution(conceptual_solution, year, day, part);
        defer solution_result.deinit(gpa);

        if (!solution_result.success) {
            try result.addError(gpa, "Solution generation failed");
            return result;
        }
        result.solution_generated = true;

        // Step 4: Write solution file
        try result.debug_info.addStep(gpa, "Writing solution file");
        writeSolutionFile(year, day, solution_result.solution_code) catch |err| {
            const error_msg = try std.fmt.allocPrint(gpa, "Failed to write solution file: {}", .{err});
            try result.addError(gpa, error_msg);
            return result;
        };

        // Step 5: Run tests with retry logic
        workflow_guard.WorkflowGuard.guardStep(&step_tracker, .tests_run) catch {
            const error_msg = "Workflow guard: test execution step cannot be executed - prerequisites not met";
            try result.addError(gpa, error_msg);
            return result;
        };
        try result.debug_info.addStep(gpa, "Running tests");
        var test_result = try runTests(year, day);
        defer test_result.deinit(gpa);

        if (!test_result.success) {
            try result.addError(gpa, "Tests failed");
            const output_copy = try gpa.dupe(u8, test_result.test_output);
            try result.debug_info.addResult(gpa, output_copy);
            return result;
        }
        result.tests_passed = true;
        // Checkpoint after tests
        saveCheckpoint(year, day, part, .tests_run) catch {};

        // Step 6: Submit answer with retry logic (if tests pass)
        workflow_guard.WorkflowGuard.guardStep(&step_tracker, .answer_submitted) catch {
            const error_msg = "Workflow guard: answer submission step cannot be executed - prerequisites not met";
            try result.addError(gpa, error_msg);
            return result;
        };
        try result.debug_info.addStep(gpa, "Submitting answer");
        var submission_result = try submitAnswer(year, day, part);
        defer submission_result.deinit(gpa);

        // Handle rate limiting
        if (submission_result.rate_limited) {
            const retry_delay = workflow_types.AgentConfig.SUBMISSION_DELAY_MS;
            const delay_msg = try std.fmt.allocPrint(gpa, "Rate limited, waiting {d}ms before retry", .{retry_delay});
            try result.debug_info.addStep(gpa, delay_msg);
            // TODO: Add delay when sleep API is available

            // Retry submission once
            submission_result = try submitAnswer(year, day, part);
        }

        if (!submission_result.success) {
            try result.addError(gpa, "Submission failed");
            const response_copy = try gpa.dupe(u8, submission_result.response);
            try result.debug_info.addResult(gpa, response_copy);
            return result;
        }

        // Check if answer was correct
        if (!submission_result.correct and !submission_result.cached) {
            // Answer was incorrect - provide context and exit gracefully
            const context_msg = try std.fmt.allocPrint(gpa,
                \\Submission incorrect. Implementation yielded answer but AoC rejected it.
                \\Check test inputs, double-check logic, or revisit implementation.
                \\Response: {s}
            , .{submission_result.response});
            try result.debug_info.addResult(gpa, context_msg);
            try result.addError(gpa, "Answer rejected by AoC - implementation needs review");
            return result;
        }
        result.submission_successful = true;
        // Checkpoint after submission
        saveCheckpoint(year, day, part, .answer_submitted) catch {};

        // Step 7: Update learning guide (if submission successful)
        workflow_guard.WorkflowGuard.guardStep(&step_tracker, .learning_guide_updated) catch {
            const error_msg = "Workflow guard: learning guide update step cannot be executed - prerequisites not met";
            try result.addError(gpa, error_msg);
            return result;
        };
        try result.debug_info.addStep(gpa, "Updating learning guide");
        if (updateLearningGuide(year, day)) {
            result.learning_guide_updated = true;
        } else |err| {
            const error_msg = try std.fmt.allocPrint(gpa, "Learning guide update failed: {}", .{err});
            try result.addError(gpa, error_msg);
            // Don't fail the entire workflow for learning guide issues
        }

        // Checkpoint after learning guide update
        saveCheckpoint(year, day, 1, .learning_guide_updated) catch {};

        // Commit logic moved to executeFullWorkflow to avoid duplication

        // Calculate execution time
        const end_time = std.time.milliTimestamp();
        result.execution_time = @intCast(end_time - start_time);
        const time_metric = try std.fmt.allocPrint(gpa, "Total execution time: {d}ms", .{result.execution_time});
        try result.debug_info.addMetric(gpa, time_metric);

        // Record workflow completion
        workflow_guard.WorkflowGuard.guardStep(&step_tracker, .completed) catch {
            const error_msg = "Workflow guard: completion step cannot be executed - prerequisites not met";
            try result.addError(gpa, error_msg);
            return result;
        };

        // Validate workflow completion
        if (!try workflow_guard.WorkflowGuard.validateCompletion(&step_tracker)) {
            try result.addError(gpa, "Workflow validation failed - some steps may have been skipped");
        }

        result.success = true;
        try result.debug_info.addStep(gpa, "Workflow completed successfully");

        return result;
    }

    // Setup directories for year/day
    fn setupDirectories(year: u32, day: u32) !void {
        _ = day; // Currently unused, but may be needed for day-specific setup
        // Create year directory
        const year_dir = try std.fmt.allocPrint(gpa, "{d}", .{year});
        defer gpa.free(year_dir);

        std.fs.cwd().makePath(year_dir) catch |err| switch (err) {
            error.PathAlreadyExists => {}, // OK
            else => return err,
        };

        // Create input directory
        const input_dir = try std.fmt.allocPrint(gpa, "input/{d}", .{year});
        defer gpa.free(input_dir);

        std.fs.cwd().makePath(input_dir) catch |err| switch (err) {
            error.PathAlreadyExists => {}, // OK
            else => return err,
        };

        // Create cache directory
        std.fs.cwd().makePath(workflow_types.AgentConfig.CACHE_DIR) catch |err| switch (err) {
            error.PathAlreadyExists => {}, // OK
            else => return err,
        };
    }

    // Fetch input using existing fetch.sh logic
    fn fetchInput(year: u32, day: u32) !void {
        const day_str = try std.fmt.allocPrint(gpa, "{d:0>2}", .{day});
        defer gpa.free(day_str);

        const input_file = try std.fmt.allocPrint(gpa, "input/{d}/day{s}.txt", .{ year, day_str });
        defer gpa.free(input_file);

        // Check if input already exists
        if (std.fs.cwd().openFile(input_file, .{})) |file| {
            file.close();
            return; // Already exists
        } else |_| {}

        // Use existing fetch.sh script
        const year_str = try std.fmt.allocPrint(gpa, "{d}", .{year});
        defer gpa.free(year_str);
        const fetch_day_str = try std.fmt.allocPrint(gpa, "{d}", .{day});
        defer gpa.free(fetch_day_str);

        const fetch_args = [_][]const u8{ "./fetch.sh", year_str, fetch_day_str };

        const result = try std.process.Child.run(.{
            .allocator = gpa,
            .argv = &fetch_args,
        });
        defer gpa.free(result.stdout);
        defer gpa.free(result.stderr);

        if (result.term.Exited != 0) {
            return error.FetchFailed;
        }
    }

    // Generate solution from conceptual description using pattern detection
    fn generateSolution(conceptual_solution: []const u8, year: u32, day: u32, part: u32) !workflow_types.SolutionResult {
        const solution_generator = @import("solution-generator.zig");

        // Detect pattern from conceptual solution
        const pattern = try solution_generator.SolutionGenerator.detectPattern(conceptual_solution);

        // Generate solution based on detected pattern
        var solution_result = try solution_generator.SolutionGenerator.generateSolution(pattern, conceptual_solution, year, day, part);

        // Post-process solution to add part-specific logic
        const processed_code = try postProcessSolution(solution_result.solution_code, year, day, part);
        gpa.free(solution_result.solution_code);
        solution_result.solution_code = processed_code;

        return solution_result;
    }

    // Post-process generated solution for specific part
    fn postProcessSolution(solution_code: []const u8, year: u32, day: u32, part: u32) ![]const u8 {
        // Add part-specific header comment
        const header = try std.fmt.allocPrint(gpa,
            \\// AoC {d} Day {d} Part {d}
            \\// Generated by unified AoC agent
            \\
        , .{ year, day, part });
        defer gpa.free(header);

        const full_code = try std.fmt.allocPrint(gpa, "{s}{s}", .{ header, solution_code });
        return full_code;
    }

    // Write solution to file
    fn writeSolutionFile(year: u32, day: u32, solution_code: []const u8) !void {
        const day_str = try std.fmt.allocPrint(gpa, "{d:0>2}", .{day});
        defer gpa.free(day_str);

        const solution_file = try std.fmt.allocPrint(gpa, "{d}/day_{s}.zig", .{ year, day_str });
        defer gpa.free(solution_file);

        const file = try std.fs.cwd().createFile(solution_file, .{});
        defer file.close();

        try file.writeAll(solution_code);
    }

    // Run tests using build system with detailed result parsing
    fn runTests(year: u32, day: u32) !workflow_types.TestResult {
        const day_str = try std.fmt.allocPrint(gpa, "{d:0>2}", .{day});
        defer gpa.free(day_str);

        const start_time = std.time.milliTimestamp();

        // Use build system to run solution
        const year_opt = try std.fmt.allocPrint(gpa, "-Dyear={d}", .{year});
        defer gpa.free(year_opt);
        const day_opt = try std.fmt.allocPrint(gpa, "-Dday={s}", .{day_str});
        defer gpa.free(day_opt);
        const build_args = [_][]const u8{ "zig", "build", "solve", year_opt, day_opt, "-Dpart=both" };

        const result = try std.process.Child.run(.{
            .allocator = gpa,
            .argv = &build_args,
        });
        defer gpa.free(result.stdout);
        defer gpa.free(result.stderr);

        const end_time = std.time.milliTimestamp();
        const performance_ms: u64 = @intCast(end_time - start_time);

        // Parse test output for success indicators
        const test_output = try std.fmt.allocPrint(gpa, "STDOUT: {s}\nSTDERR: {s}", .{ result.stdout, result.stderr });

        // Check for errors, panics, or compilation failures
        const has_errors = std.mem.indexOf(u8, result.stdout, "Error:") != null or
            std.mem.indexOf(u8, result.stdout, "panic:") != null or
            std.mem.indexOf(u8, result.stderr, "Error:") != null or
            std.mem.indexOf(u8, result.stderr, "panic:") != null;

        // Extract performance information if available
        var sample_tests_passed: u32 = 0;
        var sample_tests_total: u32 = 0;

        // Look for test result patterns in output
        if (std.mem.indexOf(u8, result.stdout, "Sample tests:") != null) {
            // Parse sample test results
            if (std.mem.indexOf(u8, result.stdout, "passed")) |pos| {
                // Simple pattern matching for "X/Y passed"
                const before = result.stdout[0..pos];
                if (std.mem.lastIndexOf(u8, before, " ")) |num_start| {
                    const passed_str = before[num_start + 1 .. pos];
                    sample_tests_passed = try std.fmt.parseInt(u32, passed_str, 10);
                }

                const after = result.stdout[pos..];
                if (std.mem.indexOf(u8, after, "/")) |slash_pos| {
                    const total_start = slash_pos + 1;
                    const total_end = std.mem.indexOf(u8, after[total_start..], " ") orelse after.len;
                    const total_str = after[total_start .. total_start + total_end];
                    sample_tests_total = try std.fmt.parseInt(u32, total_str, 10);
                }
            }
        }

        return workflow_types.TestResult{
            .success = result.term.Exited == 0 and !has_errors,
            .sample_tests_passed = sample_tests_passed,
            .sample_tests_total = sample_tests_total,
            .custom_tests_passed = 0, // TODO: Parse custom tests when implemented
            .custom_tests_total = 0, // TODO: Parse custom tests when implemented
            .performance_ms = performance_ms,
            .test_output = test_output,
        };
    }

    // Validate AoC session cookie exists
    fn validateSession() !void {
        const home_dir = std.process.getEnvVarOwned(gpa, "HOME") catch return error.NoHomeDir;
        defer gpa.free(home_dir);
        const cookie_path = try std.fmt.allocPrint(gpa, "{s}/.config/aoc/session.cookie", .{home_dir});
        defer gpa.free(cookie_path);

        std.fs.cwd().access(cookie_path, .{}) catch {
            return error.SessionCookieNotFound;
        };
    }

    // Submit answer using existing submit.sh logic
    fn submitAnswer(year: u32, day: u32, part: u32) !workflow_types.SubmissionResult {
        // Validate session before attempting submission
        validateSession() catch {
            return workflow_types.SubmissionResult{
                .success = false,
                .response = "Session validation failed - check ~/.config/aoc/session.cookie",
                .cached = false,
                .rate_limited = false,
                .correct = false,
            };
        };

        // First, get the answer by running the solution
        const day_str = try std.fmt.allocPrint(gpa, "{d:0>2}", .{day});
        defer gpa.free(day_str);

        const year_opt = try std.fmt.allocPrint(gpa, "-Dyear={d}", .{year});
        defer gpa.free(year_opt);
        const day_opt = try std.fmt.allocPrint(gpa, "-Dday={s}", .{day_str});
        defer gpa.free(day_opt);
        const part_opt = try std.fmt.allocPrint(gpa, "-Dpart={d}", .{part});
        defer gpa.free(part_opt);
        const build_args = [_][]const u8{ "zig", "build", "solve", year_opt, day_opt, part_opt };

        const result = try std.process.Child.run(.{
            .allocator = gpa,
            .argv = &build_args,
        });
        defer gpa.free(result.stdout);
        defer gpa.free(result.stderr);

        if (result.term.Exited != 0) {
            return error.SolutionExecutionFailed;
        }

        // Extract answer from output (look for last non-empty line that looks like an answer)
        var lines = std.mem.tokenizeScalar(u8, result.stdout, '\n');
        var answer: []const u8 = "";
        while (lines.next()) |line| {
            // Skip empty lines and debug output
            if (line.len > 0) {
                // Check if line looks like a valid answer (not an error or debug message)
                const is_debug_line = std.mem.indexOf(u8, line, "Debug:") != null or
                    std.mem.indexOf(u8, line, "INFO:") != null or
                    std.mem.indexOf(u8, line, "Error:") != null or
                    std.mem.indexOf(u8, line, "panic:") != null;

                if (!is_debug_line) {
                    answer = line;
                }
            }
        }

        // Submit using existing submit.sh
        const submit_year_str = try std.fmt.allocPrint(gpa, "{d}", .{year});
        defer gpa.free(submit_year_str);
        const submit_day_str = try std.fmt.allocPrint(gpa, "{d}", .{day});
        defer gpa.free(submit_day_str);
        const submit_part_str = try std.fmt.allocPrint(gpa, "{d}", .{part});
        defer gpa.free(submit_part_str);

        const submit_args = [_][]const u8{ "./submit.sh", submit_year_str, submit_day_str, submit_part_str, answer, "--force" };

        const submit_result = try std.process.Child.run(.{
            .allocator = gpa,
            .argv = &submit_args,
        });
        defer gpa.free(submit_result.stdout);
        defer gpa.free(submit_result.stderr);

        const response = try std.fmt.allocPrint(gpa, "{s}", .{submit_result.stdout});

        return workflow_types.SubmissionResult{
            .success = submit_result.term.Exited == 0,
            .response = response,
            .cached = std.mem.indexOf(u8, response, "already been completed") != null,
            .rate_limited = std.mem.indexOf(u8, response, "too recently") != null,
            .correct = std.mem.indexOf(u8, response, "right answer") != null,
        };
    }

    // Update learning guide using existing system
    fn updateLearningGuide(year: u32, day: u32) !void {
        const day_str = try std.fmt.allocPrint(gpa, "{d:0>2}", .{day});
        defer gpa.free(day_str);

        const solution_file = try std.fmt.allocPrint(gpa, "{d}/day_{s}.zig", .{ year, day_str });
        defer gpa.free(solution_file);

        // Use existing update-learning-guide.sh
        const update_year_str = try std.fmt.allocPrint(gpa, "{d}", .{year});
        defer gpa.free(update_year_str);
        const update_day_str = try std.fmt.allocPrint(gpa, "{d}", .{day});
        defer gpa.free(update_day_str);

        const update_args = [_][]const u8{ "./update-learning-guide.sh", update_year_str, update_day_str, solution_file };

        const result = try std.process.Child.run(.{
            .allocator = gpa,
            .argv = &update_args,
        });
        defer gpa.free(result.stdout);
        defer gpa.free(result.stderr);

        if (result.term.Exited != 0) {
            return error.LearningGuideUpdateFailed;
        }
    }

    // Check if Part 2 is available after successful Part 1 submission
    fn isPart2Available(year: u32, day: u32) !bool {
        // Re-fetch puzzle description to check for Part 2
        const year_str = try std.fmt.allocPrint(gpa, "{d}", .{year});
        defer gpa.free(year_str);
        const day_str = try std.fmt.allocPrint(gpa, "{d}", .{day});
        defer gpa.free(day_str);

        const fetch_args = [_][]const u8{ "./fetch.sh", year_str, day_str, "--puzzle" };

        const result = try std.process.Child.run(.{
            .allocator = gpa,
            .argv = &fetch_args,
        });
        defer gpa.free(result.stdout);
        defer gpa.free(result.stderr);

        // Check if output contains Part 2 indicator
        return result.term.Exited == 0 and
            (std.mem.indexOf(u8, result.stdout, "Part 2") != null or
                std.mem.indexOf(u8, result.stdout, "--- Part Two ---") != null);
    }

    // Commit changes to Git after successful completion
    fn commitChanges(year: u32, day: u32) !void {
        const commit_msg = try std.fmt.allocPrint(gpa, "feat: solve aoc {d} day{d:0>2}", .{ year, day });
        defer gpa.free(commit_msg);

        // Git add all changes
        const git_add_args = [_][]const u8{ "git", "add", "." };
        const add_result = try std.process.Child.run(.{
            .allocator = gpa,
            .argv = &git_add_args,
        });
        defer gpa.free(add_result.stdout);
        defer gpa.free(add_result.stderr);

        if (add_result.term.Exited != 0) {
            return error.GitAddFailed;
        }

        // Git commit
        const git_commit_args = [_][]const u8{ "git", "commit", "-m", commit_msg };
        const commit_result = try std.process.Child.run(.{
            .allocator = gpa,
            .argv = &git_commit_args,
        });
        defer gpa.free(commit_result.stdout);
        defer gpa.free(commit_result.stderr);

        if (commit_result.term.Exited != 0) {
            return error.GitCommitFailed;
        }

        // Optional: Git push (commented out to avoid authentication issues)
        // const git_push_args = [_][]const u8{ "git", "push" };
        // const push_result = try std.process.Child.run(.{
        //     .allocator = gpa,
        //     .argv = &git_push_args,
        // });
        // defer gpa.free(push_result.stdout);
        // defer gpa.free(push_result.stderr);
        //
        // if (push_result.term.Exited != 0) {
        //     return error.GitPushFailed;
        // }
    }

    // Enhanced executeWorkflow to handle Part 2 progression
    pub fn executeFullWorkflow(year: u32, day: u32, conceptual_solution: []const u8) !workflow_types.WorkflowResult {
        const start_time = std.time.milliTimestamp();

        var final_result = workflow_types.WorkflowResult.init(gpa);
        errdefer final_result.deinit(gpa);

        try final_result.debug_info.addStep(gpa, "Starting full AoC workflow (both parts)");
        const metric_str = try std.fmt.allocPrint(gpa, "Year: {d}, Day: {d}", .{ year, day });
        try final_result.debug_info.addMetric(gpa, metric_str);

        // Execute Part 1
        try final_result.debug_info.addStep(gpa, "=== EXECUTING PART 1 ===");
        const part1_result = try executeWorkflow(year, day, 1, conceptual_solution);
        defer {
            const mut_part1_result = @constCast(&part1_result);
            mut_part1_result.deinit(gpa);
        }

        if (!part1_result.success) {
            try final_result.addError(gpa, "Part 1 workflow failed");
            return final_result;
        }

        final_result.solution_generated = true;
        final_result.tests_passed = part1_result.tests_passed;
        final_result.submission_successful = part1_result.submission_successful;
        final_result.learning_guide_updated = part1_result.learning_guide_updated;

        // Check if Part 1 submission was correct before proceeding
        if (!part1_result.submission_successful) {
            try final_result.addError(gpa, "Part 1 submission failed, not proceeding to Part 2");
            return final_result;
        }

        // Wait a moment before Part 2 to avoid rate limiting
        try final_result.debug_info.addStep(gpa, "Waiting before Part 2 to avoid rate limiting");
        // TODO: Add delay when sleep API is available

        // Check if Part 2 is available before proceeding
        try final_result.debug_info.addStep(gpa, "Checking Part 2 availability");
        if (!try isPart2Available(year, day)) {
            try final_result.addError(gpa, "Part 2 is not available yet");
            final_result.success = true; // Partial success - Part 1 completed
            return final_result;
        }

        // Execute Part 2
        try final_result.debug_info.addStep(gpa, "=== EXECUTING PART 2 ===");
        const part2_result = try executeWorkflow(year, day, 2, conceptual_solution);
        defer {
            const mut_part2_result = @constCast(&part2_result);
            mut_part2_result.deinit(gpa);
        }

        if (!part2_result.success) {
            try final_result.addError(gpa, "Part 2 workflow failed");
            // Don't fail entirely if Part 2 fails, Part 1 was successful
            final_result.success = true; // Partial success
            return final_result;
        }

        // Update final result with Part 2 success
        final_result.tests_passed = final_result.tests_passed and part2_result.tests_passed;
        final_result.submission_successful = final_result.submission_successful and part2_result.submission_successful;
        final_result.learning_guide_updated = final_result.learning_guide_updated and part2_result.learning_guide_updated;

        // Commit changes if both parts successful
        if (final_result.submission_successful) {
            try final_result.debug_info.addStep(gpa, "Committing changes to Git");
            commitChanges(year, day) catch |err| {
                const error_msg = try std.fmt.allocPrint(gpa, "Git commit failed: {}", .{err});
                try final_result.addError(gpa, error_msg);
                // Don't fail the workflow for git issues
            };
            // Checkpoint after commit
            saveCheckpoint(year, day, 1, .completed) catch {};
        }

        // Calculate execution time
        const end_time = std.time.milliTimestamp();
        final_result.execution_time = @intCast(end_time - start_time);
        const time_metric = try std.fmt.allocPrint(gpa, "Total execution time: {d}ms", .{final_result.execution_time});
        try final_result.debug_info.addMetric(gpa, time_metric);

        final_result.success = true;
        try final_result.debug_info.addStep(gpa, "Full workflow completed successfully");

        return final_result;
    }
};
