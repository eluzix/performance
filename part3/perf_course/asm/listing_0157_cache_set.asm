.text
.global _CacheSetTest

_CacheSetTest:
;    ldr x6, =0x7F00
;    ldr x6, #16384
outter_loop3:
    mov x5, x2
    mov x4, x1
;    orr x4, x1, #16384

    inner_loop3:
        ldr Q0, [x4]
        ldr Q0, [x4, #128]
        ldr Q0, [x4, #256]
        ldr Q0, [x4, #384]
        ldr Q0, [x4, #512]
        ldr Q0, [x4, #640]
        ldr Q0, [x4, #768]
        ldr Q0, [x4, #896]
        adds x4, x4, #16384
;        adds x4, x4, x6
;        adds x4, x4, #4096
        subs x5, x5, 1024
;        subs x5, x5, 384
        bhi inner_loop3

    subs x0, x0, 1
    bhi outter_loop3
    ret