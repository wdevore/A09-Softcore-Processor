# A09-Softcore-Processor
An FPGA softcore processor for a corresponding [video series](https://www.youtube.com/channel/UCQxFumV2LMrKBMDW6dar_ZA) on my **After Hours Engineering** Youtube channel:

![AHE](YoutubeChannel.png)

A09 is a simplified 16bit CPU for learning purposes.

made using [drawio](app.diagrams.net)

![A video of the Cylon.dat program running](A09_CPU_Ver2b.gif)

# Source Code
All modules that make up the CPU are in the */Processor/Modules* folder, except for two files:
- mealy.v
- sequence_control_7c.v

These two files are specific to parts of the video series.

# Simulation
All module simulations are in the *Simulation* folder. The *cpu* folder has extra ".txt" files for translating numbers to labels within Gtkwave.

Here is an example of the **BNE** instruction during simulation with *iverilog*:

![BNE Gtkwave](BNE_Gtkwave.png)

# Synthesis
Any Modules that were synthesized were tested and uploaded to just the **TinyFPGAB2**. The main CPU softcore was synthesized only on the **BlackiceMx**.

# ROMs
The *roms/readme.md* file contains hand crafted assembly and machine code. The "Adr Hex" columns were copied into their respective **.dat* file. It is the **.dat* file that is embedded into the FPGA BRAM.

# Diagram
![CPU Layout diagram](A09_CPU_V3.png)


https://www.chipverify.com/verilog/verilog-timing-control

## ROM initialization
The ROM portion of memory needs to initialized **in** the *memory.v* initial block, for example:

```
`define ROM_CONTENTS "../../roms/Count_Out.dat"
...
    // memory.v
    initial begin
        $readmemh (`ROM_CONTENTS, mem);  // , 0, 6
        ...
    end
...
```

You can initialize memory *outside* of *memory.v* only in simulation mode. Synthization requires initialization only within the memory module.

# Notes and warnings

## Warning: Range select XXX out of bounds on signal \YY
https://ask.csdn.net/questions/1800353

See this response below, but it basically says:

When you do ```./yosys -f "verilog -sv" file.v``` you are implicitly doing a ```read_verilog file.v```. What read_verilog does is it both analyses (i.e. builds the AST) and elaborates (i.e. converts into RTLIL) the design. Since there is no concept of hierarchy at this step, it elaborates each module in the design as if it was a top module, using default parameter values. It's this step that causes a warning.

``` 
$ ./yosys -q -f "verilog -sv" bug2039.v
bug2039.v:26: Warning: Range select out of bounds on signal `\o_result': Setting result bit to undef.
```
If you want to suppress this behaviour, you will need to add the ```-defer``` option and set the **top** explicitly:
 
```
$ ./yosys -q -f "verilog -sv -defer" bug2039.v -p "synth_ice40 -top ALU_Test_Top"
```
What this does is to defer the elaboration step to the hierarchy pass. Since nothing has been elaborated into RTLIL, hierarchy is currently unable to auto-detect the top-level (as it can't currently examine the AST) and so you have to set it manually.

# Build Errors

## (Combinational loops) (very early Yosys build!)
```
Info: Annotating ports with timing budgets for target frequency 12.00 MHz
Info:    remaining fanin includes O (net ControlMatrix.alu_instr)        <-----                         <--- This is the issue
Info:         driver = $abc$2502$auto$blifparse.cc:492:parse_blif$2513_LC.O    |
Info:         user: $abc$2502$auto$blifparse.cc:492:parse_blif$2511_LC.I3      |    <------------------------
Info:         user: $abc$2502$auto$blifparse.cc:492:parse_blif$2513_LC.I1                                   |
Info:         user: $abc$2502$auto$blifparse.cc:492:parse_blif$2526_LC.I1                                   |  Keep traveling upward
Info:    remaining fanin includes O (net $abc$2502$techmap\ControlMatrix.$auto$rt...                        |
Info:         driver = $abc$2502$auto$blifparse.cc:492:parse_blif$2511_LC.O <--.----->----------------------|
Info:         user: $abc$2502$auto$blifparse.cc:492:parse_blif$2509_LC.I1      |        
Info:         user: $abc$2502$auto$blifparse.cc:492:parse_blif$2523_LC.I3   --> <----------------------------
Info:    remaining fanin includes O (net $abc$2502$techmap$techmap\ControlMatrix...                         |
Info:         driver = $abc$2502$auto$blifparse.cc:492:parse_blif$2526_LC.O                                 |
Info:         user: $abc$2502$auto$blifparse.cc:492:parse_blif$2525_LC.I1                                   |
Info:    remaining fanin includes O (net pin8$SB_IO_OUT)                                                    |
Info:         driver = $abc$2502$auto$blifparse.cc:492:parse_blif$2525_LC.O                                 |
Info:         user: pin8$sb_io.D_OUT_0                                                                      |   Travel upwards
Info:    remaining fanin includes O (net pin17_ss$SB_IO_OUT)                                                |
Info:         driver = $abc$2502$auto$blifparse.cc:492:parse_blif$2509_LC.O                                 |
Info:         user: $abc$2502$auto$blifparse.cc:492:parse_blif$2513_LC.I2                                   |
Info:         user: $abc$2502$auto$blifparse.cc:492:parse_blif$2521_LC.I0                                   |
Info:         user: $abc$2502$auto$blifparse.cc:492:parse_blif$2524_LC.I2                                   |
Info:         user: pin17_ss$sb_io.D_OUT_0                                                                  |
Info:    remaining fanin includes O (net $abc$2502$techmap\ControlMatrix.$4\next_state[2:0][1]_new_inv_)    |
Info:         driver = $abc$2502$auto$blifparse.cc:492:parse_blif$2523_LC.O          >-----------------------   Start here "A"
Info:         user: $abc$2502$auto$blifparse.cc:492:parse_blif$2522_LC.I0
ERROR: timing analysis failed due to presence of combinatorial loops, incomplete specification of timing ports, etc.
0 warnings, 1 error
```

When *nextpnr* detects a loop it stops immediately with an **ERROR**. Generally the last *fanin* being processed is hierarchically related to the actual cause.

In the case above we start searching based on the last *fanin*'s **driver** (aka 2523_LC.O). Searching on *2523_LC.O* yields a *user* higher up the hierarchy *2523_LC.I3*. Searching on this user's driver leeds to *2511_LC.I3* which leads to the top-most driver that is associated with the top-most *fanin*: ```net ControlMatrix.alu_instr```. This is caused by the fact that there is a **path** that results in *no* value being assigned to the **alu_instr** signal. The fix is to make sure all signals within behavioural blocks have assignments. Below the fix is to add the missing assignment just before the ```case(...)``` statement:

From this:
```
always @* begin
    ...
    src1_sel = 1'b1;    // Route Src1-IR to Reg-file Src1
    data_src = 2'b00;   // Select Zero extended source
    ...
    case (state)
    ...
    endcase
```
To:
```
always @* begin
    ...
    src1_sel = 1'b1;    // Route Src1-IR to Reg-file Src1
    data_src = 2'b00;   // Select Zero extended source
    alu_instr = 1'b0;   // Default Complete ALU instruction      <-- This was missing!!!
    ...
    case (state)
    ...
    endcase
```

Thus Combination-loops are most often caused when left-hand signals are not being *Set* within a behavioural block. For example:

```
always @*
    case (s[3:1])
        3'b001: late = 1'b1;
        3'b100: early = 1'b1;
        default: begin
            early = 1'b0;
            late = 1'b0;
        end
    endcase
```
When **s[3:1]** is *3'b001* or *3'b100*, either **late** or **early** is set but **NOT** the other, the other value remains at its previous value. This will result in an **inferred latch**. As the iCE40 doesn't have latch primitives, Yosys has to implement this as a combinational loop--which is an error.

### References
- https://github.com/YosysHQ/nextpnr/issues/224

# Test curcuits
## Common ground
It appears that connecting the ground of the TTGO to the FPGA causes trouble loading the FPGA. Just leave them separate.

## Using a R2R network
74LS02 using a resister divider network

https://electronics.stackexchange.com/questions/231616/can-i-use-a-voltage-divider-for-shifing-logic-levels

Picking R1 = 10kOhm and R2 = 20kOhm

## Using a TTGO microcontroller
See TTGO-Espressif-Projects/Verilog-Projects/A09 : https://github.com/wdevore/TTGO-Espressif-Projects/tree/main/a09_control
