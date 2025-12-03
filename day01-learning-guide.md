# Advent of Code 2025 Day 1 - Learning Guide

## Getting Session Cookie

To download your personal puzzle input, you need an Advent of Code session cookie:

### Method 1: Browser Developer Tools
1. **Log in to adventofcode.com** (GitHub, Google, Twitter, or Reddit)
2. **Open developer tools** (F12 or Ctrl+Shift+I)
3. **Go to Network tab** and refresh the page
4. **Find any request to adventofcode.com** and inspect Request Headers
5. **Copy the `session` cookie value** (long hex string starting with `53616c7465645f5f`)

### Method 2: Application/Storage Tab
1. **Open developer tools** (F12)
2. **Go to Application tab** → Storage → Cookies → adventofcode.com
3. **Find the `session` cookie** and copy its value

### Setup
Create/edit the file `~/.config/aoc/session.cookie` with just the cookie value:
```bash
mkdir -p ~/.config/aoc
echo "53616c7465645f5f..." > ~/.config/aoc/session.cookie
```

Then fetch your input:
```bash
./fetch.sh 2025 1
```

## Problem Analysis

### What This Problem Is Really About
**Simulating circular arithmetic and counting specific states during state transitions.**

At its core: *move a pointer around a circle of 100 positions and count how many times it lands on position 0.*

## Learning Concepts

### TAOCP Concepts
- **Circular Arithmetic**: Working with numbers that wrap around (modular arithmetic)
- **State Machines**: Current state (dial position) + transitions (rotations) = new state
- **Ring Data Structures**: The dial is essentially a ring buffer of 100 elements
- **Algorithm Analysis**: Time complexity O(n) where n = number of rotations

### Programming Concepts
- **Modular Arithmetic**: `(position + offset) % 100` for circular behavior
- **Parsing**: Extracting direction and magnitude from strings like "L68", "R48"
- **State Simulation**: Maintaining and updating state through iterations
- **Error Handling**: Dealing with invalid input gracefully

### Zig-Specific Concepts
- **Memory Management**: Line-by-line vs. all-at-once processing
- **Error Unions**: Handling parsing errors with `!` syntax
- **Integer Types**: Choosing `u8` vs `u32` for dial positions (0-99 fits in `u8`)
- **String Manipulation**: Working with `[]const u8` for input parsing

## Socratic Programming Guidance

### Parsing Strategy
Have you thought about:
- How to efficiently extract direction from the first character?
- Whether to use `std.fmt.parseInt()` or manual parsing for the number?
- What happens if the input contains invalid characters?

### State Management
Have you thought about:
- Should the dial position be `var` or `const`?
- How to handle negative positions when rotating left?
- Whether to count position 0 before or after each rotation?

### Algorithm Design
Have you thought about:
- Can you solve this without simulating every rotation?
- What's the minimum information needed to count zeros?
- How would this change if the dial had 1000 positions instead of 100?

### Performance Considerations
Have you thought about:
- Memory allocation patterns for large inputs?
- Whether bounds checking is necessary for modulo operations?
- How to optimize for cache locality?

## Implementation Hints

### Core Logic Structure
```zig
var position: u8 = 50;  // Starting position
var zero_count: u32 = 0;

// For each rotation:
// 1. Parse direction and distance
// 2. Apply rotation with modulo arithmetic
// 3. Check if new position is 0
// 4. Update zero count if needed
```

### Key Zig Features to Explore
- `std.mem.tokenize()` for splitting input into lines
- `std.fmt.parseInt()` for parsing numbers
- Error handling with `try` and `catch`
- Integer overflow protection with wrapping operations

## Testing Strategy
- Test with the example input first
- Verify edge cases: L1 from position 0, R1 from position 99
- Consider performance with large input files
- Test error handling with malformed input

Remember: The goal is learning, not just the answer. Focus on understanding *why* each approach works!