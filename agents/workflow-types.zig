const std = @import("std");

// Core workflow types for unified AoC agent system

pub const WorkflowRequest = struct {
    year: u32,
    day: u32,
    part: u32,
    conceptual_solution: []const u8,
};

// Workflow state for checkpoint and resume capability
pub const WorkflowState = struct {
    year: u32,
    day: u32,
    current_part: u32, // 0=not started, 1=part1, 2=part2, 3=complete
    step: WorkflowStep,
    timestamp: i64,

    pub fn save(self: WorkflowState, allocator: std.mem.Allocator) ![]const u8 {
        // Simple string format for now, can upgrade to JSON later
        return std.fmt.allocPrint(allocator, "{d}|{d}|{d}|{}|{d}", .{ self.year, self.day, self.current_part, @intFromEnum(self.step), self.timestamp });
    }

    pub fn load(data: []const u8) !WorkflowState {
        var parts = std.mem.tokenizeScalar(u8, data, '|');
        const year_str = parts.next() orelse return error.InvalidFormat;
        const day_str = parts.next() orelse return error.InvalidFormat;
        const part_str = parts.next() orelse return error.InvalidFormat;
        const step_str = parts.next() orelse return error.InvalidFormat;
        const timestamp_str = parts.next() orelse return error.InvalidFormat;

        return WorkflowState{
            .year = try std.fmt.parseInt(u32, year_str, 10),
            .day = try std.fmt.parseInt(u32, day_str, 10),
            .current_part = try std.fmt.parseInt(u32, part_str, 10),
            .step = @enumFromInt(try std.fmt.parseInt(u8, step_str, 10)),
            .timestamp = try std.fmt.parseInt(i64, timestamp_str, 10),
        };
    }
};

// Individual workflow steps for granular checkpointing
pub const WorkflowStep = enum {
    not_started,
    directories_setup,
    input_fetched,
    solution_generated,
    tests_run,
    answer_submitted,
    learning_guide_updated,
    completed,
};

pub const WorkflowResult = struct {
    success: bool,
    solution_generated: bool,
    tests_passed: bool,
    submission_successful: bool,
    learning_guide_updated: bool,
    errors: std.ArrayList([]const u8),
    debug_info: DebugInfo,
    execution_time: u64, // milliseconds

    pub fn init(allocator: std.mem.Allocator) WorkflowResult {
        return WorkflowResult{
            .success = false,
            .solution_generated = false,
            .tests_passed = false,
            .submission_successful = false,
            .learning_guide_updated = false,
            .errors = std.ArrayList([]const u8){},
            .debug_info = DebugInfo.init(allocator),
            .execution_time = 0,
        };
    }

    pub fn deinit(self: *WorkflowResult, allocator: std.mem.Allocator) void {
        for (self.errors.items) |error_msg| {
            allocator.free(error_msg);
        }
        self.errors.deinit(allocator);
        self.debug_info.deinit(allocator);
    }

    pub fn addError(self: *WorkflowResult, allocator: std.mem.Allocator, error_msg: []const u8) !void {
        try self.errors.append(allocator, error_msg);
    }

    pub fn hasErrors(self: WorkflowResult) bool {
        return self.errors.items.len > 0;
    }
};

pub const DebugInfo = struct {
    steps: std.ArrayList([]const u8),
    intermediate_results: std.ArrayList([]const u8),
    performance_metrics: std.ArrayList([]const u8),

    pub fn init(allocator: std.mem.Allocator) DebugInfo {
        _ = allocator; // Will be used in append calls
        return DebugInfo{
            .steps = .empty,
            .intermediate_results = .empty,
            .performance_metrics = .empty,
        };
    }

    pub fn deinit(self: *DebugInfo, allocator: std.mem.Allocator) void {
        for (self.steps.items) |step| {
            allocator.free(step);
        }
        self.steps.deinit(allocator);

        for (self.intermediate_results.items) |result| {
            allocator.free(result);
        }
        self.intermediate_results.deinit(allocator);

        for (self.performance_metrics.items) |metric| {
            allocator.free(metric);
        }
        self.performance_metrics.deinit(allocator);
    }

    pub fn addStep(self: *DebugInfo, allocator: std.mem.Allocator, step: []const u8) !void {
        const duped_step = try allocator.dupe(u8, step);
        try self.steps.append(allocator, duped_step);
    }

    pub fn addResult(self: *DebugInfo, allocator: std.mem.Allocator, result: []const u8) !void {
        const duped_result = try allocator.dupe(u8, result);
        try self.intermediate_results.append(allocator, duped_result);
    }

    pub fn addMetric(self: *DebugInfo, allocator: std.mem.Allocator, metric: []const u8) !void {
        const duped_metric = try allocator.dupe(u8, metric);
        try self.performance_metrics.append(allocator, duped_metric);
    }
};

pub const SolutionResult = struct {
    success: bool,
    solution_code: []const u8,
    compilation_output: []const u8,
    errors: []const []const u8,

    pub fn deinit(self: *SolutionResult, allocator: std.mem.Allocator) void {
        allocator.free(self.solution_code);
        allocator.free(self.compilation_output);
        for (self.errors) |error_msg| {
            allocator.free(error_msg);
        }
        allocator.free(self.errors);
    }
};

pub const TestResult = struct {
    success: bool,
    sample_tests_passed: u32,
    sample_tests_total: u32,
    custom_tests_passed: u32,
    custom_tests_total: u32,
    performance_ms: u64,
    test_output: []const u8,

    pub fn deinit(self: *TestResult, allocator: std.mem.Allocator) void {
        allocator.free(self.test_output);
    }
};

pub const SubmissionResult = struct {
    success: bool,
    response: []const u8,
    cached: bool,
    rate_limited: bool,
    correct: bool,

    pub fn deinit(self: *SubmissionResult, allocator: std.mem.Allocator) void {
        allocator.free(self.response);
    }
};

// Zig constants for agent configuration
pub const AgentConfig = struct {
    pub const MAX_RETRIES: u32 = 3;
    pub const TEST_TIMEOUT_MS: u32 = 30000;
    pub const SUBMISSION_DELAY_MS: u32 = 60000;
    pub const DEBUG_MODE: bool = true;
    pub const MAX_SOLUTION_SIZE: usize = 1024 * 1024; // 1MB
    pub const MAX_INPUT_SIZE: usize = 10 * 1024 * 1024; // 10MB
    pub const CACHE_DIR: []const u8 = ".cache/aoc-agent";
    pub const LOG_LEVEL: enum { debug, info, warn, err } = .info;
};

// Error types for comprehensive error handling
pub const AgentError = error{
    InvalidWorkflowRequest,
    PatternDetectionFailed,
    SolutionGenerationFailed,
    CompilationFailed,
    TestFailed,
    SubmissionFailed,
    LearningGuideUpdateFailed,
    NetworkError,
    FileSystemError,
    ParseError,
    TimeoutError,
    MemoryError,
    ConfigurationError,
};

// Problem patterns for rule-based detection
pub const ProblemPattern = enum {
    sequential_processing, // Like Day 1: state machines
    grid_processing, // 2D arrays, pathfinding
    graph_algorithms, // DFS/BFS, connectivity
    mathematical, // Number theory, sequences
    combinatorial, // Permutations, backtracking
    parsing_complex, // Complex input formats
    optimization, // DP, greedy algorithms
    string_processing, // String manipulation, pattern matching
    simulation, // Step-by-step simulation
    data_transformation, // Data format conversion
};

// Debug strategies for intensive error handling
pub const DebugStrategy = enum {
    input_validation,
    step_by_step_execution,
    sample_testing,
    edge_case_analysis,
    performance_profiling,
    memory_analysis,
    algorithm_comparison,
    brute_force_verification,
};

// Recovery actions for error handling
pub const RecoveryAction = struct {
    strategy: DebugStrategy,
    steps: []const []const u8,
    max_retries: u32,
    current_retry: u32,
    description: []const u8,

    pub fn deinit(self: *RecoveryAction, allocator: std.mem.Allocator) void {
        allocator.free(self.steps);
        allocator.free(self.description);
    }
};

// Context for error handling
pub const ErrorContext = struct {
    error_type: AgentError,
    workflow_request: WorkflowRequest,
    solution_code: []const u8,
    test_input: []const u8,
    expected_output: []const u8,
    actual_output: []const u8,
    compilation_output: []const u8,

    pub fn deinit(self: *ErrorContext, allocator: std.mem.Allocator) void {
        allocator.free(self.solution_code);
        allocator.free(self.test_input);
        allocator.free(self.expected_output);
        allocator.free(self.actual_output);
        allocator.free(self.compilation_output);
    }
};
