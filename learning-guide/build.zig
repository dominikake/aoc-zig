const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Learning guide agent executable
    const agent_mod = b.createModule(.{
        .root_source_file = b.path("learning-guide-agent.zig"),
        .target = target,
        .optimize = optimize,
    });

    const agent_exe = b.addExecutable(.{
        .name = "learning-guide-agent",
        .root_module = agent_mod,
    });

    b.installArtifact(agent_exe);

    // Run step for learning guide agent
    const run_agent = b.addRunArtifact(agent_exe);
    const agent_step = b.step("learning-guide", "Update learning guide for a day");
    agent_step.dependOn(&run_agent.step);
}
