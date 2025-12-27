# Day 06 Learning Guide: Signals and Noise

## Problem Breakdown
### Part 1: Decode error-corrected message by finding the most frequent character at each position across repeated transmissions
### Part 2: Decode original message by finding the least frequent character at each position (modified repetition code)

## TAOCP Concepts Applied
- **Volume 3, Section 5.2.1 (Counting Sort)**: Using fixed-size arrays (26 counters) for O(n) frequency counting per column
- **Volume 2, Section 4.6.3 (Frequency Counts)**: Building histograms for each column position by counting character occurrences
- **Volume 4, Section 1.1 (Data Transposition)**: Switching from row-major (messages) to column-major (positions) processing
- **Volume 1, Section 1.3.3 (Arrays and Tables)**: Direct table lookup using character-to-index mapping (char - 'a')

## Programming Concepts
- **Frequency histograms**: Array-based counting for fixed small domains (radix-like counting)
- **Argmax/argmin selection**: Finding index with maximum/minimum value from count arrays
- **Column-major processing**: Treating input as 2D array where we aggregate statistics per column
- **Data validation**: Bounds checking to ensure only valid lowercase letters are processed

## Zig-Specific Concepts
- **Fixed-size arrays**: `[26]u32` for letter frequency counters, stack-allocated without allocators
- **`std.mem.splitScalar`**: Efficient line-by-line input parsing with minimal allocation
- **Direct array indexing**: `counts[char - 'a']` for O(1) frequency updates
- **`std.mem.zeroes`**: Zero-initialization of count arrays
- **`@intCast`**: Safe type conversion for character arithmetic
- **Range checking**: `if (char >= 'a' and char <= 'z')` to prevent invalid memory access

## Learning Exercises
1. Implement a frequency counter for uppercase letters (A-Z, 26 counters)
2. Modify solution to find the second most/least frequent character per position
3. Implement tie-breaking rules (e.g., alphabetical order for equal frequencies)
4. Optimize for very long messages using streaming counts (no line buffer)
5. Extend to handle Unicode or multi-byte character encoding

## Key Insights
- **Counting sort principles**: When domain is small and fixed (26 letters), direct array indexing beats hash maps
- **O(n) complexity**: Single pass through all lines per column achieves optimal performance
- **Space-time tradeoff**: Trading O(26) extra space per column for O(n) time is always worthwhile
- **Column vs row processing**: Problem naturally lends itself to column-wise aggregation (vertical thinking)
- **Safety first**: Bounds checking on character values prevents integer overflow and out-of-bounds access