# Day 01 Learning Guide

## Problem Breakdown
### Part 1: Navigate taxicab geometry grid following turn and walk instructions, calculate Manhattan distance from origin
### Part 2: Find first location visited twice during navigation using step-by-step position tracking

## TAOCP Concepts Applied
- **Finite State Machine** - Four-direction compass states with deterministic transitions
- **Modular Arithmetic** - Circular direction changes using modulo 4 operations  
- **Hash Tables** - O(1) position lookup for duplicate detection (Part 2)
- **Vector Addition** - 2D coordinate manipulation for grid movement
- **Cycle Detection** - Tortoise/hare algorithm pattern for finding revisited locations

## Programming Concepts
- State machines and finite automata
- Coordinate systems and vector mathematics
- Hash-based duplicate detection algorithms
- Sequential processing with state updates
- Input parsing and tokenization
- Algorithm complexity analysis (O(1) vs O(n))

## Zig-Specific Concepts
- **Enum patterns** - Type-safe direction representation
- **Custom hash contexts** - Efficient Position struct hashing  
- **Memory management** - Allocator-aware hash map operations
- **Error handling** - Result types and error propagation
- **Pattern matching** - Switch statements for state transitions
- **Type casting** - Safe integer conversions with @intCast

## Learning Exercises
1. Implement a generic 2D hash grid for spatial indexing
2. Create a finite state machine library in Zig
3. Practice modular arithmetic with different ring sizes
4. Implement Floyd's cycle detection algorithm
5. Build a vector math library for 2D/3D operations

## Key Insights
- **State Machine Design**: Enum with switch provides clean, type-safe state transitions vs arithmetic overflow
- **Hash vs Linear Search**: O(1) duplicate detection essential for Part 2 performance  
- **Step Granularity**: Must track every single step, not just final positions of each instruction
- **Manhattan Distance**: L1 norm for taxicab geometry - simple |x| + |y| calculation
- **Memory Tradeoffs**: Storing all visited positions worth O(n) space for O(n) time complexity

## Implementation Patterns
- **Single Pass Algorithm**: Process instructions sequentially with accumulated state
- **Early Termination**: Return first duplicate found without completing full traversal
- **Modular Functions**: Isolate logic (turn, walk, distance) into testable components
- **Error Resilience**: Validate input format and handle edge cases gracefully

## Complexity Analysis
- **Part 1**: O(n) time, O(1) space - single pass through instructions
- **Part 2**: O(s) time, O(u) space - s=total steps, u=unique positions before duplicate
- **Hash Operations**: O(1) average case lookup/insertion for position tracking