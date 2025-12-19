const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Advent of Code specific options
    const day = b.option(u32, "day", "Advent of Code day to solve");
    const year = b.option(u32, "year", "Advent of Code year (default: 2025)") orelse 2025;
    const part = b.option([]const u8, "part", "Which part to solve: 1, 2, or both (default: both)") orelse "both";

    // Submission options
    const submit = b.option(bool, "submit", "Submit answer to Advent of Code");
    const answer = b.option([]const u8, "answer", "Answer to submit");
    const level = b.option(u32, "level", "Part level to submit (1 or 2)");

    const mod = b.addModule("aoc_zig", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    const exe = b.addExecutable(.{
        .name = "aoc_zig",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "aoc_zig", .module = mod },
            },
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);

    // Advent of Code solve step
    if (day) |d| {
        const solution_path = b.fmt("{d}/day_{d:0>2}.zig", .{ year, d });
        const solution_mod = b.createModule(.{
            .root_source_file = b.path(solution_path),
            .target = target,
            .optimize = optimize,
        });

        const solve_exe = b.addExecutable(.{
            .name = "aoc_solve",
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/aoc_runner.zig"),
                .target = target,
                .optimize = optimize,
                .imports = &.{
                    .{ .name = "aoc_zig", .module = mod },
                    .{ .name = "solution", .module = solution_mod },
                },
            }),
        });

        const solve_cmd = b.addRunArtifact(solve_exe);
        solve_cmd.addArgs(&.{ b.fmt("{d}", .{year}), b.fmt("{d}", .{d}), part });
        const solve_step = b.step("solve", "Run Advent of Code solution");
        solve_step.dependOn(&solve_cmd.step);
    }

    // Advent of Code submission step
    if (submit) |_| {
        if (level) |lvl| {
            if (answer) |ans| {
                if (day) |d| {
                    const submit_cmd = b.addSystemCommand(&.{ "./submit.sh", b.fmt("{d}", .{year}), b.fmt("{d}", .{d}), b.fmt("{d}", .{lvl}), ans });
                    const submit_step = b.step("submit", "Submit answer to Advent of Code");
                    submit_step.dependOn(&submit_cmd.step);
                }
            }
        }
    }

    // Learning guide system
    const learning_guide_mod = b.createModule(.{
        .root_source_file = b.path("learning-guide/agents/learning-guide-agent.zig"),
        .target = target,
        .optimize = optimize,
    });

    const learning_guide_exe = b.addExecutable(.{
        .name = "learning-guide-agent",
        .root_module = learning_guide_mod,
    });

    b.installArtifact(learning_guide_exe);

    // Run step for learning guide agent
    const run_learning_guide = b.addRunArtifact(learning_guide_exe);
    const learning_guide_step = b.step("learning-guide", "Update learning guide for a day");
    learning_guide_step.dependOn(&run_learning_guide.step);

    // Unified AoC Agent system
    const unified_agent_mod = b.createModule(.{
        .root_source_file = b.path("agents/unified-aoc-agent.zig"),
        .target = target,
        .optimize = optimize,
    });

    const unified_agent_exe = b.addExecutable(.{
        .name = "aoc-agent",
        .root_module = b.createModule(.{
            .root_source_file = b.path("agents/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "unified_agent", .module = unified_agent_mod },
            },
        }),
    });

    b.installArtifact(unified_agent_exe);

    // Run step for unified agent
    const run_unified_agent = b.addRunArtifact(unified_agent_exe);
    const unified_agent_step = b.step("agent", "Run unified AoC agent workflow");
    unified_agent_step.dependOn(&run_unified_agent.step);
}
