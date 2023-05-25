.data 

penis: .asciiz "AbcDEfgHJA"

.text
la $t0, penis
li $t1, 0 #t1 = num upper
li $t2, 10
li $t3, 0
li $t4, 'Z'
loop:
	lbu $t3, 0($t0)
	beqz $t3, done
	addi $t0, $t0, 1
	bgt $t3, $t4, loop
	addi $t1, $t1, 1
	j loop
done:
move $a0, $t1
li $v0, 1
syscall

sub $t1, $t2, $t1
move $a0, $t1
li $v0, 1
syscall

li $v0, 10
syscall
