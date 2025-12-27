# Day 04 Learning Guide

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
1. Implement brute-force enumeration for equipment combinations
2. Create turn-based combat simulation
3. Practice struct design for game entities
4. Write min/max optimization functions

## Key Insights
- **Brute-force enumeration**: Systematic testing of all combinations works for small search spaces
- **Cartesian product**: Equipment combinations form nested loops over weapons, armor, rings
- **Combat simulation**: Deterministic turn-based games can be simulated exactly
- **Min/max optimization**: Track both best and worst solutions during enumeration