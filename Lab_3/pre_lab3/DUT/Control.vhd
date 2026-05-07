
-- INSTRUCTION CYCLE COUNTS:
--   mov          : FETCH(1) → DECODE(2) → MOV_EX(3)                   = 3 cycles
--   add/sub/...  : FETCH(1) → DECODE(2) → EX1(3) → EX2(4)            = 4 cycles
--   ld           : FETCH(1) → DECODE(2) → EX1(3) → EX2(4) → EX3(5)  = 5 cycles
--   st           : FETCH(1) → DECODE(2) → EX1(3) → EX2(4) → EX3(5)  = 5 cycles
--   jmp/jc/jnc   : FETCH(1) → DECODE(2) → J_EX(3)                    = 3 cycles
--   done         : FETCH(1) → DECODE(2) → DONE (halts)
-- =============================================================================

library IEEE;
use ieee.std_logic_1164.all;
use work.aux_package.all;

------------------------------------------------------------------------
entity Control is
  port (
    clk  : in std_logic;
    rst  : in std_logic;   -- synchronous reset → returns FSM to S_FETCH
    ena  : in std_logic;   -- clock enable  ('0' = freeze FSM)
--  input's from the datapath -------------------------
    ld_s   : in std_logic;   -- OPC = "1101"  load
    st_s   : in std_logic;   -- OPC = "1110"  store
    mov_s  : in std_logic;   -- OPC = "1100"  move immediate
    done_s : in std_logic;   -- OPC = "1111"  program done
    add_s  : in std_logic;   -- OPC = "0000"  add
    sub_s  : in std_logic;   -- OPC = "0001"  subtract
    and_s  : in std_logic;   -- OPC = "0010"  bitwise AND
    or_s   : in std_logic;   -- OPC = "0011"  bitwise OR
    xor_s  : in std_logic;   -- OPC = "0100"  bitwise XOR
    jmp_s  : in std_logic;   -- OPC = "0111"  unconditional jump
    jc_s   : in std_logic;   -- OPC = "1000"  jump if carry
    jnc_s  : in std_logic;   -- OPC = "1001"  jump if no carry

    -- Status inputs from Datapath — ALU flags -----
    -- Registered inside Datapath on every Cin='1' pulse  ---
    -- Used by conditional jumps (jc, jnc) in their execute states --
    Cflag  : in std_logic;   -- carry  flag
    Zflag  : in std_logic;   -- zero   flag
    Nflag  : in std_logic;   -- negative flag

    -- 16 Control outputs to Datapath ---
    IRin         : out std_logic;   -- ITCM_data -> to IR_reg
    PCin         : out std_logic;   -- PC_next -> to PC_reg
    Ain          : out std_logic;   -- REG_A    ← BUS_wire  AND selects RFaddr_rd=rb
    Cin          : out std_logic;   -- REG_C    ← ALU_result; flags ← ALU_flags
    RFin         : out std_logic;   -- RF[RFaddr_wr] ← BUS_wire  (write enable)
    DTCM_addr_in : out std_logic;   -- DTCM_addr_reg ← BUS_wire[5:0]
    RFout        : out std_logic;   -- RF[RFaddr_rd]  → BUS_wire
    Cout         : out std_logic;   -- REG_C          → BUS_wire
    Imm1_in      : out std_logic;   -- SignExt(IR[7:0])→ BUS_wire  (8-bit imm)
    Imm2_in      : out std_logic;   -- SignExt(IR[3:0])→ BUS_wire  (4-bit imm)
    DTCM_out     : out std_logic;   -- DTCM_data      → BUS_wire
    PCsel        : out std_logic_vector(1 downto 0);;   -- '0'=PC+1 , '1'=PC+offset (jump target)
    DTCM_wr      : out std_logic;   -- DTCM write enable
    ALUFN        : out std_logic_vector(3 downto 0);
    --   "0000" = ADD --
    --   "0001" = SUB --
    --   "0010" = AND --
    --   "0011" = OR  --
    --   "0100" = XOR --

    -- to Testbench --
    done         : out std_logic    -- '1' when DONE instruction executed
  );
end entity Control;

--------------------------------------------------------------------
architecture rtl of Control is

  -- State encoding ------
  type state_type is (
    S_FETCH,       -- Cycle 1 (all)   : fetch instruction, advance PC
    S_DECODE,      -- Cycle 2 (all)   : decode OPC, pre-read rb for ALU/MEM
    S_MOV_EX,      -- Cycle 3 (mov)   : imm8 → RF[ra]
    S_RTYPE_EX1,   -- Cycle 3 (rtype) : rc → BUS; ALU computes; REG_C latches
    S_RTYPE_EX2,   -- Cycle 4 (rtype) : REG_C → RF[ra]
    S_LDST_EX1,    -- Cycle 3 (ld/st) : rb+imm4 → REG_C  (effective address)
    S_LDST_EX2,    -- Cycle 4 (ld/st) : REG_C → DTCM_addr_reg
    S_LD_EX3,      -- Cycle 5 (ld)    : DTCM_data → RF[ra]
    S_ST_EX3,      -- Cycle 5 (st)    : RF[ra] → DTCM
    S_JMP_EX,      -- Cycle 3 (jmp)   : PC ← PC+1+offset  (unconditional)
    S_JC_EX,       -- Cycle 3 (jc)    : PC ← PC+1+offset  if Cflag='1'
    S_JNC_EX,      -- Cycle 3 (jnc)   : PC ← PC+1+offset  if Cflag='0'
    S_DONE         -- terminal        : assert done, halt until rst
  );

  signal state_reg  : state_type := S_FETCH;
  signal next_state : state_type;

  -- Convenience: '1' when current instruction is any ALU R-type operation
  signal rtype_s : std_logic;

begin

  rtype_s <= add_s or sub_s or and_s or or_s or xor_s;

  -- ===========================================================================
  -- PROCESS 1 — STATE REGISTER  (sequential, clocked)
  -- Responsibility: store the current FSM state in flip-flops.
  -- This is the ONLY clocked element in the Control Unit.
  -- ===========================================================================
  STATE_REG : process(clk, rst)
  begin
    if rst = '1' then
      state_reg <= S_FETCH;          -- synchronous reset to Fetch
    elsif rising_edge(clk) then
      if ena = '1' then
        state_reg <= next_state;     -- advance FSM on every enabled clock edge
      end if;
    end if;
  end process STATE_REG;

  -- ===========================================================================
  -- PROCESS 2 — COMBINATORIAL OUTPUT  (Mealy logic)
  -- Responsibility:
  --   1. Compute next_state  based on state_reg + status inputs.
  --   2. Drive all control outputs based on state_reg (+flags for Mealy states).
  --
  -- DEFAULT ASSIGNMENTS (before CASE):
  --   Every output is deasserted ('0' / "000") by default.
  --   This guarantees no latch inference for any signal not explicitly set
  --   in a particular state branch.
  -- ===========================================================================
  COMB_OUT : process(state_reg,
                     ld_s, st_s, mov_s, done_s,
                     add_s, sub_s, and_s, or_s, xor_s, rtype_s,
                     jmp_s, jc_s, jnc_s,
                     Cflag, Zflag, Nflag)
  begin
    -- ── Defaults: all control outputs low ────────────────────────────────────
    next_state   <= S_FETCH;
    IRin         <= '0';
    PCin         <= '0';
    PCsel        <= '0';
    Ain          <= '0';
    Cin          <= '0';
    Cout         <= '0';
    RFout        <= '0';
    RFin         <= '0';
    Imm1_in      <= '0';
    Imm2_in      <= '0';
    DTCM_wr      <= '0';
    DTCM_out     <= '0';
    DTCM_addr_in <= '0';
    ALUFN        <= "0000";
    done         <= '0';

    case state_reg is

     
      when S_FETCH =>
        IRin       <= '1';        -- IR_reg ← ITCM_data  (at rising edge)
        next_state <= S_DECODE;   -- ALWAYS — do NOT branch on OPC here

     
      when S_DECODE =>

        if rtype_s = '1' then
          -- R-type: read rb → REG_A
          -- Ain='1' tells Datapath RF mux to use IR[7:4] as read address
          RFout      <= '1';          -- RF[IR[7:4]] = rb → BUS_wire
          Ain        <= '1';          -- REG_A ← BUS_wire  (rb stored here)
          next_state <= S_RTYPE_EX1;

        elsif ld_s = '1' or st_s = '1' then
          -- LD/ST: read rb (base register) → REG_A for address calc
          RFout      <= '1';          -- RF[IR[7:4]] = rb → BUS_wire
          Ain        <= '1';          -- REG_A ← BUS_wire
          next_state <= S_LDST_EX1;

        elsif mov_s = '1' then
          -- MOV: no register pre-read needed
          next_state <= S_MOV_EX;

        elsif jmp_s = '1' then
          next_state <= S_JMP_EX;

        elsif jc_s = '1' then
          next_state <= S_JC_EX;

        elsif jnc_s = '1' then
          next_state <= S_JNC_EX;

        elsif done_s = '1' then
          next_state <= S_DONE;

        else
          next_state <= S_FETCH;      -- unknown OPC: skip to next fetch
        end if;

     
      when S_MOV_EX =>
        Imm1_in    <= '1';            -- Imm1_sext = SignExt(IR[7:0]) on BUS
        RFin       <= '1';            -- RF[IR[11:8]] ← BUS_wire
        next_state <= S_FETCH;

     
      when S_RTYPE_EX1 =>
        RFout <= '1';                 -- RF[IR[3:0]] = rc on BUS (Ain='0' → rc path)
        Cin   <= '1';                 -- REG_C ← ALU_result; flags latched

        -- Select ALU operation from OPC
        if    add_s = '1' then ALUFN <= "000";   -- ADD
        elsif sub_s = '1' then ALUFN <= "001";   -- SUB
        elsif and_s = '1' then ALUFN <= "010";   -- AND
        elsif or_s  = '1' then ALUFN <= "011";   -- OR
        elsif xor_s = '1' then ALUFN <= "100";   -- XOR
        end if;

        next_state <= S_RTYPE_EX2;

      
      when S_RTYPE_EX2 =>
        Cout       <= '1';            -- REG_C on BUS_wire
        RFin       <= '1';            -- RF[IR[11:8]] = RF[ra] ← BUS_wire
        next_state <= S_FETCH;


      when S_LDST_EX1 =>
        Imm2_in    <= '1';            -- Imm2_sext = SignExt(IR[3:0]) on BUS
        ALUFN      <= "0000";         -- ADD: REG_A(rb) + Imm2(imm4) = eff_addr
        Cin        <= '1';            -- REG_C ← effective address
        next_state <= S_LDST_EX2;

     
      when S_LDST_EX2 =>
        Cout         <= '1';          -- eff_addr on BUS_wire
        DTCM_addr_in <= '1';          -- DTCM_addr_reg ← BUS_wire[5:0]

        if ld_s = '1' then
          next_state <= S_LD_EX3;
        else
          next_state <= S_ST_EX3;
        end if;

     
      when S_LD_EX3 =>
        DTCM_out   <= '1';            -- DTCM_data → BUS_wire
        RFin       <= '1';            -- RF[IR[11:8]] = RF[ra] ← BUS_wire
        next_state <= S_FETCH;

     
      when S_ST_EX3 =>
        RFout      <= '1';            -- RF[IR[11:8]] = RF[ra] → BUS_wire
        DTCM_wr    <= '1';            -- DTCM[DTCM_addr_reg] ← BUS_wire
        next_state <= S_FETCH;

     
      when S_JMP_EX =>
        PCin       <= '1';
        PCsel      <= "01";            -- PC_next = PC_jump = PC_reg + IR[7:0]
        next_state <= S_FETCH;

     
      when S_JC_EX =>
        if Cflag = '1' then
          PCin  <= '1';
          PCsel <= '1';               -- jump taken: PC ← PC_reg+IR[7:0]
        end if;
        -- Cflag='0': PCin='0' by default — PC unchanged (stays at old_PC+1)
        next_state <= S_FETCH;

      
      when S_JNC_EX =>
        if Cflag = '0' then
          PCin  <= '1';
          PCsel <= '1';               -- jump taken
        end if;
        next_state <= S_FETCH;

      
      when S_DONE =>
        done       <= '1';
        next_state <= S_DONE;         -- halt: only rst escapes this state

      
      when others =>
        next_state <= S_FETCH;

    end case;
  end process COMB_OUT;

end architecture rtl;
-- =============================================================================
-- End of Control.vhd
-- =============================================================================
