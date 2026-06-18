--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- EX/MEM Pipeline Register
--
-- Sits between stage 3 (EXECUTE) and stage 4 (MEMORY), per Figure 7.
--
-- The EX control bundle (ALUOp, ALUSrc, UpperImm) is NOT carried into this
-- register: it was only needed inside EXECUTE itself to produce ALUres,
-- and that job is already finished by the time this register latches.
--
-- EXCEPTIONS that move from the EX bundle into stage-4-or-later concerns:
--   MULOp               -> gates Multiplier (stage 2), which physically
--                           lives in MEMORY (see below)
--   Branch, Jal, Jalr   -> needed by the Flush-generation logic, which
--                           combines EX/MEM's REGISTERED Branch/brTaken/
--                           Jal/Jalr (i.e. one cycle after EXECUTE produced
--                           them) to decide whether to flush IF/ID and
--                           ID/EX. brTaken_o alone is not enough: tracing
--                           the existing single-cycle EXECUTE.VHD shows
--                           brTaken_w is only ever asserted for actual
--                           conditional branches (BEQ/BNE/BLT/...) -- it is
--                           explicitly '0' for JAL/JALR (see EXECUTE.VHD's
--                           ALU_ADD case, which groups add/addi/auipc/jal/
--                           jalr together with brTaken_w<='0'). So Jal_i
--                           and Jalr_i must be carried here separately to
--                           let Flush-generation logic detect unconditional
--                           redirects too.
--
--   M  bundle (+MULOp) -> consumed by stage 4 (this register's own output)
--   WB bundle           -> consumed by stage 5 (one more hop, into MEM/WB)
--
-- Data fields carried:
--   pc_i        -> kept flowing for debug/Signal-Tap taps (Figure 8)
--   alu_res_i   -> DTCM address (loads/stores) and the eventual ALU-result
--                  writeback value
--   mul_res_stage1_i -> handed to Multiplier (stage 2) in stage 4
--   read_data2_i (RF[rs2]) -> the store-data value DTCM needs for sw
--   rd_i        -> destination register address. Exported to BOTH the
--                  Forwarding-Unit (EX/MEM_rd) and the Stall Condition Unit
--                  (EX/MEMrd), confirmed by Figure 7's red/pink wires
--   addr_gen_i  -> the branch/jump target address computed in EXECUTE
--                  (PC + imm<<1). Must be carried at least long enough to
--                  redirect the PC mux in stage 1 once Flush fires.
--   brTaken_i   -> branch/jump resolution for the instruction now entering
--                  this register (its own EXECUTE-stage ALU/comparator
--                  result, latched here like any other data field)
--   RegWrite (inside the WB bundle) -> exported to the Forwarding-Unit as
--                  EX/MEM_RegWrite, so it knows whether EX/MEM_rd is a real
--                  forwarding candidate or a don't-write instruction
--
-- flush_i: confirmed against Figure 7 (high-res render) to be a real pin on
-- this register, labelled "clr", driven by the same purple net as IF/ID's
-- clear. This does NOT recreate the same-cycle race we were worried about:
-- tracing the actual OR-gate logic that produces Flush shows it combines
-- (a) the CURRENT brTaken coming live from EXECUTE for the instruction
-- about to enter this register, together with (b) a signal already
-- REGISTERED in EX/MEM from the PREVIOUS instruction (its ena/M status).
-- Because of input (b), the Flush asserted at any given edge is dominated
-- by what EX/MEM already held going into that edge -- i.e. it reflects a
-- branch that is already one instruction "ahead" of whatever is currently
-- landing here, not the incoming instruction erasing itself. Confirmed
-- against the figure: see the two-OR-gate cluster between EX/MEM and the
-- Flush label.
--
-- No stall input: an EX/MEM bubble (from an upstream stall) arrives here
-- as an already-zeroed bundle via ID_EX_REG, so no separate stall_i input
-- is needed on this register.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY EX_MEM_REG IS
	generic(
		DATA_BUS_WIDTH	: integer := 32;
		PC_WIDTH				: integer := 13
	);
	PORT(
		--Inputs
		clk_i						: IN	STD_LOGIC;
		rst_i						: IN	STD_LOGIC;
		flush_i						: IN	STD_LOGIC;	-- matches Figure 7's "clr" pin (purple net)

		-- ---- Data from EXECUTE (stage 3) ----
		pc_i						: IN	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		alu_res_i				: IN	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		mul_res_stage1_i: IN	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		read_data2_i		: IN	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);	-- RF[rs2], store data
		rd_i						: IN	STD_LOGIC_VECTOR(4 DOWNTO 0);
		addr_gen_i			: IN	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);	-- branch/jump target
		brTaken_i				: IN	STD_LOGIC;	-- branch/jump resolution, valid NOW
		Branch_i				: IN	STD_LOGIC;	-- needed by Flush-gen, see header
		Jal_i						: IN	STD_LOGIC;
		Jalr_i					: IN	STD_LOGIC;

		-- ---- M control bundle (consumed in stage 4) ----
		MemRead_i				: IN	STD_LOGIC;
		MemWrite_i			: IN	STD_LOGIC;
		MULOp_i					: IN	STD_LOGIC;	-- gates Multiplier (stage 2)

		-- ---- WB control bundle (consumed in stage 5) ----
		RegWrite_i			: IN	STD_LOGIC;
		MemtoReg_i			: IN	STD_LOGIC;
		RegDst_i				: IN	STD_LOGIC;
		WBSrc_i					: IN	STD_LOGIC;

		-- ---- Outputs to MEMORY (stage 4) ----
		pc_o						: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		alu_res_o				: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		mul_res_stage1_o: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		read_data2_o		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		rd_o						: OUT	STD_LOGIC_VECTOR(4 DOWNTO 0);
		addr_gen_o			: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		brTaken_o				: OUT	STD_LOGIC;
		Branch_o				: OUT	STD_LOGIC;
		Jal_o						: OUT	STD_LOGIC;
		Jalr_o					: OUT	STD_LOGIC;

		MemRead_o				: OUT	STD_LOGIC;
		MemWrite_o			: OUT	STD_LOGIC;
		MULOp_o					: OUT	STD_LOGIC;

		RegWrite_o			: OUT	STD_LOGIC;
		MemtoReg_o			: OUT	STD_LOGIC;
		RegDst_o				: OUT	STD_LOGIC;
		WBSrc_o					: OUT	STD_LOGIC
	);
END EX_MEM_REG;


ARCHITECTURE behavior OF EX_MEM_REG IS

	SIGNAL pc_q						: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL alu_res_q			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL mul_res_stage1_q : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL read_data2_q	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL rd_q						: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL addr_gen_q		: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL brTaken_q			: STD_LOGIC;
	SIGNAL Branch_q			: STD_LOGIC;
	SIGNAL Jal_q					: STD_LOGIC;
	SIGNAL Jalr_q					: STD_LOGIC;

	SIGNAL MemRead_q			: STD_LOGIC;
	SIGNAL MemWrite_q			: STD_LOGIC;
	SIGNAL MULOp_q				: STD_LOGIC;

	SIGNAL RegWrite_q			: STD_LOGIC;
	SIGNAL MemtoReg_q			: STD_LOGIC;
	SIGNAL RegDst_q				: STD_LOGIC;
	SIGNAL WBSrc_q				: STD_LOGIC;

BEGIN
	--------------------------------------------------------------------------
	-- Synchronous register, synchronous reset, and clear (flush_i).
	-- No stall input -- see header comment.
	--------------------------------------------------------------------------
	PROCESS(clk_i)
	BEGIN
		IF (clk_i'EVENT AND clk_i = '1') THEN
			IF (rst_i = '1' OR flush_i = '1') THEN
				pc_q						<= (OTHERS => '0');
				alu_res_q				<= (OTHERS => '0');
				mul_res_stage1_q <= (OTHERS => '0');
				read_data2_q		<= (OTHERS => '0');
				rd_q						<= (OTHERS => '0');
				addr_gen_q			<= (OTHERS => '0');
				brTaken_q				<= '0';
				Branch_q				<= '0';
				Jal_q						<= '0';
				Jalr_q					<= '0';

				MemRead_q				<= '0';
				MemWrite_q			<= '0';
				MULOp_q					<= '0';

				RegWrite_q			<= '0';
				MemtoReg_q			<= '0';
				RegDst_q				<= '0';
				WBSrc_q					<= '0';

			ELSE
				pc_q						<= pc_i;
				alu_res_q				<= alu_res_i;
				mul_res_stage1_q <= mul_res_stage1_i;
				read_data2_q		<= read_data2_i;
				rd_q						<= rd_i;
				addr_gen_q			<= addr_gen_i;
				brTaken_q				<= brTaken_i;
				Branch_q				<= Branch_i;
				Jal_q						<= Jal_i;
				Jalr_q					<= Jalr_i;

				MemRead_q				<= MemRead_i;
				MemWrite_q			<= MemWrite_i;
				MULOp_q					<= MULOp_i;

				RegWrite_q			<= RegWrite_i;
				MemtoReg_q			<= MemtoReg_i;
				RegDst_q				<= RegDst_i;
				WBSrc_q					<= WBSrc_i;
			END IF;
		END IF;
	END PROCESS;

	-- Data outputs
	pc_o						<= pc_q;
	alu_res_o				<= alu_res_q;
	mul_res_stage1_o<= mul_res_stage1_q;
	read_data2_o		<= read_data2_q;
	rd_o						<= rd_q;
	addr_gen_o			<= addr_gen_q;
	brTaken_o				<= brTaken_q;
	Branch_o				<= Branch_q;
	Jal_o						<= Jal_q;
	Jalr_o					<= Jalr_q;

	-- M bundle outputs
	MemRead_o				<= MemRead_q;
	MemWrite_o			<= MemWrite_q;
	MULOp_o					<= MULOp_q;

	-- WB bundle outputs
	RegWrite_o			<= RegWrite_q;
	MemtoReg_o			<= MemtoReg_q;
	RegDst_o				<= RegDst_q;
	WBSrc_o					<= WBSrc_q;

END behavior;