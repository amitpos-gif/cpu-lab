--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- IF/ID Pipeline Register
--
-- Sits between stage 1 (IFETCH) and stage 2 (IDECODE), per Figure 7.
-- Holds the only two things that exist before decode happens: the fetched
-- instruction word and its PC. Everything else (control signals, register
-- values, immediate) is *produced* by IDECODE, so there is nothing else to
-- latch here yet.
--
-- Two hazard-handling behaviours live in this register, both driven by the
-- Stall Condition Unit (red box, Figure 7) and the stage-4 Flush signal:
--
--   IF_IDwrite_i = '0'  ->  HOLD current contents (do not latch new instr.)
--                            Used for the load-use stall: we want this same
--                            instruction sitting in IF/ID again next cycle,
--                            because ID/EX is being told to insert a bubble
--                            instead of letting this instruction proceed.
--
--   flush_i      = '1'  ->  FORCE NOP (instruction = 0x00000013 = ADDI x0,x0,0)
--                            Used when a branch/jump resolved in stage 4 was
--                            taken: the instruction(s) fetched on the wrong
--                            path must be squashed before they reach Decode.
--
-- Priority: rst_i > flush_i > IF_IDwrite_i ('0' = hold) > normal latch.
-- A synchronous reset is used here (per LAB5 report file requirements,
-- section "Design requirements", item 2: "System RESET (KEY0) must be
-- synchronous").
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.cond_compilation_package.all;

ENTITY IF_ID_REG IS
	generic(
		DATA_BUS_WIDTH	: integer := 32;
		PC_WIDTH		: integer := 13
	);
	PORT(
		--Inputs
		clk_i					: IN	STD_LOGIC;
		rst_i					: IN	STD_LOGIC;

		-- Stall Condition Unit control 
		IF_IDwrite_i		    : IN	STD_LOGIC;	-- '0' = hold (stall), '1' = latch normally
		flush_i					: IN	STD_LOGIC;	-- '1' = force NOP (branch/jump taken in stage 4)

		-- Data from IFETCH (stage 1)
		pc_i					: IN	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		instruction_i		    : IN	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

		--Outputs to IDECODE (stage 2)
		pc_o					: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		instruction_o		    : OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0)
	);
END IF_ID_REG;


ARCHITECTURE behavior OF IF_ID_REG IS

	-- NOP encoding: ADDI x0, x0, 0  (opcode=0010011, funct3=000, rd=rs1=0, imm=0)
	-- Safe to insert anywhere in the pipeline: writes x0 (hardwired discard),
	-- reads no meaningful operands, triggers no memory access, no branch.
	CONSTANT NOP_INSTRUCTION : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000013";

	SIGNAL pc_q						: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL instruction_q	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

BEGIN
	--------------------------------------------------------------------------
	-- Synchronous register with synchronous reset, flush, and stall (hold)
	--------------------------------------------------------------------------
	PROCESS(clk_i)
	BEGIN
		IF (clk_i'EVENT AND clk_i = '1') THEN
			IF (rst_i = '1') THEN
				pc_q					<= (OTHERS => '0');
				instruction_q	<= NOP_INSTRUCTION;

			ELSIF (flush_i = '1') THEN
				-- Branch/jump taken in stage 4: squash whatever was fetched
				-- on the (now known to be wrong) sequential path.
				pc_q					<= (OTHERS => '0');
				instruction_q	<= NOP_INSTRUCTION;

			ELSIF (IF_IDwrite_i = '1') THEN
				-- Normal operation: latch newly fetched instruction
				pc_q					<= pc_i;
				instruction_q	<= instruction_i;

			-- ELSE (IF_IDwrite_i = '0'): hold -- do nothing, pc_q/instruction_q
			-- retain their values automatically (no assignment = no change)
			END IF;
		END IF;
	END PROCESS;

	pc_o					<= pc_q;
	instruction_o	<= instruction_q;

END behavior;
