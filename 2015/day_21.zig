const std = @import("std");

// TAOCP Concept: Tuple data structure for RPG items
const Item = struct {
    cost: u32,
    damage: u32,
    armor: u32,
};

// TAOCP Concept: Player state for combat simulation
const Player = struct {
    hp: u32,
    damage: u32,
    armor: u32,
    cost: u32,
};

// TAOCP: Shop items data - weapons, armor, rings
const WEAPONS = [_]Item{
    .{ .cost = 8, .damage = 4, .armor = 0 }, // Dagger
    .{ .cost = 10, .damage = 5, .armor = 0 }, // Shortsword
    .{ .cost = 25, .damage = 6, .armor = 0 }, // Warhammer
    .{ .cost = 40, .damage = 7, .armor = 0 }, // Longsword
    .{ .cost = 74, .damage = 8, .armor = 0 }, // Greataxe
};

const ARMORS = [_]Item{
    .{ .cost = 0, .damage = 0, .armor = 0 }, // No armor
    .{ .cost = 13, .damage = 0, .armor = 1 }, // Leather
    .{ .cost = 31, .damage = 0, .armor = 2 }, // Chainmail
    .{ .cost = 53, .damage = 0, .armor = 3 }, // Splintmail
    .{ .cost = 75, .damage = 0, .armor = 4 }, // Bandedmail
    .{ .cost = 102, .damage = 0, .armor = 5 }, // Platemail
};

const RINGS = [_]Item{
    .{ .cost = 0, .damage = 0, .armor = 0 }, // No ring (left)
    .{ .cost = 0, .damage = 0, .armor = 0 }, // No ring (right)
    .{ .cost = 25, .damage = 1, .armor = 0 }, // Damage +1
    .{ .cost = 50, .damage = 2, .armor = 0 }, // Damage +2
    .{ .cost = 100, .damage = 3, .armor = 0 }, // Damage +3
    .{ .cost = 20, .damage = 0, .armor = 1 }, // Armor +1
    .{ .cost = 40, .damage = 0, .armor = 2 }, // Armor +2
    .{ .cost = 80, .damage = 0, .armor = 3 }, // Armor +3
};

// TAOCP: Parse boss stats from input
fn parseBoss(input: []const u8) !Player {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var hp: u32 = 0;
    var damage: u32 = 0;
    var armor: u32 = 0;

    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "Hit Points:")) {
            hp = try std.fmt.parseInt(u32, line[12..], 10);
        } else if (std.mem.startsWith(u8, line, "Damage:")) {
            damage = try std.fmt.parseInt(u32, line[8..], 10);
        } else if (std.mem.startsWith(u8, line, "Armor:")) {
            armor = try std.fmt.parseInt(u32, line[7..], 10);
        }
    }

    return Player{ .hp = hp, .damage = damage, .armor = armor, .cost = 0 };
}

// TAOCP: Simulate turn-based combat to conclusion
fn simulateCombat(player: Player, boss: Player) bool {
    var player_hp = player.hp;
    var boss_hp = boss.hp;

    const player_damage = if (player.damage > boss.armor) player.damage - boss.armor else 1;
    const boss_damage = if (boss.damage > player.armor) boss.damage - player.armor else 1;

    while (true) {
        // Player attacks first
        if (boss_hp <= player_damage) return true; // Player wins
        boss_hp -= player_damage;

        // Boss attacks
        if (player_hp <= boss_damage) return false; // Boss wins
        player_hp -= boss_damage;
    }
}

// TAOCP: Generate all valid equipment combinations (Cartesian product)
fn generateEquipments(boss: Player, min_gold: *u32, max_gold: *u32) void {
    // Player always starts with 100 HP
    const player_base_hp: u32 = 100;

    // TAOCP: Brute-force enumeration of all combinations
    for (WEAPONS) |weapon| {
        for (ARMORS) |armor| {
            for (RINGS, 0..) |left_ring, left_i| {
                for (RINGS, 0..) |right_ring, right_j| {
                    // Can't use same ring twice (except "no ring")
                    if (left_i == right_j and left_i >= 2) continue;

                    const total_damage = weapon.damage + armor.damage + left_ring.damage + right_ring.damage;
                    const total_armor = weapon.armor + armor.armor + left_ring.armor + right_ring.armor;
                    const total_cost = weapon.cost + armor.cost + left_ring.cost + right_ring.cost;

                    const player = Player{
                        .hp = player_base_hp,
                        .damage = total_damage,
                        .armor = total_armor,
                        .cost = total_cost,
                    };

                    const player_wins = simulateCombat(player, boss);

                    if (player_wins) {
                        min_gold.* = @min(min_gold.*, total_cost);
                    } else {
                        max_gold.* = @max(max_gold.*, total_cost);
                    }
                }
            }
        }
    }
}

pub fn part1(input: []const u8) !?[]const u8 {
    const boss = try parseBoss(input);

    var min_gold: u32 = std.math.maxInt(u32);
    var max_gold: u32 = 0;

    generateEquipments(boss, &min_gold, &max_gold);

    const gpa = std.heap.page_allocator;
    const result = try std.fmt.allocPrint(gpa, "{}", .{min_gold});
    return result;
}

pub fn part2(input: []const u8) !?[]const u8 {
    const boss = try parseBoss(input);

    var min_gold: u32 = std.math.maxInt(u32);
    var max_gold: u32 = 0;

    generateEquipments(boss, &min_gold, &max_gold);

    const gpa = std.heap.page_allocator;
    const result = try std.fmt.allocPrint(gpa, "{}", .{max_gold});
    return result;
}

// Test the simulation function
test "combat simulation" {
    const player = Player{ .hp = 8, .damage = 5, .armor = 5, .cost = 0 };
    const boss = Player{ .hp = 12, .damage = 7, .armor = 2, .cost = 0 };

    // Player hits for 3 (5-2), boss hits for 2 (7-5)
    // Player: 8→6→4→2→0 (dies on 4th boss turn)
    // Boss: 12→9→6→3→0 (dies on 4th player turn)
    // Player wins with 2 HP left
    try std.testing.expect(simulateCombat(player, boss) == true);
}

test "parse boss stats" {
    const input =
        \\Hit Points: 100
        \\Damage: 8
        \\Armor: 2
    ;

    const boss = try parseBoss(input);
    try std.testing.expectEqual(@as(u32, 100), boss.hp);
    try std.testing.expectEqual(@as(u32, 8), boss.damage);
    try std.testing.expectEqual(@as(u32, 2), boss.armor);
}

test "generate equipment combinations" {
    const boss = Player{ .hp = 12, .damage = 7, .armor = 2, .cost = 0 };

    var min_gold: u32 = std.math.maxInt(u32);
    var max_gold: u32 = 0;

    generateEquipments(boss, &min_gold, &max_gold);

    // Should find winning combinations
    try std.testing.expect(min_gold < std.math.maxInt(u32));
    // May or may not have losing combinations depending on boss stats
}
