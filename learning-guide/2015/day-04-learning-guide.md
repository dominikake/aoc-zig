# Advent of Code 2015 Day 4 - Learning Guide

## Problem Breakdown

**Part 1**: Find the lowest positive integer that, when appended to a secret key and MD5 hashed, produces a hash starting with at least five zeroes (`00000...`).

**Part 2**: Find the lowest positive integer that produces a hash starting with at least six zeroes (`000000...`).

This is essentially a proof-of-work mining problem similar to Bitcoin, where we need to find a nonce (number) that satisfies a specific hash condition.

## TAOCP Concepts Applied

### Volume 1 - Fundamental Algorithms
- **Exhaustive Search**: Implemented as a linear scan through integers 1, 2, 3, ... until finding the solution
- **Basic Operations**: String concatenation, MD5 hashing, and comparison in a tight loop
- **Algorithm Analysis**: The problem demonstrates O(n) complexity where n is the solution number

### Volume 2 - Seminumerical Algorithms  
- **Number Generation**: Sequential integer generation for combinatorial search
- **Arithmetic Operations**: Efficient integer-to-string conversion and concatenation
- **Random Access vs Sequential**: Uses sequential access pattern optimal for this proof-of-work problem

### Volume 3 - Searching and Sorting
- **Hash Functions**: MD5 as a cryptographic hash function for uniform distribution
- **Search Termination**: Early exit conditions based on hash prefix checking
- **Search Space**: Infinite theoretical space, practical bounds based on puzzle constraints

### Volume 4A - Combinatorial Algorithms
- **Combinatorial Generation**: Systematic generation of candidate numbers in order
- **Backtracking**: Not applicable here as we always move forward (no need to backtrack)
- **Constraint Satisfaction**: Finding values that satisfy the zero-prefix constraint

## Programming Concepts

### Cryptographic Hashing
- **MD5**: 128-bit cryptographic hash function (though broken for security, still useful for puzzles)
- **Deterministic**: Same input always produces same output
- **Avalanche Effect**: Small input changes produce dramatically different outputs
- **Uniform Distribution**: Hash outputs appear randomly distributed

### Brute Force Optimization
- **Early Termination**: Check only necessary bytes of hash (first 2-3 bytes for 5-6 zeros)
- **Memory Efficiency**: Use stack-allocated buffers instead of heap allocations
- **Loop Optimization**: Minimize operations per iteration in the hot loop
- **Cache Efficiency**: Work with data that fits in CPU cache

### String Operations
- **Buffer Management**: Fixed-size buffers prevent allocations in hot path
- **Concatenation**: Efficiently combine secret key with numbers
- **Number Formatting**: Convert integers to decimal strings without allocations

## Zig-Specific Concepts

### Memory Management
- **Stack Allocation**: `var buffer: [64]u8 = undefined;` for temporary storage
- **Zero-Allocation Hashing**: `std.crypto.hash.Md5.hash()` with fixed digest buffer
- **Compile-Time Known Sizes**: Arrays with known sizes for optimal performance

### Performance Features
- **@memcpy**: Efficient memory copying operation
- **Built-in Functions**: `@min`, `@max` for efficient comparisons
- **Compile-Time Safety**: Strong typing prevents many runtime errors

### Standard Library Usage
- **std.crypto.hash.Md5**: Direct, zero-allocation MD5 hashing
- **std.fmt.bufPrint**: Safe string formatting without heap allocation
- **std.mem.trim**: Clean input whitespace handling
- **std.mem.zeroes**: Initialize arrays with zeros efficiently

## Key Implementation Insights

### Efficient Zero Checking
```zig
// For 5 zeros: first 2.5 bytes must be zero (20 bits)
return digest[0] == 0 and digest[1] == 0 and digest[2] < 16;

// For 6 zeros: first 3 bytes must be zero (24 bits)  
return digest[0] == 0 and digest[1] == 0 and digest[2] == 0;
```

This avoids expensive hex string conversion and works directly with raw bytes.

### Memory-Efficient String Building
```zig
var buffer: [64]u8 = undefined;
@memcpy(buffer[0..secret_len], secret_key);
const number_str = try std.fmt.bufPrint(buffer[secret_len..], "{}", .{n});
```

Reuses the same buffer for each iteration, avoiding repeated allocations.

### Loop Optimization
The hot loop does minimal work:
1. Convert number to string (in-place buffer)
2. Compute MD5 hash (fixed buffer)
3. Check prefix condition (early exit)
4. Increment counter

## Learning Exercises

1. **Hash Analysis**: Implement functions to verify that our zero-checking logic is correct by converting full MD5 digests to hex strings and comparing.

2. **Benchmarking**: Compare the performance of our optimized byte-level checking vs. naive hex string conversion and prefix checking.

3. **Alternative Hashes**: Implement the same solution using SHA-1 or SHA-256. Compare performance and discuss why MD5 might be preferred for puzzles.

4. **Parallel Mining**: Implement a multi-threaded version that divides the search space among threads. Discuss the challenges of parallel proof-of-work.

5. **Prefix Generalization**: Generalize the solution to find hashes with any number of leading zeros, not just 5 or 6.

6. **Memory Profiling**: Analyze memory usage patterns and identify any potential memory leaks or inefficiencies in the hot loop.

## Performance Considerations

- **Hash Computation**: This is the bottleneck - MD5 is relatively fast but still the dominant cost
- **String Conversion**: Integer to string conversion happens every iteration - our buffer reuse approach minimizes allocation overhead
- **Cache Usage**: All data structures fit comfortably in L1/L2 cache for optimal performance
- **Branch Prediction**: The zero-checking condition is predictable (mostly false until we find the solution)

## Real-World Applications

This pattern appears in:
- **Cryptocurrency Mining**: Bitcoin's proof-of-work uses double SHA-256 instead of MD5
- **Password Security**: PBKDF2 and similar functions use repeated hashing
- **Deduplication**: Content-addressed storage uses hash prefixes as bloom filters
- **Load Balancing**: Consistent hashing uses hash prefixes for node selection

## Cross-References

This problem connects to:
- **Day 5**: More string manipulation and character counting
- **Day 10**: String transformation rules and iteration
- **Day 14**: Reusable hash function (similar core concept)
- **Day 17**: Iterative computation with state management

The pattern of iterative computation with a stopping condition appears frequently in AoC problems.