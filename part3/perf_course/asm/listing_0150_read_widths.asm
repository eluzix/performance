.text
.global _Read_4x3
.global _Read_8x3
.global _Read_16x1
.global _Read_16x2
.global _Read_16x3
.global _Read_16x4
.global _Read_32x3
.global _Read_64x3
.global _Read_128x3

_Read_4x3:
loop1:
    ldr w2,[x1]
    ldr w2,[x1, #4]
    ldr w2,[x1, #8]
    subs x0, x0, 12
    bhi loop1
    ret

_Read_8x3:
loop2:
    ldr x2,[x1]
    ldr x2,[x1, #8]
    ldr x2,[x1, #16]
    subs x0, x0, 24
    bhi loop2
    ret

_Read_16x1:
loop6:
    LDR H0, [X1]
    subs x0, x0, 16
    bhi loop6
    ret

_Read_16x2:
loop7:
    LDR H0, [X1]
    LDR H0, [X1, #16]
    subs x0, x0, 32
    bhi loop7
    ret

_Read_16x3:
loop8:
    LDR H0, [X1]
    LDR H0, [X1, #16]
    LDR H0, [X1, #32]
    subs x0, x0, 48
    bhi loop8
    ret

_Read_16x4:
loop9:
    LDR H0, [X1]
    LDR H0, [X1, #16]
    LDR H0, [X1, #32]
    LDR H0, [X1, #48]
    subs x0, x0, 64
    bhi loop9
    ret

_Read_32x3:
loop5:
    LDR S0, [X1]
    LDR S0, [X1, #32]
    LDR S0, [X1, #64]
    subs x0, x0, 96
    bhi loop5
    ret

_Read_64x3:
loop3:
    LDR D0, [X1]
    LDR D0, [X1, #64]
    LDR D0, [X1, #128]
    subs x0, x0, 192
    bhi loop3
    ret

_Read_128x3:
loop4:
;    ld1 {V0.2D}, [x1]
    ldr Q0, [x1]
    ldr Q0, [x1, #128]
    ldr Q0, [x1, #256]
    subs x0, x0, 384
    bhi loop4
    ret
