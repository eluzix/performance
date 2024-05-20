.text
.global _NOP1AllBytes
.global _NOP3AllBytes
.global _NOP9AllBytes

_NOP1AllBytes:
    eor    x8, x8, x8
loop1:
    nop
    add    x8, x8, #0x1
    cmp    x8, x0
    b.lo   loop1
    ret


_NOP3AllBytes:
    eor    x8, x8, x8
loop2:
    nop
    nop
    nop
    nop
    nop
    add    x8, x8, #0x1
    cmp    x8, x0
    b.lo   loop2
    ret


_NOP9AllBytes:
    eor    x8, x8, x8
loop3:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    add    x8, x8, #0x1
    cmp    x8, x0
    b.lo   loop3
    ret



