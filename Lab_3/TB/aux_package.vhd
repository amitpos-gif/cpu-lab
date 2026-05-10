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
          RmemData : out std_logic_vector(Dwidth-1 downto 0));
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
          RmemData : out std_logic_vector(Dwidth-1 downto 0));
  end component;

------------------------------------------------------------------------
  component BidirPin is
    generic (width : integer := 16);
    port (Dout  : in    std_logic_vector(width-1 downto 0);
          en    : in    std_logic;
          Din   : out   std_logic_vector(width-1 downto 0);
          IOpin : inout std_logic_vector(width-1 downto 0));
  end component;

------------------------------------------------------------------------
  component Datapath is
    port (
      clk  : in std_logic;
      rst  : in std_logic;
      -- Control from CU (16 bits)
      IRin         : in std_logic;
      PCin         : in std_logic;
      PCsel        : in std_logic;
      Ain          : in std_logic;
      Cin          : in std_logic;
      Cout         : in std_logic;
      RFout        : in std_logic;
      RFin         : in std_logic;
      Imm1_in      : in std_logic;
      Imm2_in      : in std_logic;
      DTCM_wr      : in std_logic;
      DTCM_out     : in std_logic;
      DTCM_addr_in : in std_logic;
      ALUFN        : in std_logic_vector(2 downto 0);
      -- Status to CU (15 bits)
      ld_s   : out std_logic;
      st_s   : out std_logic;
      mov_s  : out std_logic;
      done_s : out std_logic;
      add_s  : out std_logic;
      sub_s  : out std_logic;
      jmp_s  : out std_logic;
      jc_s   : out std_logic;
      jnc_s  : out std_logic;
      and_s  : out std_logic;
      or_s   : out std_logic;
      xor_s  : out std_logic;
      Cflag  : out std_logic;
      Zflag  : out std_logic;
      Nflag  : out std_logic;
      -- Testbench ports (green – Figure 2)
      TBactive         : in  std_logic;
      ITCM_tb_wr       : in  std_logic;
      ITCM_tb_in       : in  std_logic_vector(15 downto 0);
      ITCM_tb_addr_in  : in  std_logic_vector(5  downto 0);
      DTCM_tb_wr       : in  std_logic;
      DTCM_tb_in       : in  std_logic_vector(15 downto 0);
      DTCM_tb_out      : out std_logic_vector(15 downto 0);
      DTCM_tb_addr_in  : in  std_logic_vector(5  downto 0);
      DTCM_tb_addr_out : in  std_logic_vector(5  downto 0));
  end component;

------------------------------------------------------------------------
  component Control is
  port (
    clk  : in std_logic;
    rst  : in std_logic;
    ena  : in std_logic;

    -- Inputs from Datapath
    mov_s  : in std_logic;
    done_s : in std_logic;
    and_s  : in std_logic;
    or_s   : in std_logic;
    xor_s  : in std_logic;
    jnc_s  : in std_logic;
    jc_s   : in std_logic;
    jmp_s  : in std_logic;
    sub_s  : in std_logic;
    add_s  : in std_logic;
    ld_s   : in std_logic;
    st_s   : in std_logic;

    -- Status inputs from Datapath
    Cflag  : in std_logic;
    Zflag  : in std_logic;
    Nflag  : in std_logic;

    -- Control outputs to Datapath
    DTCM_wr      : out std_logic;
    Cin          : out std_logic;
    Cout         : out std_logic;
    DTCM_addr_in : out std_logic;
    DTCM_out     : out std_logic;
    ALUFN        : out std_logic_vector(3 downto 0);

    Ain          : out std_logic;
    RFin         : out std_logic;
    RFout        : out std_logic;

    RFaddr_rd    : out std_logic_vector(1 downto 0);
    RFaddr_wr    : out std_logic;

    IRin         : out std_logic;
    PCin         : out std_logic;
    PCsel        : out std_logic_vector(1 downto 0);

    Imm1_in      : out std_logic;
    Imm2_in      : out std_logic;

    done         : out std_logic
  );
end component;

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
-------------------------------------------------------------------------------
component alu is
    generic (n:integer :=16);
    port(
        A,B :in std_logic_vector(n-1 downto 0 ); --ra - A, rb - B
        alufn:in std_logic_vector(3 downto 0 );
        C  :out std_logic_vector(n-1 downto 0); --c like in the draw
        C_flag, Z_flag,N_flag: out std_logic
    );
    end component;















end aux_package;
------------------------------------------------------------------------