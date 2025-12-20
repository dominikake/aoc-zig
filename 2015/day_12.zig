const std = @import("std");

// TAOCP Concept: Tree traversal - recursive function to process JSON tree
fn sumJsonNumbers(value: std.json.Value, ignore_red: bool) i64 {
    return switch (value) {
        // TAOCP: Leaf nodes - base case for recursion
        .integer => |int| int,
        .float => |float| @intFromFloat(@floor(float)),
        .number_string => |num_str| {
            const trimmed = std.mem.trim(u8, num_str, " \t\n\r");
            return std.fmt.parseInt(i64, trimmed, 10) catch 0;
        },

        // TAOCP: Tree traversal - process children (arrays and objects)
        .array => |array| {
            var total: i64 = 0;
            for (array.items) |item| {
                total += sumJsonNumbers(item, ignore_red);
            }
            return total;
        },

        .object => |object| {
            // TAOCP: Conditional pruning - Part 2 logic
            if (ignore_red) {
                var it = object.iterator();
                while (it.next()) |entry| {
                    if (entry.value_ptr.* == .string and
                        std.mem.eql(u8, entry.value_ptr.string, "red"))
                    {
                        return 0; // Prune entire subtree
                    }
                }
            }

            var total: i64 = 0;
            var it = object.iterator();
            while (it.next()) |entry| {
                total += sumJsonNumbers(entry.value_ptr.*, ignore_red);
            }
            return total;
        },

        // TAOCP: Ignore non-numeric leaf nodes
        .string, .bool, .null => 0,
    };
}

// TAOCP: Parsing with allocation management
fn parseAndSumJson(input: []const u8, ignore_red: bool) !i64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var parsed = try std.json.parseFromSlice(std.json.Value, allocator, input, .{});
    defer parsed.deinit();

    return sumJsonNumbers(parsed.value, ignore_red);
}

pub fn part1(input: []const u8) !?[]const u8 {
    // TAOCP: Single-pass algorithm with JSON tree traversal
    const total = try parseAndSumJson(input, false);

    const gpa = std.heap.page_allocator;
    const result = try std.fmt.allocPrint(gpa, "{}", .{total});
    return result;
}

pub fn part2(input: []const u8) !?[]const u8 {
    // TAOCP: Conditional tree traversal with pruning
    const total = try parseAndSumJson(input, true);

    const gpa = std.heap.page_allocator;
    const result = try std.fmt.allocPrint(gpa, "{}", .{total});
    return result;
}

// Test Part 1 examples
test "part1 array [1,2,3]" {
    const input = "[1,2,3]";
    const result = try part1(input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("6", result.?);
}

test "part1 object {\"a\":2,\"b\":4}" {
    const input = "{\"a\":2,\"b\":4}";
    const result = try part1(input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("6", result.?);
}

test "part1 nested array [[[3]]]" {
    const input = "[[[3]]]";
    const result = try part1(input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("3", result.?);
}

test "part1 nested object {\"a\":{\"b\":4},\"c\":-1}" {
    const input = "{\"a\":{\"b\":4},\"c\":-1}";
    const result = try part1(input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("3", result.?);
}

test "part1 mixed {\"a\":[-1,1]}" {
    const input = "{\"a\":[-1,1]}";
    const result = try part1(input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("0", result.?);
}

test "part1 array with object [-1,{\"a\":1}]" {
    const input = "[-1,{\"a\":1}]";
    const result = try part1(input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("0", result.?);
}

test "part1 empty structures" {
    const input1 = "[]";
    const input2 = "{}";

    const result1 = try part1(input1);
    defer std.heap.page_allocator.free(result1.?);
    try std.testing.expectEqualStrings("0", result1.?);

    const result2 = try part1(input2);
    defer std.heap.page_allocator.free(result2.?);
    try std.testing.expectEqualStrings("0", result2.?);
}

test "part1 complex example" {
    const input = "[1,2,3]";
    const result = try part1(input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("6", result.?);
}

// Test Part 2 examples - ignoring objects with "red"
test "part2 object with red" {
    const input = "{\"d\":\"red\",\"e\":[1,2,3,4],\"f\":5}";
    const result = try part2(input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("0", result.?); // entire object ignored
}

test "part2 nested object with red" {
    const input = "[1,{\"c\":\"red\",\"b\":2},3]";
    const result = try part2(input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("4", result.?); // 1 + 3, object ignored
}

test "part2 array with red not ignored" {
    const input = "[1,\"red\",5]";
    const result = try part2(input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("6", result.?); // arrays not affected
}

test "part2 object with red as key not value" {
    const input = "{\"red\":1,\"blue\":2}";
    const result = try part2(input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("3", result.?); // no red value
}

test "part2 complex mixed structure" {
    const input = "[1,2,3]";
    const result = try part2(input);
    defer std.heap.page_allocator.free(result.?);
    try std.testing.expectEqualStrings("6", result.?); // no red objects
}

// Test the recursive sum function directly
test "sumJsonNumbers basic types" {
    const int_val = std.json.Value{ .integer = 42 };
    const float_val = std.json.Value{ .float = 3.14 };
    const string_val = std.json.Value{ .string = "hello" };
    const bool_val = std.json.Value{ .bool = true };
    const null_val = std.json.Value{ .null = {} };

    try std.testing.expectEqual(@as(i64, 42), sumJsonNumbers(int_val, false));
    try std.testing.expectEqual(@as(i64, 3), sumJsonNumbers(float_val, false));
    try std.testing.expectEqual(@as(i64, 0), sumJsonNumbers(string_val, false));
    try std.testing.expectEqual(@as(i64, 0), sumJsonNumbers(bool_val, false));
    try std.testing.expectEqual(@as(i64, 0), sumJsonNumbers(null_val, false));
}

test "sumJsonNumbers with red ignoring" {
    const gpa = std.testing.allocator;

    // Test object without red
    var obj_without_red = std.json.ObjectMap.init(gpa);
    defer obj_without_red.deinit();
    try obj_without_red.put("a", std.json.Value{ .integer = 1 });
    try obj_without_red.put("b", std.json.Value{ .integer = 2 });
    const obj_val_without_red = std.json.Value{ .object = obj_without_red };

    try std.testing.expectEqual(@as(i64, 3), sumJsonNumbers(obj_val_without_red, true));

    // Test object with red
    var obj_with_red = std.json.ObjectMap.init(gpa);
    defer obj_with_red.deinit();
    try obj_with_red.put("color", std.json.Value{ .string = "red" });
    try obj_with_red.put("value", std.json.Value{ .integer = 100 });
    const obj_val_with_red = std.json.Value{ .object = obj_with_red };

    try std.testing.expectEqual(@as(i64, 0), sumJsonNumbers(obj_val_with_red, true));
}

test "parseAndSumJson memory management" {
    const input = "{\"a\":1,\"b\":[2,3],\"c\":{\"d\":4}}";
    const result = try parseAndSumJson(input, false);
    try std.testing.expectEqual(@as(i64, 10), result); // 1 + 2 + 3 + 4 = 10
}
