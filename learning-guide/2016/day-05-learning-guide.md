# Day 05 Learning Guide

## Problem Breakdown

### Part 1: Sequential Password Generation
Generate an 8-character password by finding MD5 hashes of `door_id + index` that start with five zeroes ("00000"). The sixth character of each valid hash (in hexadecimal) becomes the next character in the password, in order.

For example, with door ID "abc":
- Index 3231929 produces hash starting with "0000018f..." → first password character is '1'
- Index 5017308 produces hash starting with "000008f8..." → second password character is '8'
- Continue until 8 characters found

### Part 2: Position-Mapped Password
Similar to Part 1, but use the sixth character (hex digit 5) as the position (0-7) and the seventh character (hex digit 6) as the value. Fill password array sparsely, ignoring invalid positions and already-filled slots.

For example with door ID "abc":
- A hash starting with "0000018f..." would set position 1 to value '8'
- A hash starting with "000008f8..." would be ignored if position 8 is out of bounds (0-7)
- Continue until all 8 positions are filled

## TAOCP Concepts Applied

### Volume 1 - Fundamental Algorithms

**Linear Search (Section 1.1)**
- Sequential iteration through indices 0, 1, 2, ... without skipping
- No heuristic or optimization beyond checking hash condition
- Complexity: O(n) where n is the index of the last required hash

**Iteration Patterns (Section 1.2.1)**
- `while` loops with termination conditions (found 8 characters for Part 1, array complete for Part 2)
- Early termination: stop as soon as password is complete
- Counter variable increments monotonically without jumps or resets

**Arrays and Vectors (Section 1.3.1)**
- Fixed-size arrays `[8]u8` for password storage
- Sentinel values (255) to mark unfilled positions (Part 2)
- Direct array indexing O(1) access for sparse array operations

### Volume 2 - Seminumerical Algorithms

**Bit Manipulation (Section 4.3.2)**
- Extracting hex nibbles from bytes using bitwise operations
- `digest[2] & 0x0F`: Mask to get low nibble (bits 0-3)
- `digest[3] >> 4`: Right shift to get high nibble (bits 4-7)
- Byte-level comparison: `digest[2] < 16` equivalent to high nibble being zero

**Modular Arithmetic (Section 4.1)**
- Position mapping using modulo concept: hex digit in range 0-7 maps to array index
- Bounds checking: `if (pos >= 8)` prevents array overflow
- Nibble extraction is equivalent to `nibble % 16` operation

**Multiple-Precision Arithmetic (Section 4.3)**
- MD5 as 128-bit fixed-width arithmetic operation
- Each byte in digest is independent 8-bit value
- Operations on digest bytes are modular arithmetic (each nibble ∈ [0, 15])

**Random Number Generation (Section 3.2)**
- MD5 hash as deterministic pseudorandom generator
- Uniform distribution ensures rare prefix matches (~1 in 16⁵ = 1,048,576 for five zeros)
- Avalanche effect: small input changes produce dramatically different hashes

### Volume 3 - Searching and Sorting

**Hash Functions (Section 6.4)**
- MD5 as deterministic uniform distributor
- Avalanche effect ensures "random-looking" output distribution
- Hash prefix checking as early exit condition (only examine first 3 bytes for 5-zero check)

**Search Termination (Section 6.1)**
- Linear search with immediate success condition
- Early exit: stop as soon as password is complete
- No backtracking or lookahead needed

**Infinite Sequences (Section 5.2.1)**
- Lazy evaluation: generate hashes on demand, not in advance
- Stop when condition met, not at predetermined index
- Memory-efficient: never store more than one hash in memory

### Volume 4A - Combinatorial Algorithms

**Combinatorial Generation (Section 7.2.1.1)**
- Systematic enumeration of integer sequence 0, 1, 2, ...
- Gray codes not applicable here; sequential generation is sufficient
- No need to generate all combinations, just evaluate until complete

**Exhaustive Search (Section 7.1)**
- Brute-force through all possible candidates
- Constraint: hash must start with "00000"
- Stop when 8 constraints satisfied (8 characters found)

**Constraint Satisfaction (Section 7.4)**
- Part 1: Find 8 values satisfying "starts with 00000" constraint
- Part 2: Additional constraints:
  - Position must be in range [0, 7]
  - Position must not already be filled
  - All 8 positions must eventually be filled

## Programming Concepts

### Cryptographic Hashing

**MD5 Properties**
- 128-bit output represented as 32 hex characters
- Deterministic: same input always produces same output
- Avalanche effect: small input changes cause large output changes
- Preimage resistance: infeasible to find input for given hash

**Hex Representation**
- Each byte = 2 hex characters (nibbles)
- Byte `0x5F` = hex "5f" = nibbles 5 and 15
- Hex digit positions: 0-31 for 128-bit hash

### Brute Force Optimization

**Early Termination**
- Check only first 3 bytes for 5-zero prefix (not full 16 bytes)
- Use byte-level comparison: `digest[0] == 0 and digest[1] == 0 and digest[2] < 16`
- Avoid hex string conversion (expensive) in hot loop

**Memory Efficiency**
- Stack-allocated buffers for hash input and output
- Reuse same buffer across iterations (no repeated allocations)
- Fixed-size arrays prevent heap fragmentation

**Loop Optimization**
- Minimal operations per iteration in hot path
- Branch prediction friendly (condition mostly false until solution)
- Cache locality: all data fits in L1 cache

### String Operations

**Buffer Management**
- Fixed buffer `[64]u8` for `door_id + index` concatenation
- Pre-copy door_id, append number with `std.fmt.bufPrint`
- Zero allocations in hash computation loop

**Number Formatting**
- Convert integer to decimal string without heap allocation
- `std.fmt.bufPrint` writes directly to provided buffer
- Handle multi-digit numbers dynamically

### Sparse Arrays

**Sentinel Pattern**
- Use 255 (or any value outside [0,15]) to mark unfilled positions
- Check `if (array[pos] == 255)` to detect unfilled
- Direct O(1) insertion and lookup

**Position Validation**
- Bounds checking before array access
- Ignore invalid positions without erroring
- Continue search until all valid positions filled

## Zig-Specific Concepts

### Memory Management

**Stack Allocation**
- `var buffer: [64]u8 = undefined;` for hash input
- `var digest: [16]u8 = undefined;` for MD5 output
- `var password: [8]u8 = undefined;` for result
- Zero heap allocations in hot loop path

**Buffer Reuse**
- Pre-copy door_id to buffer, overwrite number portion each iteration
- `@memcpy` for efficient initial copy
- `std.fmt.bufPrint` for formatted number appending

**Compile-Time Known Sizes**
- All arrays have comptime-known lengths
- Enables stack allocation and bounds checking at compile time
- No runtime size checks needed (implicit safety)

### Performance Features

**Bitwise Operations**
- `digest[2] & 0x0F`: Mask low nibble
- `digest[3] >> 4`: Extract high nibble
- `digest[2] < 16`: Byte-level prefix check
- Direct bit manipulation is faster than hex string parsing

**Built-in Functions**
- `@memcpy`: Efficient memory copying
- Inline-friendly: small functions get inlined by optimizer
- Comptime evaluation: constants computed at compile time

### Standard Library Usage

**std.crypto.hash.Md5**
- Zero-allocation MD5 hashing interface
- `Md5.hash(input, output, .{})` computes hash in place
- Fixed digest length: `std.crypto.hash.Md5.digest_length` = 16 bytes

**std.fmt.bufPrint**
- Format string to buffer without allocation
- Returns error if buffer too small
- Used for `door_id + number` concatenation

**std.mem.trim**
- Remove whitespace from input
- Handles Windows/Unix line endings
- Prevents spaces in door_id from corrupting results

## Key Implementation Insights

### Efficient Zero Checking
```zig
// For 5 zeros: first 5 hex digits = 20 bits = 2.5 bytes
// digest[0] == 0: 8 bits (2 hex digits)
// digest[1] == 0: 8 bits (2 hex digits)
// digest[2] < 16: high nibble zero (1 hex digit)
fn startsWithFiveZeros(digest: [16]u8) bool {
    return digest[0] == 0 and digest[1] == 0 and digest[2] < 16;
}
```

This avoids expensive hex string conversion and works directly with raw bytes. Complexity: O(1).

### Nibble Extraction from MD5 Digest
```zig
// MD5 digest is 16 bytes = 128 bits = 32 hex characters
// Hex digit positions: 0-31
// Byte 0: digits 0-1, Byte 1: digits 2-3, Byte 2: digits 4-5

// Part 1: 6th hex digit = low nibble of byte 2
const password_char = digest[2] & 0x0F;

// Part 2: position = 6th hex digit, value = 7th hex digit
const position = digest[2] & 0x0F;
const value = digest[3] >> 4;
```

Direct byte access is O(1) and avoids hex string parsing.

### Sparse Array with Sentinel
```zig
const PasswordArray = struct {
    data: [8]u8,

    fn initEmpty() PasswordArray {
        return PasswordArray{ .data = [_]u8{255} ** 8 };
    }

    fn trySet(self: *PasswordArray, pos: usize, char: u8) bool {
        if (pos >= 8) return false;
        if (self.data[pos] != 255) return false;
        self.data[pos] = char;
        return true;
    }
};
```

Sentinel value (255) marks unfilled positions, enabling O(1) insertion and duplicate detection.

### Buffer Reuse Pattern
```zig
var buffer: [64]u8 = undefined;
@memcpy(buffer[0..door_id.len], door_id);

while (needs_more) {
    const number_str = try std.fmt.bufPrint(buffer[door_id.len..], "{}", .{index});
    const full_input = buffer[0 .. door_id.len + number_str.len];
    std.crypto.hash.Md5.hash(full_input, &digest, .{});
    // Process digest...
    index += 1;
}
```

Reuses same buffer for every iteration, avoiding allocation overhead.

## Learning Exercises

### Beginner

1. **Hash Analysis**: Implement a function that converts full MD5 digest to hex string and verify that byte-level zero checking produces same result as hex string prefix comparison.

2. **Password Validation**: Create a function that validates whether a password could be generated from the algorithm (given door_id and password).

3. **Position Mapping**: Implement password generation where characters go into positions 1-8 instead of 0-7 (offset by one).

### Intermediate

4. **Sparse Array Variants**: Implement using:
   - Bitset of 8 positions (one byte: 8 bits)
   - Linked list of filled positions
   - Compare performance and memory usage

5. **Alternative Prefixes**: Generalize solution to find hashes with any number of leading zeros (not just 5). How does runtime change?

6. **Parallel Mining**: Implement multi-threaded search that divides index ranges among threads. How do you handle duplicate position assignments in Part 2?

### Advanced

7. **Benchmarking Hashes**: Compare performance of:
   - MD5 vs SHA-1 vs SHA-256
   - Byte-level checking vs hex string checking
   - Single-threaded vs multi-threaded

8. **Position-Based Passwords**: Implement variants:
   - Reverse position order (7, 6, ..., 0)
   - Fibonacci position sequence (1, 1, 2, 3, 5, 8... modulo 8)
   - Random position generation from hash

9. **Optimization**: Implement early termination strategies:
   - Stop searching after N hashes without finding new positions
   - Predict required search range based on probability
   - Memoize hashes to avoid recomputation

10. **Memory Profiling**: Analyze:
    - Peak memory usage during hash computation
    - Cache hit rates for buffer/digest access
    - Impact of different buffer sizes

## Performance Considerations

### Expected Hash Counts

Based on probability (1 in 16⁵ = 1,048,576 for 5 zeros):
- **Part 1**: ~8-9 million hashes (8 valid hashes needed)
- **Part 2**: ~20-30 million hashes (many positions rejected as invalid or duplicate)

### Bottleneck Analysis

1. **Hash Computation**: Dominant cost (MD5 is fast but called millions of times)
   - MD5 on modern CPU: ~500 MB/s
   - For "abc": ~15-30 seconds for both parts

2. **String Formatting**: Integer to string conversion every iteration
   - `std.fmt.bufPrint` overhead per iteration
   - Mitigated by buffer reuse

3. **Branch Prediction**: Prefix condition mostly false
   - CPU predicts branch not taken
   - Minimal misprediction penalty (true only ~1/1,000,000 times)

### Optimization Opportunities

1. **SIMD Hashing**: Use SIMD-accelerated MD5 implementation
2. **Parallel Search**: Distribute index ranges across CPU cores
3. **Early Position Pruning**: If position 7 is last unfilled, filter hashes aggressively
4. **Hash Caching**: Cache recent hashes if input patterns repeat (unlikely here)

## Real-World Applications

This pattern appears in:

- **Cryptocurrency Mining**: Bitcoin proof-of-work (SHA-256 instead of MD5)
- **Password Derivation**: PBKDF2 iteratively hashes password+salt to derive keys
- **Deduplication**: Content-addressed storage uses hash prefixes as Bloom filters
- **Load Balancing**: Consistent hashing uses hash prefixes for node selection
- **Distributed Key Derivation**: Shamir's Secret Sharing with hash-derived shares
- **Token Generation**: One-time passwords from hash sequences

## Cross-References

This problem connects to:

- **2015 Day 4**: Same MD5 prefix concept (single nonce vs 8 characters)
- **2016 Day 14**: Reusable hash function with cache optimization
- **TAOCP Vol. 4A Section 7.2**: Combinatorial generation fundamentals
- **TAOCP Vol. 3 Section 6.4**: Hash function properties and applications

## Complexity Analysis

### Time Complexity
- **Part 1**: O(k) where k = index of 8th valid hash (~8-9 million)
- **Part 2**: O(k') where k' = index to fill all 8 positions (~20-30 million)
- Per iteration: O(1) (hash computation is constant time)

### Space Complexity
- **Both parts**: O(1) (fixed-size buffers and arrays)
- Password storage: 8 bytes
- Hash buffer: 64 bytes
- MD5 digest: 16 bytes

## Implementation Patterns

### Single-Pass Streaming
- Generate hashes on-demand, not in advance
- Stop immediately when password complete
- Never store more than one hash in memory

### Separation of Concerns
- `HashInputBuffer`: Manages string concatenation
- `PasswordArray`: Manages sparse array operations
- `startsWithFiveZeros`: Pure hash validation function

### Error-Resilient Design
- Handle empty door_id gracefully
- Bounds checking on array access
- Defensive programming in hot loop (avoid crashes on malformed input)

### Performance-First Design
- Zero allocations in critical path
- Minimal operations per iteration
- Cache-friendly data access patterns
