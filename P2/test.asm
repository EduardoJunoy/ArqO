##########################################################################
#   Programa de prueba para Practica 1 ARQO 2023                         #
#                                                                        #
##########################################################################
# AUTORES: PABLO ANTÓN ALAMILLO Y EDUARDO JUNOY ORTEGA
#
############################################################################

.data
num0:   .word  1 # posic base + 0
num1:   .word  2 # posic base + 4
num2:   .word  4 # posic base + 8
num3:   .word  8 # posic base + 12
num4:   .word 16 # posic base + 16
num5:   .word 32 # posic base + 20
num32:  .word 0xAAAA5555 # posic base + 24
buffer: .space 4
.text

main:       
lui  t0, %hi(num0)  # Carga la parte alta de la dir num0
nop
nop
nop
lw   t1, 0(t0)      # En x6 un 1
lw   t2, 4(t0)      # En x7 un 2
lw   t3, 8(t0)      # En x28 un 4 
lw   t4,12(t0)      # En x29 un 8
lw   t5,16(t0)      # En x30 un 16
lw   t6,20(t0)      # En x31 un 32

nop
nop
nop

# TEST DE ADELANTAMIENTO EN MEM   
li t2, 0x0FEA         
li t1, 0x0FE0
addi t3, t1, 0x000A
nop
nop
nop
bne t3, t2, ERROR
# TEST DE ADELANTAMIENTO EN WB
li t1, 0xCABE 
li t2, 0xCAFE         
addi t3, t1, 0x0040
nop
nop
nop
bne t3, t2, ERROR
# TEST DE ADELANTAMIENTO INTERNO EN EL BANCO DE REGISTROS
li t2, 0xDAD0
li t1, 0xDED0
nop
addi t3, t2, 0x0400
nop 
nop 
nop
bne t3, t1, ERROR

# TEST DE DETECCIÓN DE RIESGOS DE LOAD-USE
li t2, 0xFF
lw t1, 0(t0)
xori t3, t1, 0xFE
nop
nop
nop
bne t3, t2, ERROR
# DETECCIÓN DE RIESGOS DE SALTO EFECTIVO
li t4, 0x0033
beq x0, x0, TEST_JMP
li t1, 0x0032
li t2, 0x0032
li t3, 0x0032

TEST_JMP:
li t1, 0x0033
li t2, 0x0033
li t3, 0x0033
nop
nop
nop
bne t4, t1, ERROR
bne t4, t2, ERROR
bne t4, t3, ERROR

TEST_OK:
addi t6, t6, 1
beq x0, x0, TEST_OK
nop 
nop
nop

ERROR: 
addi t6, t6, -1
beq x0, x0, ERROR
nop 
nop
nop
