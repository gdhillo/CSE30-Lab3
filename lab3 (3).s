@@@============================================================================
@@@ SoftWare Interrupts (SWI)
@@@
.equ SWI_PrChr, 0x00    @ Write an ASCII char to Stdout
.equ SWI_RdChr, 0x01    @ Read an ASCII char 
.equ SWI_Exit,  0x11    @ Stop execution
.equ SWI_Open,  0x66    @ open a file
.equ SWI_Close, 0x68    @ close a file
.equ SWI_PrStr, 0x69    @ Write a null-ending string
.equ SWI_PrInt, 0x6b    @ Write an Integer
.equ SWI_RdInt, 0x6c    @ Read an Integer from a file
.equ Stdout,    1       @ Set output target to be Stdout


@@@============================================================================
@@@ Helper function to read data from file
@@@ 
.align   8
.global  open_file
.type    open_file, %function

open_file:
    .fnstart
	
    @ == Open an input file for reading =======================================
	@ if problems, print message to Stdout and exit
	
	
	mov r1,#0 @ mode is input
	swi SWI_Open @ open file for input
	bcs InFileError @ Check Carry-Bit (C): if= 1 then ERROR
	
	@ Save the file handle in memory:
	ldr r1,=InputFileHandle @ if OK, load input file handle
	str r0,[r1] @ save the file handle
	
	bx lr
    .fnend



@@@============================================================================
@@@ Echo input file to output file
@@@   input:   whatin.txt
@@@   output:  whatout.txt
@@@
.align   8
.global  read_write_echo_ARM
.type    read_write_echo_ARM, %function

read_write_echo_ARM:
    .fnstart
   
    ldr r0,=whatin_file_in @ set Name for input file
    bl open_file
	
	
	@ == Read integers until end of file ======================================
	
	RLoop_rwe: @ If we are here, file was successfully opened.
	
	ldr r0,=InputFileHandle @ load input file handle
	ldr r0,[r0]
	swi SWI_RdInt @ read the integer into R0
	bcs EOFReached_rwe @ Check Carry-Bit (C): if= 1 then EOF reached
	
	
	stmdb sp!, {r0}
	add R2, R2, #1 @keep track of how many items read in
	
	mov r9, sp @ R9 contains top of stack.
	bal RLoop_rwe @ keep reading until end of file
	@ == End of file ==========================================================

	EOFReached_rwe:

	@ == Open output file for writing =========================================
	
	@ Reset sp to beg of stack
	@ sp now points to first element read from input file.
	@ Here, R2 contains total # of data read in from file.
	mov R3, R2, LSL #2
	add sp, sp, R3

	@ Open output file
	ldr r0,=whatout_file_out @ set Name for output file
	mov r1,#1 @ mode is output
	swi SWI_Open @ open file for output
	
	
	mov r7, #0 @ start at beginning of stack

	@ negate R3 for stack comparison
	@ Want to print out data in same order as read in
	mvn R3, R3
	add R3, R3, #1

	Exit:

	@ == Stream data to output file one element at a time =====================
	
	PrintOut:
	
	@ Print next stack value
	ldmdb sp!, {r1}
	swi SWI_PrInt
	
	@ If not last element in input file,
	@ print space after element.
	
	cmp r9, sp
	beq LastElement
	
	ldr r1, =SPACE
	swi SWI_PrStr
	
	LastElement:
	
	sub r7, r7, #4
	cmp r7, R3
	bne PrintOut 
	@ldr r1, [sp, r7]
	@swi SWI_PrInt
	@ldr r1, R1;
	@swi SWI_prStr

	
	InFileError: 
	mov R0, #Stdout
	ldr R1, =FileOpenInpErrMsg
	swi SWI_PrStr
	swi SWI_Exit @ stop executing
	bx lr
	.fnend

	
	

@@@============================================================================
@@@ Read two 4x4 matrix
@@@   input:   matin.txt
@@@      
@@@   If the input file have the following 3x3 matrix:
@@@
@@@      1 2 3 4 5 6 7 8 9
@@@
@@@   The stack will have the following pattern:
@@@      
@@@      +-+
@@@      |7| <-- SP
@@@      +-+      
@@@      |8|   
@@@      +-+
@@@      |9|
@@@      +-+
@@@      |4|
@@@      +-+
@@@      |5|
@@@      +-+
@@@      |6|
@@@      +-+
@@@      |1|
@@@      +-+
@@@      |2|
@@@      +-+
@@@      |3|
@@@      +-+
@@@

.align   8
.global  matrix_read_ARM
.type    matrix_read_ARM, %function
matrix_read_ARM:
    .fnstart
	
	
   
	ldr r0,=matin_file_in @ set Name for input file
    bl open_file
	
	@ == Read in 2 4x4 matrices until end of file ======================================
	
	RLoop_mra: @ If we are here, file was successfully opened.
	
   MOV R1, #0

ReadInMatrixLoop:

	ldr r0,=InputFileHandle @ load input file handle
	ldr r0,[r0]

    @if(R1 ==0)
    CMP R1, #0
    BEQ ifR1EqualToZero
    B ifR1NotEqualToZero:

ifR1EqualToZero:
    MOV R4, R0	
ifR1NotEqualToZero: @exit if(R1==0)

     @if(R1==1)
     CMP R1, #1
     BEQ ifR1EqualToOne
     B ifR1NotEqualToOne
ifR1EqualToOne:
    MOV R5, R0
ifR1NotEqualToOne: @exit if(R1==1)

     @if(R1==2)
     CMP R1, #2
     BEQ ifR1EqualToTwo
     B   ifR1NotEqualToTwo
ifR1EqualToTwo:
    MOV R6, R0
ifR1NotEqualToTwo:


     @if(R1==3)
     CMP R1, #3
     BEQ ifR1EqualToThree
     B ifR1NotEqualToThree
ifR1EqualToThree:
    MOV R7, R0
ifR1NotEqualToTwo:


    CMP R1, #4
    BEQ endReadInMartixLoop
    ADD R1, R1, #1 @increment loop counter
    BAL ReadInMatrixLoop
endReadInMatrixLoop: 
	
	@stmdb sp!, {R4-R7}
	
	swi SWI_RdInt @ read the integer into R0
	bcs EOFReached_mra @ Check Carry-Bit (C): if= 1 then EOF reached
		
	@stmdb sp!, {r0}
	add R2, R2, #1 @keep track of how many items read in
	
	
	
	
	mov r9, sp @ R9 contains top of stack.
	bal RLoop_mra @ keep reading until end of file
	@ == End of file ==========================================================

	EOFReached_mra:
	
   
    bx lr
    .fnend

@@@============================================================================
@@@ 4x4 matrix multiplication
@@@   input:   matin.txt
@@@   output:  matout.txt
@@@      
@@@   For example:
@@@
@@@ a =             b =
@@@   8   1   6       8   1   6
@@@   3   5   7       3   5   7
@@@   4   9   2       4   9   2
@@@
@@@ a * b = 
@@@       91    67    67
@@@       67    91    67
@@@       67    67    91
@@@
.align   8
.global  matrix_mult_ARM
.type    matrix_mult_ARM, %function

matrix_mult_ARM:
    .fnstart

    @ Your Code Here

    bx lr
    .fnend

@@@============================================================================
@@@ compute the input count, median, sum, mean
@@@   input:   seq_in.txt
@@@
@@@  The solution will need to be push onto the stack as such:
@@@
@@@         +--------+        
@@@         | count  | <-- SP
@@@         +--------+
@@@         | median |
@@@         +--------+
@@@         | total  |
@@@         +--------+
@@@         | mean   |
@@@         +--------+
@@@
.align   8
.global  seq_ARM
.type    seq_ARM, %function

seq_ARM:
    .fnstart

    @ Your Code Here

    bx lr
    .fnend


@@@============================================================================
.align   8
.global  _start
.type    _start, %function

_start:
   .fnstart
   
   @ Your Test Cases Here
    BL read_write_echo_ARM
	
	BL matrix_read_ARM
	
	BL matrix_mult_ARM
	
	BL seq_ARM
	
   .fnend


.data
.align
InputFileHandle: .skip 4

whatin_file_in:      .asciz "whatin.txt"
whatout_file_out:    .asciz "whatout.txt"
matin_file_in:       .asciz "matin.txt"
matout_file_out:     .asciz "matout.txt"


FileOpenInpErrMsg: .asciz "Failed to open input file \n"
SPACE: .asciz " "

.end
