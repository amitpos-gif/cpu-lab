
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

package aux_package is
 
  component RF is
    generic (Dwidth : integer := 16;
             Awidth : integer := 4);
    port (clk      : in  std_logic;
          rst      : in  std_logic;
          WregEn   : in  std_logic;
          WregData : in  std_logic_vector(Dwidth-1 downto 0);
          WregAddr : in  std_logic_vector(Awidth-1 downto 0);
          RregAddr : in  std_logic_vector(Awidth-1 downto 0);
          RregData : out std_logic_vector(Dwidth-1 downto 0));
  end component;

------------------------------------------------------------------------
  component dataMem is
    generic (Dwidth : integer := 16;
             Awidth : integer := 6;
             dept   : integer := 64);
    port (clk      : in  std_logic;
          memEn    : in  std_logic;
          WmemData : in  std_logic_vector(Dwidth-1 downto 0);
          WmemAddr : in  std_logic_vector(Awidth-1 downto 0);
          RmemAddr : in  std_logic_vector(Awidth-1 downto 0);
          RmemData : out std_logic_vector(Dwidth-1 downto 0)
          );
  end component;

------------------------------------------------------------------------
  component ProgMem is
    generic (Dwidth : integer := 16;
             Awidth : integer := 6;
             dept   : integer := 64);
    port (clk      : in  std_logic;
          memEn    : in  std_logic;
          WmemData : in  std_logic_vector(Dwidth-1 downto 0);
          WmemAddr : in  std_logic_vector(Awidth-1 downto 0);
          RmemAddr : in  std_logic_vector(Awidth-1 downto 0);
          RmemData : out std_logic_vector(Dwidth-1 downto 0)
          );
  end component;

------------------------------------------------------------------------
  component BidirPin is
    generic (width : integer := 16);
    port (Dout  : in    std_logic_vector(width-1 downto 0);
          en    : in    std_logic;
          Din   : out   std_logic_vector(width-1 downto 0);
          IOpin : inout std_logic_vector(width-1 downto 0)
          );
  end component;

------------------------------------------------------------------------
  component Datapath is
  generic( Dwidth: integer:=16;
      Awidth: integer:=6;
      dept:   integer:=64);
    port (
      clk  : in std_logic;
      rst  : in std_logic;
      -- Control from CU (16 bits) --
      DTCM_wr      : in std_logic;   -- DTCM write enable
      Cin          : in std_logic;   -- REG_C    ← ALU_result; flags ← ALU_flags
      Cout         : in std_logic;   -- REG_C          → BUS_wire
      DTCM_addr_in : in std_logic;   -- DTCM_addr_reg ← BUS_wire[5:0]
      DTCM_out     : in std_logic;   -- DTCM_data      → BUS_wire
      ALUFN        : in std_logic_vector(3 downto 0);
      Ain          : in std_logic;                        -- REG_A    ← BUS_wire  AND selects RFaddr_rd=rb
      RFin         : in std_logic;   
      RFout        : in std_logic;    
      RFaddr_rd	 : in std_logic_vector(1 downto 0);       --00 = off  , 01 = rc  , 10 = rb --
      RFaddr_wr	 : in std_logic;                          -- 0 = off  , 1 = wr from the data is ra --
      IRin         : in std_logic;                        -- ITCM_data -> to IR_reg
      PCin         : in std_logic;                        -- PC_next -> to PC_reg
      PCsel        : in std_logic_vector(1 downto 0);    -- '00'= "000000"  , '01'=PC+1+offset (jump target)  , "10" = PC+1 --
      Imm1_in      : in std_logic;                        -- SignExt(IR[7:0])→ BUS_wire  (8-bit imm)
      Imm2_in      : in std_logic;                        -- SignExt(IR[3:0])→ BUS_wire  (4-bit imm)
      -- Status to CU (15 bits) --
      mov_s  : out std_logic;   -- OPC = "1100"  move immediate
      done_s : out std_logic;   -- OPC = "1111"  program done
      and_s  : out std_logic;   -- OPC = "0010"  bitwise AND
      or_s   : out std_logic;   -- OPC = "0011"  bitwise OR
      xor_s  : out std_logic;   -- OPC = "0100"  bitwise XOR
      jnc_s  : out std_logic;   -- OPC = "1001"  jump if no carry
      jc_s   : out std_logic;   -- OPC = "1000"  jump if carry
      jmp_s  : out std_logic;   -- OPC = "0111"  unconditional jump
      sub_s  : out std_logic;   -- OPC = "0001"  subtract
      add_s  : out std_logic;   -- OPC = "0000"  add
      ld_s   : out std_logic;   -- OPC = "1101"  load
      st_s   : out std_logic;   -- OPC = "1110"  store
      -- Status inputs from Datapath — ALU flags --
      Cflag  : out std_logic;   -- carry  flag
      Zflag  : out std_logic;   -- zero   flag
      Nflag  : out std_logic;   -- negative flag

      -- Testbench ports (green line) --
      TBactive         : in  std_logic;
      ITCM_tb_wr       : in  std_logic;
      ITCM_tb_in       : in  std_logic_vector(Dwidth-1 downto 0);
      ITCM_tb_addr_in  : in  std_logic_vector(Awidth-1  downto 0);
      DTCM_tb_wr       : in  std_logic;
      DTCM_tb_in       : in  std_logic_vector(Dwidth-1 downto 0);
      DTCM_tb_out      : out std_logic_vector(Dwidth-1 downto 0);
      DTCM_tb_addr_in  : in  std_logic_vector(Awidth-1  downto 0);
      DTCM_tb_addr_out : in  std_logic_vector(Awidth-1  downto 0)
    );
  end component;
------------------------------------------------------------------------
  component Control is
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
  end component;
  -------------------------------------------------
  ------------------------------------------------------------------------------
component FA IS
	PORT (xi_FA, yi_FA, cin_FA: IN std_logic;
			  s_FA, cout_FA: OUT std_logic);
END component;
-----------------------------------------------------------------------------
component AdderSub is 
    generic (n : integer := 16);
	port (
	      x_adder,y_adder :in std_logic_vector(n-1 downto 0);
		  alufn_adder : in STD_LOGIC_VECTOR(3 downto 0);
		  res_out_Adder : OUT std_logic_vector(n-1 downto 0);  --3 input 2 output
		  c_out_Adder : out std_logic);
end component;
-------------------------------------------------------------------------------
component logic is
     generic (n : integer := 16);
	 port(x_logic,y_logic :in std_logic_vector(n-1 downto 0);
	      alufn_in_logic : in std_logic_vector(3 downto 0); 
		  logic_out: out std_logic_vector(n-1 downto 0));
end component;
------------------------------------------------------------------------------
component alu is
    generic (n : integer :=16);
    port(
        A,B :in std_logic_vector(n-1 downto 0 ); --ra - A, rb - B
        alufn:in std_logic_vector(3 downto 0 );
        C  :out std_logic_vector(n-1 downto 0); --c like in the draw
        C_flag, Z_flag,N_flag: out std_logic
    );
end component;
-------------------------------------------------------------------------------

end aux_package;
------------------------------------------------------------------------
