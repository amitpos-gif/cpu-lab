
-- INSTRUCTION CYCLE COUNTS:
--   mov          : FETCH(1) → DECODE(2) → MOV_EX(3)                   = 3 cycles
--   add/sub/...  : FETCH(1) → DECODE(2) → EX1(3) → EX2(4)            = 4 cycles
--   ld           : FETCH(1) → DECODE(2) → EX1(3) → EX2(4) → EX3(5)  = 5 cycles
--   st           : FETCH(1) → DECODE(2) → EX1(3) → EX2(4) → EX3(5)  = 5 cycles
--   jmp/jc/jnc   : FETCH(1) → DECODE(2) → J_EX(3)                    = 3 cycles
--   done         : FETCH(1) → DECODE(2) → DONE (halts)
-- ----------------------------------------------------------------------------===

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
	  mov_s  : in std_logic;   -- OPC = "1100"  move immediate
    done_s : in std_logic;   -- OPC = "1111"  program done
	  and_s  : in std_logic;   -- OPC = "0010"  bitwise AND
    or_s   : in std_logic;   -- OPC = "0011"  bitwise OR
    xor_s  : in std_logic;   -- OPC = "0100"  bitwise XOR
	  jnc_s  : in std_logic;   -- OPC = "1001"  jump if no carry
	  jc_s   : in std_logic;   -- OPC = "1000"  jump if carry
	  jmp_s  : in std_logic;   -- OPC = "0111"  unconditional jump
	  sub_s  : in std_logic;   -- OPC = "0001"  subtract
    add_s  : in std_logic;   -- OPC = "0000"  add
    ld_s   : in std_logic;   -- OPC = "1101"  load
    st_s   : in std_logic;   -- OPC = "1110"  store
    -- Status inputs from Datapath — ALU flags --
    Cflag  : in std_logic;   -- carry  flag
    Zflag  : in std_logic;   -- zero   flag
    Nflag  : in std_logic;   -- negative flag

    -- 16 Control outputs to Datapath ---
	  DTCM_wr      : out std_logic;   -- DTCM write enable
	  Cin          : out std_logic;   -- REG_C    ← ALU_result; flags ← ALU_flags
	  Cout         : out std_logic;   -- REG_C          → BUS_wire
	  DTCM_addr_in : out std_logic;   -- DTCM_addr_reg ← BUS_wire[5:0]
	  DTCM_out     : out std_logic;   -- DTCM_data      → BUS_wire
	  ALUFN        : out std_logic_vector(3 downto 0);
		--   "0000" = ADD --
		--   "0001" = SUB --
		--   "0010" = AND --
		--   "0011" = OR  --
		--   "0100" = XOR --
  	Ain          : out std_logic;                        -- REG_A    ← BUS_wire  AND selects RFaddr_rd=rb
	  RFin         : out std_logic;   
  	RFout        : out std_logic;    
    RFaddr_rd	 : out std_logic_vector(1 downto 0);       --00 = off  , 01 = rc  , 10 = rb --
	  RFaddr_wr	 : out std_logic;                          -- 0 = off  , 1 = wr from the data is ra --
    IRin         : out std_logic;                        -- ITCM_data -> to IR_reg
    PCin         : out std_logic;                        -- PC_next -> to PC_reg
    PCsel        : out std_logic_vector(1 downto 0);    -- '00'= "000000"  , '01'=PC+1+offset (jump target)  , "10" = PC+1 --
    Imm1_in      : out std_logic;                        -- SignExt(IR[7:0])→ BUS_wire  (8-bit imm)
    Imm2_in      : out std_logic;                        -- SignExt(IR[3:0])→ BUS_wire  (4-bit imm)
    done         : out std_logic 
  );
end entity Control;


------------------------------------------------------------------------------------
architecture rtl of Control is

  -- State encoding ------
  type state_type is (
    S_FETCH,       -- Cycle 1 (all)   : fetch instruction, advance PC
    S_DECODE1,     -- Cycle 2 (all)   : decode OPC, pre-read rb for ALU/MEM
    S_Decode2_EX,  -- Cycle 3 (rtype) : rc → BUS; ALU computes; REG_C latches
    S_WB,          -- Cycle 4 (rtype) : REG_C → RF[ra]
    --------------------------------------------------------------------------------
    S_MOV_EX,      -- Cycle 3 (mov)   : imm8 → RF[ra]
    S_LDST_EX1,    -- Cycle 3 (ld/st) : rb+imm4 → REG_C  (effective address)
    S_LDST_EX2,    -- Cycle 4 (ld/st) : REG_C → DTCM_addr_reg
    S_LD_EX3,      -- Cycle 5 (ld)    : DTCM_data → RF[ra]
    S_ST_EX3,      -- Cycle 5 (st)    : RF[ra] → DTCM
    S_DONE         -- terminal        : assert done, halt until rst
  );

  signal state_reg  : state_type := S_FETCH;
  signal next_state : state_type;

  -- Convenience: '1' when current instruction is any ALU R-type operation
  signal rtype_s : std_logic;

begin

  rtype_s <= add_s or sub_s or and_s or or_s or xor_s;

  -----------------------------------------------------------------------------------
  STATE_REG : process(clk, rst)
  begin
    if rst = '1' then
      state_reg <= S_FETCH;          -- Asynchronous reset to Fetch
    elsif rising_edge(clk) then
      if ena = '1' then
        state_reg <= next_state;     -- advance FSM on every enabled clock edge
      end if;
    end if;
  end process STATE_REG;

  
  -----------------------------------------------------------------------------------
  COMB_OUT : process(state_reg, rst,
                     ld_s, st_s, mov_s, done_s,
                     add_s, sub_s, and_s, or_s, xor_s, rtype_s,
                     jmp_s, jc_s, jnc_s,
                     Cflag, Zflag, Nflag)
  begin
    ----- Defaults: all control outputs low -----------------------------------------
    next_state   <= S_FETCH;
    IRin         <= '0';
    PCin         <= '0';
    PCsel        <= "10";
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
    RFaddr_rd    <= "00";        --00 = off  , 01 = rc  , 10 = rb , 11 = ra -- what with Ra? we need to read in st op
    RFaddr_wr    <= '0';

    ----- rst option -----
    if rst = '1' then
      PCin <= '1';
      PCsel <= "00";
    else
    ----------------------

      case state_reg is
        
      
        when S_FETCH =>
          IRin       <= '1';        -- IR_reg ← ITCM_data  (at rising edge)
          next_state <= S_DECODE1;   -- ALWAYS — do NOT branch on OPC here

      
        when S_DECODE1 =>

          if rtype_s = '1' then
            -- R-type: read rb → REG_A
            -- Ain='1' tells Datapath RF mux to use IR[7:4] as read address
            RFout      <= '1';          -- RF[IR[7:4]] = rb → BUS_wire
            Ain        <= '1';          -- REG_A ← BUS_wire  (rb stored here)
            RFaddr_rd  <= "01";         -- data from rc is going to be the addres register          
            next_state <= S_Decode2_EX;

          elsif ld_s = '1' or st_s = '1' then
            -- LD/ST: read rb (base register) → REG_A for address calc
            RFout      <= '1';          -- RF[IR[7:4]] = rb → BUS_wire
            Ain        <= '1';          -- REG_A ← BUS_wire
            RFaddr_rd  <= "10";
            next_state <= S_LDST_EX1;

          elsif mov_s = '1' then
            -- MOV: no register pre-read needed
            next_state <= S_MOV_EX;

          elsif jmp_s = '1' then
            PCsel      <= "01";            -- PC_next = PC_jump = PC_reg + IR[7:0]
            PCin       <= '1';
            next_state <= S_FETCH;

          ---

          elsif jc_s = '1' then
            PCin <= '1'; 
            if Cflag = '1' then
              PCsel <= "01";   
            else 
              PCsel <= "10";
            end if; 
            next_state <= S_FETCH;

          ---

          elsif jnc_s = '1' then
            PCin <= '1';
            if Cflag = '0' then
            PCsel <= "01";
            else 
            PCsel <= "10";               
            end if;  
            next_state <= S_FETCH;


          elsif done_s = '1' then
            next_state <= S_DONE;

          else
            next_state <= S_FETCH;      -- unknown OPC: skip to next fetch
          end if;

      
        when S_MOV_EX =>
          Imm1_in    <= '1';            -- Imm1_sext = SignExt(IR[7:0]) on BUS
          RFin       <= '1';            -- RF[IR[11:8]] ← BUS_wire
          RFaddr_wr  <= '1';
          PCin       <= '1';
          next_state <= S_FETCH;

      
        when S_Decode2_EX =>
          RFout <= '1';                 -- RF[IR[3:0]] = rc on BUS (Ain='0' → rc path)
          Cin   <= '1';                 -- REG_C ← ALU_result; flags latched
          RFaddr_rd <= "10";            -- reading the data of the other adrees register --
          
          -- Select ALU operation from OPCss
          if    add_s = '1' then ALUFN <= "0000";   -- ADD
          elsif sub_s = '1' then ALUFN <= "0001";   -- SUB
          elsif and_s = '1' then ALUFN <= "0010";   -- AND
          elsif or_s  = '1' then ALUFN <= "0011";   -- OR
          elsif xor_s = '1' then ALUFN <= "0100";   -- XOR
          end if;

          next_state <= S_WB;

        
        when S_WB =>
          Cout       <= '1';            -- REG_C on BUS_wire
          RFin       <= '1';            -- RF[IR[11:8]] = RF[ra] ← BUS_wire
          RFaddr_wr  <= '1';
          PCin      <= '1';
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
          RFaddr_wr  <= '1';
          PCin       <= '1';
          next_state <= S_FETCH;

      
        when S_ST_EX3 =>
          RFout      <= '1';            -- RF[IR[11:8]] = RF[ra] → BUS_wire
          DTCM_wr    <= '1';            -- DTCM[DTCM_addr_reg] ← BUS_wire
          RFaddr_rd  <= "11";           --NEW!! 5\10 11:45
          PCin       <= '1';
          next_state <= S_FETCH;


        when S_DONE =>
          done       <= '1';
          next_state <= S_DONE;         -- halt: only rst escapes this state

        
        when others =>
          next_state <= S_FETCH;

      end case;
    end if;
    ---------------------------------------------------------------------------------------------
    ------------------------------ for Testbench ------------------------------------------------
    ---------------------------------$$ 1 $$------------------------------------------------------
    assert PCsel /= "11"
      report "ILLEGAL PCsel=11 in state " & state_type'image(state_reg)
      severity ERROR;
    ---------------------------------$$ 2 $$-----------------------------------------------------
    assert not (Cin = '1' and Cout = '1')
      report "Cin and Cout both asserted in state " & state_t      st_s   : in std_logic;   -- OPC = "1110"  store      st_s   : in std_logic;   -- OPC = "1110"  store      st_s   : in std_logic;   -- OPC = "1110"  store      st_s   : in std_logic;   -- OPC = "1110"  store      st_s   : in std_logic;   -- OPC = "1110"  store      st_s   : in std_logic;   -- OPC = "1110"  storeype'image(state_reg)
      severity ERROR;
    ---------------------------------$$ 3 $$-----------------------------------------------------
    assert not (RFin = '1' and RFout = '1')
      report "RFin and RFout both asserted in state " & state_type'image(state_reg)
      severity ERROR;

  end process COMB_OUT;

end architecture rtl;
-- ----------------------------------------------------------------------------===
-- End of Control.vhd
-- ----------------------------------------------------------------------------===
