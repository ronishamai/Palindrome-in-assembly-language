# check if user provided string is palindrome

.data

userInput: .space 64
stringAsArray: .space 256

welcomeMsg: .asciiz "Enter a string: "
calcLengthMsg: .asciiz "Calculated length: "
newline: .asciiz "\n"
yes: .asciiz "The input is a palindrome!"
no: .asciiz "The input is not a palindrome!"
notEqualMsg: .asciiz "Outputs for loop and recursive versions are not equal"

.text

main:

	li $v0, 4
	la $a0, welcomeMsg
	syscall
	la $a0, userInput
	li $a1, 64
	li $v0, 8
	syscall

	li $v0, 4
	la $a0, userInput
	syscall
	
	# convert the string to array format
	la $a1, stringAsArray
	jal string_to_array
	
	addi $a0, $a1, 0
	
	# calculate string length
	jal get_length
	addi $a1, $v0, 0
	
	li $v0, 4
	la $a0, calcLengthMsg
	syscall
	
	li $v0, 1
	addi $a0, $a1, 0
	syscall
	
	li $v0, 4
	la $a0, newline
	syscall
	
	addi $t0, $zero, 0
	addi $t1, $zero, 0
	la $a0, stringAsArray
	
	# Swap a0 and a1
	addi $t0, $a0, 0
	addi $a0, $a1, 0
	addi $a1, $t0, 0
	addi $t0, $zero, 0
	
	# Function call arguments are caller saved
	addi $sp, $sp, -8
	sw $a0, 4($sp)
	sw $a1, 0($sp)
	
	# check if palindrome with loop
	jal is_pali_loop
	
	# Restore function call arguments
	lw $a0, 4($sp)
	lw $a1, 0($sp)
	addi $sp, $sp, 8
	
	addi $s0, $v0, 0
	
	# check if palindrome with recursive calls
	jal is_pali_recursive
	bne $v0, $s0, not_equal
	
	beq $v0, 0, not_palindrome

	li $v0, 4
	la $a0, yes
	syscall
	j end_program

	not_palindrome:
		li $v0, 4
		la $a0, no
		syscall
		j end_program
	
	not_equal:
		li $v0, 4
		la $a0, notEqualMsg
		syscall
		
	end_program:
	li $v0, 10
	syscall
	
string_to_array:	
	add $t0, $a0, $zero
	add $t1, $a1, $zero
	addi $t2, $a0, 64

	
	to_arr_loop:
		lb $t4, ($t0)
		sw $t4, ($t1)
		
		addi $t0, $t0, 1
		addi $t1, $t1, 4
	
		bne $t0, $t2, to_arr_loop
		
	jr $ra


#################################################
#         DO NOT MODIFY ABOVE THIS LINE         #
#################################################
	
get_length: # returns num of bytes (char = 4 bytes)
	lb $t0, newline # $t0 = '\n'
	
	add $v0, $zero, $zero # sets counter to zero
	lw $t1, 0($a0) # $t1 = 1st char from beginning of the string
	
	loop:
		beq $t1, $t0, finish_len # stops when next char is '\n'
		
		# counter += 4 (read one char = 4 bytes)
		addi $t1, $zero, 1 
		sll $t1,$t1, 2
		add $v0, $v0, $t1
		
		 # moving to the next char in string -> $t1:
		addi $a0, $a0, 4
    		lw $t1, 0($a0) 
    		
    		j loop # haven`t finished count chars in string (haven`t seen '/n' yet)
    	
    	finish_len: 
    		jr $ra # exit function: jump to adrress in $ra
	
is_pali_loop: 
# iterative implementation
# $a0 = get_length(string) in bytes
# &a1 = place in memory of the beginning of the string

	# if num of chars in string < 2 -> return is palindrom
	addi $t0, $zero, 2
	sll $t0, $t0, 2
	slt $t0,$a0,$t0 # $t0 = 1 if $a0 < $t0 (string lenth in bytes < 2 chars * 4 bytes)
	bne $t0,$zero,return_is_pali_iter # if $t0 = 1 -> return is palindrom
		
	# init places in memory: $t0 = place of the first char, $t1 = place of the last char
	add $t0, $a1, $zero
	add $t1, $t0, $a0 
	addi $t1, $t1, -4 
		
	check_is_pali_iter:
		# if address of char from end is BEFORE address of char from end -> return is palindrom
		slt $t2,$t1,$t0 
		bne $t2,$zero,return_is_pali_iter
		
		# if address of char from end is EQUAL address of char from end -> return is palindrom
		beq $t0,$t1,return_is_pali_iter
		
		# else: check if char from begin of string == char from end of string:	
				
		# init char from begin - $t0, and char from end - $t1:
		lw $t2, 0($t0)
		lw $t3, 0($t1)
		
		# if char from begin != char from end -> return is not palindrom
		bne $t2, $t3, return_is_not_pali_iter
		
		# update place of the next chars from begin & end of string
		addi $t0, $t0, 4 # moving to the place of the next char in string from start
		addi $t1, $t1, -4 # moving to the place of the next char in string from end
		
		# loop
		j check_is_pali_iter
	
	return_is_pali_iter:
		addi $v0, $zero, 1 # return 1
		j finish_is_pali_iter
	
	return_is_not_pali_iter:
		add $v0, $zero, $zero # return 0
		
	finish_is_pali_iter:	
		jr $ra # exit function: jump to adrress in $ra
	
is_pali_recursive:
# recursive implementation
# $a0 = get_length(string) in bytes
# &a1 = place in memory of the beginning of the string

	addi $sp, $sp, -4 # adjust stack to make room for 3 items
	sw $ra, 0($sp) # save register $ra (address) for use afterwards - we have a call to another function inside the callee
		
	
	# if num of chars in string < 2 -> return is palindrom
	addi $t0, $zero, 2
	sll $t0, $t0, 2
	slt $t0,$a0,$t0 # $t0 = 1 if $a0 < $t0 (string lenth in bytes < 2 chars * 4 bytes)
	bne $t0,$zero,return_is_pali_rec # if $t0 = 1 -> return is palindrom
	
	# init places in memory: $s0 = place of the first char, $s1 = place of the last char
	add $t0, $a1, $zero
	add $t1, $t0, $a0 
	addi $t1, $t1, -4 
	
	# if address of char from end is BEFORE address of char from end -> return is palindrom
	slt $t2,$t1,$t0 
	bne $t2,$zero,return_is_pali_rec
		
	# if address of char from end is EQUAL address of char from end -> return is palindrom
	beq $t0,$t1,return_is_pali_rec
	
	# if char from begin != char from end -> return is not palindrom
	lw $t2, 0($t0)
	lw $t3, 0($t1)
	bne $t2, $t3, return_is_not_pali_rec
	
	j check_is_pali_rec
		
	return_is_pali_rec:
		addi $v0, $zero, 1 # return 1
		jr $ra # exit function: jump to adrress in $ra
	
	return_is_not_pali_rec:
		add $v0, $zero, $zero # return 0
		jr $ra # exit function: jump to adrress in $ra
	
	check_is_pali_rec:
		# update $a0 = string lentgh in bytes - 8
		addi $a0, $a0, -8
		
		# update &a1 = place in memory of the beginning of the string + 4
		addi $a1, $a1, 4
		
		# recurse
		jal is_pali_recursive	
		
		lw $ra, 4($sp) # restore register $ra (address) for caller -  - we had a call to another function inside the callee
		addi $sp, $sp, 4 #  adjust stack to delete 3 items
		jr $ra # exit function: jump to adrress in $ra

