# RISC V MIPS32 Microprocessor

Verilog, 5 stage pipelined design for a simple 32-bit Reduced Instruction Set Chip (RISC) ISA microprocessor MIPS32 (Microprocessor without Interlocked Pipelined Stages). 

32 bit Program Counter, NO flag registers, very few addressing modes and assuming memory word size is 32 bits.


# Registers

32 Registers of 32 bit each. Register 0 is always read as zero and loads to it have no effect.

# List of Instructions (ONLY A SUBSET OF ACTUAL MIPS32 Instruction set have been executed)

Load and Store Instructions:

	LW  R2, 124(R8)      &nbsp;//R2 = Mem[R8+124]
	SW R5, -10(R42)      &nbsp;//Mem[R42-10] = R5


Arithmetic and Logic Functions on Register Operands: 

	ADD R1, R2, R3    &nbsp;//R1 = R2+R3

	ADD R1, R2, R0    &nbsp;//R1 = R2+0

	SUB R1, R2, R3    &nbsp;//R1 = R2-R3

	AND R1, R2, R3    &nbsp;//R1 = R2 & R3

	OR R1, R2, R3     &nbsp;//R1 = R2 | R3

	MUL R1, R2, R3    &nbsp;//R1 = R2*R3

	SLT R1, R2, R3    &nbsp;//IF R2 < R3, R1 = 1 ; else R1 = 0

	
Arithmetic and Logic Functions on Immediate Operands: 

	ADDI R1, R2, 34    &nbsp;//R1 = R2 + 34

	SUBI R1, R2, 42    &nbsp;//R1 = R2 - 42

	SLTI R1, R2, 16    &nbsp;// IF R2 < 16, R1 = 1; else R1 = 0


Branch Instructions:

	BEQZ R1, LOOP    &nbsp;//Branch to LOOP if R1 == 0

	BNEQZ R2, LOOP   &nbsp;//Branch to LOOP if R2 != 0

Jump Instructions have not been added.

Miscellaneous Instruction
	
	HLT    &nbsp;//HALT execution


# INSTRUCTION ENCODING


R- type, I-type and Jump-type (not included)


1. R-type
		
	|31-26 | 25-21 |20-16 |	15-11 |	11-0|
	| --- | --- | --- | --- | --- |
	|OPCODE| SOURCE Register 1| SOURCE Register 2| Destination Register | <empty>|                         
	
	                                                                                   
	|ADD |000000|  
	|SUB |000001|
	|AND |000010| 
	|OR |000011|
	|SLT |000100|
	|MUL |000101|
	|HLT| 111111|
  
--> SUB R5, R12, R25
		
|000001|01100|11001|00101|00000000000|
|SUB|R12|R25|R5|<empty>|
		
--> 05992800 in hexadecimal
		
	
2. I-type
	
	|31-26|	25-21| 20-16| 15-0|
	|OPCODE| Source Register–1| Destination Register| 16 bit immediate Data|
		
|LW|001000|
|SW|001001|
|ADDI|001010|
|SUBI|001011|
|SLTI|001100|
|BNEQZ|	001101|
|BEQZ|	001110|

--> LW R20, 84(R9)
	
|001000	|01001	|10100	|0000000001010100|
|LW	|R9	|R20	|Offset|
		
-->21340054 in hexadecimal
		
--> BEQZ R25, Label
		|001110|11001|00000|YYYYYYYYYYYYYYYY|
		|BEQZ|R25|Unused|Offset|
		
--> HERE Offset = Number of Instructions we Need to go back +1
		

