.text
.global _GarbageLoopExample
.global _FullLoopExample
.global _NopLoopExample
.global _JustLoopExample
.global _DecLoopExample

_GarbageLoopExample:
    eor    x8, x8, x8       // Initialize x8 to 0
g_loop:
    // Garbage instructions to break parallelism
    mov    x9, x8           // Move x8 to x9, creating a dependency
    mov    x10, x9          // Move x9 to x10, creating another dependency
    mov    x11, x10         // Move x10 to x11, creating yet another dependency

    strb   w8, [x1, x8]     // Store byte from w8 into memory at address x1 + x8
    add    x8, x8, #0x1     // Increment x8 by 1

    // More garbage instructions
    add    x12, x11, x10    // Add x11 and x10, store in x12
    sub    x13, x12, x9     // Subtract x9 from x12, store in x13

    cmp    x8, x0           // Compare x8 with x0
    b.lo   g_loop             // If x8 is less than x0, branch to loop
    ret                     // Return from function

_FullLoopExample:
    eor    x8, x8, x8
loop:
    strb   w8, [x1, x8]
    add    x8, x8, #0x1
    cmp    x8, x0
    b.lo loop
    ret

_NopLoopExample:
    eor    x8, x8, x8
loop1:
    nop
    add    x8, x8, #0x1
    cmp    x8, x0
    b.lo   loop1
    ret

_JustLoopExample:
    eor    x8, x8, x8
loop2:
    add    x8, x8, #0x1
    cmp    x8, x0
    b.lo   loop2
    ret

_DecLoopExample:
loop3:
    sub    x0, x0, #0x1
    cbnz   x0, loop3
    ret
