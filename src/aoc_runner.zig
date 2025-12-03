const std = @import("std");
const solution = @import("solution");

// We'll use a simpler approach where the build system creates a custom runner
// for each specific day/year combination

pub fn main() !void {
    const gpa = std.heap.page_allocator;

    // Get command line arguments
    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    if (args.len < 2) {
        std.debug.print("Usage:\n", .{});
        std.debug.print("  Solve:    aoc_solve <year> <day> <part> [input_file]\n", .{});
        std.debug.print("  Submit:   aoc_submit <year> <day> <level> <answer>\n", .{});
        return;
    }

    const year = try std.fmt.parseInt(u32, args[1], 10);
    const day = try std.fmt.parseInt(u32, args[2], 10);

    // This is only for solving, submission is handled by submit.sh

    // Otherwise, treat as solve request
    const part = args[3];
    _ = if (args.len > 4) args[4] else @as([]const u8, "input"); // unused for now

    // Format day with leading zero for file paths
    const day_str = try std.fmt.allocPrint(gpa, "{d:0>2}", .{day});
    defer gpa.free(day_str);

    // Construct input file path
    const input_path = try std.fmt.allocPrint(gpa, "input/{d}/day{s}.txt", .{ year, day_str });
    defer gpa.free(input_path);

    // Read input file
    const file = std.fs.cwd().openFile(input_path, .{}) catch |err| {
        std.debug.print("Error opening input file '{s}': {}\n", .{ input_path, err });
        return err;
    };
    defer file.close();

    const input = try file.readToEndAlloc(gpa, 1024 * 1024 * 10); // 10MB max
    defer gpa.free(input);

    // Solution is imported at the top of the file

    const run_part1 = std.mem.eql(u8, part, "both") or std.mem.eql(u8, part, "1");
    const run_part2 = std.mem.eql(u8, part, "both") or std.mem.eql(u8, part, "2");

    if (run_part1) {
        std.debug.print("Part 1:\n", .{});
        if (solution.part1(input)) |result| {
            if (result) |answer| {
                std.debug.print("{s}\n", .{answer});
            } else {
                std.debug.print("No result\n", .{});
            }
        } else |err| {
            std.debug.print("Error: {}\n", .{err});
        }
    }

    if (run_part2) {
        std.debug.print("Part 2:\n", .{});
        if (solution.part2(input)) |result| {
            if (result) |answer| {
                std.debug.print("{s}\n", .{answer});
            } else {
                std.debug.print("No result\n", .{});
            }
        } else |err| {
            std.debug.print("Error: {}\n", .{err});
        }
    }
}
