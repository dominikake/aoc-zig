# Advent of Code - Zig Template

A streamlined Zig template for solving Advent of Code puzzles with automated workflow.

## Quick Start

```bash
// Create session cookie file with your AoC session token
mkdir -p ~/.config/aoc && echo "your_session_token" > ~/.config/aoc/session.cookie

// Download input and auto-create solution file for a specific day
./fetch.sh 2025 1

// Edit your solution in the created file
// 2025/day_01.zig now has part1() and part2() functions ready

// Run your solution for the day
zig build solve -Dday=1 -Dyear=2025

// Run tests for the day
zig build test -Dday=1 -Dyear=2025

// Format all Zig files
zig fmt
```

## Workflow

1. **Setup**: Create session cookie file once with your Advent of Code session token
2. **Fetch**: Run `./fetch.sh YYYY DAY` to download input and auto-create solution file
3. **Solve**: Edit the generated `YYYY/day_DD.zig` file with your solution logic
4. **Run**: Use `zig build solve` to execute your solution
5. **Test**: Use `zig build test` to run tests

## Part 1 & Part 2 Handling

The build system automatically detects and runs these functions:

```zig
pub fn part1(input: []const u8) !?[]const u8 {
    // Your part 1 solution here
    // Input is automatically read from input/YYYY/dayDD.txt
    // Return any printable type or error union
}

pub fn part2(input: []const u8) !?[]const u8 {
    // Your part 2 solution here
    // Same input as part1 (you can mutate it safely)
    // Return any printable type or error union
}
```

**Key Points:**
- Functions must be `pub` and named exactly `part1` and `part2`
- Input parameter: `[]const u8` (read-only) or `[]u8` (mutable)
- Return: Any printable type, error union, or `![]const u8`
- Build system runs both parts by default
- Use `-Dpart=1`, `-Dpart=2`, or `-Dpart=both` to control which parts run

## Build Commands

```bash
zig build solve -Dday=5 -Dyear=2023    # Run single day
zig build solve -Dday=1..5            # Run range of days  
zig build solve -Dday=..25            # Run all days
zig build test -Dday=5                # Run tests for specific day
zig fmt                               # Format all files
```

## Directory Structure

```
build.zig
fetch.sh
input/
    2025/
        day01.txt
        day02.txt
        ...
2025/
    day_01.zig
    day_02.zig
    ...
```

## Session Cookie Setup

1. Go to [adventofcode.com](https://adventofcode.com) and log in
2. Open browser developer tools (F12)
3. Go to Network tab, refresh the page
4. Find any request to adventofcode.com, look at headers
5. Copy the `session` cookie value
6. Create `~/.config/aoc/session.cookie` with just the cookie value