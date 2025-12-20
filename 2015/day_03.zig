const std = @import("std");

// TAOCP Concept: Abstract data type for coordinate keys
// Implements hashable coordinate pair for O(1) lookup in hash table
const Coordinate = struct {
    x: i32,
    y: i32,

    // TAOCP: Hash function design - uniform distribution principle
    pub fn hash(self: Coordinate) u64 {
        // Simple multiplicative hash combining x,y coordinates
        // Follows TAOCP discussion on hash function design
        // Handle negative coordinates by casting through i64 first
        var result: u64 = 0;
        result = result *% 31 +% @as(u64, @bitCast(@as(i64, self.x)));
        result = result *% 31 +% @as(u64, @bitCast(@as(i64, self.y)));
        return result;
    }

    // TAOCP: Equality comparison for key matching
    pub fn eql(self: Coordinate, other: Coordinate) bool {
        return self.x == other.x and self.y == other.y;
    }
};

// TAOCP: Context for automatic hash computation
// Implements AutoContext pattern from TAOCP hash table discussions
const CoordinateContext = struct {
    pub fn hash(_: CoordinateContext, key: Coordinate) u64 {
        return key.hash();
    }

    pub fn eql(_: CoordinateContext, key_a: Coordinate, key_b: Coordinate) bool {
        return key_a.eql(key_b);
    }
};

// TAOCP: House record with extensible field structure
// Demonstrates fixed-size record design from TAOCP Volume 1
const House = struct {
    x: i32,
    y: i32,
    // 10 optional u8 fields as requested - available for extensions
    visit_count: ?u8 = null,
    first_visit: ?u8 = null,
    last_visit: ?u8 = null,
    present_type: ?u8 = null,
    delivery_priority: ?u8 = null,
    route_segment: ?u8 = null,
    time_slot: ?u8 = null,
    special_delivery: ?u8 = null,
    weather_condition: ?u8 = null,
    house_category: ?u8 = null,
};

// TAOCP: Coordinate change vectors for navigation
const Direction = struct {
    dx: i32,
    dy: i32,
};

// TAOCP: Parse direction character to coordinate vector
fn parseDirection(char: u8) ?Direction {
    return switch (char) {
        '^' => Direction{ .dx = 0, .dy = 1 },
        'v' => Direction{ .dx = 0, .dy = -1 },
        '>' => Direction{ .dx = 1, .dy = 0 },
        '<' => Direction{ .dx = -1, .dy = 0 },
        else => null,
    };
}

// TAOCP: Set operations using hash table for O(1) average performance
// Implements set abstract data type with collision resolution
const HouseSet = struct {
    // TAOCP: Hash table with automatic context for coordinate keys
    visited: std.HashMap(Coordinate, void, CoordinateContext, std.hash_map.default_max_load_percentage),

    fn init(allocator: std.mem.Allocator) HouseSet {
        return HouseSet{
            .visited = std.HashMap(Coordinate, void, CoordinateContext, std.hash_map.default_max_load_percentage).initContext(allocator, CoordinateContext{}),
        };
    }

    fn deinit(self: *HouseSet) void {
        self.visited.deinit();
    }

    // TAOCP: Set insertion operation - O(1) average case
    fn addHouse(self: *HouseSet, x: i32, y: i32) !void {
        const coord = Coordinate{ .x = x, .y = y };
        try self.visited.put(coord, {});
    }

    // TAOCP: Set cardinality operation
    fn count(self: HouseSet) usize {
        return self.visited.count();
    }
};

// TAOCP: Optimized unique house counting with hash-based set operations
fn countUniqueHouses(allocator: std.mem.Allocator, input: []const u8, part: u8) !usize {
    var house_set = HouseSet.init(allocator);
    defer house_set.deinit();

    // Part 1: Santa alone starts at (0,0)
    // Part 2: Santa and Robo-Santa alternate, both start at (0,0)
    var santa_x: i32 = 0;
    var santa_y: i32 = 0;
    var robo_x: i32 = 0;
    var robo_y: i32 = 0;

    // Add starting house
    try house_set.addHouse(santa_x, santa_y);

    var move_count: usize = 0;
    for (input) |char| {
        if (parseDirection(char)) |dir| {
            if (part == 1) {
                // Santa moves - single simulation
                santa_x += dir.dx;
                santa_y += dir.dy;
                try house_set.addHouse(santa_x, santa_y);
            } else {
                // Part 2: Alternating simulation with set union
                if (move_count % 2 == 0) {
                    // Santa's turn
                    santa_x += dir.dx;
                    santa_y += dir.dy;
                    try house_set.addHouse(santa_x, santa_y);
                } else {
                    // Robo-Santa's turn
                    robo_x += dir.dx;
                    robo_y += dir.dy;
                    try house_set.addHouse(robo_x, robo_y);
                }
                move_count += 1;
            }
        }
    }

    return house_set.count();
}

pub fn part1(input: []const u8) !?[]const u8 {
    const gpa = std.heap.page_allocator;
    const count = try countUniqueHouses(gpa, input, 1);
    const result = try std.fmt.allocPrint(gpa, "{}", .{count});
    return result;
}

pub fn part2(input: []const u8) !?[]const u8 {
    const gpa = std.heap.page_allocator;
    const count = try countUniqueHouses(gpa, input, 2);
    const result = try std.fmt.allocPrint(gpa, "{}", .{count});
    return result;
}
