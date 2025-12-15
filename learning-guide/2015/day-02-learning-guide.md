# Day 02 Learning Guide

## Problem Breakdown
### Part 1: Calculate total wrapping paper needed for boxes with dimensions l×w×h, including surface area plus smallest side area as slack
### Part 2: Complete part 1 first to unlock part 2

## TAOCP Concepts Applied

- Tuple Data Structure - Struct for 3-dimensional geometry representation
- Mathematical Functions - Surface area calculations using arithmetic operations
- Parsing with Delimiters - Extract dimensions from "l×w×h" format using tokenization
- Single-Pass Algorithm - Streaming processing with O(1) additional space
- Min/Max Operations - Efficient smallest side area calculation using @min builtin

## Programming Concepts

- Input parsing and validation
- Error handling patterns
- Streaming algorithms
- Stack-based memory management
- Mathematical surface area calculations

## Zig-Specific Concepts

- Error handling with try/catch
- Pattern matching with switch statements
- Type safety with u64 for overflow protection
- Memory management with allocators
- Built-in functions (@min, @max)
- Comptime features (for future days)

## Learning Exercises

1. Implement a function to calculate volume of rectangular prisms
2. Create a parser that handles different input formats (pipe, numbered, basic)
3. Practice error handling patterns for malformed input
4. Write a function to calculate ribbon length (hint: perimeter of smallest face)
5. Implement a streaming algorithm for other geometric calculations

## Key Insights
- **Tuple Structure**: Using structs for multi-dimensional data improves code clarity
- **Overflow Protection**: u64 types prevent integer overflow with large dimensions
- **Streaming Algorithm**: Single-pass processing is memory efficient and fast
- **Error Resilience**: Skip malformed lines while continuing processing
- **Built-in Efficiency**: @min/@max are more efficient than custom comparisons
- **Input Flexibility**: Handle multiple input formats for robust parsing
