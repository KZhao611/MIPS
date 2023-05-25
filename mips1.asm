.data
# Command-line arguments
num_args: .word 0
addr_arg0: .word 0
addr_arg1: .word 0
addr_arg2: .word 0
addr_arg3: .word 0
addr_arg4: .word 0
no_args: .asciiz "You must provide at least one command-line argument.\n"

# Output messages
straight_str: .asciiz "STRAIGHT_HAND"
four_str: .asciiz "FOUR_OF_A_KIND_HAND"
pair_str: .asciiz "TWO_PAIR_HAND"
unknown_hand_str: .asciiz "UNKNOWN_HAND"

# Error messages
invalid_operation_error: .asciiz "INVALID_OPERATION"
invalid_args_error: .asciiz "INVALID_ARGS"

# Put your additional .data declarations here, if any.
hex_start: .ascii "0x"

# Main program starts here
.text
.globl main
main:
    # Do not modify any of the code before the label named "start_coding_here"
    # Begin: save command-line arguments to main memory  
    sw $a0, num_args
    beqz $a0, zero_args
    li $t0, 1
    beq $a0, $t0, one_arg
    li $t0, 2
    beq $a0, $t0, two_args
    li $t0, 3
    beq $a0, $t0, three_args
    li $t0, 4
    beq $a0, $t0, four_args
five_args:
    lw $t0, 16($a1)
    sw $t0, addr_arg4
four_args:
    lw $t0, 12($a1)
    sw $t0, addr_arg3
three_args:
    lw $t0, 8($a1)
    sw $t0, addr_arg2
two_args:
    lw $t0, 4($a1)
    sw $t0, addr_arg1
one_arg:
    lw $t0, 0($a1)
    sw $t0, addr_arg0
    j start_coding_here

zero_args:
    la $a0, no_args
    li $v0, 4
    syscall
    j exit
    # End: save command-line arguments to main memory

start_coding_here: 
    # Start the assignment by writing your code here
    lw $t2, addr_arg0 #address of the first char in arg0 
    lbu $s0, 1($t2)  #char after first one
    bnez $s0, invalid_operation #if there is no null terminator after the one character then it is not of length 1
    lbu $s0, 0($t2) #Store the first argument in s0
    lw $s1, num_args #number of arguments in s1
    li $t1, 'E' #Store ascii of E in t1
    li $t2, 'D' #ascii of D in t2
    li $t3, 'P' #ascii of P in t3
    beq $s0, $t1, arg0_E
    beq $s0, $t2, arg0_D
    beq $s0, $t3, arg0_P
invalid_operation: 
	la $a0, invalid_operation_error
	li $v0, 4
	syscall
	j exit
invalid_arguments:
	la $a0, invalid_args_error
	li $v0, 4
	syscall
	j exit
arg0_E:
	li $t1, 5
	bne $s1, $t1, invalid_arguments #not five args
	
	lw $a0, addr_arg1
	jal parse_string
	move $s1, $v0 #store the opcode
	li $t2, 63 
	bgt $s1, $t2, invalid_arguments
	
	
	lw $a0, addr_arg2
	jal parse_string
	move $s2, $v0 #store the rs
	li $t2, 31
	bgt $s2, $t2, invalid_arguments
	
	lw $a0, addr_arg3
	jal parse_string
	move $s3, $v0 #store the rt
	li $t2, 31
	bgt $s3, $t2, invalid_arguments
	
	lw $a0, addr_arg4
	jal parse_string
	move $s4, $v0 #store the immediate
	li $t2, 65535 
	bgt $s4, $t2, invalid_arguments
	
	#shift and sum
	sll $s1, $s1, 26
	sll $s2, $s2, 21
	sll $s3, $s3, 16
	add $s4, $s4, $s3
	add $s4, $s4, $s2
	add $s4, $s4, $s1
	#print in hex
	move $a0, $s4
	li $v0, 34
	syscall

	j exit 
arg0_D:
	li $t1, 2
	bne $s1, $t1, invalid_arguments #not 2 args
	#validate it beginning with 0x
	lw $t1, addr_arg1
	la $t2, hex_start
	lbu $t3, 0($t1)
	lbu $t4, 0($t2)
	bne $t3, $t4, invalid_arguments
	lbu $t3, 1($t1)
	lbu $t4, 1($t2)
	bne $t3, $t4, invalid_arguments
	#validate length of 10
	lbu $t3, 10($t1)
	bnez $t3, invalid_arguments
	
	li $s1, 0 #initialize sum to 0
	li $s2, 0 #initialize count to 0
	li $s7, 8 #8 runs of loop because 4 bytes  
	li $t4, '0'
	li $t5, '9'
	li $t6, 'a'
	li $s5, 'f'
	addi $t1, $t1, 2 #skip past 0x
	D_loop:
		sll $s1, $s1, 4 #multiply by 16 
		lbu $t3, 0($t1) #load ascii into t3
		#validate input, ascii is numbers < letters 
		bgt $t3, $s5, invalid_arguments #past f
		blt $t3, $t4, invalid_arguments #before 0
		bge $t3, $t6, valid_let #after or equal to a
		ble $t3, $t5, valid_int #before or equal to 9
		j invalid_arguments
		
		valid_int:
			addi $t2, $t3, -48 #decimal value
			add $s1, $t2, $s1
			j incr
		valid_let:
			addi $t2, $t3, -87 #87 so a = 10...
			add $s1, $t2, $s1
		incr:
			addi $t1, $t1, 1 #go to next char
			addi $s2, $s2, 1 #increment counter
			bne $s2, $s7, D_loop #go back if not 8 runs yet
	#print opcode t4 = section to print 
	srl $t4, $s1, 26
	move $a0, $t4
	li $a1, 2#width = 2
	jal print_int
	move $a0, $t4
	li $v0, 1
	syscall #print 
	li $v0, 11
	li $a0, 32
	syscall
	
	sll $s1, $s1, 6 #nuke 6 leftmost bits
	srl $s1, $s1, 6
	srl $t4, $s1, 21
	move $a0, $t4
	li $a1, 2#width = 2
	jal print_int
	move $a0, $t4
	li $v0, 1
	syscall #print 
	li $v0, 11
	li $a0, 32
	syscall
	
	sll $s1, $s1, 11 #nuke 11 leftmost bits
	srl $s1, $s1, 11
	srl $t4, $s1, 16
	move $a0, $t4
	li $a1, 2#width = 2
	jal print_int
	move $a0, $t4
	li $v0, 1
	syscall #print 
	li $v0, 11
	li $a0, 32
	syscall
	
	sll $s1, $s1, 16 #nuke 16 leftmost bits
	srl $s1, $s1, 16
	move $a0, $s1
	li $a1, 5#width = 5
	jal print_int
	move $a0, $s1
	li $v0, 1
	syscall #print 
	
	j exit
arg0_P:
	li $t1, 2
	bne $s1, $t1, invalid_arguments #not 2 args
	#in order to get the suit and rank, divide by 16 and the suit is in lo, rank in hi
	li $t1, 16 #divisor 
	lw $t0, addr_arg1 #address of arg
	lbu $t2, 0($t0) #first ascii
	div $t2, $t1 
	mfhi $s0 #rank
	
	lbu $t2, 1($t0) #second ascii 
	div $t2, $t1 
	mfhi $s1 #rank
	
	lbu $t2, 2($t0) #third ascii 
	div $t2, $t1 
	mfhi $s2 #rank
	
	lbu $t2, 3($t0) #fourth ascii
	div $t2, $t1 
	mfhi $s3 #rank
	 
	lbu $t2, 4($t0) #fifth ascii 
	div $t2, $t1 
	mfhi $s4 #rank
	
	#can use t again, we can check a straight by finding the range and seeing if there are no pairs 
	move $t0, $s0 #t0 = min
	move $t1, $s0 #t1 = max
	
	ble $s1, $t1, _2_not_max
		move $t1, $s1 #s1 is greater than max
	_2_not_max:
	bge $s1, $t0, _2_not_min
		move $t0, $s1 #s1 is less than min 
	_2_not_min:
	
	ble $s2, $t1, _3_not_max
		move $t1, $s2 #s2 is greater than max
	_3_not_max:
	bge $s2, $t0, _3_not_min
		move $t0, $s2 #s2 is less than min 
	_3_not_min:
	
	ble $s3, $t1, _4_not_max
		move $t1, $s3 #s3 is greater than max
	_4_not_max:
	bge $s3, $t0, _4_not_min
		move $t0, $s3 #s3 is less than min 
	_4_not_min:
	
	ble $s4, $t1, _5_not_max
		move $t1, $s4 #s4 is greater than max
	_5_not_max:
	bge $s4, $t0, _5_not_min
		move $t0, $s4 #s4 is less than min 
	_5_not_min:
	
	sub $t2, $t1, $t0 #range has to equal 4
	addi $t2, $t2, -4 #t2 = 0 if it is a possible straight 
	
	#now check how many pairs there are
	li $t3, 0 #num pairs 
	li $t4, 0 #does max same rank ever equal 3
	li $t5, 0 #= 1 if max same rank equals 3
	
	bne $s0, $s1, one_two
		addi $t3, $t3, 1
		addi $t4, $t4, 1
	one_two:
	bne $s0, $s2, one_three
		addi $t3, $t3, 1
		addi $t4, $t4, 1
	one_three:
	bne $s0, $s3, one_four
		addi $t3, $t3, 1
		addi $t4, $t4, 1
	one_four:
	bne $s0, $s4, one_five
		addi $t3, $t3, 1
		addi $t4, $t4, 1
	one_five:
	#see if t4 = 2, then three of the same rank
	addi $t4, $t4 ,-2
	bnez $t4, one_not_triple
		li $t5, 1
	one_not_triple:
	li $t4, 0
	
	
	bne $s1, $s2, two_three
		addi $t3, $t3, 1
		addi $t4, $t4, 1
	two_three:
	bne $s1, $s3, two_four
		addi $t3, $t3, 1
		addi $t4, $t4, 1
	two_four:
	bne $s1, $s4, two_five
		addi $t3, $t3, 1
		addi $t4, $t4, 1
	two_five:
	#see if the second card is a triplet
	addi $t4, $t4, -2
	bnez $t4, two_not_triple
		li $t5, 1
	two_not_triple:
	li $t4, 0
	
	bne $s2, $s3, three_four
		addi $t3, $t3, 1
		addi $t4, $t4, 1
	three_four:
	bne $s2, $s4, three_five
		addi $t3, $t3, 1
		addi $t4, $t4, 1
	three_five:
	#see if last three cards are a triple
	addi $t4, $t4,  -2
	bnez $t4, three_not_triple
		li $t5, 1
	three_not_triple:
	li $t4, 0
	
	bne $s3, $s4, four_five
		addi $t3, $t3, 1
	four_five:
	
	bnez $t3, not_straight #there is at least one pair
		bnez $t2, not_straight#range is not 4
			la $a0, straight_str
			li $v0, 4
			syscall
			j exit
	not_straight:
	
	li $t6, 6
	bne $t3, $t6, not_four #there is not 6 pairs, first card will have 3, second have 2, an third have 1
		la $a0, four_str
		li $v0, 4
		syscall
		j exit
	not_four:
	
	li $t6, 3 #if there are three of the same rank, must be 3 pairs for a two pair
	beqz $t5, no_triple #if t5 is 0, there is no triple 
		bne $t3, $t6, unknown
			la $a0, pair_str
			li $v0, 4
			syscall
			j exit
	no_triple:
		li $t6, 2 #no triple, so only two pairs for a two pair
		bne $t3, $t6, unknown 
			la $a0, pair_str
			li $v0, 4
			syscall
			j exit
	unknown:
	la $a0, unknown_hand_str
	li $v0, 4
	syscall

exit:
    li $v0, 10
    syscall
	
parse_string:
    li $v0, 0 #initialize v0
    lbu $t1, 0($a0)#load the ascii value into $t1
    li $t9, 10 #load the value 10 into $t9
	parse_string_loop: #loop
    	mult $v0, $t9
	    mflo $v0
	    addi $t1, $t1, -48 #convert the ascii to decimal
	    add $v0, $v0, $t1 #add the decimal value to the current integer value
	    addi $a0, $a0, 1 #next char
	    lbu $t1, 0($a0) #load next char ascii
	    bnez $t1, parse_string_loop #if the character is not null, loop back to continue
	jr $ra  
	
print_int:
	#a1 = width, a0 = number
	li $t1, 10 #10
	print_int_loop:
		div $a0, $t1
		addi $a1, $a1, -1
		mflo $a0
		bnez $a0, print_int_loop
	li $a0, 0 #reduntant but better readability
	li $v0, 1
	beqz $a1, no_zero 
	print_zeroes:
		 syscall
		 addi $a1, $a1, -1
		 bnez $a1, print_zeroes
	no_zero:
	jr $ra
		
