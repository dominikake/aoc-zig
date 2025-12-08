# Advent of Code Zig Template

A simple Zig template for solving Advent of Code puzzles with automated input fetching and answer submission.

## Quick Start

```bash
# Fetch puzzle input and create solution template
./fetch.sh 2025 1

# Solve the puzzle
zig build solve -Dday=1 -Dyear=2025

# Submit your answer
./submit.sh 2025 1 1 "your_answer_here"
```

## Project Structure

```
aoc-zig/
├── src/                    # Core application files
│   ├── main.zig           # Main entry point
│   ├── aoc_runner.zig     # Solution runner
│   └── root.zig           # Module exports
├── 2025/                   # Year-specific solutions
│   └── day_01.zig         # Day 1 solution
├── input/                  # Puzzle inputs
│   └── 2025/
│       └── day01.txt      # Day 1 input
├── fetch.sh               # Download inputs and create templates
├── submit.sh              # Submit answers to AoC
└── build.zig              # Build configuration
```

## Commands

### Building and Running

```bash
# Build the project
zig build

# Run tests
zig build test

# Run specific day solution
zig build solve -Dday=N -Dyear=YYYY

# Run specific part only
zig build solve -Dday=N -Dyear=YYYY -Dpart=1
zig build solve -Dday=N -Dyear=YYYY -Dpart=2
```

### Input Fetching

```bash
# Download input and create solution template
./fetch.sh 2025 1

# Force re-download (overwrites existing files)
./fetch.sh 2025 1 --force

# Only fetch puzzle description
./fetch.sh 2025 1 --puzzle
```

### Answer Submission

```bash
# Submit answer for part 1
./submit.sh 2025 1 1 "your_answer"

# Submit answer for part 2  
./submit.sh 2025 1 2 "your_answer"
```

## Solution Template

Each day follows this structure:

```zig
pub fn part1(input: []const u8) !?[]const u8 {
    _ = input;
    // TODO: Implement part 1 solution
    return null;
}

pub fn part2(input: []const u8) !?[]const u8 {
    _ = input;
    // TODO: Implement part 2 solution
    return null;
}

const std = @import("std");
```

## Setup

1. **Session Cookie**: Create `~/.config/aoc/session.cookie` with your Advent of Code session token
   - Get token from browser dev tools on adventofcode.com
   - Network tab → Find any request → Copy `session` cookie value

2. **Zig**: Install Zig (0.11.0 or later recommended)

## Features

- ✅ Automated input downloading
- ✅ Solution template generation  
- ✅ Answer submission with confirmation
- ✅ Submission caching (prevents duplicates)
- ✅ Rate limiting awareness
- ✅ Part 2 unlock detection
- ✅ Build system integration

## License

MIT License - see [LICENSE](LICENSE) file for details.