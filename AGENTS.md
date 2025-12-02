# Agent Guidelines

## Build Commands

### Advent of Code Template
- `zig build solve -Dday=5 -Dyear=2023` - Run single day solution
- `zig build solve -Dday=1..5` - Run range of days
- `zig build solve -Dday=..25` - Run all days
- `zig build test -Dday=5` - Run tests for specific day
- Build options: `-Dtimer=true` (default), `-Dcolor=true` (default), `-Dfail-stop=false`, `-Dpart=both`
- `./fetch.sh 2023 5` - Download input for day 5, 2023
- `zig fmt` - Format all Zig files
- `zig build` - Build project with custom runner

## Code Style Guidelines

### Zig
- Use snake_case for variables and functions
- Use PascalCase for types and structs
- Use UPPER_SNAKE_CASE for constants
- 4-space indentation, no tabs
- Prefer `const` over `var` when possible
- Use explicit error handling with `try`, `catch`, or `if`
- Function documentation comments start with `///`
- Import statements at top of file, grouped by standard library then third-party

### Directory Structure
```
build.zig
fetch.sh
input/
    2023/
        day01.txt
        day02.txt
        ...
2023/
    day_01.zig
    day_02.zig
    ...
```

### Advent of Code
- Each day in separate file: `2023/day_01.zig`, `2023/day_02.zig`, etc.
- Solution functions: `pub fn part1(input: []const u8) !?[]const u8` and `pub fn part2(input: []const u8) !?[]const u8`
- Input files automatically read by build system from `input/YYYY/dayDD.txt`
- Test with sample input from problem description
- Functions accept mutable byte slice, can return any printable type or error union

### Input Fetching
- Create session cookie file at `~/.config/aoc/session.cookie` with Advent of Code session token
- Use `./fetch.sh YYYY DAY` to download input files (e.g., `./fetch.sh 2023 5`)
- Session cookie available from browser developer tools on adventofcode.com