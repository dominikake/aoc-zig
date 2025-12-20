# Day 05 Learning Guide

## Problem Breakdown

### Part 1: String classification based on three rules: vowel count (≥3), double letters (consecutive same char), and forbidden substrings (ab, cd, pq, xy). Classify strings as "nice" or "naughty".
### Part 2: Enhanced classification with two new rules: non-overlapping repeated pairs of letters, and sandwich patterns (letter repeats with one char between).

## TAOCP Concepts Applied

- **String Processing Algorithms** (TAOCP Volume 3, Chapter 6): Fundamental sequential search and pattern matching techniques for string analysis
- **Linear-time String Scanning**: O(n) algorithms where n is string length, using single passes over each string for efficiency
- **Basic Pattern Matching**: Brute-force substring search for fixed small patterns (forbidden pairs, double letters) - appropriate when patterns are tiny and strings short
- **Sliding Window Technique**: Overlapping windows of size 2 (pairs) and 3 (sandwich patterns) for local pattern detection
- **Hash Table Applications**: Using string hash maps for O(1) pair lookups to detect non-overlapping repeats efficiently
- **State Tracking**: Maintaining counters and flags during linear traversal to satisfy multiple rule conditions simultaneously
- **Finite-State Machine Mindset**: Rule implementation as sequential state transitions, though explicit loops provide clarity for learning

## Programming Concepts

- **Iterative String Traversal**: Single or multiple passes over strings with indexed access for character-by-character analysis
- **Substring Checking**: Efficient window-based pattern detection with proper bounds checking
- **Hash Map Usage**: Tracking first occurrences of pairs to detect non-overlapping repeats in O(n) time
- **Short-Circuit Evaluation**: Early rule failure detection to optimize processing
- **Streaming Algorithms**: Processing input line-by-line with O(1) additional space
- **Error Handling**: Safe bounds checking and memory management throughout string processing
- **Time Complexity Analysis**: Understanding O(N × L) where N is number of lines, L is average string length

## Zig-Specific Concepts

- **Slice Iteration**: Using `for (s) |c|` and `for (0..s.len) |i|` for indexed character access
- **Comptime Safety**: Defining forbidden substrings as compile-time arrays for efficiency and type safety
- **Memory Management**: Using allocators for dynamic result allocation while keeping core algorithms allocation-free
- **Error Handling**: Proper use of `try` and `catch` for robust input processing
- **HashMap Integration**: `std.StringHashMap(usize)` for efficient pair tracking with position storage
- **Bounds Safety**: Explicit `i + 1 < s.len` checks to prevent undefined behavior
- **Multiple Linear Passes**: Clear, readable approach balancing performance with Zig's explicit memory philosophy

## Learning Exercises

1. Implement a circular buffer pattern detection for overlapping substrings
2. Create a finite-state machine that processes strings with multiple rule sets
3. Practice comptime string processing with different pattern matching strategies
4. Write a function to count all possible substrings of length k in O(n) time
5. Implement a streaming string analyzer that works with very large files

## Key Insights

- **Pattern Matching Strategy**: Simple brute-force is optimal for small fixed patterns; complex algorithms like KMP aren't needed
- **Linear Pass Philosophy**: Multiple clear passes are better than one complex pass for learning and maintenance
- **Hash Map Power**: Transforming non-overlapping detection from O(n²) to O(n) through intelligent use of hash tables
- **Safety First**: Explicit bounds checking prevents undefined behavior while maintaining performance
- **Memory Efficiency**: Core algorithms can work without allocations, only results need dynamic memory
- **Educational Balance**: Clear, explicit code teaches TAOCP fundamentals better than highly optimized but obscure solutions