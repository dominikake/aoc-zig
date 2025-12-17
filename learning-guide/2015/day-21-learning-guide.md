# Day 21 Learning Guide

## Problem Breakdown
### Part 1: Find minimum equipment cost to guarantee victory against boss
### Part 2: Find maximum equipment cost that still results in defeat

## TAOCP Concepts Applied
- Brute-force enumeration (Vol. 4A, Section 7.2.1.3)
- Cartesian product generation for equipment combinations
- Turn-based combat simulation
- Min/max optimization over enumerated search space

## Programming Concepts
- Game state management with Player struct
- Equipment data structure design
- Loop control for combat rounds
- Filtering and aggregation over valid outcomes

## Zig-Specific Concepts
- Struct definitions (Player, Item)
- Built-in functions (@max) for damage calculation
- Array constants for shop items
- Error handling with try/catch

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