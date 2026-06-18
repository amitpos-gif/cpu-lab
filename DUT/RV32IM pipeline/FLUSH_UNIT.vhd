--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- FLUSH_UNIT -- Branch/jump misprediction flush generation
--
-- Combinational logic, sits AFTER EX_MEM_REG (reads its registered outputs
-- only), and produces the single Flush signal that feeds:
--   - IF_ID_REG.flush_i
--   - ID_EX_REG.flush_i
--   - the PC-redirect mux in IFETCH (selects addr_gen/alu_res over PC+4)
--
-- Equation (confirmed against Figure 7 and independently cross-checked):
--   Flush = (EX/MEM_Branch AND EX/MEM_brTaken) OR EX/MEM_Jal OR EX/MEM_Jalr
--
-- Per Figure 7, this AND+OR computation is actually split across
-- EX_MEM_REG, not entirely on this side: the AND and first OR happen in
-- EXECUTE, combinationally, BEFORE the register, producing the single
-- combined bit br_or_jump_taken, which is what EX_MEM_REG actually
-- latches (see EX_MEM_REG.vhd). This unit's job is therefore trivial: it
-- just exposes that already-registered bit as Flush.
--
-- Causal safety (no same-cycle self-erasure): br_or_jump_taken_i is an
-- EX_MEM_REG OUTPUT -- already latched, one cycle behind whatever
-- instruction currently sits in EXECUTE. See EX_MEM_REG.vhd's header
-- comment for the full discussion.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY FLUSH_UNIT IS
	PORT(
		br_or_jump_taken_i	: IN	STD_LOGIC;	-- EX_MEM_REG.br_or_jump_taken_o

		flush_o							: OUT	STD_LOGIC
	);
END FLUSH_UNIT;


ARCHITECTURE behavior OF FLUSH_UNIT IS
BEGIN

	flush_o <= br_or_jump_taken_i;

END behavior;
