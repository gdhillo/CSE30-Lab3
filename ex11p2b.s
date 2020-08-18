@@@ OPEN INPUT FILE, READ INTEGER FROM FILE, PRINT IT, CLOSE INPUT FILE
.equ SWI_PrChr, 0x00 @ Write an ASCII char to Stdout
.equ SWI_RdChr, 0x01 @Read an ASCII char 
.equ SWI_Exit,  0x11 @ Stop execution
.equ SWI_Open,  0x66 @open a file
.equ SWI_Close, 0x68 @close a file
.equ SWI_PrStr, 0x69 @ Write a null-ending string
.equ SWI_PrInt, 0x6b @ Write an Integer
.equ SWI_RdInt, 0x6c @ Read an Integer from a file
.equ Stdout, 1 @ Set output target to be Stdout
.global _start
.text


@@@============================================================================
@@@ Helper function to do division on two numbers
@@@
.align   8
.global  div_function
.type    div_function, %function

   .fnstart
    push {r4-r11, lr}

@    MOV R1,R1
@   MOV R2,R2

    MOV R2, R1
    MOV R1, R0
    CMP R2, #0
    BEQ divide_end
@check for divide by zero!
    MOV R0,#0 @clear R0 to accumulate result
    MOV R3,#1 @set bit 0 in R3, which will be
@shifted left then right
start:
    CMP R2,R1
    MOVLS R2,R2,LSL#1
    MOVLS R3,R3,LSL#1
    BLS start
@shift R2 left until it is about to
@be bigger than R1
@shift R3 left in parallel in order
@to flag how far we have to go
next:
    CMP R1,R2 @carry set if R1&gt@R2 (don't ask why)
    SUBCS R1,R1,R2 @subtract R2 from R1 if this would
@give a positive answer
    ADDCS R0,R0,R3 @and add the current bit in R3 to
@the accumulating answer in R0
    MOVS R3,R3,LSR#1 @Shift R3 right into carry flag
    MOVCC R2,R2,LSR#1 @and if bit 0 of R3 was zero, also
@shift R2 right
    BCC next @If carry not clear, R3 has shifted
@back to where it started, and we
@can end
divide_end:

    pop {r4-r11, lr}
    bx lr
   .fnend


@==============================================================================

_start:
@ print an initial message to the screen
mov R0,#Stdout @print an initial message


MOV R4, #0 @ counter for how many time something is pushed onto the stack


@ == Open an input file for reading =============================
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

@numbers being pushed onto the stack
    stmdb sp!, {r0}
@COUNT
    ADD R4, R4, #1
@TOTAL
    ADD R5, R5, R0



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

    MOV R9, R4 @ R9 Holds the count
    MOV R10, R5 @ R10 will hold the total

@===============================================================
@ Do the mean (average)

@R1 and R2 are being passed into the Division function
    MOV R1,R5 @ Total
    MOV R2,R4 @ Count
BL div_function
/*
@===DIV_FUNCTION===============================================
    CMP R2, #0
    BEQ divide_end1
@check for divide by zero!
    MOV R0,#0 @clear R0 to accumulate result
    MOV R3,#1 @set bit 0 in R3, which will be
@shifted left then right
start1:
    CMP R2,R1
    MOVLS R2,R2,LSL#1
    MOVLS R3,R3,LSL#1
    BLS start1
@shift R2 left until it is about to
@be bigger than R1
@shift R3 left in parallel in order
@to flag how far we have to go
next1:
    CMP R1,R2 @carry set if R1&gt@R2 (don't ask why)
    SUBCS R1,R1,R2 @subtract R2 from R1 if this would
@give a positive answer
    ADDCS R0,R0,R3 @and add the current bit in R3 to
@the accumulating answer in R0
    MOVS R3,R3,LSR#1 @Shift R3 right into carry flag
    MOVCC R2,R2,LSR#1 @and if bit 0 of R3 was zero, also
@shift R2 right
    BCC next1 @If carry not clear, R3 has shifted
@back to where it started, and we
@can end
divide_end1:
@===============================================================
*/

@ R6 HOLDS THE MEAN (AVERAGE) OF THE LIST
    MOV R6, R0 @ moving the average into R6


@================================================================
@ Finding the MEDIAN

@ Check if The count is ODD 
    TST R4, #1
    BNE _ODD

@ EVEN SECTION
@R4 == count 
@if the count is even then you need to average the inner two numbers


@R1 and R2 are being passed into the Division function
    MOV R1, R4
    MOV R2, #2
BL div_function

/*
@===DIV_FUNCTION===============================================
CMP R2, #0
    BEQ divide_end2
@check for divide by zero!
    MOV R0,#0 @clear R0 to accumulate result
    MOV R3,#1 @set bit 0 in R3, which will be
@shifted left then right
start2:
    CMP R2,R1
    MOVLS R2,R2,LSL#1
    MOVLS R3,R3,LSL#1
    BLS start2
@shift R2 left until it is about to
@be bigger than R1
@shift R3 left in parallel in order
@to flag how far we have to go
next2:
    CMP R1,R2 @carry set if R1&gt@R2 (don't ask why)
    SUBCS R1,R1,R2 @subtract R2 from R1 if this would
@give a positive answer
    ADDCS R0,R0,R3 @and add the current bit in R3 to
@the accumulating answer in R0
    MOVS R3,R3,LSR#1 @Shift R3 right into carry flag
    MOVCC R2,R2,LSR#1 @and if bit 0 of R3 was zero, also
@shift R2 right
    BCC next2 @If carry not clear, R3 has shifted
@back to where it started, and we
@can end
divide_end2:
@========================================================
*/
    MOV R7, R0 @ count/2 

@Want to move the stack pointer to the middle of the list 
    MOV R5, #4
    MUL R0, R0, R5
    ADD sp, R0

    LDR R1, [sp]

@getting the next element because the list is even
    SUB sp, #4

    LDR R2, [sp]

    ADD R8, R1, R2

@R1 and R2 are being passed into the Division function
    MOV R1, R8
    MOV R2, #2
BL div_function

/*
@===DIV_FUNCTION==========================================
CMP R2, #0
    BEQ divide_end3
@check for divide by zero!
    MOV R0,#0 @clear R0 to accumulate result
    MOV R3,#1 @set bit 0 in R3, which will be
@shifted left then right
start3:
    CMP R2,R1
    MOVLS R2,R2,LSL#1
    MOVLS R3,R3,LSL#1
    BLS start3
@shift R2 left until it is about to
@be bigger than R1
@shift R3 left in parallel in order
@to flag how far we have to go
next3:
    CMP R1,R2 @carry set if R1&gt@R2 (don't ask why)
    SUBCS R1,R1,R2 @subtract R2 from R1 if this would
@give a positive answer
    ADDCS R0,R0,R3 @and add the current bit in R3 to
@the accumulating answer in R0
    MOVS R3,R3,LSR#1 @Shift R3 right into carry flag
    MOVCC R2,R2,LSR#1 @and if bit 0 of R3 was zero, also
@shift R2 right
    BCC next3 @If carry not clear, R3 has shifted
@back to where it started, and we
@can end
divide_end3:
@====================================================
*/

    MOV R8, R0 @ R8 holds the median of the list

@ reseting the sp to top of the stack
    MOV R0, #0
    MUL R0, R7, R5
    SUB sp, R0
@====================================


B _EXIT_EVEN
_ODD:
@ ODD SECTION1

@getting the median for odd numbered list

@R4
@2
@BL div_function

MOV R1, R4
MOV R2, #2
BL div_function
/*
@===DIV_FUNCTION===============================================
CMP R2, #0
    BEQ divide_end4
@check for divide by zero!
    MOV R0,#0 @clear R0 to accumulate result
    MOV R3,#1 @set bit 0 in R3, which will be
@shifted left then right
start4:
    CMP R2,R1
    MOVLS R2,R2,LSL#1
    MOVLS R3,R3,LSL#1
    BLS start4
@shift R2 left until it is about to
@be bigger than R1
@shift R3 left in parallel in order
@to flag how far we have to go
next4:
    CMP R1,R2 @carry set if R1&gt@R2 (don't ask why)
    SUBCS R1,R1,R2 @subtract R2 from R1 if this would
@give a positive answer
    ADDCS R0,R0,R3 @and add the current bit in R3 to
@the accumulating answer in R0
    MOVS R3,R3,LSR#1 @Shift R3 right into carry flag
    MOVCC R2,R2,LSR#1 @and if bit 0 of R3 was zero, also
@shift R2 right
    BCC next2 @If carry not clear, R3 has shifted
@back to where it started, and we
@can end
divide_end4:
*/

@getting the median from the stack 
MOV R5, #4
MUL R0, R0, R5
ADD sp, R0
LDR R8, [sp]
@R8 now has the median of the list



@resetting the stack
SUB sp, R0

_EXIT_EVEN:










mov R0, #Stdout @ print last message
ldr R1, =EndOfFileMsg
swi SWI_PrStr
@ == Close a file ===============================================
ldr R0, =InFileHandle @ get address of file handle
ldr R0, [R0] @ get value at address
@swi SWI_Close
Exit:
add sp, sp, #4
ldmdb sp!, {R5}
mov R0, #Stdout @ print last message
ldr r0,=OutFileName @ set Name for output file
mov r1,#1 @ mode is output
swi SWI_Open @ open file for output
@ldr R1, =OutFileHandle
@ldr R0, [R0]
mov r7, #0
PrintOut:
ldr r1, [sp, r7]@=ColonSpace
swi SWI_PrInt
ldr r1, =SPACE
swi SWI_PrStr
add r7, r7, #4
cmp r7, #24
bne PrintOut
@ldr r1, [sp, r7]
@swi SWI_PrInt
@ldr r1, R1;
@swi SWI_prStr
swi SWI_Exit @ stop executing
InFileError:
mov R0, #Stdout
ldr R1, =FileOpenInpErrMsg
swi SWI_PrStr
bal Exit @ give up, go to end
.data
.align
InputFileHandle: .skip 4  @added
InFileHandle: .skip 4
OutFileHandle: .skip 4
InFileName: .asciz "seq_in.txt"
OutFileName: .asciz "whatout.txt"
FileOpenInpErrMsg: .asciz "Failed to open input file \n"
EndOfFileMsg: .asciz "End of file reached\n"
ColonSpace: .asciz ":"
NL: .asciz " \n " @ new line
SPACE: .asciz " "
Message1: .asciz "Hello World! \n"
.end
