--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- MEM/WB Pipeline Register
--
-- Sits between stage 4 (MEMORY) and stage 5 (WRITEBACK), per Figure 7.
-- This is the simplest and most "passive" pipeline register: by the time
-- an instruction reaches here, every hazard that could affect it has
-- already been resolved upstream (forwarding sources it; stalls/flushes
-- never touch it). Nothing here ever needs to be squashed or held -- an
-- instruction sitting in MEM/WB is always correct and always proceeds.
--
-- Only the WB control bundle survives to this point -- M and EX bundles
-- were already "used up" by stage 4 and stage 3 respectively:
--
--   WB bundle  -> consumed THIS register's own output stage (stage 5,
--                 WRITEBACK). This is the last hop; nothing is forwarded
--                 any further after this register.
--
-- Data fields carried:
--   pc_i        -> kept flowing for the debug/Signal-Tap tap required by
--                  Figure 8 (WBpc_o)
--   alu_res_i   -> one of the four write-back candidates (WBSrc/MemtoReg
--                  select among ALUres / mem_data / mul_res / PC+4)
--   mem_data_i  -> DTCM's registered read-data output, for loads
--   mul_res_i   -> the FINAL multiplier result (Multiplier stage 2 already
--                  combined M=P1+P2 and the shifted sum back in stage 4,
--                  so by the time it reaches here it is a complete 32-bit
--                  product, unlike EX/MEM's mul_res_stage1 which only held
--                  the four raw partial products)
--   rd_i        -> destination register address. Used by WRITEBACK's own
--                  RF write port, AND exported to the Forwarding-Unit as
--                  MEM/WB_rd (confirmed by Figure 7's pink wires) and to
--                  the Stall Condition Unit as MEM/WBrd (confirmed by
--                  Figure 7's red wires)
--
-- No flush_i, no stall_i: this is intentional, not an oversight -- see the
-- explanation above. The figure does label this register's bar with "ena"
-- and "rst" (distinct from the other three registers' labels), but as with
-- ID/EX's "ena" label, no driving wire was found feeding it in the figure;
-- it is treated here as the standard register template artifact, not a
-- real hold/stall mechanism. "rst" here is the same synchronous core reset
-- as every other register (LAB5 design requirement #2), nothing special.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY MEM_WB_REG IS
	generic(
		DATA_BUS_WIDTH	: integer := 32;
		PC_WIDTH		: integer := 13
	);
	PORT(
		--Inputs
		clk_i						: IN	STD_LOGIC;
		rst_i						: IN	STD_LOGIC;

		-- ---- Data from MEMORY (stage 4) ----
		pc_i					: IN	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		alu_res_i				: IN	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		mem_data_i				: IN	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		mul_res_i				: IN	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);	-- final MUL result
		rd_i					: IN	STD_LOGIC_VECTOR(4 DOWNTO 0);

		-- ---- WB control bundle (consumed in stage 5) ----
		RegWrite_i				: IN	STD_LOGIC;
		MemtoReg_i				: IN	STD_LOGIC;
		RegDst_i				: IN	STD_LOGIC;
		WBSrc_i					: IN	STD_LOGIC;

		-- ---- Outputs to WRITEBACK (stage 5) ----
		pc_o					: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		alu_res_o				: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		mem_data_o				: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		mul_res_o				: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		rd_o					: OUT	STD_LOGIC_VECTOR(4 DOWNTO 0);

		RegWrite_o				: OUT	STD_LOGIC;
		MemtoReg_o				: OUT	STD_LOGIC;
		RegDst_o				: OUT	STD_LOGIC;
		WBSrc_o					: OUT	STD_LOGIC
	);
END MEM_WB_REG;


ARCHITECTURE behavior OF MEM_WB_REG IS

	SIGNAL pc_q						: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL alu_res_q			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL mem_data_q			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL mul_res_q			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL rd_q						: STD_LOGIC_VECTOR(4 DOWNTO 0);

	SIGNAL RegWrite_q			: STD_LOGIC;
	SIGNAL MemtoReg_q			: STD_LOGIC;
	SIGNAL RegDst_q				: STD_LOGIC;
	SIGNAL WBSrc_q				: STD_LOGIC;

BEGIN
	--------------------------------------------------------------------------
	-- Synchronous register, synchronous reset only. No flush, no stall --
	-- every cycle, whatever MEMORY produced is latched unconditionally.
	--------------------------------------------------------------------------
	PROCESS(clk_i)
	BEGIN
		IF (clk_i'EVENT AND clk_i = '1') THEN
			IF (rst_i = '1') THEN
				pc_q					<= (OTHERS => '0');
				alu_res_q				<= (OTHERS => '0');
				mem_data_q				<= (OTHERS => '0');
				mul_res_q				<= (OTHERS => '0');
				rd_q					<= (OTHERS => '0');

				RegWrite_q				<= '0';
				MemtoReg_q				<= '0';
				RegDst_q				<= '0';
				WBSrc_q					<= '0';

			ELSE
				pc_q					<= pc_i;
				alu_res_q				<= alu_res_i;
				mem_data_q				<= mem_data_i;
				mul_res_q				<= mul_res_i;
				rd_q					<= rd_i;

				RegWrite_q				<= RegWrite_i;
				MemtoReg_q				<= MemtoReg_i;
				RegDst_q				<= RegDst_i;
				WBSrc_q					<= WBSrc_i;
			END IF;
		END IF;
	END PROCESS;

	-- Data outputs
	pc_o								<= pc_q;
	alu_res_o							<= alu_res_q;
	mem_data_o							<= mem_data_q;
	mul_res_o							<= mul_res_q;
	rd_o								<= rd_q;

	-- WB bundle outputs
	RegWrite_o							<= RegWrite_q;
	MemtoReg_o							<= MemtoReg_q;
	RegDst_o							<= RegDst_q;
	WBSrc_o								<= WBSrc_q;

END behavior;
