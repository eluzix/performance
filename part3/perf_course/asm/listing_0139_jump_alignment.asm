.text
.global _NOPAligned64
.global _NOPAligned31
.global _NOPAligned63

_NOPAligned64:
    eor    x8, x8, x8

; Align the following code to a 64-byte boundary
.p2align 6
loop1:
    strb   w8, [x1, x8]
    add    x8, x8, #0x1
    cmp    x8, x0
    b.lo loop1
    ret

_NOPAligned31:
    eor    x8, x8, x8
; Align the following code to a 64-byte boundary
.p2align 6
.rept 31
    nop
.endr
loop2:
    strb   w8, [x1, x8]
    add    x8, x8, #0x1
    cmp    x8, x0
    b.lo loop2
    ret


_NOPAligned63:
    eor    x8, x8, x8
; Align the following code to a 64-byte boundary
.p2align 6
.rept 62
    nop
.endr
loop3:
    strb   w8, [x1, x8]
    add    x8, x8, #0x1
    cmp    x8, x0
    b.lo loop3
    ret


