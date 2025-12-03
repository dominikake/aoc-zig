# Agent Guidelines

## Build Commands
- `zig build` - Build project
- `zig build test` - Run all tests
- `zig build run` - Run the application
- `zig build solve -Dday=N -Dyear=YYYY` - Run specific day solution
- `zig build solve -Dday=N -Dyear=YYYY -Dpart=1|2|both` - Run specific part
- `zig fmt` - Format all Zig files
- `./fetch.sh YYYY DAY` - Download AoC input and create solution template
- `./fetch.sh YYYY DAY --force` - Re-download input and update solution template
- `./fetch.sh YYYY DAY --puzzle` - Only fetch puzzle description
- `./submit.sh YYYY DAY LEVEL ANSWER` - Submit answer for specific part

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

### Advent of Code
- Each day in separate file: `YYYY/day_01.zig`, `YYYY/day_02.zig`, etc.
- Solution functions: `pub fn part1(input: []const u8) !?[]const u8` and `pub fn part2(input: []const u8) !?[]const u8`
- Input files in `input/YYYY/dayDD.txt` format
- Functions accept mutable byte slice, can return any printable type or error union

### Input Fetching
- Create session cookie at `~/.config/aoc/session.cookie` with AoC session token
- Session cookie available from browser developer tools on adventofcode.com

### Answer Submission
- `./submit.sh YYYY DAY LEVEL ANSWER` - Submit answer with confirmation prompt
- Answers are cached to prevent duplicate submissions
- Rate limiting: 1 submission/minute, 5/day per AoC rules
- Successful submissions are cached in `~/.cache/aoc/`
- Use `--force` with fetch.sh to update puzzle descriptions after part 1 completion

### Safety Guidelines
- Always test solutions locally before submitting
- Submissions are rate-limited by Advent of Code servers
- Incorrect answers may provide hints in the response
- Successful submissions unlock the next part of the puzzle
- Cache prevents accidental duplicate submissions