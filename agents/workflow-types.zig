const std = @import("std");

// Core workflow types for unified AoC agent system

pub const WorkflowRequest = struct {
    year: u32,
    day: u32,
    part: u32,
    conceptual_solution: []const u8,
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
        // TODO: Fix memory management - temporarily disabled to prevent panic
        _ = allocator;
        _ = self;
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
        _ = allocator; // TODO: Figure out how to properly initialize ArrayList in Zig 0.15
        return DebugInfo{
            .steps = std.ArrayList([]const u8){},
            .intermediate_results = std.ArrayList([]const u8){},
            .performance_metrics = std.ArrayList([]const u8){},
        };
    }

    pub fn deinit(self: *DebugInfo, allocator: std.mem.Allocator) void {
        // TODO: Fix memory management - temporarily disabled to prevent panic
        _ = allocator;
        _ = self;
    }

    pub fn addStep(self: *DebugInfo, allocator: std.mem.Allocator, step: []const u8) !void {
        try self.steps.append(allocator, step);
    }

    pub fn addResult(self: *DebugInfo, allocator: std.mem.Allocator, result: []const u8) !void {
        try self.intermediate_results.append(allocator, result);
    }

    pub fn addMetric(self: *DebugInfo, allocator: std.mem.Allocator, metric: []const u8) !void {
        try self.performance_metrics.append(allocator, metric);
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
