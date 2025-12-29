const std = @import("std");

const Player = struct {
    hp: u32,
    damage: u32,
    armor: u32,
    cost: u32,
};

fn parseBoss(input: []const u8) !Player {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var hp: u32 = 0;
    var damage: u32 = 0;
    var armor: u32 = 0;

    while (lines.next()) |line| {
        std.debug.print("Line: '{s}'\n", .{line});
        if (std.mem.startsWith(u8, line, "Hit Points:")) {
            hp = try std.fmt.parseInt(u32, line[11..], 10);
            std.debug.print("Parsed HP: {}\n", .{hp});
        } else if (std.mem.startsWith(u8, line, "Damage:")) {
            damage = try std.fmt.parseInt(u32, line[7..], 10);
            std.debug.print("Parsed Damage: {}\n", .{damage});
        } else if (std.mem.startsWith(u8, line, "Armor:")) {
            armor = try std.fmt.parseInt(u32, line[6..], 10);
            std.debug.print("Parsed Armor: {}\n", .{armor});
        }
    }

    return Player{ .hp = hp, .damage = damage, .armor = armor, .cost = 0 };
}

pub fn main() !void {
    const input =
        \\Hit Points: 100
        \\Damage: 8
        \\Armor: 2
    ;

    const boss = try parseBoss(input);
    std.debug.print("Boss: HP={}, Damage={}, Armor={}\n", .{ boss.hp, boss.damage, boss.armor });
}
