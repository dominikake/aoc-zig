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
- `./submit.sh YYYY DAY LEVEL ANSWER --force` - Non-interactive submission (for automation)

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

## Learning Guide System

### Overview
Automatically generates educational learning guides after successful AoC submissions, focusing on TAOCP concepts, programming principles, and Zig-specific features.

### Directory Structure
```
learning-guide/
├── agents/
│   ├── learning-guide-agent.zig    # Core agent logic
│   └── main.zig                # CLI interface
├── templates/
│   └── day-template.md           # Template for new guides
├── 2025/
│   └── day-01-learning-guide.md  # Generated guides
├── build.zig                    # Build system integration
└── README.md                    # System documentation
```

### Usage Commands
```bash
# Build learning guide system
zig build learning-guide

# Update learning guide manually
./.zig-cache/o/*/learning-guide-agent <year> <day> <solution_file>

# Update using integration script
./update-learning-guide.sh <year> <day> <solution_file>
```

### Integration with AoC Workflow
The agent system follows a structured workflow for each part:
1. **Solve Problem**: Implement solution using TAOCP concepts
2. **Test Solution**: Verify solution works correctly with sample and custom tests
3. **Submit Answer**: Use `submit.sh` script if tests pass
4. **Generate Guide**: Run `./update-learning-guide.sh` after successful submission
5. **Commit Changes**: Git commit all changes (solution, learning guide, etc.)
6. **Review Learning**: Study concepts and exercises
7. **Progress to Part 2**: Repeat workflow for Part 2 (if available)

### Workflow Sequence Enforcement
- **Single Part**: test → submit → learning guide → commit
- **Full Workflow**: Part 1 (test → submit → learning guide → commit) → Part 2 (test → submit → learning guide → commit)
- **Checkpoint System**: Saves state after each major step for recovery
- **Error Handling**: Stops workflow on failures with detailed recovery suggestions

### Learning Guide Components
Each generated guide includes:
- **Problem Breakdown**: High-level understanding of each part
- **TAOCP Concepts**: Mathematical and algorithmic principles applied
- **Programming Concepts**: General computer science concepts
- **Zig-Specific Concepts**: Language features and syntax
- **Learning Exercises**: Practice problems for reinforcement
- **Key Insights**: Important takeaways and patterns

### Educational Philosophy
- **Learning Over Answers**: Focus on concepts, not solutions
- **Progressive Complexity**: Build from simple to advanced
- **Practical Application**: Real-world programming techniques
- **Cross-Reference**: Connect concepts across days

### GH-Grep

If you are unsure how to do something, use `gh_grep` to search code examples from github.

### search

When you need to search docs, use `context7` tools.
