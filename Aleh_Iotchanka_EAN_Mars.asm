## Aleh Iotchanka
# conversion of 8-digit decimal sequence of numbers to EAN-8 code, saved in BMP file
# input file is free bmp file named input.bmp with size (67x1 - 512x512)
# output file is output.bmp

.eqv	address_of_head    0
.eqv	address_of_image   4
.eqv	size_of_file       8
.eqv	width_of_image    12
.eqv	height_of_image   16
.eqv	size_of_row       20
.eqv	length_of_code	   67
.eqv	nr_of_bytes       33000
	
.data	
# data needed for text transformation
	dec_data:    .space 8
	dec_code:    .asciiz "16032001"
	bin_code:    .asciiz ""
	code_data:   .space length_of_code
	bin_data:    .space 70
		                     
# binary representation of barcode digits
	cipher:      .asciiz "0001101001100100100110111101010001101100010101111011101101101110001011" 
			     
			     #0001101     0
			     #0011001     1
			     #0010011     2
			     #0111101     3
			     #0100011     4
			     #0110001     5
			     #0101111     6
			     #0111011     7
			     #0110111     8
			     #0001011     9
						
# data needed for code drawing
	image_despription: .word 0
		            .word 0
		            .word 0
		            .word 0
		            .word 0
		            .word 0
	image:	            .space nr_of_bytes
	name_of_imp:	.asciiz "input.bmp"
	name_of_out:	.asciiz "output.bmp"

.text
	
#start the program
	main:
		jal	decrypt	        # code development
		jal	open_rfile	# open file and save information
		jal	draw	        # EAN8 drawing
		j	open_wfile	# saving and closing a file
		
# recoding a string of numbers into binary code		
# $a0: 0 dla kodu EAN typu A, 1 dla C; 
#$a1: ilosc znakow
	decrypt:    
		la	$t9, ($ra)
		la	$s0, bin_code
		la	$s1, dec_code
		li	$a0, '1'	# first character
		li	$a1, 3		# number of characters
		li	$a2, 1	
		jal	m_loop
		li	$a0, 0		# 0 for A, 1 for C (EAN8 code types)
		li	$a1, 4		# loop counter
		jal	encrypt
		li	$a0, '0'
		li	$a1, 5
		jal	m_loop
		li	$a0, 1
		li	$a1, 4
		jal	encrypt
		li	$a0, '1'
		li	$a1, 3
		jal	m_loop
		jr	$t9
	
	encrypt:
		lbu	$s2, ($s1)
		subiu	$s2, $s2, '0'
		la	$s3, ($s2)
		sll	$s2, $s2, 3
		subu	$s2, $s2, $s3
		la	$s3, cipher	# loading
		addu	$s3, $s3, $s2	# shift cipher address by 7 * number in dec_code (every dec number is 7-numbers binaty-kod)
		li	$s2, 0		# loop counter
	loop:
		lbu	$s4, ($s3)
		beq	$a0, 0, code_not_c
		# negations
		subiu	$s4, $s4, '0'	
		nor	$s4, $s4, $s4	
		addiu	$s4, $s4, '2'	
	code_not_c:
		sb	$s4, ($s0)
		addiu	$s3, $s3, 1
		addiu	$s0, $s0, 1
		addiu	$s2, $s2, 1
		blt	$s2, 7, loop
		addiu	$s1, $s1, 1	# move to the next dec_code character
		subiu   $a1, $a1, 1
		bgtz	$a1, encrypt
		jr	$ra

# $a0: first sign; 
# $a1: amount of signs to repeat; 
# $a2:0 if non-repeating 11111..., 1 if its changing numbers 10101...
	m_loop:
		sb	$a0, ($s0)
		addiu	$s0, $s0, 1
		subiu	$a1, $a1, 1
		beqz	$a2, m_loop_end
		beq	$a0, '1', m_loop_2
	m_loop_1:
		addiu	$a0, $a0, 1
		j	m_loop_end
	m_loop_2:
		subiu	$a0, $a0, 1
	m_loop_end:
		bgtz	$a1, m_loop
		jr	$ra

# code drawing
	draw:
		la	$t9, ($ra)
		li	$a1, 0			# x = 0
		li	$a3, 1			# 0 = white, 1 = black
		la	$t3, bin_code
		li	$t8, 0			# loop counter
	draw_code:
		li	$a2, 0			# y = 0
		lbu	$s5, ($t3)
		beq	$s5, '0', draw_check	# skips if is '0'
		jal	set_of_mask		# sets the mask in $t1 and size_of_row in $t3
	draw_line:
		sb	$s1, 0($s0)		# enters the mask to the address
		addu	$s0, $s0, $s3		# adds address to rowsize
		addiu	$a2, $a2, 1
		blt	$a2, $t2, draw_line	# checks that the line is not the height of the file
	draw_check:
		addiu	$t8, $t8, 1
		addiu	$a1, $a1, 1
		blt	$t8, $t7, draw_code
		li	$t8, 0
		addiu	$t3, $t3, 1
		blt	$a1, $t1, draw_code	# checks that the line is not the maximal weidt of the file
		jr	$t9		
	set_of_mask:       
		lw	$s3, size_of_row ($t0)
		srl	$s1, $a1, 3		# horizontal shift by full bytes
		lw	$s0, address_of_image($t0)
		add	$s0, $s0, $s1		# address of the pixel containing byte
		andi	$s1, $a1, 0x07		# pixel index in byte
		li	$s2, 0x80		# bitmask of the highest bit
		srlv	$s2, $s2, $s1
		lb	$s1, 0($s0)		# 8 pixel image
		nor	$s2, $s2, $s2		# negation of mask
		and	$s1, $s1, $s2		# set black color , sum of mask and 8 bits
		jr	$ra

# opening a file and saving information
# version for reading file
	open_rfile:
		la	$a0, name_of_imp
		li	$a1, 0			
		li	$a2, 0
		li	$v0, 13
		syscall
		bltz	$v0, exit		# if plik not open , exit
	read_file:
		move	$a0, $v0
		la	$a1, image
		li	$a2, nr_of_bytes
		li	$v0, 14
		syscall
		move	$s0, $v0		# keep file size
	close_rfile:
		li	$v0, 16
		syscall
	save_file:
		la	$t0, image_despription
		sw	$a1, size_of_file($t0)
		sw	$v0, address_of_head($t0)
		lhu	$s0, 10($a1)		# image shift from start of file
		addu	$s1, $a1, $s0
		sw	$s1, address_of_image($t0)
		lhu	$s0, 18($a1)		# width of image 
		sw	$s0, width_of_image ($t0)
		lhu	$s0, 22($a1)		# heidth of image
		sw	$s0, height_of_image($t0)
	set_size_of_row:
# set width and heigth of image in pixels
		lw	$s0, width_of_image ($t0)	
		lw	$t2, height_of_image($t0)	
		la	$s1, ($s0)
		li	$t1, 0
	logic_of_image:    # extract information from a picture
		addiu	$t1, $t1, 1
		srl	$s1, $s1, 1
		bgt	$s1, 1, logic_of_image		
	       	div	$t7, $s0, length_of_code			
        	srl	$s0, $s0, 3
		srl	$s6, $s0, 2
		sll	$s6, $s6, 2
		subu	$s6, $s0, $s6
		beqz	$s6, add_4
		addiu	$s0, $s0, 4
	add_4:
		subu	$s0, $s0, $s6
		sw	$s0, size_of_row ($t0)
		mul	$t1, $t7, length_of_code	# weidth of all code EAN8		
		jr	$ra

# save and close a file
# only write
	open_wfile:
		la	$a0, name_of_out
		li	$a1, 1			
		li	$a2, 0
		li	$v0, 13
		syscall
	write_file:
		move	$a0, $v0
		la	$a1, image
		li	$a2, nr_of_bytes
		li	$v0, 15
		syscall
	close_wfile:
		li	$v0, 16
		syscall
	exit:
		li	$v0, 10
		syscall
