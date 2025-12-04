    .section .text
    .globl _start

UART_ADDR = 0x10000000

_start:
    la   t0, msg              # pointer to string
loop:
    lbu  t1, 0(t0)            # load byte
    beqz t1, done             # end when zero
    lui  t2, %hi(UART_ADDR)
    addi t2, t2, %lo(UART_ADDR)
    sw   t1, 0(t2)            # print char
    addi t0, t0, 1
    j    loop

done:
    # PASS
    li   t3, 123456789
    lui  t4, 0x20000
    sw   t3, 0(t4)

    # EXIT VALUE 0
    li   t5, 0
    lui  t6, 0x20000
    addi t6, t6, 4
    sw   t5, 0(t6)

    # EXIT VALID
    li   a0, 1
    lui  s0, 0x20000
    addi s0, s0, 16
    sw   a0, 0(s0)

1:  j 1b

    .section .rodata
msg:
    .ascii "Hello, world!\n"
    .byte 0
