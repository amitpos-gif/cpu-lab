README.TXT

DUT Files Description
=====================

top.vhd
--------
Top-level entity of the processor system.
Connects the Control unit, Datapath, Instruction memory and Data memory.

Control.vhd
------------
Implements the control finite state machine (FSM).
Generates all control signals for the processor according to the opcode and current state.

Datapath.vhd
-------------
Implements the processor datapath.
Contains the ALU, Register File, multiplexers and internal buses.

alu.vhd
--------
Arithmetic Logic Unit.
Performs arithmetic and logical operations such as ADD, SUB, AND and OR.

AdderSub.vhd
-------------
Adder/Subtractor unit used by the ALU.

FA.vhd
-------
Full Adder building block used in arithmetic operations.

RF.vhd
-------
Register File implementation.
Stores the processor registers and supports read/write operations.

Logic.vhd
----------
Implements logical operations used by the ALU.

BidirPin.vhd
-------------
Bidirectional pin interface module.

progMem.vhd
------------
Instruction memory (ITCM) implementation.
Stores the program instructions.

dataMem.vhd
------------
Data memory (DTCM) implementation.
Stores program data and supports load/store operations.

aux_package.vhd
----------------
Contains constants, component declarations and shared types used in the project.