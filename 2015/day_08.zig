const std = @import("std");

// Count the actual number of characters in memory for a string literal
fn countMemoryCharacters(str: []const u8) usize {
    if (str.len < 2 or str[0] != '"' or str[str.len - 1] != '"') return 0;

    var memory_count: usize = 0;
    var i: usize = 1; // Skip opening quote

    while (i < str.len - 1) { // Stop before closing quote
        if (str[i] == '\\') {
            if (i + 1 >= str.len - 1) {
                // Backslash at end, count it literally
                memory_count += 1;
                i += 1;
                continue;
            }

            switch (str[i + 1]) {
                '\\', '"' => {
                    // Escaped backslash or quote
                    memory_count += 1;
                    i += 2;
                },
                'x' => {
                    // Hex escape sequence \xNN
                    if (i + 3 < str.len - 1 and
                        std.ascii.isHex(str[i + 2]) and
                        std.ascii.isHex(str[i + 3]))
                    {
                        memory_count += 1;
                        i += 4;
                    } else {
                        // Invalid hex sequence, count literally
                        memory_count += 1;
                        i += 1;
                    }
                },
                else => {
                    // Unknown escape, count backslash literally
                    memory_count += 1;
                    i += 1;
                },
            }
        } else {
            // Regular character
            memory_count += 1;
            i += 1;
        }
    }

    return memory_count;
}

// Count the number of characters needed to encode a string literal with escapes
fn countEscapedCharacters(str: []const u8) usize {
    var escaped_count: usize = 2; // Start with opening and closing quotes

    for (str) |c| {
        switch (c) {
            '\\', '"' => {
                // Need to escape these characters
                escaped_count += 2;
            },
            else => {
                escaped_count += 1;
            },
        }
    }

    return escaped_count;
}

pub fn part1(input: []const u8) !?[]const u8 {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var total_code_len: usize = 0;
    var total_memory_len: usize = 0;

    while (lines.next()) |line| {
        if (line.len == 0) continue;

        total_code_len += line.len;
        total_memory_len += countMemoryCharacters(line);
    }

    const difference = total_code_len - total_memory_len;
    return try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{difference});
}

pub fn part2(input: []const u8) !?[]const u8 {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var total_original_len: usize = 0;
    var total_escaped_len: usize = 0;

    while (lines.next()) |line| {
        if (line.len == 0) continue;

        total_original_len += line.len;
        total_escaped_len += countEscapedCharacters(line);
    }

    const difference = total_escaped_len - total_original_len;
    return try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{difference});
}
