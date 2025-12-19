const std = @import("std");

fn testHardModeLogic() !void {
    // Test the exact logic from AoC description:
    // "at the start of each player turn (before any other effects apply), you lose 1 hit point."

    // Simulate simple case: Player with 2 HP, no effects, boss turn doesn't matter
    var player_hp: i32 = 2;

    // Hard mode: lose 1 HP at start of player turn
    player_hp -= 1;
    std.debug.print("After hard mode damage: Player HP = {}\n", .{player_hp});

    // Player is now at 1 HP, should still be alive
    if (player_hp <= 0) {
        std.debug.print("Player would be dead (wrong!)", .{});
    } else {
        std.debug.print("Player still alive (correct)", .{});
    }
}

pub fn main() !void {
    try testHardModeLogic();
}
