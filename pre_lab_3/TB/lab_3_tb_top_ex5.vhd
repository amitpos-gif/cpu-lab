--==============================================================================
-- Testbench for Example 1
-- Loads ITCM/DTCM from text files, runs CPU, dumps DTCM to file.
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

entity lab_3_tb_top_ex5 is
end entity;

architecture sim of lab_3_tb_top_ex5 is

  constant Dwidth      : integer := 16;
  constant Awidth      : integer := 6;
  constant DEPT        : integer := 64;
  constant CLK_PERIOD  : time    := 20 ns;
  constant RUN_TIMEOUT : time    := 50 us;

  -- Input init files (one 16-bit hex word per line)
  -- NOTE: use forward slashes, even on Windows.
  -- Either keep these as plain filenames AND copy the files into ModelSim's
  -- working directory (type `pwd` in the transcript to see where that is),
  -- or use a full absolute path like below.
  constant ITCM_IN_FILE  : string := "C:\Users\amitp\OneDrive\Desktop\Comp_Lab\Lab_3\206458333_318676061\SW-QA\Ex5_toComplete\bin\ITCMinit.txt";
  constant DTCM_IN_FILE  : string := "C:\Users\amitp\OneDrive\Desktop\Comp_Lab\Lab_3\206458333_318676061\SW-QA\Ex5_toComplete\bin\DTCMinit.txt";

  -- Output dump file
  constant DTCM_OUT_FILE : string := "DTCMout_ex1.txt";

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
    file out_file  : text open write_mode is DTCM_OUT_FILE;
    file itcm_file : text open read_mode  is ITCM_IN_FILE;
    file dtcm_file : text open read_mode  is DTCM_IN_FILE;
    variable Lout  : line;
    variable Lin   : line;
    variable word_v : std_logic_vector(Dwidth-1 downto 0);
    variable addr_i : integer;
  begin

    rst      <= '1';
    ena      <= '0';
    TBactive <= '1';

    wait until rising_edge(clk);
    wait until rising_edge(clk);

    -- ---------------------------------------------------------------
    -- Load ITCM from file
    -- ---------------------------------------------------------------
    ITCM_tb_wr <= '1';
    addr_i := 0;

    while not endfile(itcm_file) loop
      readline(itcm_file, Lin);
      -- skip blank/empty lines safely (Lin is access string)
      if Lin = null then
        next;
      end if;
      if Lin.all'length = 0 then
        next;
      end if;

      hread(Lin, word_v);

      ITCM_tb_in      <= word_v;
      ITCM_tb_addr_in <= conv_std_logic_vector(addr_i, Awidth);
      wait until rising_edge(clk);
      wait until falling_edge(clk);

      addr_i := addr_i + 1;
    end loop;

    ITCM_tb_wr <= '0';

    -- ---------------------------------------------------------------
    -- Load DTCM from file
    -- ---------------------------------------------------------------
    DTCM_tb_wr <= '1';
    addr_i := 0;

    while not endfile(dtcm_file) loop
      readline(dtcm_file, Lin);
      if Lin = null then
        next;
      end if;
      if Lin.all'length = 0 then
        next;
      end if;

      hread(Lin, word_v);

      DTCM_tb_in      <= word_v;
      DTCM_tb_addr_in <= conv_std_logic_vector(addr_i, Awidth);
      wait until rising_edge(clk);
      wait until falling_edge(clk);

      addr_i := addr_i + 1;
    end loop;

    DTCM_tb_wr <= '0';

    -- ---------------------------------------------------------------
    -- Run CPU
    -- ---------------------------------------------------------------
    TBactive <= '0';
    rst      <= '0';
    ena      <= '1';

    wait until rising_edge(clk);

    wait until (done = '1') for RUN_TIMEOUT;

    -- ---------------------------------------------------------------
    -- Dump DTCM
    -- ---------------------------------------------------------------
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
    file_close(itcm_file);
    file_close(dtcm_file);

    sim_done <= true;
    wait for 2 * CLK_PERIOD;

    report "End of simulation" severity failure;
    wait;

  end process;

end architecture;