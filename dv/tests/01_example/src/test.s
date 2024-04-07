.section .text
.equ res_addr, 0x00020040
.global _start

_start:         
    li x1, 10
    li x2, 0
    li x3, res_addr
loop:                        
    add x2, x2, x1
    addi x1, x1, -1
    beq x1, x0, exit
    j loop
exit:
    sw x2, 0(x3)



