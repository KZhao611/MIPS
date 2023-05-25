null_cipher_sf:
	#a0 = plaintext pointer
	#a1 = ciphertext pointer
	#a2 = indices pointer
	#a3 = num indices 
	li $v0, 0
	
	next_word:
		beqz $a3, null_terminate #there are no more indices left
		addi $a3, $a3, -1
		lw $t1, 0($a2) #t1 = index
		beqz $t1, skip #if index = 0, skip word
		addi $t1, $t1, -1 #because 1-indexed not 0, so when index as at 1 then right char 
		next_letter: #evaluate if it is at right index first, if not then iterate again
			beqz $t1, right_index
			addi $a1, $a1, 1 #next char 
			addi $t1, $t1, -1 #decrease counter/index
			j next_letter
		right_index:
			lbu $t0, 0($a1) #t0 = current char 
			sb $t0, 0($a0) #store char in plaintext
			addi $a0, $a0, 1 #next char in plaintext 
			addi $v0, $v0, 1 #another char in plaintext
		skip:
			addi $a2, $a2, 4 #next int in indices 
		clear_word:
			lbu $t0, 0($a1)
			beqz $t0, null_terminate #end of string 
			addi $t0, $t0, -32 #t0 = 0 if it is a space 
			addi $a1, $a1, 1 #next char, put it in front so it will skip the space after 
			beqz $t0, next_word 
			j clear_word #not a space so go to next char
	null_terminate:
	li $t2, 0
	sb $t2, 0($a0)#add null terminator to end
    jr $ra

transposition_cipher_sf:
	#a0 = plaintext pointer
	#a1 = ciphertext pointer
	#a2 = num rows
	#a3 = num cols
	#ok so we just need to access the column major order text into row major 
	li $t0, 0 #t0 = row number
	li $t1, 0 #t1 = column number 
	li $t2, 0 #t2 = 1d equivalent of 2d array [r][c]
	li $t3, 0 #t3 = current char
	move $t4, $a1 #t4 = moveable pointer 
	li $t5, '*' #t5 = asterisk
	#arr[r][c] = r * num_col + c
	trans_loop: #iterate by starting at [r][0] then adding num_rows each time
		add $t4, $t0, $a1 #set t4 to [r][0]
		li $t1, 0 #t1 = column number 
		next_element_in_row:
			lbu $t3, 0($t4)
			beq $t3, $t5, trans_done #found an asteriks so we are done
			sb $t3, 0($a0)
			add $t4, $t4, $a2 #next element 
			addi $a0, $a0, 1 #next place in plaintext
			addi $t1, $t1, 1 #update column number
			bne $t1, $a3, next_element_in_row #if not end of row, continue 
		addi $t0, $t0, 1 #next row
		bne $t0, $a2, trans_loop #not last row, so continue
	trans_done:
	li $t5, 0
	sb $t5, 0($a0)#add null terminator to end
    jr $ra

decrypt_sf:
	#ok so first we run trans decrypt then null decrypt 
	#need to get a buffer string for the trans decryptions, ideally same length as its ciphertext
	#find the length of ciphertext 
	move $t9, $a0 #don't use t9 in my functions so it is guaranteed to be preserved 
	lw $t7, 4($sp) #t7 = indices pointer
	lw $t6, 0($sp) #t6 = num indices
	
	addi $sp, $sp, -8	
	sw $fp, 4($sp) #store frame pointer 
	sw $ra, 0($sp) #store return address
	move $fp, $sp #frame pointer starts here!!!!!!!!1
	
	li $t0, 0 #t0 = counter
	li $t1, 0 #t1 = char
	length_loop: #length including null terminator 
		lbu $t1, 0($a1)
		addi $a1, $a1, 1 #next char 
		addi $t0, $t0, 1 #increment count
		bnez $t1, length_loop
	sub $a1, $a1, $t0
	addi $sp, $sp, -4 #keep it word aligned for length
	sw $t0, 0($sp) #equal to -4(fp)
	
	sub $sp, $sp, $t0 #move the stack pointer down by the required space
	move $a0, $sp
	move $t8, $a0 #t8 = plaintext cipher pointer
	jal transposition_cipher_sf 
	move $a1, $t8 #a1 = null ciphertext 
	move $a0, $t9 #a0 = plaintext pointer
	move $a2, $t7 #a2 = indices poitner
	move $a3, $t6 #a3 = num indices
	jal null_cipher_sf #already sets v0 to the right value
	lw $t0, -4($fp) 
	add $sp, $sp, $t0 #deallocate the middle string 
	addi $sp, $sp, 4 #deallocate the length counter 
	lw $ra, 0($sp)
	lw $fp, 4($sp)
	addi $sp, $sp, 8 #deallocate ra and fp
    jr $ra
