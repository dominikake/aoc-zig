# Day 3 Learning Guide: Perfectly Spherical Houses in a Vacuum

## Problem Overview

Santa delivers presents to houses on a 2D infinite grid following navigation instructions (`^`, `v`, `>`, `<`). Part 1 tracks unique houses visited by Santa alone. Part 2 introduces Robo-Santa, with both alternating moves starting from the same location.

**Results:**
- Part 1: 2081 unique houses visited by Santa
- Part 2: 2341 unique houses visited by Santa + Robo-Santa

## TAOCP Concepts Applied

### 1. Abstract Data Types and Set Operations
**TAOCP Reference**: Volume 1, Section 2.2.2 - "Abstract Data Types"
- **Set as ADT**: Implemented `HouseSet` struct with insert and cardinality operations
- **Hash Table Implementation**: O(1) average case insertion vs O(n) linear search
- **Collision Resolution**: Uses Zig's built-in chaining hash table implementation

**Learning**: Sets are fundamental ADTs where hash tables provide optimal performance for membership testing and insertion compared to array-based approaches.

### 2. Hash Function Design
**TAOCP Reference**: Volume 3, Section 6.4 - "Hashing"
- **Multiplicative Hash Function**: `result = result * 31 + coordinate_bitcast`
- **Uniform Distribution**: Simple but effective for coordinate pairs
- **Handling Negative Values**: Bit casting preserves sign information in hash space

**Learning**: Hash functions must uniformly distribute keys across hash space while handling all possible input values, including negative coordinates.

### 3. Coordinate Systems and Vector Arithmetic
**TAOCP Reference**: Volume 1, Section 1.2.1 - "Mathematical Preliminaries"
- **2D Coordinate System**: Cartesian coordinates for grid navigation
- **Vector Addition**: Position updates via `(x, y) + (dx, dy)`
- **Direction Vectors**: Fixed unit vectors for cardinal directions

**Learning**: Computational geometry relies on efficient coordinate representation and vector operations for spatial problems.

### 4. Algorithmic Complexity Analysis
**TAOCP Reference**: Volume 1, Section 1.3 - "Mathematical Foundations"
- **Part 1 Complexity**: O(n) time, O(k) space where k = unique houses
- **Part 2 Complexity**: Same complexity with alternating simulation
- **Space-Time Trade-off**: Hash table uses more memory for O(1) lookups

**Learning**: Algorithm analysis must consider both time and space complexity, choosing appropriate data structures for optimal performance.

## Programming Concepts

### 1. Hash Maps and Custom Key Types
- **Custom Hash Function**: Implemented `Coordinate` with custom `hash()` and `eql()` methods
- **Context Pattern**: Used `CoordinateContext` for automatic hash computation
- **Memory Management**: Proper initialization and cleanup of hash table

### 2. Simulation and State Management
- **Iterative State Updates**: Position tracking through instruction sequence
- **Multiple Entities**: Managing Santa and Robo-Santa positions separately
- **Side Effect Modeling**: House visitation as set insertion operation

### 3. Set Operations in Practice
- **Union Operation**: Part 2 naturally creates union of two visitation sets
- **Uniqueness Enforcement**: Hash table guarantees unique house counting
- **Cardinality**: Set size represents unique houses with presents

## Zig-Specific Concepts

### 1. HashMap with Custom Context
```zig
const CoordinateContext = struct {
    pub fn hash(_: CoordinateContext, key: Coordinate) u64 {
        return key.hash();
    }
    
    pub fn eql(_: CoordinateContext, key_a: Coordinate, key_b: Coordinate) bool {
        return key_a.eql(key_b);
    }
};
```

**Learning**: Zig's context pattern allows custom hash and equality functions without modifying the key type itself.

### 2. Struct Methods and Memory Safety
- **Method Syntax**: `coord.hash()` and `coord.eql(other)` for natural API
- **Allocator Management**: Proper init/deinit pattern for dynamic structures
- **Error Handling**: `try` for hash table insertions that may allocate

### 3. Type System for Domain Modeling
- **Custom Coordinate Type**: Strongly-typed `(x, y)` pairs vs generic tuples
- **Direction as Struct**: Type-safe direction representation
- **Optional Fields**: House struct with extensible 10-field design

## Key Insights

1. **Hash Tables vs Linear Search**: The optimization from O(n²) to O(n) demonstrates why algorithmic complexity matters in practice.

2. **Set Abstraction**: Modeling "unique houses visited" as a set provides conceptual clarity and optimal implementation.

3. **Coordinate Hashing**: Effective hash functions can be simple while handling edge cases like negative values.

4. **Simulation Patterns**: Multiple-entity simulations follow the same pattern as single-entity, with state tracking per entity.

## Learning Exercises

### Basic
1. Implement a HashSet using only arrays (no HashMap). Compare performance.
2. Modify the hash function to use different multipliers (31, 37, 101). Analyze collision rates.
3. Add house visitation counting to track how many times each house is visited.

### Intermediate
1. Implement both linear array and hash table versions. Benchmark with large inputs.
2. Create a 3D version of the problem with an additional z-axis.
3. Add diagonal movement directions (NE, NW, SE, SW) and analyze the complexity impact.

### Advanced
1. Implement different collision resolution strategies (open addressing with linear/quadratic probing).
2. Create a memory-efficient version using a single 64-bit integer as hash key (bit-packing coordinates).
3. Design a sparse matrix representation for the grid to handle extremely large coordinate ranges.

### Mathematical
1. Prove that the current hash function distributes coordinates uniformly for bounded ranges.
2. Calculate theoretical collision probability for different hash functions.
3. Analyze the expected number of unique houses after n random moves in an infinite grid.

## Further Reading

- TAOCP Volume 1: Section 2.2.2 (Abstract Data Types)
- TAOCP Volume 3: Section 6.4 (Hashing)
- "Introduction to Algorithms" (CLRS): Chapter 11 (Hash Tables)
- "The Art of Computer Programming" by Donald Knuth: Sections on random access and sequential access

## Practical Applications

The concepts demonstrated here apply to:
- **GPS tracking**: Recording unique locations visited
- **Game development**: Grid-based movement and exploration tracking
- **Network routing**: Path tracking and unique node visitation
- **Data analysis**: Unique item counting and set operations
- **Spatial databases**: Point indexing and range queries