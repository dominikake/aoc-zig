const std = @import("std");

// TAOCP Concept: Fixed-size data structure for ingredient properties
// Each ingredient has 5 properties: capacity, durability, flavor, texture, calories
const Ingredient = struct {
    capacity: i64,
    durability: i64,
    flavor: i64,
    texture: i64,
    calories: i64,
};

// TAOCP Concept: Parsing with structured input format
// Input format: "Sugar: capacity 3, durability 0, flavor 0, texture -3, calories 2"
fn parseIngredient(line: []const u8) !Ingredient {
    var trimmed_line = std.mem.trim(u8, line, " \r\t");
    if (trimmed_line.len == 0) return error.EmptyLine;

    // Extract ingredient name before colon
    const colon_pos = std.mem.indexOfScalar(u8, trimmed_line, ':') orelse return error.InvalidFormat;
    trimmed_line = trimmed_line[colon_pos + 1 ..];
    trimmed_line = std.mem.trim(u8, trimmed_line, " ");

    var ingredient = Ingredient{ .capacity = 0, .durability = 0, .flavor = 0, .texture = 0, .calories = 0 };

    // Parse property-value pairs
    var iter = std.mem.tokenizeScalar(u8, trimmed_line, ',');
    while (iter.next()) |prop_pair| {
        const trimmed_pair = std.mem.trim(u8, prop_pair, " ");
        const space_pos = std.mem.indexOfScalar(u8, trimmed_pair, ' ') orelse return error.InvalidFormat;

        const prop_name = trimmed_pair[0..space_pos];
        const value_str = trimmed_pair[space_pos + 1 ..];
        const value = try std.fmt.parseInt(i64, value_str, 10);

        if (std.mem.eql(u8, prop_name, "capacity")) {
            ingredient.capacity = value;
        } else if (std.mem.eql(u8, prop_name, "durability")) {
            ingredient.durability = value;
        } else if (std.mem.eql(u8, prop_name, "flavor")) {
            ingredient.flavor = value;
        } else if (std.mem.eql(u8, prop_name, "texture")) {
            ingredient.texture = value;
        } else if (std.mem.eql(u8, prop_name, "calories")) {
            ingredient.calories = value;
        }
    }

    return ingredient;
}

// TAOCP Concept: Linear combination with clamping
// Calculate property sum with clamping at zero (negative values become zero)
fn calculateProperty(
    amounts: [4]u64,
    ingredients: [4]Ingredient,
    comptime property: std.meta.FieldEnum(Ingredient),
) i64 {
    var sum: i64 = 0;
    for (amounts, ingredients) |amount, ingredient| {
        const value = @field(ingredient, @tagName(property));
        sum += @as(i64, @intCast(amount)) * value;
    }
    return @max(0, sum); // Clamp negative values to zero
}

// TAOCP Concept: Objective function evaluation
// Cookie score is product of clamped property sums (excluding calories)
fn calculateCookieScore(amounts: [4]u64, ingredients: [4]Ingredient) u64 {
    const capacity = calculateProperty(amounts, ingredients, .capacity);
    const durability = calculateProperty(amounts, ingredients, .durability);
    const flavor = calculateProperty(amounts, ingredients, .flavor);
    const texture = calculateProperty(amounts, ingredients, .texture);

    // Product of all properties (u64 to prevent overflow)
    return @as(u64, @intCast(capacity)) *
        @as(u64, @intCast(durability)) *
        @as(u64, @intCast(flavor)) *
        @as(u64, @intCast(texture));
}

// TAOCP Concept: Calorie calculation for Part 2 constraint
fn calculateCalories(amounts: [4]u64, ingredients: [4]Ingredient) i64 {
    return calculateProperty(amounts, ingredients, .calories);
}

pub fn part1(input: []const u8) !?[]const u8 {
    // TAOCP: Parse ingredients into fixed-size array
    var ingredients: [4]Ingredient = undefined;
    var ingredient_count: usize = 0;

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        if (line.len == 0) continue;

        if (ingredient_count >= 4) return error.TooManyIngredients;
        ingredients[ingredient_count] = try parseIngredient(line);
        ingredient_count += 1;
    }

    if (ingredient_count != 4) return error.IncorrectIngredientCount;

    // TAOCP: Combinatorial search using nested loops (stars and bars)
    // Enumerate all combinations where sum = 100 teaspoons
    var max_score: u64 = 0;

    var i: u64 = 0; // Sugar
    while (i <= 100) : (i += 1) {
        var j: u64 = 0; // Sprinkles
        while (j <= 100 - i) : (j += 1) {
            var k: u64 = 0; // Candy
            while (k <= 100 - i - j) : (k += 1) {
                const l = 100 - i - j - k; // Chocolate (remainder)

                const amounts = [4]u64{ i, j, k, l };
                const score = calculateCookieScore(amounts, ingredients);

                if (score > max_score) {
                    max_score = score;
                }
            }
        }
    }

    const gpa = std.heap.page_allocator;
    const result = try std.fmt.allocPrint(gpa, "{}", .{max_score});
    return result;
}

pub fn part2(input: []const u8) !?[]const u8 {
    // TAOCP: Parse ingredients into fixed-size array
    var ingredients: [4]Ingredient = undefined;
    var ingredient_count: usize = 0;

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        if (line.len == 0) continue;

        if (ingredient_count >= 4) return error.TooManyIngredients;
        ingredients[ingredient_count] = try parseIngredient(line);
        ingredient_count += 1;
    }

    if (ingredient_count != 4) return error.IncorrectIngredientCount;

    // TAOCP: Combinatorial search with additional constraint satisfaction
    // Enumerate all combinations where sum = 100 teaspoons AND calories = 500
    var max_score: u64 = 0;

    var i: u64 = 0; // Sugar
    while (i <= 100) : (i += 1) {
        var j: u64 = 0; // Sprinkles
        while (j <= 100 - i) : (j += 1) {
            var k: u64 = 0; // Candy
            while (k <= 100 - i - j) : (k += 1) {
                const l = 100 - i - j - k; // Chocolate (remainder)

                const amounts = [4]u64{ i, j, k, l };

                // TAOCP: Constraint satisfaction - filter by calorie requirement
                const calories = calculateCalories(amounts, ingredients);
                if (calories != 500) continue;

                const score = calculateCookieScore(amounts, ingredients);

                if (score > max_score) {
                    max_score = score;
                }
            }
        }
    }

    const gpa = std.heap.page_allocator;
    const result = try std.fmt.allocPrint(gpa, "{}", .{max_score});
    return result;
}
