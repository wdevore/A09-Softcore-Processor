Tool for hex calcs
http://www.eecs.umich.edu/courses/eng100/calc.html
OR
https://www.rapidtables.com/convert/number/index.html


# Nop_Halt.dat
## Usage:
`> make sim ROM=Nop_Halt CYCLES=10`
```
Adr Hex     Binary                  Assembly
...
@05 1000    0001_0000_0000_0000     NOP
@06 B000    1011_0000_0000_0000     HLT
...
@FF 0005                            ---          Reset Vector
```

# Nop_Ld.dat
## Usage:
`> make sim ROM=Nop_Ld CYCLES=13`
```
Adr Hex     Binary                  Assembly
@05 1000    0001_0000_0000_0000     NOP
@06 91A5    1001_0001_1010_0101     LDI R1, 0xA5
@07 B000    1011_0000_0000_0000     HLT
@FF 0005                            ---          Reset Vector
```

# Nop_Out_Ld.dat
## Usage:
`> make sim ROM=Nop_Ld CYCLES=13`
```
Adr Hex     Binary                  Assembly
@05 1000    0001_0000_0000_0000     NOP
@06 91A5    1001_0001_1010_0101     LDI R1, 0xA5
@07 A001    1010_0000_0000_0001     OTR R1   Copy Reg 1 to output
@08 B000    1011_0000_0000_0000     HLT
@FF 0005                            ---          Reset Vector
```

# Out_Reg_Nop.dat
## Usage:
`> make sim ROM=Out_Reg_Nop CYCLES=15`
```
Adr Hex     Binary                  Assembly
@00 91A5    1001_0001_1010_0101     LDI R1, 0xA5
@01 1000    0001_0000_0000_0000     NOP
@02 A001    1010_0000_0000_0001     OTR R1    Copy Reg 1 to output
@03 B000    1011_0000_0000_0000     HLT
@FF 0000                            ---          Reset Vector
```

# JMP_Halt.dat
Shows that the Jump instruction works by writing 9 to output.
If it fails then R1's output is the last thing written.
## Usage:
`> make sim ROM=JMP_Halt CYCLES=18`
```
Adr Hex     Binary                  Assembly
@00 9106    1001_0001_0000_0110     LDI R1, 0x06 <-- absolute address
@01 A001    1010_0000_0000_0001     OTR R1
@02 7001    0111_0000_0000_0001     JMP R1   --------.
@03 1000    0001_0000_0000_0000     NOP              |
@04 1000    0001_0000_0000_0000     NOP              |
@05 B000    1011_0000_0000_0000     HLT              |
@06 9209    1001_0010_0000_1001     LDI R2, 0x09  <--. Jump to here
@07 A002    1010_0000_0000_0010     OTR R2
@08 B000    1011_0000_0000_0000     HLT
@FF 0000                            ---          Reset Vector
```

# JPL_1_Halt.dat
Shows Jump-Ret. First output R2 followed by R1 and halt.
## Usage:
`> make sim ROM=JPL_1_Halt CYCLES=22`
```
Adr Hex     Binary                  Assembly
@00 910A    1001_0001_0000_1010     LDI R1, 0x0A
@01 9255    1001_0010_0101_0101     LDI R2, 0x55
@02 C001    1100_0000_0000_0001     JPL R1  >--.
@03 A001    1010_0000_0000_0001     OTR R1     |
@04 B000    1011_0000_0000_0000     HLT        |     
@0A A002    1010_0000_0000_0010     OTR R2  <--.
@0B 1000    0001_0000_0000_0000     NOP
@0C 8000    1000_0000_0000_0000     RET   
@FF 0000                            ---          Reset Vector
```

```
=======================================================================
== Part 2
=======================================================================
```


# Shift_Left.dat
Shifts R1 5 places to the left.

`0000_0000_0000_0001  --> 0000_0000_0010_0000`

## Usage:
`> make sim ROM=Shift_Left CYCLES=20`
```
Adr Hex     Binary                  Assembly
@00 9101    1001_0001_0000_0001     LDI R1, 0x01
@01 A001    1010_0000_0000_0001     OTR R1
@02 9205    1001_0010_0000_0101     LDI R2, 0x05
@03 A002    1010_0000_0000_0010     OTR R2
@04 4051    0100_0000_0101_0001     SHL R1, R1, R2  = R1 <-- R1 << R2
@05 A001    1010_0000_0000_0001     OTR R1
@06 B000    1011_0000_0000_0000     HLT
@FF 0000                            ---          Reset Vector
```

# Shift_Right.dat
Shifts R1 3 places to the right.

`0000_0000_0000_1000  --> 0000_0000_0000_0001`

## Usage:
`> make sim ROM=Shift_Right CYCLES=20`
```
Adr Hex     Binary                  Assembly
@00 9108    1001_0001_0000_1000     LDI R1, 0x08
@01 A001    1010_0000_0000_0001     OTR R1
@02 9203    1001_0010_0000_0011     LDI R2, 0x03
@03 A002    1010_0000_0000_0010     OTR R2
@04 5051    0101_0000_0101_0001     SHR R1, R1, R2  = R1 <-- R1 >> R2
@05 A001    1010_0000_0000_0001     OTR R1
@06 B000    1011_0000_0000_0000     HLT
@FF 0000                            ---          Reset Vector
```

# Shift_Right_Carry.dat
Shifts R1 1 place to the right causing the Carry flag to Set.

`0000_0000_0000_1001  --> 0000_0000_0000_0100`  --> 1 => Carry

## Usage:
`> make sim ROM=Shift_Right_Carry CYCLES=20`
```
Adr Hex     Binary                  Assembly
@00 9109    1001_0001_0000_1001     LDI R1, 0x09
@01 A001    1010_0000_0000_0001     OTR R1
@02 9201    1001_0010_0000_0001     LDI R2, 0x01
@03 A002    1010_0000_0000_0010     OTR R2
@04 5051    0101_0000_0101_0001     SHR R1, R1, R2  = R1 <-- R1 >> R2
@05 A001    1010_0000_0000_0001     OTR R1
@06 B000    1011_0000_0000_0000     HLT
@FF 0000                            ---          Reset Vector
```

# Add_Halt.dat

2 + 5 = 7

## Usage:
`> make sim ROM=Add_Halt CYCLES=20`
```
Adr Hex     Binary                  Assembly
@00 9102    1001_0001_0000_0010     LDI R1, 0x02
@01 A001    1010_0000_0000_0001     OTR R1
@02 9205    1001_0010_0000_0101     LDI R2, 0x05
@03 A002    1010_0000_0000_0010     OTR R2
@04 20D1    0010_0000_1101_0001     ADD R3, R2, R1
@05 A003    1010_0000_0000_0011     OTR R3
@06 B000    1011_0000_0000_0000     HLT
@FF 0000                            ---          Reset Vector
```

# Sub_Halt.dat

4 - 2 = 2

## Usage:
`> make sim ROM=Sub_Halt CYCLES=20`
```
Adr Hex     Binary                  Assembly
@00 9102    1001_0001_0000_0010     LDI R1, 0x02
@01 A001    1010_0000_0000_0001     OTR R1
@02 9204    1001_0010_0000_0100     LDI R2, 0x04
@03 A002    1010_0000_0000_0010     OTR R2
@04 30CA    0011_0000_1100_1010     SUB R3, R1, R2
@05 A003    1010_0000_0000_0011     OTR R3
@06 B000    1011_0000_0000_0000     HLT
@FF 0000                            ---          Reset Vector
```

# BNE_Halt.dat
Add 2 numbers and check that the Z-flag is NOT set. If not then take branch, thus the output register should have 0004, not 0007.

## Usage:
`> make sim ROM=BNE_Halt CYCLES=28`
```
Adr Hex     Binary                  Assembly
@00 9102    1001_0001_0000_0010     LDI R1, 0x02
@01 A001    1010_0000_0000_0001     OTR R1
@02 9205    1001_0010_0000_0101     LDI R2, 0x05
@03 A002    1010_0000_0000_0010     OTR R2
@04 20D1    0010_0000_1101_0001     ADD R3, R2, R1   = 7
@05 A003    1010_0000_0000_0011     OTR R3
@06 6004    0110_0000_0000_0100     BNE 0x04     -------
@07 1000    0001_0000_0000_0000     NOP                 |
@08 1000    0001_0000_0000_0000     NOP                 |  Branch
@09 B000    1011_0000_0000_0000     HLT                 |  to here
@0A 9204    1001_0010_0000_0100     LDI R2, 0x04  <-----
@0B A002    1010_0000_0000_0010     OTR R2
@0C B000    1011_0000_0000_0000     HLT
@FF 0000                            ---          Reset Vector
```

# Count_Up.dat
Counts up in steps of 2
## Usage:
`> make sim ROM=Count_Up CYCLES=50`
```
Adr Hex     Binary                  Assembly
@00 9100    1001_0001_0000_0000     LDI R1, 0x00  <-- Counter
@01 9202    1001_0010_0000_0010     LDI R2, 0x02  <-- Count by 2
@02 9306    1001_0011_0000_0110     LDI R3, 0x06  <-- Count up to 6
@03 2051    0010_0000_0101_0001     ADD R1, R2, R1   <---.  Inc
@04 A001    1010_0000_0000_0001     OTR R1               |
@05 3419    0011_0100_0001_1001     CMP R3, R1           |  Compare
@06 60FD    0110_0000_1111_1100     BNE -3  >------------.  Loop until 0
@07 B000    1011_0000_0000_0000     HLT
@FF 0000                            ---          Reset Vector
```

# Count_Down.dat
Counts down to zero
## Usage:
`> make sim ROM=Count_Down CYCLES=50`
```
Adr Hex     Binary                  Assembly
@00 9105    1001_0001_0000_0101     LDI R1, 0x05  <-- Counter (A)
@01 9201    1001_0010_0000_0001     LDI R2, 0x01  <-- Count down by 1 (B)
@02 3051    0011_0000_0101_0001     SUB R1, R2, R1   <---. Dec (A - B)
@03 A001    1010_0000_0000_0001     OTR R1               |
@04 60FE    0110_0000_1111_1101     BNE -2    >----------.  Loop until 0
@05 B000    1011_0000_0000_0000     HLT
@FF 0000                            ---          Reset Vector
```

# Count_Out.dat
Counts to F
## Usage:
`> make sim ROM=Count_Out CYCLES=180`
```
Adr Hex     Binary                  Assembly
@00 9100    1001_0001_0000_0000     LDI R1, 0x00  <-- Counter
@01 9201    1001_0010_0000_0001     LDI R2, 0x01  <-- Count by 1
@02 930F    1001_0011_0000_1111     LDI R3, 0x0F  <-- Count up to F
@03 2051    0010_0000_0101_0001     ADD R1, R2, R1   <---.  Inc
@04 A001    1010_0000_0000_0001     OTR R1               |
@05 3419    0011_0100_0001_1001     CMP R3, R1           | Compare
@06 60FD    0110_0000_1111_1100     BNE -3   >-----------. Loop until 0
@07 B000    1011_0000_0000_0000     HLT
@FF 0000                            ---          Reset Vector
```

# JPL_Halt.dat
Use a sub routine to increment counter to 3
## Usage:
`> make sim ROM=JPL_Halt CYCLES=75`
```
Adr Hex     Binary                  Assembly
@00 910A    1001_0001_0000_1010     LDI R1, 0x0A  <-- Sub routine addr
@01 9200    1001_0010_0000_0000     LDI R2, 0x00  <-- Counter
@02 9303    1001_0011_0000_0011     LDI R3, 0x03  <-- Count up to 3
@03 9401    1001_0100_0000_0001     LDI R4, 0x01  <-- Count by 1
@04 C001    1100_0000_0000_0001     JPL R1   <--------.
@05 A002    1010_0000_0000_0010     OTR R2            |
@06 341A    0011_0100_0001_1010     CMP R3, R2        |  Compare
@07 60FD    0110_0000_1111_1100     BNE -3  >---------.  Loop until 0
@08 1000    0001_0000_0000_0000     NOP
@09 B000    1011_0000_0000_0000     HLT              
@0A 20A2    0010_0000_1010_0010     ADD R2, R4, R2  <-- Sub routine
@0B 1000    0001_0000_0000_0000     NOP
@0C 8000    1000_0000_0000_0000     RET   
@FF 0000                            ---          Reset Vector
```

# Cylon.dat
R1 contains the pattern visible on the output.
A single bit bounces back and forth within a single byte.
The program never stops.
## Usage:
`> make sim ROM=Cylon CYCLES=200`
```
Adr Hex     Binary                  Assembly
@00 9101    1001_0001_0000_0001     LDI R1, 0x01  <-- Pattern
@01 9201    1001_0010_0000_0001     LDI R2, 0x01  <-- Shift by 1
@02 9380    1001_0011_1000_0000     LDI R3, 0x80  <-- Left limit
@03 9401    1001_0100_0000_0001     LDI R4, 0x01  <-- Right limit
@04 9506    1001_0100_0000_0110     LDI R5, 0x06  <-- Jump address to SHL
@05 A001    1010_0000_0000_0001     OTR R1
@06 4051    0100_0000_0101_0001     SHL R1, R1, R2  <----.   <-------.
@07 A001    1010_0000_0000_0001     OTR R1               |           |
@08 3419    0011_0100_0001_1001     CMP R3, R1           |           |
@09 60FD    0110_0000_1111_1100     BNE -3    >----------. while !=  |
@0A 5051    0101_0000_0101_0001     SHR R1, R1, R2  <----.           |
@0B A001    1010_0000_0000_0001     OTR R1               |           |
@0C 3421    0011_0100_0010_0001     CMP R4, R1           |           |
@0D 60FD    0110_0000_1111_1100     BNE -3    >----------. while !=  |
@0E 7005    0111_0000_0000_0101     JMP R5  <-- Rinse and Repeat >---.
@0F B000    1011_0000_0000_0000     HLT     <-- Never executed
@FF 0000                            ---           Reset Vector
```

## --------------------------
# chip.bin: ${SUB_MODULES_FILES} ${PCF}
# 	yosys -q -p "synth_ice40 -blif chip.blif" ${SUB_MODULES_FILES}
# 	~/.apio/packages/toolchain-ice40/bin/nextpnr-ice40 --hx8k --package tq144:4k --asc chip.asc --pcf blink.pcf -l next.log -q
# 	~/.apio/packages/toolchain-ice40/bin/icepack chip.txt chip.bin

# .PHONY: upload
# upload:
# 	stty -F /dev/ttyACM1 raw
# 	cat chip.bin >/dev/ttyACM1

# .PHONY: clean
# clean:
# 	$(RM) -f chip.blif chip.txt chip.ex chip.bin
