# Day 12 Learning Guide

## Problem Breakdown

### Part 1: Parse JSON document and sum all numbers throughout the entire nested structure, including arrays, objects, and mixed nesting
### Part 2: Same as Part 1, but ignore any object (and all its contents) that has any property with the value "red"

## TAOCP Concepts Applied

- **Tree Traversal Algorithms** (Vol. 1, Section 2.3) - JSON structure maps directly to tree data structures with arrays as branches and objects as nodes
- **Recursive Processing** (Vol. 1, Section 2.2.1) - Natural fit for processing nested JSON structures using depth-first traversal
- **Linked Allocation** (Vol. 1, Section 2.2.1) - Dynamic JSON parsing uses memory allocation patterns similar to linked structures
- **Pattern Matching** (Vol. 3, Section 6.4) - String value detection for "red" in Part 2 using pattern matching
- **Arithmetic Aggregation** (Vol. 2, Section 4.6.1) - Summation over leaf nodes in tree structure
- **Conditional Pruning** (Vol. 1, Section 2.3.1) - Early termination of subtree traversal when "red" condition is met

## Programming Concepts

- **Recursive Tree Traversal** - Post-order traversal (process children before parent) for aggregation
- **Memory Management** - Arena allocation for efficient cleanup of parsed JSON structures
- **Type Pattern Matching** - Switch statements to handle different JSON value types
- **Error Handling** - Graceful handling of malformed JSON and parsing errors
- **Tree Data Structures** - Mapping JSON to abstract tree representation
- **String Processing** - Comparison operations for value matching

## Zig-Specific Concepts

- **std.json.parseFromSlice** - JSON parsing with automatic memory management
- **ArenaAllocator** - Single-deallocation memory management for complex structures
- **Tagged Unions** - Type-safe pattern matching on std.json.Value
- **Error Union Types** - Comprehensive error handling with try/catch
- **Switch Statement Exhaustiveness** - Compiler-enforced handling of all JSON value types
- **Memory Safety** - Automatic cleanup with defer statements

## Learning Exercises

1. Implement a binary tree traversal function that sums all leaf values
2. Create a recursive XML parser that extracts all numeric values
3. Write a function to find the maximum depth of a nested structure
4. Practice memory management by implementing a simple tree allocator
5. Build a pattern matching system for different data type structures

## Key Insights

- **Tree Abstraction**: JSON structure naturally maps to tree algorithms - objects are nodes, arrays are branches, values are leaves
- **Recursive Design**: Depth-first traversal is the most natural way to process nested data structures
- **Memory Efficiency**: Arena allocation provides simple cleanup for complex parsing operations
- **Type Safety**: Tagged unions and exhaustive switches ensure all cases are handled
- **Conditional Logic**: Part 2 demonstrates how pruning can optimize tree traversal by skipping entire subtrees
- **JSON Parsing**: Standard library provides robust parsing tools with proper error handling
- **Pattern Matching**: String comparison operations enable flexible filtering conditions