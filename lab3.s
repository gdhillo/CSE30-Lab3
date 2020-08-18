/* 
	lab3.s
	Created by: Gurpreet Dhillon
			   
*/




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

.equ Matrix_Row_Size, 4	@ Size of 4x4 matrix 

@@@============================================================================
@@@ Helper function to print data to file
@@@ 
.align   8
.global  print_file
.type    print_file, %function

print_file:
	.fnstart
	push {r4-r11, lr}

	@ R0 = InputFileHandle
	@ R1 = pinter matrixC data to write
	mov r9, r1
	mov r4, #0
	
PrintOut: add r4, r4, #1
	mov r5, r4
	
	@ Print product
	sub r7, r4, #1
	ldr r1, [r9, r7, lsl #2]
	swi SWI_PrInt
	ldr r1, =SPACE
	swi SWI_PrStr
	mov r6, r5
	bic r6,	#3 @ check if div by 4.
	cmp r6, r5
	bne noLine

	ldr r1, =NL
	swi SWI_PrStr
	
noLine:
	cmp r4, #16
	beq exit
	b PrintOut
	
exit:
	

	pop {r4-r11, lr}
	bx lr
	.fnend
	
	
	

@@@============================================================================
@@@ Helper function to read data from file
@@@ 
.align   8
.global  open_file
.type    open_file, %function

open_file:
	.fnstart
	push {r4-r11, lr}

	@ == Open an input file for reading =======================================
	@ if problems, print message to Stdout and exit


	swi SWI_Open @ open file for input
	bcs InFileError @ Check Carry-Bit (C): if= 1 then ERROR

	@ Save the file handle in memory:
	ldr r1,=InputFileHandle @ if OK, load input file handle
	str r0,[r1] @ save the file handle
	
	bal exit_open
	
InFileError: 
	mov R0, #Stdout
	ldr R1, =FileOpenInpErrMsg
	swi Stdout
	swi SWI_Exit
	
exit_open:

	pop {r4-r11, lr}
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

	push {r4-r11, lr}
	
	ldr r0,=whatin_file_in @ set Name for input file
	mov r1, #0
	swi SWI_Open @ open file for input
	ldr r8,=InputFileHandle @ if OK, load input file handle
	str r0,[r8] @ save the file handle
	@bl open_file

	mov r2, #0

	@ == Read integers until end of file ======================================

RLoop_rwe: @ If we are here, file was successfully opened.

	ldr r0, [r8]
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

	@ == Stream data to output file one element at a time =====================

PrintOut_rwe:

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
	bne PrintOut_rwe 

	sub sp, sp, R3
	
	
	ldr r0, =InputFileHandle
	ldr r0, [r0]
	swi SWI_Close

	pop {r4-r11, lr}
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
	push {r4-r11, lr}

	ldr r5, [r0] @matrix A
	ldr r6, [r1] @matrix B

	ldr r0,=matin_file_in @ set Name for input file
	mov r1, #0 	@input mode
	swi SWI_Open @ open file for output
	ldr r9,=InputFileHandle @ if OK, load input file handle
	str r0,[r9] @ save the file handle
	

	@ == Read in two 4x4 matrices until end of file ===========================
	mov r7, #0 @ matrix index counter
	mov r8, #0
RLoop_mra: @ If we are here, file was successfully opened.

	ldr r0,[r9]
	swi SWI_RdInt @ read the integer into R0
	bcs EOFReached_mra @ Check Carry-Bit (C): if= 1 then EOF reached

	cmp r7, #15
	bgt load_MatrixB

	str r0, [r5, r7, lsl #2]
	add r7, r7, #1 @ increment matrix index counter
	bal end_if_mra

load_MatrixB:

	str r0, [r6, r8, lsl #2]
	add r8, r8, #1 @ increment matrix index counter
end_if_mra:

	add R2, R2, #1 @keep track of how many items read in

	bal RLoop_mra @ keep reading until end of file
	@ == End of file ==========================================================

EOFReached_mra:

	ldr r0, =InputFileHandle
	ldr r0, [r0]
	swi SWI_Close

	pop {r4-r11, lr}
	bx lr
	.fnend

	
@@@============================================================================
@@@  Helper function to Transpose input 4x4 matrix
@@@   input:   4x4 matrix
@@@   output:  4x4 transposed matrix
@@@      
@@@   For example:
@@@
@@@ a =             
@@@   1   2   3
@@@   4   5   6
@@@   7   8   9
@@@
@@@ a transpose = 
@@@       1   4   7 
@@@       2   5   8
@@@       3   6   9
@@@
.align   8
.global  matrix_transpose_ARM
.type    matrix_transpose_ARM, %function

matrix_transpose_ARM:
	.fnstart
	push {r4-r11, lr}
	@ R0 = 4x4 matrixA
	@ R1 = transposed matrixB buffer

	mov r8, #Matrix_Row_Size
	mov r9, #0 @total element access counter

	@ == begin outer loop =====================================================
	mov r4, #0  @ outer loop counter (i)
	bal test_transpose_outer_loop
transpose_outer_loop:

	@ == begin inner loop =====================================================
	mov r5, #0  @ inner loop counter (j)
	bal test_transpose_inner_loop
transpose_inner_loop:

	mul r6, r5, r8 @ r6 = j * 4
	add r6, r6, r4  @ r6 = i + j * Matrix row size

	ldr r7, [r0, r6, lsl #2] @ matrixA[j + i * Matrix_Row_Size]
	str r7, [r1, r9, lsl #2] @ matrixB

	add r9, r9, #1 
	add r5, r5, #1 @increment inner loop counter
test_transpose_inner_loop:
	cmp r5, #Matrix_Row_Size
	blt transpose_inner_loop
	@ == end inner loop =====================================================
	

	add r4, r4, #1 @increment outer loop counter
test_transpose_outer_loop:
	cmp r4, #Matrix_Row_Size
	blt transpose_outer_loop
	@ == end outer loop =====================================================

	pop {r4-r11, lr}
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
	push {r4-r11, lr}
	
	@ R0 = pointer to matrixA
	@ R1 = pointer to matrixB
	@ R2 = pointer to matrixC

    mov r6, #0 @sum = 0
	mov r4, #Matrix_Row_Size
	
	@ == begin outer loop (i)==================================================
	mov r7, #0 @loop counter {i}
	bal test_product_outer_loop
product_outer_loop:
	
	@ == begin inner loop (j)==================================================
	
	mov r8, #0 @loop counter (j)
	bal test_product_inner_loop
product_inner_loop:
	
	@ == begin 2nd-inner loop (k)==============================================

	mov r9, #0 @loop counter (k)
	bal test_second_inner_loop
second_inner_loop:

	mla r5, r7, r4, r9    @ i*4 + k
	mla r3, r9, r4, r8    @ k*4 + j
	mla r12, r7, r4, r8   @ i*4 + j
	
	@ R10 = data from matrixA
	ldr r10, [r0, r5, lsl #2]  @ MatrixA[i*4 + k]
	
	@ R11 = data from matrixB
	ldr r11, [r1, r3, lsl #2]  @ MatrixB[k*4 + j]
	
	@ calculate matrix multiplication
	mla r6, r10, r11, r6
		
	add r9, r9, #1 @k++
test_second_inner_loop:
	cmp r9, #Matrix_Row_Size
	blt second_inner_loop
	@ == end 2nd-inner loop ===================================================
	
	@ store value into matrixB
	@ note, transposed matrixB is stored in matrixC
	str r6, [r2, r12, lsl #2] @ MatrixC[i*4 + j]
	mov r6, #0  @reset sum for next entry

	add r8, r8, #1 @inc outer loop j++
test_product_inner_loop:
	cmp r8, #Matrix_Row_Size
	blt product_inner_loop
	@ == end inner loop =======================================================
	
	add r7, r7, #1 @inc outer loop i++
test_product_outer_loop:
	cmp r7, #Matrix_Row_Size
	blt product_outer_loop
	@ == end outer loop =======================================================


	
	ldr r0,=matout_file_out @ set Name for output file
	mov r1,#1 @ mode is output
	
	swi SWI_Open
	
	
	@ldr r0, =InputFileHandle
	@mov r0, #Stdout
	mov r1, r2
	bl print_file
	
	pop {r4-r11, lr}
	bx lr
	.fnend
	
	
	
	
	
@@@============================================================================
@@@ Helper function to do division on two numbers
@@@
.align   8
.global  div_function
.type    div_function, %function

div_function:
	.fnstart
	push {r4-r11, lr}

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
	push {r4-r11, lr}
	

	@ Your Code Here
	
	mov r12, sp @ R9 contains top of stack.
	
	
	MOV R4, #0 @ counter for how many time something is pushed onto the stack
	MOV r5, #0

	
	ldr r0,=seqin_file_in @ set Name for input file
	mov r1, #0
	swi SWI_Open @ open file for input
	ldr r8,=InputFileHandle @ if OK, load input file handle
	str r0,[r8] @ save the file handle
	
	mov r2, #0

	
	@ == Read integers until end of file ======================================

RLoop_seq: @ If we are here, file was successfully opened.

	ldr r0, [r8]
	swi SWI_RdInt @ read the integer into R0
	bcs EOFReached_seq @ Check Carry-Bit (C): if= 1 then EOF reached


	stmdb sp!, {r0}


	ADD R4, R4, #1 @keep track of how many items read in
	
    ADD R5, R5, R0 @TOTAL

	
	bal RLoop_seq @ keep reading until end of file
	@ == End of file ==========================================================

EOFReached_seq:

	MOV R7, R4 @ R9 Holds the count
    MOV R9, R5 @ R10 will hold the total

	@==========================================================================
	@ Do the mean (average)

	@R1 and R2 are being passed into the Division function
    MOV R0,R5 @ Total
    MOV R1,R4 @ Count
	BL div_function


	@ R10 HOLDS THE MEAN (AVERAGE) OF THE LIST
    MOV R10, R0 @ moving the average into R10


	@==========================================================================
	@ Finding the MEDIAN

	@ Check if The count is ODD 
    TST R4, #1
    BNE _ODD

	@ EVEN SECTION
	@R4 == count 
	@if the count is even then you need to average the inner two numbers


	@R1 and R2 are being passed into the Division function
    MOV R0, R4
    MOV R1, #2
	BL div_function


    MOV R6, R0 @ count/2 

	@Want to move the stack pointer to the middle of the list 
    MOV R5, #4
    MUL R0, R0, R5 @TODO: change register for this.
    ADD sp, R0

    LDR R1, [sp]

	@getting the next element because the list is even
    SUB sp, #4

    LDR R2, [sp]

    ADD R8, R1, R2

	@R1 and R2 are being passed into the Division function
    MOV R0, R8
    MOV R1, #2
	BL div_function

    MOV R8, R0 @ R8 holds the median of the list

	@ reseting the sp to top of the stack
    MOV R0, #0
    MUL R0, R6, R5
    SUB sp, R0
	@==========================================================================


	B _EXIT_EVEN
_ODD:
	@ ODD SECTION1

	@getting the median for odd numbered list

	@R4
	@2
	@BL div_function

	MOV R0, R4
	MOV R1, #2
	BL div_function

	@getting the median from the stack 
	MOV R5, #4
	MUL R0, R0, R5
	ADD sp, R0
	LDR R8, [sp]
	@R8 now has the median of the list



	@resetting the stack
	SUB sp, R0

_EXIT_EVEN:
	

	mov sp, r12
	push {r7-r10}
		
	ldr r0,=seqout_file_out @ set Name for output file
	mov r1,#1 @ mode is output
	@bl open_file
	swi SWI_Open
	
@ R7 = count
@ R8 = median
@ R9 = total
@ R10 = mean

	
	@==== Print data to file ==================================================
		
	mov r3, #0
	bal test_print_loop
print_loop:
	
	ldmia sp!, {r1}
	swi SWI_PrInt
	
	cmp r3, #3 @if last element, dont print space afterwards
	beq last_element
	
	ldr r1, =NL
	swi SWI_PrStr
	
last_element:

	add r3, r3, #1
test_print_loop:
	cmp r3, #4 
	blt print_loop

	swi SWI_Close
	
	
	mov sp, r12
	
	pop {r4-r11, lr}
	bx lr
	.fnend

	
/*
@@@============================================================================
.align   8
.global  pseudo_noise
.type    pseudo_noise, %function

pseudo_noise:
	.fnstart
	push {r4-r11, lr}
	
	@pseudo_noise sequence generator
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

	BX lr
	.fnend
*/
	
	
	
@@@============================================================================
.align   8
.global  encryption
.type    encryption, %function

encryption:
	.fnstart
	push {r4-r11, lr}
	

	
	
	mov r4, sp @top of stack
	
	@ load PRNs onto stack
	@bl pseudo_noise
	
	@pseudo_noise sequence generator
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
	
	@ move stack pointer back to begining of stack
	mov sp, r4
	
	
	@Open input file
	ldr r0,=messagein_file_in @ set Name for input file
	mov r1, #0
	swi SWI_Open @ open file for input
	ldr r8,=InputFileHandle @ if OK, load input file handle
	str r0,[r8] @ save the file handle
	
	@Open output file
	ldr r0,=messagescram_file_out @ set Name for input file
	mov r1, #1
	swi SWI_Open @ open file for input
	ldr r12,=OutputFileHandle @ if OK, load input file handle
	str r0,[r12] @ save the file handle

	mov r2, #0

	@ == Read integers until end of file ======================================

RLoop_enc: @ If we are here, file was successfully opened.

	ldr r0, [r8]
	swi SWI_RdInt @ read the integer into R0
	bcs EOFReached_enc @ Check Carry-Bit (C): if= 1 then EOF reached


	@stmdb sp!, {r0}
	
	@ldr r5, [sp]
	@eor r4, r0, r5
	
	
	cmp r4, sp @if at top of stack, XOR read in val with 0x02
	bne else_next_element
	
	eor r5, r0, #0x02
	bal end_if_enc
	
 else_next_element:
	
	ldr r6, [sp]
	eor r5, r0, r6

end_if_enc:	
	sub sp, sp, #4
	

	
	@ == Write XOR'd val to file ==============================================
	
	ldr r0, [r12]
	mov r1, r5
	swi SWI_PrInt
	
	ldr r1, =NL
	swi SWI_PrStr

	add R7, R2, #1 @keep track of how many items read in
	bal RLoop_enc @ keep reading until end of file
	@ == End of file ==========================================================

EOFReached_enc:

	
	
	ldr r0, =InputFileHandle
	ldr r0, [r0]
	swi SWI_Close

	ldr r0, =OutputFileHandle
	ldr r0, [r0]
	swi SWI_Close
	
	mov sp, r4
	
	pop {r4-r11, lr}
	bx lr
	.fnend
	
	
	
	
	
@@@============================================================================
.align   8
.global  decryption
.type    decryption, %function

decryption:
	.fnstart
	push {r4-r11, lr}
	

	
	mov r4, sp @top of stack
	
	@ load PRNs onto stack
	@bl pseudo_noise
	
	@pseudo_noise sequence generator
	@ repeats every 1023 outputs
	MOV r0,#2  @start
	MOV r1,r0  @a
	MOV r7,#1024 @loop_ctr
LOOP_dec:
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
	BEQ  end_dec
	BAL LOOP_dec
end_dec:
	
	@ move stack pointer back to begining of stack
	mov sp, r4
	
	
	@Open input file
	ldr r0,=messagescram_file_out @ set Name for input file
	mov r1, #0
	swi SWI_Open @ open file for input
	ldr r8,=InputFileHandle @ if OK, load input file handle
	str r0,[r8] @ save the file handle
	
	@Open output file
	ldr r0,=messageout_file_out @ set Name for input file
	mov r1, #1
	swi SWI_Open @ open file for input
	ldr r12,=OutputFileHandle @ if OK, load input file handle
	str r0,[r12] @ save the file handle

	mov r2, #0

	@ == Read integers until end of file ======================================

RLoop_dec: @ If we are here, file was successfully opened.

	ldr r0, [r8]
	swi SWI_RdInt @ read the integer into R0
	bcs EOFReached_dec @ Check Carry-Bit (C): if= 1 then EOF reached


	@stmdb sp!, {r0}
	
	@ldr r5, [sp]
	@eor r4, r0, r5
	
	
	cmp r4, sp @if at top of stack, XOR read in val with 0x02
	bne else_next_element_dec
	
	eor r5, r0, #0x02
	bal end_if_dec
	
else_next_element_dec:
	
	ldr r6, [sp]
	eor r5, r0, r6

end_if_dec:	
	sub sp, sp, #4
	

	
	@ == Write XOR'd val to file ==============================================
	
	ldr r0, [r12]
	mov r1, r5
	swi SWI_PrInt
	
	ldr r1, =NL
	swi SWI_PrStr

	add R7, R2, #1 @keep track of how many items read in
	bal RLoop_dec @ keep reading until end of file
	@ == End of file ==========================================================

EOFReached_dec:

	
	
	
	ldr r0, =InputFileHandle
	ldr r0, [r0]
	swi SWI_Close

	ldr r0, =OutputFileHandle
	ldr r0, [r0]
	swi SWI_Close
	

	
	mov sp, r4
	
	pop {r4-r11, lr}
	bx lr
	.fnend
	
	
	
	
	
	
	
	


@@@============================================================================
.align   8
.global  _start
.type    _start, %function

_start:
	.fnstart
	@ Make space for matricies in memory
	@ R0 = pointer to matrixA
	@ R1 = pointer to matrixB
	@ R2 = pointer to matrixC
	ldr r0, =matrixA
	ldr r1, =matrix_arr_A
	str r1, [r0]

	ldr r1, =matrixB
	ldr r2, =matrix_arr_B
	str r2, [r1]

	ldr r2, =matrixC
	ldr r3, =matrix_arr_C
	str r3, [r2]

	@ Your Test Cases Here

	BL read_write_echo_ARM

	ldr r0, =matrixA
	ldr r1, =matrixB
	BL matrix_read_ARM

	ldr r0, =matrixA
	ldr r1, =matrixB
	ldr r2, =matrixC
	
	ldr r0, [r0] @ matrixA
	ldr r1, [r1] @ matrixB
	ldr r2, [r2] @ transposed matrixB
	BL matrix_mult_ARM

	BL seq_ARM
	
	BL encryption
	
	BL decryption

	swi SWI_Exit @ stop executing
	.fnend


.data

InputFileHandle: .skip 4
OutputFileHandle: .skip 4


whatin_file_in:      .asciz "whatin.txt"
whatout_file_out:    .asciz "whatout.txt"
matin_file_in:       .asciz "matin.txt"
matout_file_out:     .asciz "matout.txt"
seqin_file_in:       .asciz "seq_in.txt"
seqout_file_out:     .asciz "seq_out.txt"
messagein_file_in:    .asciz "message_in.txt"
messageout_file_out:  .asciz "message_out.txt"
messagescram_file_out: .asciz "message_scram.txt"


FileOpenInpErrMsg: .asciz "Failed to open input file \n"
SPACE: .asciz " "
NL: .asciz "\n"



.align 4
matrixA: .word 0
matrixB: .word 0
matrixC: .word 0

matrix_arr_A: .skip 64
matrix_arr_B: .skip 64
matrix_arr_C: .skip 64


.end