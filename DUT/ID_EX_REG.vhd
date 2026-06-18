--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- ID/EX Pipeline Register
--
-- Sits between stage 2 (IDECODE) and stage 3 (EXECUTE), per Figure 7.
-- This is the widest pipeline register: Decode is where every data value
-- AND every control signal is first produced, so everything has to be
-- latched here before it can flow further down the pipe.
--
-- Control signals are grouped into three bundles, exactly as drawn in
-- Figure 7 (the WB / M / EX labels stacked inside the ID/EX box):
--
--   EX bundle  -> consumed immediately by stage 3 (this register's own
--                 output stage). Not forwarded any further once EX/MEM
--                 latches, because by then EX's job is done.
--   M  bundle  -> consumed by stage 4 (MEMORY). Still has to be carried
--                 ONE more register hop (into EX/MEM) before it's used.
--   WB bundle  -> consumed by stage 5 (WRITEBACK). Has to be carried
--                 THREE more register hops (ID/EX -> EX/MEM -> MEM/WB)
--                 before it's finally used.
--
-- rs1/rs2/rd are latched here not because EXECUTE needs them for the ALU
-- (read_data1_i/read_data2_i already carry the actual operand VALUES),
-- but because the Forwarding-Unit needs ID/EX_rs1 and ID/EX_rs2 to decide
-- whether EXECUTE's ALU inputs should be forwarded from EX/MEM or MEM/WB
-- instead of using the (possibly stale) register-file values.
--
-- Hazard behaviour:
--   flush_i = '1'  ->  force NOP (branch/jump resolved as taken in stage 4)
--   stall_i = '1'  ->  force NOP (bubble insertion for a load-use hazard
--                       detected by the Stall Condition Unit, which compares
--                       THIS register's own MemRead_o/rd_o against IF/ID's
--                       rs1/rs2 -- the bubble request loops back here)
--
-- Priority: rst_i > flush_i > stall_i > normal latch.
-- Synchronous reset, per LAB5 design requirement #2.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.const_package.all;

ENTITY ID_EX_REG IS
	generic(
		DATA_BUS_WIDTH	: integer := 32;
		PC_WIDTH				: integer := 13
	);
	PORT(
		--Inputs
		clk_i					: IN	STD_LOGIC;
		rst_i					: IN	STD_LOGIC;

		flush_i					: IN	STD_LOGIC;	-- branch/jump taken in stage 4
		stall_i					: IN	STD_LOGIC;	-- load-use bubble request

		-- ---- Data from IDECODE (stage 2) ----
		pc_i					: IN	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		read_data1_i			: IN	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		read_data2_i			: IN	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		imm32_i					: IN	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		rs1_i					: IN	STD_LOGIC_VECTOR(4 DOWNTO 0);
		rs2_i					: IN	STD_LOGIC_VECTOR(4 DOWNTO 0);
		rd_i					: IN	STD_LOGIC_VECTOR(4 DOWNTO 0);
		--ALL THESE BUNDLES COME FROM THE CONTROL UNIT(ALL THE OUTPUTS OF THE UNIT)
		-- ---- EX control bundle (consumed in stage 3) ----
		ALUOp_i					: IN	STD_LOGIC_VECTOR(4 DOWNTO 0);
		ALUSrc_i				: IN	STD_LOGIC;
		UpperImm_i			    : IN	STD_LOGIC_VECTOR(1 DOWNTO 0);
		MULOp_i					: IN	STD_LOGIC;
		Branch_i				: IN	STD_LOGIC;
		Jal_i					: IN	STD_LOGIC;
		Jalr_i					: IN	STD_LOGIC;

		-- ---- M control bundle (consumed in stage 4) ----
		MemRead_i				: IN	STD_LOGIC;
		MemWrite_i				: IN	STD_LOGIC;

		-- ---- WB control bundle (consumed in stage 5) ----
		RegWrite_i				: IN	STD_LOGIC;
		MemtoReg_i				: IN	STD_LOGIC;
		RegDst_i				: IN	STD_LOGIC;
		WBSrc_i					: IN	STD_LOGIC;

		-- ---- Outputs to EXECUTE (stage 3) ----
		pc_o					: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		read_data1_o			: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		read_data2_o			: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		imm32_o					: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		rs1_o					: OUT	STD_LOGIC_VECTOR(4 DOWNTO 0);
		rs2_o					: OUT	STD_LOGIC_VECTOR(4 DOWNTO 0);
		rd_o					: OUT	STD_LOGIC_VECTOR(4 DOWNTO 0);

		ALUOp_o					: OUT	STD_LOGIC_VECTOR(4 DOWNTO 0);
		ALUSrc_o				: OUT	STD_LOGIC;
		UpperImm_o				: OUT	STD_LOGIC_VECTOR(1 DOWNTO 0);
		MULOp_o					: OUT	STD_LOGIC;
		Branch_o				: OUT	STD_LOGIC;
		Jal_o					: OUT	STD_LOGIC;
		Jalr_o					: OUT	STD_LOGIC;

		MemRead_o				: OUT	STD_LOGIC;
		MemWrite_o				: OUT	STD_LOGIC;

		RegWrite_o				: OUT	STD_LOGIC;
		MemtoReg_o				: OUT	STD_LOGIC;
		RegDst_o				: OUT	STD_LOGIC;
		WBSrc_o					: OUT	STD_LOGIC
	);
END ID_EX_REG;


ARCHITECTURE behavior OF ID_EX_REG IS

	SIGNAL pc_q					: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL read_data1_q			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL read_data2_q			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL imm32_q				: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL rs1_q				: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL rs2_q				: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL rd_q					: STD_LOGIC_VECTOR(4 DOWNTO 0);

	SIGNAL ALUOp_q				: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL ALUSrc_q				: STD_LOGIC;
	SIGNAL UpperImm_q			: STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL MULOp_q				: STD_LOGIC;
	SIGNAL Branch_q				: STD_LOGIC;
	SIGNAL Jal_q				: STD_LOGIC;
	SIGNAL Jalr_q				: STD_LOGIC;

	SIGNAL MemRead_q			: STD_LOGIC;
	SIGNAL MemWrite_q			: STD_LOGIC;

	SIGNAL RegWrite_q			: STD_LOGIC;
	SIGNAL MemtoReg_q			: STD_LOGIC;
	SIGNAL RegDst_q				: STD_LOGIC;
	SIGNAL WBSrc_q				: STD_LOGIC;

BEGIN
	--------------------------------------------------------------------------
	-- Synchronous register with synchronous reset, flush, and stall (bubble)
	--
	-- NOTE: flush and stall both force a NOP-equivalent bundle (all control
	-- signals deasserted). The difference between them is purely about WHY
	-- a bubble is needed -- the register behaviour is identical. Data path
	-- fields (pc/read_data/imm32/rs1/rs2/rd) are cleared too on either event,
	-- since a bubble must not be allowed to corrupt the RF, DTCM, or branch
	-- logic with leftover values from the squashed instruction.
	--------------------------------------------------------------------------
	PROCESS(clk_i)
	BEGIN
		IF (clk_i'EVENT AND clk_i = '1') THEN
			IF (rst_i = '1' OR flush_i = '1' OR stall_i = '1') THEN
				-- Bubble: zero data, zero all control (= NOP's effect)
				pc_q				<= (OTHERS => '0');
				read_data1_q	    <= (OTHERS => '0');
				read_data2_q		<= (OTHERS => '0');
				imm32_q				<= (OTHERS => '0');
				rs1_q				<= (OTHERS => '0');
				rs2_q				<= (OTHERS => '0');
				rd_q				<= (OTHERS => '0');
				--its the mux in the figure, below the stall unit
				ALUOp_q				<= ALU_ADD;
				ALUSrc_q			<= '0';
				UpperImm_q			<= "00";
				MULOp_q				<= '0';
				Branch_q			<= '0';
				Jal_q				<= '0';
				Jalr_q				<= '0';

				MemRead_q			<= '0';
				MemWrite_q			<= '0';

				RegWrite_q			<= '0';
				MemtoReg_q			<= '0';
				RegDst_q			<= '0';
				WBSrc_q				<= '0';

			ELSE
				-- Normal operation: latch everything Decode produced
				pc_q				<= pc_i;
				read_data1_q		<= read_data1_i;
				read_data2_q		<= read_data2_i;
				imm32_q				<= imm32_i;
				rs1_q				<= rs1_i;
				rs2_q				<= rs2_i;
				rd_q				<= rd_i;

				ALUOp_q				<= ALUOp_i;
				ALUSrc_q			<= ALUSrc_i;
				UpperImm_q			<= UpperImm_i;
				MULOp_q				<= MULOp_i;
				Branch_q			<= Branch_i;
				Jal_q				<= Jal_i;
				Jalr_q				<= Jalr_i;

				MemRead_q			<= MemRead_i;
				MemWrite_q			<= MemWrite_i;

				RegWrite_q			<= RegWrite_i;
				MemtoReg_q			<= MemtoReg_i;
				RegDst_q			<= RegDst_i;
				WBSrc_q				<= WBSrc_i;
			END IF;
		END IF;
	END PROCESS;

	-- Data outputs
	pc_o					<= pc_q;
	read_data1_o	<= read_data1_q;
	read_data2_o	<= read_data2_q;
	imm32_o				<= imm32_q;
	rs1_o					<= rs1_q;
	rs2_o					<= rs2_q;
	rd_o					<= rd_q;

	-- EX bundle outputs
	ALUOp_o				<= ALUOp_q;
	ALUSrc_o			<= ALUSrc_q;
	UpperImm_o		<= UpperImm_q;
	MULOp_o				<= MULOp_q;
	Branch_o			<= Branch_q;
	Jal_o					<= Jal_q;
	Jalr_o				<= Jalr_q;

	-- M bundle outputs
	MemRead_o			<= MemRead_q;
	MemWrite_o		<= MemWrite_q;

	-- WB bundle outputs
	RegWrite_o		<= RegWrite_q;
	MemtoReg_o		<= MemtoReg_q;
	RegDst_o			<= RegDst_q;
	WBSrc_o				<= WBSrc_q;

END behavior;
