const std = @import("std");

// TAOCP Vol. 1: Abstract data types - enumeration of spell types
const SpellType = enum {
    magic_missile,
    drain,
    shield,
    poison,
    recharge,
};

// TAOCP Vol. 4: Graph node state representation - complete battle state
const GameState = struct {
    // Player stats
    player_hp: i32,
    player_mana: i32,
    player_armor: i32,

    // Boss stats (from input)
    boss_hp: i32,
    boss_damage: i32,

    // TAOCP Vol. 3: Searching - active spell effects with timers
    shield_timer: i32,
    poison_timer: i32,
    recharge_timer: i32,

    // Search metadata
    total_mana_spent: i32,
    turn: enum { player, boss },

    const Self = @This();

    // TAOCP Vol. 2: Arithmetic - damage calculation with armor
    fn calculateBossDamage(self: Self, damage: i32) i32 {
        const actual_damage = damage - self.player_armor;
        return @max(1, actual_damage); // Boss always deals at least 1 damage
    }
};

// TAOCP Vol. 4: Weighted graph edge - spell costs and effects
const Spell = struct {
    spell_type: SpellType,
    mana_cost: i32,

    const all_spells = [_]Spell{
        .{ .spell_type = .magic_missile, .mana_cost = 53 },
        .{ .spell_type = .drain, .mana_cost = 73 },
        .{ .spell_type = .shield, .mana_cost = 113 },
        .{ .spell_type = .poison, .mana_cost = 173 },
        .{ .spell_type = .recharge, .mana_cost = 229 },
    };
};

// TAOCP Vol. 4: Uniform-cost search priority queue - compare by total mana spent
fn compareGameState(context: void, a: GameState, b: GameState) std.math.Order {
    _ = context;
    return std.math.order(a.total_mana_spent, b.total_mana_spent);
}

// TAOCP Vol. 1: Information structures - boss stats from input
const BossStats = struct {
    hp: i32,
    damage: i32,
};

// TAOCP Vol. 1: String processing - parse boss statistics
fn parseBossStats(input: []const u8) !BossStats {
    var hp: i32 = 0;
    var damage: i32 = 0;

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');

    while (line_iter.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \r\t");
        if (trimmed.len == 0) continue;

        if (std.mem.startsWith(u8, trimmed, "Hit Points:")) {
            const colon_pos = std.mem.indexOfScalar(u8, trimmed, ':') orelse return error.InvalidFormat;
            const hp_str = trimmed[colon_pos + 1 ..];
            hp = try std.fmt.parseInt(i32, std.mem.trim(u8, hp_str, " "), 10);
        } else if (std.mem.startsWith(u8, trimmed, "Damage:")) {
            const colon_pos = std.mem.indexOfScalar(u8, trimmed, ':') orelse return error.InvalidFormat;
            const damage_str = trimmed[colon_pos + 1 ..];
            damage = try std.fmt.parseInt(i32, std.mem.trim(u8, damage_str, " "), 10);
        }
    }

    if (hp <= 0 or damage <= 0) return error.InvalidStats;

    return BossStats{ .hp = hp, .damage = damage };
}

// TAOCP Vol. 7.2.2: Backtracking - apply spell effects at start of turn
fn applyEffects(state: *GameState) void {
    // Shield effect
    if (state.shield_timer > 0) {
        state.player_armor = 7;
        state.shield_timer -= 1;
        if (state.shield_timer == 0) state.player_armor = 0;
    }

    // Poison effect
    if (state.poison_timer > 0) {
        state.boss_hp -= 3;
        state.poison_timer -= 1;
    }

    // Recharge effect
    if (state.recharge_timer > 0) {
        state.player_mana += 101;
        state.recharge_timer -= 1;
    }
}

// TAOCP Vol. 4: Graph edge validation - check if spell can be cast
fn canCastSpell(state: GameState, spell: Spell) bool {
    if (state.player_mana < spell.mana_cost) return false;

    return switch (spell.spell_type) {
        .shield => state.shield_timer == 0,
        .poison => state.poison_timer == 0,
        .recharge => state.recharge_timer == 0,
        else => true, // Instant spells can always be cast
    };
}

// TAOCP Vol. 4: State transition - apply spell effects
fn castSpell(state: *GameState, spell: Spell) void {
    state.player_mana -= spell.mana_cost;
    state.total_mana_spent += spell.mana_cost;

    switch (spell.spell_type) {
        .magic_missile => {
            state.boss_hp -= 4;
        },
        .drain => {
            state.boss_hp -= 2;
            state.player_hp += 2;
        },
        .shield => {
            state.shield_timer = 6;
        },
        .poison => {
            state.poison_timer = 6;
        },
        .recharge => {
            state.recharge_timer = 5;
        },
    }
}

// TAOCP Vol. 6: Hashing - create compact state representation for visited tracking
fn stateToString(state: GameState, buf: []u8) []const u8 {
    return std.fmt.bufPrint(buf, "{}|{}|{}|{}|{}|{}", .{
        state.player_hp,
        state.player_mana,
        state.boss_hp,
        state.shield_timer,
        state.poison_timer,
        state.recharge_timer,
    }) catch "";
}

// TAOCP Vol. 4: DFS with branch and bound - recursive search for optimal solution
fn dfsBattle(state: GameState, best_cost: *?i32, hard_mode: bool, depth: u32) void {
    // Add depth limit to prevent infinite recursion (hard mode requires faster wins)
    if (depth > 20) return;

    // Prune if we already have a better solution
    if (best_cost.*) |cost| {
        if (state.total_mana_spent >= cost) return;
    }

    // Check if boss is dead - we won!
    if (state.boss_hp <= 0) {
        best_cost.* = state.total_mana_spent;
        std.debug.print("New best: {}\n", .{state.total_mana_spent});
        return;
    }

    // Check if player is dead - this path fails
    if (state.player_hp <= 0) return;

    // Start of player turn
    var player_state = state;

    // Apply effects at start of player turn (BEFORE hard mode damage!)
    applyEffects(&player_state);
    if (player_state.boss_hp <= 0) {
        best_cost.* = player_state.total_mana_spent;
        std.debug.print("New best (effects killed): {}\n", .{player_state.total_mana_spent});
        return;
    }

    // Hard mode: player loses 1 HP at start of turn (AFTER effects)
    if (hard_mode) {
        player_state.player_hp -= 1;
        if (player_state.player_hp <= 0) return;
    }

    // Try spells in order of efficiency for hard mode
    // Priority: Magic Missile (cheap damage), Poison (efficient DoT), Drain (damage+heal), Recharge (mana), Shield (defense)
    const spell_order = [_]Spell{
        .{ .spell_type = .magic_missile, .mana_cost = 53 },
        .{ .spell_type = .poison, .mana_cost = 173 },
        .{ .spell_type = .drain, .mana_cost = 73 },
        .{ .spell_type = .recharge, .mana_cost = 229 },
        .{ .spell_type = .shield, .mana_cost = 113 },
    };

    for (spell_order) |spell| {
        if (!canCastSpell(player_state, spell)) continue;

        var spell_state = player_state;

        // Cast spell
        castSpell(&spell_state, spell);
        if (spell_state.boss_hp <= 0) {
            best_cost.* = spell_state.total_mana_spent;
            std.debug.print("New best (spell killed): {}\n", .{spell_state.total_mana_spent});
            return;
        }

        // Boss turn starts
        var boss_state = spell_state;

        // Apply effects at start of boss turn
        applyEffects(&boss_state);
        if (boss_state.boss_hp <= 0) {
            best_cost.* = boss_state.total_mana_spent;
            std.debug.print("New best (boss effects killed): {}\n", .{boss_state.total_mana_spent});
            return;
        }

        // Boss attacks
        const damage = boss_state.calculateBossDamage(boss_state.boss_damage);
        boss_state.player_hp -= damage;

        // Recursively continue
        dfsBattle(boss_state, best_cost, hard_mode, depth + 1);
    }
}

// TAOCP Vol. 4: Game state simulation - wrapper for DFS
fn simulateBattle(allocator: std.mem.Allocator, initial_state: GameState, hard_mode: bool) !?i32 {
    _ = allocator; // Mark as used
    var best_cost: ?i32 = null;

    std.debug.print("Starting DFS search (hard mode: {})\n", .{hard_mode});

    dfsBattle(initial_state, &best_cost, hard_mode, 0);

    if (best_cost) |cost| {
        std.debug.print("WINNING SEQUENCE FOUND: {}\n", .{cost});
    } else {
        std.debug.print("NO WINNING SEQUENCE FOUND\n", .{});
    }

    return best_cost;
}

// TAOCP Vol. 2: Information structures - find minimum mana to win
fn findMinManaToWin(allocator: std.mem.Allocator, input: []const u8, hard_mode: bool) !?[]const u8 {
    const boss_stats = try parseBossStats(input);

    const initial_state = GameState{
        .player_hp = 50,
        .player_mana = 500,
        .player_armor = 0,
        .boss_hp = boss_stats.hp,
        .boss_damage = boss_stats.damage,
        .shield_timer = 0,
        .poison_timer = 0,
        .recharge_timer = 0,
        .total_mana_spent = 0,
        .turn = .player,
    };

    const result = try simulateBattle(allocator, initial_state, hard_mode);

    if (result) |cost| {
        return try std.fmt.allocPrint(allocator, "{}", .{cost});
    } else {
        return null;
    }
}

pub fn part1(input: []const u8) !?[]const u8 {
    const gpa = std.heap.page_allocator;
    return try findMinManaToWin(gpa, input, false);
}

pub fn part2(input: []const u8) !?[]const u8 {
    const gpa = std.heap.page_allocator;
    return try findMinManaToWin(gpa, input, true);
}

// Test basic spell mechanics
test "spell costs validation" {
    const state = GameState{
        .player_hp = 10,
        .player_mana = 100,
        .player_armor = 0,
        .boss_hp = 13,
        .boss_damage = 8,
        .shield_timer = 0,
        .poison_timer = 0,
        .recharge_timer = 0,
        .total_mana_spent = 0,
        .turn = .player,
    };

    // Should be able to cast magic missile
    const mm_spell = Spell{ .spell_type = .magic_missile, .mana_cost = 53 };
    try std.testing.expect(canCastSpell(state, mm_spell));

    // Should not be able to cast recharge if not enough mana
    const recharge_spell = Spell{ .spell_type = .recharge, .mana_cost = 229 };
    try std.testing.expect(!canCastSpell(state, recharge_spell));
}

test "effect application" {
    var state = GameState{
        .player_hp = 50,
        .player_mana = 500,
        .player_armor = 0,
        .boss_hp = 55,
        .boss_damage = 8,
        .shield_timer = 2,
        .poison_timer = 1,
        .recharge_timer = 3,
        .total_mana_spent = 0,
        .turn = .player,
    };

    applyEffects(&state);

    try std.testing.expectEqual(@as(i32, 1), state.shield_timer);
    try std.testing.expectEqual(@as(i32, 7), state.player_armor);
    try std.testing.expectEqual(@as(i32, 0), state.poison_timer);
    try std.testing.expectEqual(@as(i32, 52), state.boss_hp); // 55 - 3 poison damage
    try std.testing.expectEqual(@as(i32, 2), state.recharge_timer);
    try std.testing.expectEqual(@as(i32, 601), state.player_mana); // 500 + 101
}

test "boss stats parsing" {
    const input =
        \\Hit Points: 55
        \\Damage: 8
    ;

    const stats = try parseBossStats(input);
    try std.testing.expectEqual(@as(i32, 55), stats.hp);
    try std.testing.expectEqual(@as(i32, 8), stats.damage);
}

test "spell casting" {
    var state = GameState{
        .player_hp = 50,
        .player_mana = 500,
        .player_armor = 0,
        .boss_hp = 55,
        .boss_damage = 8,
        .shield_timer = 0,
        .poison_timer = 0,
        .recharge_timer = 0,
        .total_mana_spent = 0,
        .turn = .player,
    };

    const mm_spell = Spell{ .spell_type = .magic_missile, .mana_cost = 53 };
    castSpell(&state, mm_spell);

    try std.testing.expectEqual(@as(i32, 447), state.player_mana); // 500 - 53
    try std.testing.expectEqual(@as(i32, 51), state.boss_hp); // 55 - 4
    try std.testing.expectEqual(@as(i32, 53), state.total_mana_spent);

    const drain_spell = Spell{ .spell_type = .drain, .mana_cost = 73 };
    castSpell(&state, drain_spell);

    try std.testing.expectEqual(@as(i32, 374), state.player_mana); // 447 - 73
    try std.testing.expectEqual(@as(i32, 49), state.boss_hp); // 51 - 2
    try std.testing.expectEqual(@as(i32, 52), state.player_hp); // 50 + 2
    try std.testing.expectEqual(@as(i32, 126), state.total_mana_spent); // 53 + 73
}

test "boss damage calculation" {
    const state1 = GameState{
        .player_hp = 50,
        .player_mana = 500,
        .player_armor = 7, // Shield active
        .boss_hp = 55,
        .boss_damage = 8,
        .shield_timer = 0,
        .poison_timer = 0,
        .recharge_timer = 0,
        .total_mana_spent = 0,
        .turn = .player,
    };

    // 8 damage - 7 armor = 1 damage
    try std.testing.expectEqual(@as(i32, 1), state1.calculateBossDamage(8));

    const state2 = GameState{
        .player_hp = 50,
        .player_mana = 500,
        .player_armor = 0, // No shield
        .boss_hp = 55,
        .boss_damage = 8,
        .shield_timer = 0,
        .poison_timer = 0,
        .recharge_timer = 0,
        .total_mana_spent = 0,
        .turn = .player,
    };

    // 8 damage - 0 armor = 8 damage
    try std.testing.expectEqual(@as(i32, 8), state2.calculateBossDamage(8));

    // Even with high armor, minimum damage is 1
    const state3 = GameState{
        .player_hp = 50,
        .player_mana = 500,
        .player_armor = 10, // High armor
        .boss_hp = 55,
        .boss_damage = 8,
        .shield_timer = 0,
        .poison_timer = 0,
        .recharge_timer = 0,
        .total_mana_spent = 0,
        .turn = .player,
    };

    // 8 damage - 10 armor = -2, but minimum is 1
    try std.testing.expectEqual(@as(i32, 1), state3.calculateBossDamage(8));
}

test "duplicate spell prevention" {
    const state = GameState{
        .player_hp = 50,
        .player_mana = 500,
        .player_armor = 0,
        .boss_hp = 55,
        .boss_damage = 8,
        .shield_timer = 3, // Shield already active
        .poison_timer = 0,
        .recharge_timer = 2, // Recharge already active
        .total_mana_spent = 0,
        .turn = .player,
    };

    const shield_spell = Spell{ .spell_type = .shield, .mana_cost = 113 };
    const recharge_spell = Spell{ .spell_type = .recharge, .mana_cost = 229 };
    const poison_spell = Spell{ .spell_type = .poison, .mana_cost = 173 };
    const mm_spell = Spell{ .spell_type = .magic_missile, .mana_cost = 53 };

    try std.testing.expect(!canCastSpell(state, shield_spell)); // Shield already active
    try std.testing.expect(!canCastSpell(state, recharge_spell)); // Recharge already active
    try std.testing.expect(canCastSpell(state, poison_spell)); // Poison not active
    try std.testing.expect(canCastSpell(state, mm_spell)); // Instant spell always allowed
}
