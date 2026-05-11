

library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.aux_package.all;

-------------------------------------------------------------------------------
entity top is
  generic ( Dwidth : integer := 16;
            Awidth : integer := 6;
            dept   : integer := 64 );
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;
    ena  : in  std_logic;
    -- Testbench memory access (Figure 1 - "green line" ports) --
    TBactive         : in  std_logic;
    ITCM_tb_wr       : in  std_logic;
    ITCM_tb_in       : in  std_logic_vector(Dwidth-1 downto 0);
    ITCM_tb_addr_in  : in  std_logic_vector(Awidth-1 downto 0);
    DTCM_tb_wr       : in  std_logic;
    DTCM_tb_in       : in  std_logic_vector(Dwidth-1 downto 0);
    DTCM_tb_out      : out std_logic_vector(Dwidth-1 downto 0);
    DTCM_tb_addr_in  : in  std_logic_vector(Awidth-1 downto 0);
    DTCM_tb_addr_out : in  std_logic_vector(Awidth-1 downto 0);
    -- Done flag -> Testbench
    done             : out std_logic
  );
end entity top;

-------------------------------------------------------------------------------
architecture struct of top is

  -------------------------------------------------------------------------
  -- Internal wires: CONTROL -> DATAPATH (16 control signals)
  -------------------------------------------------------------------------
  signal w_IRin         : std_logic;
  signal w_PCin         : std_logic;
  signal w_PCsel        : std_logic_vector(1 downto 0);
  signal w_Ain          : std_logic;
  signal w_Cin          : std_logic;
  signal w_Cout         : std_logic;
  signal w_RFout        : std_logic;
  signal w_RFin         : std_logic;
  signal w_RFaddr_rd    : std_logic_vector(1 downto 0);
  signal w_RFaddr_wr    : std_logic;
  signal w_Imm1_in      : std_logic;
  signal w_Imm2_in      : std_logic;
  signal w_DTCM_wr      : std_logic;
  signal w_DTCM_out     : std_logic;
  signal w_DTCM_addr_in : std_logic;
  signal w_ALUFN        : std_logic_vector(3 downto 0);

  -------------------------------------------------------------------------
  -- Internal wires: DATAPATH -> CONTROL (15 status signals)
  -------------------------------------------------------------------------
  signal w_ld_s, w_st_s, w_mov_s, w_done_s            : std_logic;
  signal w_add_s, w_sub_s, w_jmp_s, w_jc_s, w_jnc_s   : std_logic;
  signal w_and_s, w_or_s, w_xor_s                     : std_logic;
  signal w_Cflag, w_Zflag, w_Nflag                    : std_logic;

begin

  -------------------------------------------------------------------------
  --- Control Unit Instantiation --
  --- (formal port name => internal wire in top) --
  -------------------------------------------------------------------------
  CU : Control
    port map (
      clk          => clk,
      rst          => rst,
      ena          => ena,
      -- Status FROM Datapath (inputs to Control)
      mov_s        => w_mov_s,
      done_s       => w_done_s,
      and_s        => w_and_s,
      or_s         => w_or_s,
      xor_s        => w_xor_s,
      jnc_s        => w_jnc_s,
      jc_s         => w_jc_s,
      jmp_s        => w_jmp_s,
      sub_s        => w_sub_s,
      add_s        => w_add_s,
      ld_s         => w_ld_s,
      st_s         => w_st_s,
      Cflag        => w_Cflag,
      Zflag        => w_Zflag,
      Nflag        => w_Nflag,
      -- Control TO Datapath (outputs of Control)
      DTCM_wr      => w_DTCM_wr,
      Cin          => w_Cin,
      Cout         => w_Cout,
      DTCM_addr_in => w_DTCM_addr_in,
      DTCM_out     => w_DTCM_out,
      ALUFN        => w_ALUFN,
      Ain          => w_Ain,
      RFin         => w_RFin,
      RFout        => w_RFout,
      RFaddr_rd    => w_RFaddr_rd,
      RFaddr_wr    => w_RFaddr_wr,
      IRin         => w_IRin,
      PCin         => w_PCin,
      PCsel        => w_PCsel,
      Imm1_in      => w_Imm1_in,
      Imm2_in      => w_Imm2_in,
      done         => done            -- exits the top entity
    );

  -------------------------------------------------------------------------
  -- Datapath Instantiation
  -- (formal port name => internal wire in top)
  -------------------------------------------------------------------------
  DP : Datapath
    generic map ( Dwidth => Dwidth, Awidth => Awidth, dept => dept )
    port map (
      clk              => clk,
      rst              => rst,
      -- Control inputs (FROM CU)
      DTCM_wr          => w_DTCM_wr,
      Cin              => w_Cin,
      Cout             => w_Cout,
      DTCM_addr_in     => w_DTCM_addr_in,
      DTCM_out         => w_DTCM_out,
      ALUFN            => w_ALUFN,
      Ain              => w_Ain,
      RFin             => w_RFin,
      RFout            => w_RFout,
      RFaddr_rd        => w_RFaddr_rd,
      RFaddr_wr        => w_RFaddr_wr,
      IRin             => w_IRin,
      PCin             => w_PCin,
      PCsel            => w_PCsel,
      Imm1_in          => w_Imm1_in,
      Imm2_in          => w_Imm2_in,
      -- Status outputs (TO CU)
      mov_s            => w_mov_s,
      done_s           => w_done_s,
      and_s            => w_and_s,
      or_s             => w_or_s,
      xor_s            => w_xor_s,
      jnc_s            => w_jnc_s,
      jc_s             => w_jc_s,
      jmp_s            => w_jmp_s,
      sub_s            => w_sub_s,
      add_s            => w_add_s,
      ld_s             => w_ld_s,
      st_s             => w_st_s,
      Cflag            => w_Cflag,
      Zflag            => w_Zflag,
      Nflag            => w_Nflag,
      -- Testbench memory access ports (pass straight through to top entity)
      TBactive         => TBactive,
      ITCM_tb_wr       => ITCM_tb_wr,
      ITCM_tb_in       => ITCM_tb_in,
      ITCM_tb_addr_in  => ITCM_tb_addr_in,
      DTCM_tb_wr       => DTCM_tb_wr,
      DTCM_tb_in       => DTCM_tb_in,
      DTCM_tb_out      => DTCM_tb_out,
      DTCM_tb_addr_in  => DTCM_tb_addr_in,
      DTCM_tb_addr_out => DTCM_tb_addr_out
    );

end architecture struct;
