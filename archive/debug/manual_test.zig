const std = @import("std");

// Simple test to verify hard mode mechanics manually
fn testManualSimulation() void {
    std.debug.print("Manual simulation test:\n");

    // Example: Player vs Boss with simple strategy
    var player_hp: i32 = 50;
    var player_mana: i32 = 500;
    var player_armor: i32 = 0;
    var boss_hp: i32 = 13; // Smaller for easier testing
    var boss_damage: i32 = 8;

    var shield_timer: i32 = 0;
    var poison_timer: i32 = 0;
    var recharge_timer: i32 = 0;
    var total_mana_spent: i32 = 0;

    std.debug.print("Start: Player HP={}, Mana={}, Boss HP={}\n", .{ player_hp, player_mana, boss_hp });

    // Turn 1 (Player)
    player_hp -= 1; // Hard mode damage
    std.debug.print("After hard mode: Player HP={}\n", .{player_hp});

    // Apply effects (none active)
    std.debug.print("Effects applied: Boss HP={}\n", .{boss_hp});

    // Cast Poison
    player_mana -= 173;
    total_mana_spent += 173;
    poison_timer = 6;
    std.debug.print("Cast Poison: Mana={}, Total spent={}, Poison timer={}\n", .{ player_mana, total_mana_spent, poison_timer });

    // Boss turn
    // Apply poison
    boss_hp -= 3;
    poison_timer -= 1;
    std.debug.print("Boss turn - Poison: Boss HP={}, Poison timer={}\n", .{ boss_hp, poison_timer });

    // Boss attacks
    const damage = boss_damage - player_armor;
    const actual_damage = @max(1, damage);
    player_hp -= actual_damage;
    std.debug.print("Boss attacks for {} damage: Player HP={}\n", .{ actual_damage, player_hp });

    std.debug.print("End state: Player HP={}, Boss HP={}, Mana spent={}\n", .{ player_hp, boss_hp, total_mana_spent });
}

pub fn main() !void {
    testManualSimulation();
}
