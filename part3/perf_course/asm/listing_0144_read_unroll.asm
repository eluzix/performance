.text
.global _Read_x1
.global _Read_x2
.global _Read_x3
.global _Read_x4

.global _Write_x1
.global _Write_x2
.global _Write_x3


_Read_x1:
; Align the following code to a 64-byte boundary
;.p2align 6
loop1:
    ldr x2,[x1]
    subs x0, x0, 1
    bhi loop1
    ret

_Read_x2:
; Align the following code to a 64-byte boundary
;.p2align 6
loop2:
    ldr x2,[x1]
    ldr x2,[x1]
    subs x0, x0, 2
    bhi loop2
    ret

_Read_x3:
; Align the following code to a 64-byte boundary
;.p2align 6
loop3:
    ldr x2,[x1]
    ldr x2,[x1]
    ldr x2,[x1]
    subs x0, x0, 3
    bhi loop3
    ret

_Read_x4:
; Align the following code to a 64-byte boundary
;.p2align 6
loop4:
    ldr x2,[x1]
    ldr x2,[x1]
    ldr x2,[x1]
    ldr x2,[x1]
    subs x0, x0, 4
    bhi loop4
    ret


_Write_x1:
    eor    x8, x8, x8
loop5:
    str x8, [x1]
    subs x0, x0, 1
    bhi loop5
    ret

_Write_x2:
    eor    x8, x8, x8
loop6:
    str x8, [x1]
    str x8, [x1]
    subs x0, x0, 2
    bhi loop6
    ret

_Write_x3:
    eor    x8, x8, x8
loop7:
    str x8, [x1]
    str x8, [x1]
    str x8, [x1]
    subs x0, x0, 3
    bhi loop7
    ret
