const std = @import("std");
const workflow_types = @import("workflow-types.zig");

pub const UnifiedAoCAgent = struct {
    const Self = @This();
    const gpa = std.heap.page_allocator;

    // Main workflow orchestrator
    pub fn executeWorkflow(year: u32, day: u32, part: u32, conceptual_solution: []const u8) !workflow_types.WorkflowResult {
        const start_time = std.time.milliTimestamp();

        var result = workflow_types.WorkflowResult.init(gpa);
        errdefer result.deinit(gpa);

        try result.debug_info.addStep(gpa, "Starting unified AoC workflow");
        const metric_str = try std.fmt.allocPrint(gpa, "Year: {d}, Day: {d}, Part: {d}", .{ year, day, part });
        try result.debug_info.addMetric(gpa, metric_str);

        // Step 1: Setup directories
        try result.debug_info.addStep(gpa, "Setting up directories");
        setupDirectories(year, day) catch |err| {
            const error_msg = try std.fmt.allocPrint(gpa, "Directory setup failed: {}", .{err});
            try result.addError(gpa, error_msg);
            return result;
        };

        // Step 2: Fetch input
        try result.debug_info.addStep(gpa, "Fetching input");
        fetchInput(year, day) catch |err| {
            const error_msg = try std.fmt.allocPrint(gpa, "Input fetch failed: {}", .{err});
            try result.addError(gpa, error_msg);
            return result;
        };

        // Step 3: Generate solution
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

        // Step 5: Run tests
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

        // Step 6: Submit answer (if tests pass)
        try result.debug_info.addStep(gpa, "Submitting answer");
        var submission_result = try submitAnswer(year, day, part);
        defer submission_result.deinit(gpa);

        if (!submission_result.success) {
            try result.addError(gpa, "Submission failed");
            const response_copy = try gpa.dupe(u8, submission_result.response);
            try result.debug_info.addResult(gpa, response_copy);
            return result;
        }
        result.submission_successful = true;

        // Step 7: Update learning guide (if submission successful)
        try result.debug_info.addStep(gpa, "Updating learning guide");
        if (updateLearningGuide(year, day)) {
            result.learning_guide_updated = true;
        } else |err| {
            const error_msg = try std.fmt.allocPrint(gpa, "Learning guide update failed: {}", .{err});
            try result.addError(gpa, error_msg);
            // Don't fail the entire workflow for learning guide issues
        }

        // Calculate execution time
        const end_time = std.time.milliTimestamp();
        result.execution_time = @intCast(end_time - start_time);
        const time_metric = try std.fmt.allocPrint(gpa, "Total execution time: {d}ms", .{result.execution_time});
        try result.debug_info.addMetric(gpa, time_metric);

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

    // Generate solution from conceptual description
    fn generateSolution(conceptual_solution: []const u8, year: u32, day: u32, part: u32) !workflow_types.SolutionResult {
        _ = year;
        _ = day;
        _ = part;

        // This will be implemented in solution-generator.zig
        // For now, return a basic template
        const solution_code = try std.fmt.allocPrint(gpa,
            \\const std = @import("std");
            \\
            \\pub fn part1(input: []const u8) !?[]const u8 {{
            \\    _ = input;
            \\    // TODO: Implement part 1 solution based on: {s}
            \\    return null;
            \\}}
            \\
            \\pub fn part2(input: []const u8) !?[]const u8 {{
            \\    _ = input;
            \\    // TODO: Implement part 2 solution
            \\    return null;
            \\}}
        , .{conceptual_solution});

        return workflow_types.SolutionResult{
            .success = true,
            .solution_code = solution_code,
            .compilation_output = "",
            .errors = &[_][]const u8{},
        };
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

    // Run tests using build system
    fn runTests(year: u32, day: u32) !workflow_types.TestResult {
        const day_str = try std.fmt.allocPrint(gpa, "{d:0>2}", .{day});
        defer gpa.free(day_str);

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

        const test_output = try std.fmt.allocPrint(gpa, "STDOUT: {s}\nSTDERR: {s}", .{ result.stdout, result.stderr });

        return workflow_types.TestResult{
            .success = result.term.Exited == 0,
            .sample_tests_passed = 0,
            .sample_tests_total = 0,
            .custom_tests_passed = 0,
            .custom_tests_total = 0,
            .performance_ms = 0,
            .test_output = test_output,
        };
    }

    // Submit answer using existing submit.sh logic
    fn submitAnswer(year: u32, day: u32, part: u32) !workflow_types.SubmissionResult {
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

        // Extract answer from output (assuming it's the last line)
        var lines = std.mem.tokenizeScalar(u8, result.stdout, '\n');
        var answer: []const u8 = "";
        while (lines.next()) |line| {
            answer = line;
        }

        // Submit using existing submit.sh
        const submit_year_str = try std.fmt.allocPrint(gpa, "{d}", .{year});
        defer gpa.free(submit_year_str);
        const submit_day_str = try std.fmt.allocPrint(gpa, "{d}", .{day});
        defer gpa.free(submit_day_str);
        const submit_part_str = try std.fmt.allocPrint(gpa, "{d}", .{part});
        defer gpa.free(submit_part_str);

        const submit_args = [_][]const u8{ "./submit.sh", submit_year_str, submit_day_str, submit_part_str, answer };

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
};
