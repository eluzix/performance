.text
.global _ReadBufferTest

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
;    ldr Q0, [x4, #768]
;    ldr Q0, [x4, #896]
;    ldr Q0, [x4, #1024]
;    ldr Q0, [x4, #1152]
;    ldr Q0, [x4, #1280]
;    ldr Q0, [x4, #1408]
;    add x5, x5,1536
    add x5, x5, 768
    and x5, x5, x2 ; mask the counter
    add x4, x1, x5
;    subs x0, x0,  1536 ; the main loop counter
    subs x0, x0,  768 ; the main loop counter
    bhi loop
    ret
