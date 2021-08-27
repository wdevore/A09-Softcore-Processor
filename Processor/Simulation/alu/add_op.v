$display("%d Begining ADD tests", $time);

@(posedge Clock_TB);
IFlags_TB = 4'b0000;        // All flags cleared
FuncOp_TB = `ADD;  // Select Add with no carry operation

// -------------------------------------------------------
// Sum of two unsigned values
// Add 0+0
//            V N C Z
// Flags set: 0,0,0,1
// -------------------------------------------------------
IA_TB = 'h0000;            // Load A
IB_TB = 'h0000;            // Load B
$display("%d Checking : %h, %h", $time, IA_TB, IB_TB);

@(negedge Clock_TB);
$display("%d Flags : %04b", $time, OFlags_TB);
if (OFlags_TB !== 4'b0001) begin
    $display("%d %m: ERROR - Expected Zero flag set. Got: (%04b).", $stime, OFlags_TB);
    $finish;
end

if (OY_TB !== 'b0) begin
    $display("%d %m: ERROR - Expected sum of 0. Got: (%0d).", $stime, OY_TB);
    $finish;
end

@(posedge Clock_TB);
// -------------------------------------------------------
// Sum of two unsigned values
// Add 2+2
//            V N C Z
// Flags set: 0,0,0,0
// -------------------------------------------------------
IFlags_TB = 4'b0000;        // All flags cleared
FuncOp_TB = `ADD;  // Select Add with no carry operation
IA_TB = 'h02;           // Load A
IB_TB = 'h02;           // Load B
$display("%d Checking : %h, %h", $time, IA_TB, IB_TB);

@(negedge Clock_TB);
$display("%d Flags : %04b", $time, OFlags_TB);
if (OFlags_TB !== 4'b0000) begin
    $display("%d %m: ERROR - Expected Zero flag cleared. Got: (%04b).", $stime, OFlags_TB);
    $finish;
end

if (OY_TB !== 'h04) begin
    $display("%d %m: ERROR - Expected sum of 4: Got (%0d).", $stime, OY_TB);
    $finish;
end

@(posedge Clock_TB);
// -------------------------------------------------------
// Sum of two unsigned values
// Add 0xFF + 0x02 = 0x0101
//            V N C Z
// Flags set: 0,0,1,0
// -------------------------------------------------------
IFlags_TB = 4'b0000;        // All flags cleared
IA_TB = 'hFFFF;           // Load A
IB_TB = 'h0002;           // Load B
$display("%d Checking : %h, %h", $time, IA_TB, IB_TB);

@(negedge Clock_TB);
$display("%d Flags : %04b", $time, OFlags_TB);
if (OFlags_TB !== 4'b0010) begin
    $display("%d %m: ERROR - Expected Carry flag Set. Got (%04b).", $stime, OFlags_TB);
    $finish;
end

if (OY_TB !== 'h01) begin
    $display("%d %m: ERROR - Expected value of 1: Got (%0d).", $stime, OY_TB);
    $finish;
end

// -----------------------------------------------------------
// Carry flag
// The rules for turning on the carry flag in binary/integer math are two:
//
// 1. The carry flag is set if the addition of two numbers causes a carry
//    out of the most significant (leftmost) bits added.
//
//    1111 + 0001 = 0000 (carry flag is turned on)
//
// 2. The carry (borrow) flag is also set if the subtraction of two numbers
//    requires a borrow into the most significant (leftmost) bits subtracted.
//
//    0000 - 0001 = 1111 (carry flag is turned on)
//
// Otherwise, the carry flag is turned off (zero).
//  * 0111 + 0001 = 1000 (carry flag is turned off [zero])
//  * 1000 - 0001 = 0111 (carry flag is turned off [zero])
//
// In unsigned arithmetic, watch the carry flag to detect errors.
// In signed arithmetic, the carry flag tells you nothing interesting.
// -----------------------------------------------------------
// -------------------------------------------------------
// Sum of two unsigned values
// adding the hex values 0xE0 and 0x40 will set the Carry flag
// but not the Overflow flag.
// Add 0xE0 + 0x40 = 0x0120
//            V N C Z
// Flags set: 0,0,1,0
// -------------------------------------------------------
@(posedge Clock_TB);
IFlags_TB = 4'b0000;        // All flags cleared
IA_TB = 'hFFE0;           // Load A
IB_TB = 'h0040;           // Load B
$display("%d Checking : %h, %h", $time, IA_TB, IB_TB);

@(negedge Clock_TB);
$display("%d Flags : %04b", $time, OFlags_TB);
if (OFlags_TB !== 4'b0010) begin
    $display("%d %m: ERROR - 2 Expected Carry flag Set. Got (%04b).", $stime, OFlags_TB);
    $finish;
end

if (OY_TB !== 'h20) begin
    $display("%d %m: ERROR - 2 Expected value of 0x20: Got (%0d).", $stime, OY_TB);
    $finish;
end

@(posedge Clock_TB);
// -------------------------------------------------------
// Sum of two unsigned values, but causes a signed result.
// Add 0xEF + 0x01 = 0xF0 = 240
//            V N C Z
// Flags set: 0,1,0,0
// -------------------------------------------------------
IFlags_TB = 4'b0000;        // All flags cleared
IA_TB = 'hFFEF;           // Load A
IB_TB = 'h0001;           // Load B
$display("%d Checking : %h, %h", $time, IA_TB, IB_TB);

@(negedge Clock_TB);
$display("%d Flags : %04b", $time, OFlags_TB);
if (OFlags_TB !== 4'b0100) begin
    $display("%d %m: ERROR - Expected Negative flag Set. Got %04b.", $stime, OFlags_TB);
    $finish;
end

if (OY_TB !== 'hFFF0) begin
    $display("%d %m: ERROR - Expected value of 240: Got (%0d).", $stime, OY_TB);
    $finish;
end

// -----------------------------------------------------------
// Overflow
// The rules for turning on the overflow flag in binary/integer math are two:
//
// 1. If the sum of two numbers with the sign bits off yields a result number
//    with the sign bit on, the "overflow" flag is turned on.
//
//    0100 + 0100 = 1000 (overflow flag is turned on)
//
// 2. If the sum of two numbers with the sign bits on yields a result number
//    with the sign bit off, the "overflow" flag is turned on.
//
//    1000 + 1000 = 0000 (overflow flag is turned on)
//
// Otherwise, the overflow flag is turned off.
//  * 0100 + 0001 = 0101 (overflow flag is turned off)
//  * 0110 + 1001 = 1111 (overflow flag is turned off)
//  * 1000 + 0001 = 1001 (overflow flag is turned off)
//  * 1100 + 1100 = 1000 (overflow flag is turned off)
//
// Note that you only need to look at the sign bits (leftmost) of the three
// numbers to decide if the overflow flag is turned on or off.
//
// If you are doing two's complement (signed) arithmetic, overflow flag on
// means the answer is wrong - you added two positive numbers and got a
// negative, or you added two negative numbers and got a positive.
//
// If you are doing unsigned arithmetic, the overflow flag means nothing
// and should be ignored.
//
// The rules for two's complement detect errors by examining the sign of
// the result.  A negative and positive added together cannot be wrong,
// because the sum is between the addends. Since both of the addends fit
// within the allowable range of numbers, and their sum is between them, it
// must fit as well.  Mixed-sign addition never turns on the overflow flag.
//
// In signed arithmetic, watch the overflow flag to detect errors.
// In unsigned arithmetic, the overflow flag tells you nothing interesting.
// -----------------------------------------------------------
// An example is what happens if we add 127 and 127 using 8-bit registers.
// 127 (0x7F) + 127 is 254, but using 8-bit arithmetic the result would be 1111 1110 binary,
// which is -2 in two's complement, and thus negative.
// A negative result out of positive operands (or vice versa) is an overflow.

// -------------------------------------------------------
// Sum of two unsigned values, but causes a signed negative and overflow.
// Add 0x80 + 0x80 = 0x0100
//            V N C Z
// Flags set: 1,0,1,1
// -------------------------------------------------------
@(posedge Clock_TB);
IFlags_TB = 4'b0000;        // All flags cleared
IA_TB = 'h8000;           // Load A
IB_TB = 'h8000;           // Load B
$display("%d Checking : %h, %h", $time, IA_TB, IB_TB);

@(negedge Clock_TB);
$display("%d Flags : %04b", $time, OFlags_TB);
if (OFlags_TB !== 4'b1011) begin
    $display("%d %m: ERROR - Expected only Overflow flag Set. Got %04b.", $stime, OFlags_TB);
    $finish;
end

if (OFlags_TB[dut.CarryFlag] !== 1'b1 && OFlags_TB[dut.ZeroFlag] !== 1'b1) begin
    $display("%d %m: ERROR - Expected Carry and Zero flags Set too. Got %04b.", $stime, OFlags_TB);
    $finish;
end

if (OY_TB !== 'h0000) begin
    $display("%d %m: ERROR - Expected value of 0: Got (%0d).", $stime, OY_TB);
    $finish;
end

// -------------------------------------------------------
// Sum of two unsigned values
// Add 0x7F + 0x7F = 0xFE = -2
//            V N C Z
// Flags set: 1,0,0,0
// -------------------------------------------------------
@(posedge Clock_TB);
IFlags_TB = 4'b0000;        // All flags cleared
IA_TB = 'h7FFF;           // Load A
IB_TB = 'h7FFF;           // Load B
$display("%d Checking : %h, %h", $time, IA_TB, IB_TB);

@(negedge Clock_TB);
$display("%d Flags2 : %04b", $time, OFlags_TB);  // 1011
if (OFlags_TB !== 4'b1100) begin
    $display("%d %m: ERROR - Expected Negative flag Set. Got %04b.", $stime, OFlags_TB);
    $finish;
end

if (OY_TB !== 'hFFFE) begin
    $display("%d %m: ERROR - Expected value of 254: Got (%0d).", $stime, OY_TB);
    $finish;
end

// -------------------------------------------------------
// Sum of two unsigned values
// Add 0xC0 + 0xC0 = 0x0180
//            V N C Z
// Flags set: 0,1,1,0
// -------------------------------------------------------
@(posedge Clock_TB);
IFlags_TB = 4'b0000;        // All flags cleared
IA_TB = 'hC000;           // Load A
IB_TB = 'hC000;           // Load B
$display("%d Checking : %h, %h", $time, IA_TB, IB_TB);

@(negedge Clock_TB);
$display("%d Flags : %04b", $time, OFlags_TB);
if (OFlags_TB !== 4'b0110) begin
    $display("%d %m: ERROR - Expected Overflow flag Set. Got %04b.", $stime, OFlags_TB);
    $finish;
end

if (OY_TB !== 'h8000) begin
    $display("%d %m: ERROR - Expected value of 128: Got (%0d).", $stime, OY_TB);
    $finish;
end

// -------------------------------------------------------
// Sum of two unsigned values + input carry flag
// Add 0x01 + 0x01 + Cf = 0x03
//            V N C Z
// Flags set: 0,0,0,0
// -------------------------------------------------------
@(posedge Clock_TB);
IFlags_TB = 4'b0010;        // Set Carry flag

IA_TB = 'h0001;           // Load A
IB_TB = 'h0001;           // Load B
$display("%d Checking : %h, %h", $time, IA_TB, IB_TB);

@(negedge Clock_TB);
$display("%d Flags : %04b", $time, OFlags_TB);
if (OFlags_TB !== 4'b0000) begin
    $display("%d %m: ERROR - Expected all flags Cleared. Got %04b.", $stime, OFlags_TB);
    $finish;
end

if (OY_TB !== 'h0003) begin
    $display("%d %m: ERROR - Expected value of 3: Got (%0d).", $stime, OY_TB);
    $finish;
end

// ------------------------------------
// Simulation duration
// ------------------------------------
#10 $display("%d %m: Testbench simulation PASSED.", $stime);
$finish;
