# Day 18 Learning Guide

## Problem Breakdown
### Part 1: Simulate 100x100 grid of lights following Game of Life rules for 100 steps
### Part 2: Part 2 adds permanently lit corners, requiring boundary condition modification

## TAOCP Concepts Applied
- Sequential allocation of arrays (Vol. 1, Section 2.2.2)
- Bounded loops and O(n×steps) simulation complexity
- Neighborhood enumeration on 2D lattice structures

## Programming Concepts
- Cellular automaton simulation with Game of Life rules
- Double buffering pattern for simultaneous updates
- 2D array traversal and neighbor counting algorithms
- Boundary condition handling for finite grids

## Zig-Specific Concepts
- Compile-time constants (GRID_SIZE, STEPS) for generic code
- Stack-allocated multi-dimensional arrays without allocators
- Array swapping for efficient double buffering
- Type casting between isize and usize for bounds checking

## Learning Exercises
1. Implement cellular automaton simulation with different rule sets
2. Create neighbor counting algorithms for various neighborhood shapes
3. Practice double buffering patterns for simultaneous updates
4. Experiment with boundary conditions (wrapping vs. fixed)

## Key Insights
- **Sequential allocation**: TAOCP's array storage patterns enable efficient grid traversal
- **Double buffering**: Essential for simultaneous updates without overwriting state
- **Boundary conditions**: Edge handling is crucial in finite cellular automata
- **O(n×steps)**: Time complexity scales linearly with grid size and simulation steps