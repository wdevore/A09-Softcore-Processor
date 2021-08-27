# Files and Folders

```
Processor
   \Simulation
   \Synthesis
      \TinyFPGAB2
         \register
      \BlackiceMx
   \Modules
   \Roms
```

## Simulation
This folder contains all the test bench flows

## Systhesis
This folder contains the implementation flows

## Modules
This folder contains all the modules that support the processor.

## Roms
This folder contains all the rom images for exercising the processor

# Building yosys
sudo apt-get install tcl-dev
sudo apt-get install libreadline-dev

sudo apt-get install libeigen3-dev

##### Simulating via iverilog...
VCD info: dumpfile /media/RAMDisk/mealy_tb.vcd opened for output.
         0 mealy_tb: Starting testbench simulation...
         0 S_Reset
         0 S_Vector1
         0 Register reset
       200 Register reset
       400 Register reset
       600 Register reset
       700 S_Reset
       700 S_Vector2
       800 Register Load: (11111111) ff
       900 S_Reset
       900 S_Vector3
      1100 S_Reset
      1100 S_Vector4
      1300 S_Ready
      1500 S_HALT
      2250 mealy_tb: Testbench simulation Finished.

------- Top MEM contents ------
memory[  0] = 0001000000010000 <- 1010
memory[  1] = 0000000100000001 <- 0101
memory[  2] = 0001000000010000 <- 1010
memory[  3] = 0000000100000001 <- 0101
memory[  4] = 1111111100000000 <- ff00
memory[  5] = 0001000000000000 <- 1000
memory[  6] = 1011000000000000 <- b000
memory[  7] = xxxxxxxxxxxxxxxx <- xxxx
memory[  8] = xxxxxxxxxxxxxxxx <- xxxx
memory[  9] = xxxxxxxxxxxxxxxx <- xxxx
memory[ 10] = xxxxxxxxxxxxxxxx <- xxxx
memory[ 11] = xxxxxxxxxxxxxxxx <- xxxx
memory[ 12] = xxxxxxxxxxxxxxxx <- xxxx
memory[ 13] = xxxxxxxxxxxxxxxx <- xxxx
memory[ 14] = xxxxxxxxxxxxxxxx <- xxxx
------- Bottom MEM contents ------
memory[250] = xxxxxxxxxxxxxxxx <- xxxx
memory[251] = xxxxxxxxxxxxxxxx <- xxxx
memory[252] = xxxxxxxxxxxxxxxx <- xxxx
memory[253] = xxxxxxxxxxxxxxxx <- xxxx
memory[254] = xxxxxxxxxxxxxxxx <- xxxx
memory[255] = 0000000000000101 <- 0005
