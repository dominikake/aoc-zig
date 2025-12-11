const std = @import("std");
const agent = @import("learning-guide-agent.zig");

pub fn main() !void {
    const gpa = std.heap.page_allocator;

    // Get command line arguments
    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    if (args.len < 4) {
        std.debug.print("Usage: learning-guide-agent <year> <day> <solution_file>\n", .{});
        return;
    }

    const year = try std.fmt.parseInt(u32, args[1], 10);
    const day = try std.fmt.parseInt(u32, args[2], 10);
    const solution_file = args[3];

    // Read solution file
    const file = try std.fs.cwd().openFile(solution_file, .{});
    defer file.close();

    const solution_content = try file.readToEndAlloc(gpa, 1024 * 1024);
    defer gpa.free(solution_content);

    // Update learning guide
    try agent.LearningGuideAgent.updateDay(year, day, solution_content);

    std.debug.print("Learning guide updated successfully for Day {d:0>2}\n", .{day});
}
