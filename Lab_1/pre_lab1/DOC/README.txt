LAB1 - VHDL part 1 Concurrent code

In this lab we implemented a concurrent VHDL-based ALU system composed of several independent modules. 
The selected module is determined by the control signal ALUFN[4:3], while ALUFN[2:0] determines the specific operation inside each module.

The submitted DUT files are:

1. AdderSub.vhd
This module implements the arithmetic operations of the system using a ripple-carry-adder-based structure.
According to ALUFN[2:0], it supports:
- Addition: Y + X
- Subtraction: Y - X
- Negation: neg(X)
- Double increment: Y + 2
- Double decrement: Y - 2

2. Shifter.vhd
This module implements the shift operations using a barrel-shifter structure.
According to ALUFN[2:0], it supports:
- Shift left of Y by X(k-1 downto 0)
- Shift right of Y by X(k-1 downto 0)

The design was implemented without using the forbidden sll/srl operators, and was built using concurrent/generate-based logic as required.

3. Logic.vhd
This module implements the Boolean operations of the system.
According to ALUFN[2:0], it supports:
- NOT(Y)
- Y OR X
- Y AND X
- Y XOR X
- Y NOR X
- Y NAND X
- Y XNOR X

4. FA.vhd
This file implements a 1-bit Full Adder component.
It is used as a basic building block inside the AdderSub module.

5. aux_package.vhd
This file contains the package declarations of the components used throughout the project.
It allows the different modules to be instantiated structurally in a clean and organized way.

6. top.vhd
This is the top-level structural module of the system.
It connects the AdderSub, Shifter, and Logic modules, selects the correct output according to ALUFN[4:3],
and generates the system output ALUout together with the status flags:
- Z flag (Zero)
- C flag (Carry)
- N flag (Negative)
- V flag (Overflow)

Notes
- For undefined ALUFN[4:3], the output is forced to zero while the flags are still updated regularly.
- For undefined ALUFN[2:0] inside a selected submodule, the submodule output is zero.
- The design was written and tested as a structural concurrent VHDL design, according to the lab requirements.

Credits
Amit Postelnik
Yuval Elron
