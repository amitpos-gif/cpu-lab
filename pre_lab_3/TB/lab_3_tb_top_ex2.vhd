--==============================================================================
-- Testbench for Example 1
-- Loads ITCM/DTCM, runs CPU, dumps DTCM to file.
-- No component declaration.
-- No DTCM_EXPECTED.
-- No assert checks.
--==============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

use work.aux_package.all;

entity lab_3_tb_top_ex2 is
end entity;

architecture sim of lab_3_tb_top_ex2 is

  constant Dwidth      : integer := 16;
  constant Awidth      : integer := 6;
  constant DEPT        : integer := 64;
  constant CLK_PERIOD  : time    := 20 ns;
  constant RUN_TIMEOUT : time    := 50 us;

  constant DTCM_OUT_FILE : string := "DTCMout_ex1.txt";

  type word_array_t is array (natural range <>) of std_logic_vector(Dwidth-1 downto 0);

  constant ITCM_INIT : word_array_t := (
    X"C100", X"C20E", X"C31C", X"C400", X"C501", X"C60E",
    X"D710", X"D820", X"0978", X"E930",
    X"0115", X"0225", X"0335", X"0445",
    X"1A46", X"90F6", X"F000", X"0000", X"70FE"
  );

  constant DTCM_INIT : word_array_t := (
    X"0000", X"0001", X"0002", X"0003", X"0004", X"0005", X"0006",
    X"0007", X"0008", X"0009", X"000A", X"000B", X"000C", X"000D",

    X"0000", X"0001", X"0002", X"0003", X"0004", X"0005", X"0006",
    X"0007", X"0008", X"0009", X"000A", X"000B", X"000C", X"000D",

    X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",
    X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000"
  );

  signal clk              : std_logic := '0';
  signal rst              : std_logic := '1';
  signal ena              : std_logic := '0';
  signal TBactive         : std_logic := '1';

  signal ITCM_tb_wr       : std_logic := '0';
  signal ITCM_tb_in       : std_logic_vector(Dwidth-1 downto 0) := (others => '0');
  signal ITCM_tb_addr_in  : std_logic_vector(Awidth-1 downto 0) := (others => '0');

  signal DTCM_tb_wr       : std_logic := '0';
  signal DTCM_tb_in       : std_logic_vector(Dwidth-1 downto 0) := (others => '0');
  signal DTCM_tb_out      : std_logic_vector(Dwidth-1 downto 0);
  signal DTCM_tb_addr_in  : std_logic_vector(Awidth-1 downto 0) := (others => '0');
  signal DTCM_tb_addr_out : std_logic_vector(Awidth-1 downto 0) := (others => '0');

  signal done             : std_logic;
  signal sim_done         : boolean := false;

begin

  DUT : entity work.top
    generic map (
      Dwidth => Dwidth,
      Awidth => Awidth,
      dept   => DEPT
    )
    port map (
      clk              => clk,
      rst              => rst,
      ena              => ena,
      TBactive         => TBactive,
      ITCM_tb_wr       => ITCM_tb_wr,
      ITCM_tb_in       => ITCM_tb_in,
      ITCM_tb_addr_in  => ITCM_tb_addr_in,
      DTCM_tb_wr       => DTCM_tb_wr,
      DTCM_tb_in       => DTCM_tb_in,
      DTCM_tb_out      => DTCM_tb_out,
      DTCM_tb_addr_in  => DTCM_tb_addr_in,
      DTCM_tb_addr_out => DTCM_tb_addr_out,
      done             => done
    );

  clk_process : process
  begin
    while not sim_done loop
      clk <= '0';
      wait for CLK_PERIOD / 2;
      clk <= '1';
      wait for CLK_PERIOD / 2;
    end loop;
    wait;
  end process;

  stim_process : process
    file out_file : text open write_mode is DTCM_OUT_FILE;
    variable Lout : line;
  begin

    rst      <= '1';
    ena      <= '0';
    TBactive <= '1';

    wait until rising_edge(clk);
    wait until rising_edge(clk);

    -- Load ITCM
    ITCM_tb_wr <= '1';

    for i in ITCM_INIT'range loop
      ITCM_tb_in      <= ITCM_INIT(i);
      ITCM_tb_addr_in <= conv_std_logic_vector(i, Awidth);
      wait until rising_edge(clk);
      wait until falling_edge(clk);
    end loop;

    ITCM_tb_wr <= '0';

    -- Load DTCM
    DTCM_tb_wr <= '1';

    for i in DTCM_INIT'range loop
      DTCM_tb_in      <= DTCM_INIT(i);
      DTCM_tb_addr_in <= conv_std_logic_vector(i, Awidth);
      wait until rising_edge(clk);
      wait until falling_edge(clk);
    end loop;

    DTCM_tb_wr <= '0';

    -- Run CPU
    TBactive <= '0';
    rst      <= '0';
    ena      <= '1';

    wait until rising_edge(clk);

    wait until (done = '1') for RUN_TIMEOUT;

    -- Dump DTCM
    ena      <= '0';
    TBactive <= '1';

    wait until falling_edge(clk);

    for i in 0 to DEPT-1 loop
      DTCM_tb_addr_out <= conv_std_logic_vector(i, Awidth);

      wait until rising_edge(clk);
      wait for 1 ns;

      hwrite(Lout, DTCM_tb_out);
      writeline(out_file, Lout);

      wait until falling_edge(clk);
    end loop;

    file_close(out_file);

    sim_done <= true;
    wait for 2 * CLK_PERIOD;

    report "End of simulation" severity failure;
    wait;

  end process;

end architecture;