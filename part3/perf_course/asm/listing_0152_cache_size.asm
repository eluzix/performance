.text
.global _ReadBufferTest
.global _ReadBufferDoubleLoopTest
.global _ReadBufferDoubleLoopTest2
.global _ReadBufferDoubleLoopTest3
.global _ReadBufferDoubleLoopTest4

_ReadBufferTest:
    eor x5, x5, x5
    mov x4, x1
loop:
    ldr Q0, [x4]
    ldr Q0, [x4, #128]
    ldr Q0, [x4, #256]
    ldr Q0, [x4, #384]
    ldr Q0, [x4, #512]
    ldr Q0, [x4, #640]
    add x5, x5, 768
    and x5, x5, x2 ; mask the counter
    add x4, x1, x5
;    subs x0, x0,  1536 ; the main loop counter
    subs x0, x0,  768 ; the main loop counter
    bhi loop
    ret


; Parameters:
; x0 - the number of iterations
; x1 - the buffer address
; x2 - inner loop run count
;
; Tmp registers:
; x5 - being reset to x2 at the beginning of the outer loop

_ReadBufferDoubleLoopTest:
outter_loop:
    mov x5, x2
    mov x4, x1

    inner_loop:
        ldr Q0, [x4]
        ldr Q0, [x4, #128]
        ldr Q0, [x4, #256]
        ldr Q0, [x4, #384]
        ldr Q0, [x4, #512]
        ldr Q0, [x4, #640]
        adds x4, x4, 768
        subs x5, x5, 768
        bhi inner_loop

    subs x0, x0, 1
    bhi outter_loop
    ret

_ReadBufferDoubleLoopTest2:
outter_loop2:
    mov x5, x2
    mov x4, x1

    inner_loop2:
        ldr Q0, [x4]
        ldr Q0, [x4, #128]
        adds x4, x4, 256
        subs x5, x5, 256
;        ldr Q0, [x4, #256]
;        adds x4, x4, 384
;        subs x5, x5, 384
        bhi inner_loop2

    subs x0, x0, 1
    bhi outter_loop2
    ret

_ReadBufferDoubleLoopTest3:
outter_loop3:
    mov x5, x2
    mov x4, x1

    inner_loop3:
        ldr Q0, [x4]
        ldr Q0, [x4, #128]
        ldr Q0, [x4, #256]
        ldr Q0, [x4, #384]
        ldr Q0, [x4, #512]
        ldr Q0, [x4, #640]
        ldr Q0, [x4, #768]
        ldr Q0, [x4, #896]
        adds x4, x4, 1024
        subs x5, x5, 1024
        bhi inner_loop3

    subs x0, x0, 1
    bhi outter_loop3
    ret
