const std = @import("std");
const mem = std.mem;
const math = std.math;

// TAOCP Vol. 2, Section 4.5.4: Divisor enumeration and sum function σ(h)
// Abundant numbers have σ(h) > 2h, useful for search optimization

pub fn part1(input: []const u8) !?[]const u8 {
    const target = try std.fmt.parseInt(u64, mem.trim(u8, input, "\n"), 10);
    const house_num = findHouse(target, 10, 0);
    return try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{house_num});
}

pub fn part2(input: []const u8) !?[]const u8 {
    const target = try std.fmt.parseInt(u64, mem.trim(u8, input, "\n"), 10);
    const house_num = findHouse(target, 11, 50);
    return try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{house_num});
}

fn findHouse(target: u64, presents_per_elf: u64, max_houses_per_elf: u64) u64 {
    // Start with reasonable estimate
    var house: u64 = target / (presents_per_elf * 10);
    if (house < 1) house = 1;

    while (true) {
        const presents = calculatePresents(house, presents_per_elf, max_houses_per_elf);
        if (presents >= target) {
            return house;
        }
        house += 1;
    }
}

// Original working calculatePresents function with TAOCP comments
fn calculatePresents(house: u64, presents_per_elf: u64, max_houses_per_elf: u64) u64 {
    var total: u64 = 0;
    const sqrt_house = @as(u64, @intFromFloat(@sqrt(@as(f64, @floatFromInt(house)))));

    var elf: u64 = 1;
    while (elf <= sqrt_house) : (elf += 1) {
        if (house % elf == 0) {
            const other_divisor = house / elf;

            // Add contribution from elf (smaller divisor)
            if (max_houses_per_elf == 0 or elf * max_houses_per_elf >= house) {
                total += elf * presents_per_elf;
            }

            // Add contribution from other divisor (if different)
            if (other_divisor != elf and (max_houses_per_elf == 0 or other_divisor * max_houses_per_elf >= house)) {
                total += other_divisor * presents_per_elf;
            }
        }
    }

    return total;
}
