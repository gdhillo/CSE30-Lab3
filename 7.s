@@@============================================================================
@@@ Helper function to do division on two numbers
@@@ 
.align   8
.global  PRN10_function
.type    PRN10_function, %function

PRN10_function:
.fnstart
    push {r4-r11, lr}

@pseudonoise sequence generator
@ repeats every 1023 outputs
    MOV r0,#2  @start
    MOV r1,r0  @a
    MOV r7,#1024 @loop_ctr
LOOP:
    MOV r6,r1,LSR #9
    MOV r5,r1,LSR #6
    EOR r5,r5,r6
    AND r5,r5,#1
    MOV r1,r1,LSL#1
    ADD r1,r1,r5
    MOV r2, #255
    MOV r3, r2, LSL#2
    ADD r3, r3,  #3
    AND r1,r1, r3
    STMDB sp!,{r1}
    SUBS r7,r7,#1
    BEQ  end
    BAL LOOP
end:
    pop {r4-r11, lr}
    bx lr
    .fnend
@=============================================================

@@@============================================================================
align   8
.global  _start
.type    _start, %function

_start:
   .fnstart

MOV R2, #0 @ Count

pen an input file for reading =============================
@ if problems, print message to Stdout and exit
    ldr r0,=InFileName @ set Name for input file
    mov r1,#0 @ mode is input
    swi SWI_Open @ open file for input
    bcs InFileError @ Check Carry-Bit (C): if= 1 then ERROR
@ Save the file handle in memory:
    ldr r1,=InputFileHandle @ if OK, load input file handle
    str r0,[r1] @ save the file handle
@ == Read integers until end of file =============================
RLoop:
    ldr r0,=InputFileHandle @ load input file handle
    ldr r0,[r0]
    swi SWI_RdInt @ read the integer into R0   @CHANGED
@ldr r0,=OutFileName
@swi SWI_PrInt
    bcs EofReached @ Check Carry-Bit (C): if= 1 then EOF reached

    push {r0}

    ADD R2, R2, #1 @ add to count for each iteration of loop

CMP R2, #1
BEQ _FirstIteration
B _OtherIterations

_FirstIteration:

MOV R3, #0x2
EOR R0, R0, R3 

BL PRN10_function

B _ExitFirstIteration       
_OtherIterations:


_ExitFirstIteration:


@ print the integer to Stdout
mov r1,r0 @ R1 = integer to print
mov R0,#Stdout @ target is Stdout
@swi SWI_PrStr
@ldr r1, =SPACE
swi SWI_PrInt
mov R0,#Stdout @ print new line
ldr r1, =NL
swi SWI_PrStr
bal RLoop @ keep reading until end of file


@ == End of file ===============================================
EofReached:









@ == Close a file ===============================================
ldr R0, =InFileHandle @ get address of file handle
ldr R0, [R0] @ get value at address
@swi SWI_Close
Exit:
@add sp, sp, #4
@ldmdb sp!, {R5}
@pop {r5}
mov R0, #Stdout @ print last message
ldr r0,=OutFileName @ set Name for output file
mov r1,#1 @ mode is output
swi SWI_Open @ open file for output
@ldr R1, =OutFileHandle
@ldr R0, [R0]
mov r7, #0














   .fnend


.data
.align

InputFileHandle: .skip 4  @added
InFileHandle: .skip 4
OutFileHandle: .skip 4
InFileName: .asciz "message_in.txt"
OutFileName: .asciz "message_scram.txt"




