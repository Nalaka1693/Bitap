	.text 	@ instruction memory
	.global main
main:
@===================================main
	sub sp, sp, #4					@ stack allocate to link reg
	str lr, [sp, #0]

@-----------------------------------pattern[i]
	sub sp, sp, #32					@ stack allocate for pattern
 									
	ldr 	r0, =f1
	bl 		printf 					@ printing f1
	ldr		r0, =fs
	mov 	r1, sp
	bl		scanf 					@ scanning pattern
	mov 	r0, sp  				
	mov 	r9, r0 					@ pattern sp is in r9
	bl		strleng 				@ strleng function
	mov		r4, r0 					@ strlen in r4

	cmp		r4, #31					@ check pattern length
	bgt		exit

@-----------------------------------creating pattern mask
	sub 	sp, sp, #512 			@ stack allocate for p_mask
	
	mov		r2, #512
	mov		r3, #0					@ r3 = 00000...000
	mvn		r3, r3 					@ r3 = 11111...111

	loop1:
	cmp		r2, #0
	ble		exit1	
	sub		r2, r2, #4 				@ r2 508, 504, 500, 496, 492, ...
	str 	r3, [sp, r2]	    	@ p_mask[508] = r3, p_mask[504] = r3, ...
	b 		loop1
	exit1:					 			

@-----------------------------------filling pattern mask
	mov		r2, #0
	mov 	r6, r9 					@ pattern sp is in r6
	mov		r11, r9 				@ copy pattern sp to r11
	mov		r7, #512 				
	mov		r10, #4

	loop2:
	cmp		r2, r4 					@ r2 < pattern length in r4
	bge		exit2

	mov		r1, #1 					@ r1 is 1UL 000...001
	mvn		r3, r1, lsl r2			@ r3  = ~(1UL << r2) 111...110, 111...101, 111...011
	add		r2, r2, #1 				@ r2 0, 1, 2, 3, 4, 5, ...
	ldrb 	r5, [r6, #0]			@ load to r5 = pattern[sp], pattern[sp+1], ...
	add		r6, r6, #1				@ r6 sp, sp+1, sp+2, sp+3, ...
	mul		r8, r5, r10 			@ r8 = r5 * 4
	sub 	r8, r7, r8 				@ r8 = 512 - (r5 * 4)
	ldr 	r9, [sp, r8] 			@ load to r9 p_mask[pattern[sp], p_mask[pattern[sp+1]]
	and 	r9, r9, r3  			@ r9 = r9 & 111...110, r9 & 111...101
	str 	r9, [sp, r8]  			@ store r9 to [sp, #504], [sp, #540], [sp, #536]

	b 		loop2
	exit2:
	
@-----------------------------------text[i]
	sub sp, sp, #256 				@ stack allocation for text

	ldr 	r0, =f2
	bl 		printf 				 	@ printing f2
	ldr		r0, =fs 				
	mov 	r1, sp
	bl		scanf 					@ scanning text
	mov 	r0, sp
	mov 	r10, r0 				@ text sp is in r10
	bl		strleng				 	@ strleng function strlen of text in r0

	mvn		r1, #1 					@ r1 is 1111...1110 = R

@-----------------------------------finding R
	mov		r2, #0
	mov 	r6, r10					@ text sp is in r6
	mov		r7, #768

	loop3:
	cmp		r2, r0
	bge		exit4

	add		r2, r2, #1 				@ r2 0, 1, 2, 3, 4, 5, 6, ... 
	ldrb 	r5, [r6, #0]			@ load to r5 = text[sp], text[sp+1], text[sp+2], ...
	add		r6, r6, #1				@ r6 sp, sp+1, sp+2, sp+3, ...
	mov		r10, #4
	mul		r8, r5, r10 			@ r8 = r5 * 4
	sub 	r8, r7, r8 				@ r8 = 768 - (r5 * 4)
	ldr 	r9, [sp, r8]			@ load to r9 p_mask[text[803]], p_mask[text[802]]
	orr 	r1, r9, r1 				@ R |= p_mask[text[r5]]
	lsl		r1, r1, #1 				@ R <<= 1
	mov		r10, #1 				@ r10 = 1UL 0000...0001
	lsl		r10, r10, r4 			@ 1UL << m, length of pattern is in r4
	and		r10, r10, r1 			@ (R & (1UL << m))

	cmp		r10, #0 				@ (0 == (R & (1UL << m)))
	beq		exit3
	b 		loop3

@===================================exit main when pattern found
exit3:
	sub		r2, r2, r4
	sub		r3, r6, r2
	mov 	r1, r11 				@ pattern sp to r1
	ldr 	r0, =fp1 				
	bl 		printf 					@ printing the position

	add		sp, sp, #800

	b 		exitmain

@===================================exit main when pattern is not found
exit4:
	ldr 	r0, =fp2 				
	bl 		printf 					@ printing no matching

	add		sp, sp, #800

	b 		exitmain

@===================================exit main when pattern is too long
exit:
	ldr 	r0, =fpe
	bl 		printf

	add		sp, sp, #32

	b 		exitmain

@===================================exit from main
exitmain:
	ldr 	lr, [sp, #0]
	add 	sp, sp, #4
	mov 	pc, lr

@===================================string length function
strleng:
	sub 	sp, sp, #4				@ stack allocate to link reg
	str 	lr, [sp, #0]			@ storing link reg value in stack

	mov r1, #0
	
	loopstrlen:
	ldrb	r2, [r0, #0]
	cmp		r2, #0
	beq		exitstrlen

	add 	r1, r1, #1
	add		r0, r0, #1
	b   	loopstrlen

	exitstrlen:
	mov 	r0, r1
	ldr 	lr, [sp, #0]	
	add		sp, sp, #4
	mov 	pc, lr


	.data	@ data memory

f1: .asciz "Enter the pattern: "
f2: .asciz "Enter the text: "
fs: .asciz "%s"
fp1: .asciz "%s is at position %d in the text %s\n"
fp2: .asciz "No match found\n"
fpd: .asciz "%d\n"
fpe: .asciz "pattern is too long\n"
