--============================================================================
-- Copyright 2026 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- IFETCH module -- PIPELINED version (Task 2)
-- Provides the PC and the ITCM of the RISC-V core.
--
-- Changes from the single-cycle IFETCH.VHD:
--   1. New ena_i port (driven by the Stall Condition Unit's PCwrite output).
--      When ena_i='0', the PC register HOLDS its current value instead of
--      latching next_pc_w -- this is the true write-enable hold described
--      for the load-use stall (same mechanism as IF/ID's ena/IF_IDwrite).
--   2. Because the PC holds, next_pc_w (and therefore the ITCM address)
--      must ALSO hold at the current pc_q value while ena_i='0' -- otherwise
--      the ITCM would present a different instruction than the one
--      corresponding to the frozen PC, even though pc_q itself isn't
--      advancing. Confirmed with the user: hold next_pc_w at pc_q.
--   3. addr_gen_i, brTaken_i, and alu_res_i (for JALR) now arrive from
--      EX_MEM_REG's REGISTERED outputs, not directly from EXECUTE's
--      same-cycle combinational signals. This is required by the pipeline:
--      the branch/jump decision for an instruction is only valid one stage
--      after EXECUTE, once EX_MEM_REG has latched it (see EX_MEM_REG.vhd
--      header comment for the full causality discussion).
--   4. Reset changed from the single-cycle version's asynchronous-style
--      rst_q synchronization chain to a single synchronous reset, per LAB5
--      design requirement #2 ("System RESET (KEY0) must be synchronous"),
--      consistent with all four pipeline register files.
--   5. pc_plus4_o is no longer produced here. In the pipeline, the JAL/JALR
--      link value (PC+4) is recomputed where needed (EXECUTE or WB) from
--      the carried pc_q, instead of carrying a second redundant value
--      through every pipeline register (see discussion: IF/ID does not
--      need a separate PC+4 field).
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;


ENTITY Ifetch IS
	generic(
		WORD_GRANULARITY 	: boolean	:= False;
		DATA_BUS_WIDTH 		: integer	:= 32;
		PC_WIDTH 			: integer	:= 10;
		ITCM_ADDR_WIDTH 	: integer	:= 8;
		WORDS_NUM 				: integer	:= 256
	);
	PORT(
		--Inputs
		clk_i			: IN 	STD_LOGIC;
		rst_i 			: IN 	STD_LOGIC;
		ena_i			: IN 	STD_LOGIC;	-- PCwrite from Stall Condition Unit; '0' = hold

		addr_gen_i 		: IN 	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0); -- branch target, from EX_MEM_REG (registered)
        Branch_ctrl_i	: IN 	STD_LOGIC;   -- "this is a branch instruction", carried via EX/MEM's M/WB bundle path
        brTaken_i 		: IN 	STD_LOGIC;   -- branch condition, from EX_MEM_REG.brTaken_o (registered)
		Jal_ctrl_i		: IN 	STD_LOGIC;   -- "this is JAL"
		Jalr_ctrl_i		: IN 	STD_LOGIC;   -- "this is JALR"
		alu_res_i 		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0); -- JALR target, from EX_MEM_REG.alu_res_o
		
		--Outputs
		pc_o 					: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0); -- current PC (registered)
		instruction_o : OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0)		-- 32-bit instruction word from ITCM (combinational)
	);
END Ifetch;


ARCHITECTURE behavior OF Ifetch IS
	SIGNAL pc_q				: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);			-- registered PC (what we output)
	SIGNAL pc_plus4_r 		: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);			-- combinational PC+4 (sequential case only)
	SIGNAL itcm_addr_w		: STD_LOGIC_VECTOR(ITCM_ADDR_WIDTH-1 DOWNTO 0);		-- address sent to ITCM
	SIGNAL next_pc_w  		: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);			-- combinational next PC value (MUX output)
	SIGNAL brTaken_w  		: STD_LOGIC;										-- Branch_ctrl_i AND brTaken_i
	
BEGIN
	--=======================================
	-- ITCM (ROM) connection
	--=======================================
	inst_memory: altsyncram
	GENERIC MAP (
		operation_mode					=> "ROM",
		width_a 								=> DATA_BUS_WIDTH,
		widthad_a 							=> ITCM_ADDR_WIDTH,
		numwords_a 							=> WORDS_NUM,
		lpm_hint 								=> "ENABLE_RUNTIME_MOD = YES,INSTANCE_NAME = ITCM",
		lpm_type 								=> "altsyncram",
		outdata_reg_a 					=> "UNREGISTERED",
		init_file 							=> "C:\Users\amitp\OneDrive\Desktop\Comp_Lab\Lab_5\BENCHMARK\test3\RV32IM\man_compiled\bin\M9K-intel\ITCM.hex",
		intended_device_family	=> "Cyclone"
	)
	PORT MAP (
		clock0    => clk_i,
		address_a	=> itcm_addr_w, 
		q_a 	   	=> instruction_o 
	);

-----------------------------------------------------------------------------------		
	-- Adder to compute PC+4 (sequential next-PC candidate)
  pc_plus4_r(PC_WIDTH-1 DOWNTO 0)	<= pc_q(PC_WIDTH-1 DOWNTO 0) + 4;
	
-----------------------------------------------------------------------------------
	-- Decision MUX for the next PC value.
	-- NOTE: priority order matters and is unchanged from the single-cycle
	-- version except for the new "hold" case (ena_i='0'), which must take
	-- priority over the sequential PC+4 case but BELOW reset, so that a
	-- reset always wins even if a stall happens to be asserted at the same
	-- time. Branch/jump redirects still take priority over a plain hold is
	-- NOT applicable here (Flush and stall_i should not coincide in normal
	-- operation -- see ID_EX_REG.vhd header), so this priority chain mirrors
	-- the single-cycle original with one new case inserted.
	brTaken_w <= 	Branch_ctrl_i AND brTaken_i;
	
	next_pc_w	<=	(others => '0') 								WHEN	rst_i = '1'							ELSE
								pc_q(PC_WIDTH-1 DOWNTO 0)			WHEN	ena_i = '0'							ELSE	-- stall: hold, re-fetch same instruction
								alu_res_i(PC_WIDTH-1 DOWNTO 0)		WHEN	Jalr_ctrl_i							ELSE	-- case of jalr
								addr_gen_i(PC_WIDTH-1 DOWNTO 0)		WHEN	brTaken_w or Jal_ctrl_i ELSE	-- case of Branch Taken or jal 
								pc_plus4_r(PC_WIDTH-1 DOWNTO 0);																			-- case of Branch Not-Taken 				

-----------------------------------------------------------------------------------
-- pc register: holds the current PC value. Synchronous reset, per LAB5
-- design requirement #2. Always loads next_pc_w on every rising edge --
-- the "hold" behaviour during a stall is achieved entirely through the
-- next_pc_w mux above (next_pc_w = pc_q when ena_i='0'), not through a
-- separate write-enable on the register itself, since rst_i must always
-- be able to override (synchronous reset has top priority either way).
-------------------------------------------------------------------------------------
PROCESS (clk_i)
	BEGIN
		IF (clk_i'EVENT AND clk_i='1') THEN
			IF rst_i = '1' THEN
				pc_q(PC_WIDTH-1 DOWNTO 0) <= (OTHERS => '0');
			ELSE
				pc_q(PC_WIDTH-1 DOWNTO 0) <= next_pc_w;
			END IF;
		END IF;
END PROCESS;
-----------------------------------------------------------------------------------	
	-- send address to inst. memory address register
	G1: 
	if (WORD_GRANULARITY = True) generate 			-- i.e. each WORD has unike address
		itcm_addr_w <= next_pc_w(PC_WIDTH-1 DOWNTO 2);
	elsif (WORD_GRANULARITY = False) generate 	-- i.e. each BYTE has unike address
		itcm_addr_w <= next_pc_w;
	end generate;
---------------------------------------------------------------------------------------
	pc_o 				<= 	pc_q;
---------------------------------------------------------------------------------------
	
END behavior;