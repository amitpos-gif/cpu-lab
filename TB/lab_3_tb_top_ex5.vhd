--==============================================================================
-- File         : lab_3_tb_top_ex5.vhd
-- Description  : Testbench for the SRMC Multi-Cycle CPU `top` entity.
--                ITCM and DTCM initial contents are HARDCODED as constant
--                arrays (no input-file reading). Runs the program until the
--                FSM asserts `done='1'`, then dumps the final DTCM contents
--                to a text file for diff'ing against the expected result.
--
-- To test a different program:
--     edit ITCM_INIT and/or DTCM_INIT constants below.
--==============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;          -- conv_std_logic_vector
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;         -- hwrite for std_logic_vector (output only)

library std;
use std.textio.all;                    -- text, line, writeline (output only)

use work.aux_package.all;

------------------------------------------------------------------------------
entity lab_3_tb_top_ex5 is
  -- No ports: top-level simulation entity.
end entity lab_3_tb_top_ex5;

------------------------------------------------------------------------------
architecture sim of lab_3_tb_top_ex5 is

  ------------------------------------------------------------------------
  -- Constants
  ------------------------------------------------------------------------
  constant Dwidth     : integer := 16;
  constant Awidth     : integer := 6;
  constant DEPT       : integer := 64;          -- ITCM / DTCM depth
  constant CLK_PERIOD : time    := 20 ns;       -- 50 MHz default
  constant RUN_TIMEOUT: time    := 50 us;       -- timeout if `done` never asserts

  constant DTCM_OUT_FILE : string := "DTCMout.txt";

  ------------------------------------------------------------------------
  -- Memory image type and hardcoded initial contents
  -- (taken verbatim from the original ITCMinit.txt / DTCMinit.txt)
  ------------------------------------------------------------------------
  type word_array_t is array (natural range <>) of std_logic_vector(Dwidth-1 downto 0);

  -- 16 instruction words, addresses 0..15
  constant ITCM_INIT : word_array_t := (
    X"C100",   -- mov r1,arr1
    X"C20E",   -- mov r2,arr2
    X"C31C",   -- mov r3,res
    X"C400",   -- mov r4,0
    X"C501",   -- mov r5,1
    X"C60E",   -- mov r6,14

    X"D710",   -- ld r7,0(r1)
    X"D820",   -- ld r8,0(r2)

    X"2945",   -- and r9,r4,r5
    X"1B95",   -- sub r11,r9,r5
    X"9003",   -- jlo 3

    X"0A78",   -- add r10,r7,r8
    X"EA30",   -- st r10,0(r3)
    X"7002",   -- jmp 2

    X"1A78",   -- sub r10,r7,r8
    X"EA30",   -- st r10,0(r3)

    X"0115",   -- add r1,r1,r5
    X"0225",   -- add r2,r2,r5
    X"0335",   -- add r3,r3,r5
    X"0445",   -- add r4,r4,r5

    X"1A46",   -- sub r10,r4,r6
    X"90F0",   -- old - jlo -15 new jlo-16  

    X"F000",   -- done
    X"0000",   -- nop
    X"70FE"    -- jmp -2
);

  -- 15 data words, addresses 0..14
  constant DTCM_INIT : word_array_t := (
    -- arr1
    X"003F",
    X"021E",
    X"00F5",
    X"00BE",
    X"005B",
    X"0056",
    X"004E",
    X"0040",
    X"0053",
    X"0010",
    X"0018",
    X"003E",
    X"004F",
    X"0013",

    -- arr2
    X"000D",
    X"0138",
    X"008D",
    X"00A0",
    X"005C",
    X"0058",
    X"0047",
    X"003F",
    X"003B",
    X"000E",
    X"002B",
    X"000C",
    X"0047",
    X"005A",

    -- res, 14 empty words
    X"0000",
    X"0000",
    X"0000",
    X"0000",
    X"0000",
    X"0000",
    X"0000",
    X"0000",
    X"0000",
    X"0000",
    X"0000",
    X"0000",
    X"0000",
    X"0000"
);

  ------------------------------------------------------------------------
  -- Component declaration for the DUT (top entity)
  ------------------------------------------------------------------------
  component top is
    generic ( Dwidth : integer := 16;
              Awidth : integer := 6;
              dept   : integer := 64 );
    port (
      clk              : in  std_logic;
      rst              : in  std_logic;
      ena              : in  std_logic;
      TBactive         : in  std_logic;
      ITCM_tb_wr       : in  std_logic;
      ITCM_tb_in       : in  std_logic_vector(Dwidth-1 downto 0);
      ITCM_tb_addr_in  : in  std_logic_vector(Awidth-1 downto 0);
      DTCM_tb_wr       : in  std_logic;
      DTCM_tb_in       : in  std_logic_vector(Dwidth-1 downto 0);
      DTCM_tb_out      : out std_logic_vector(Dwidth-1 downto 0);
      DTCM_tb_addr_in  : in  std_logic_vector(Awidth-1 downto 0);
      DTCM_tb_addr_out : in  std_logic_vector(Awidth-1 downto 0);
      done             : out std_logic
    );
  end component;

  ------------------------------------------------------------------------
  -- Signals driving the DUT
  ------------------------------------------------------------------------
  signal clk              : std_logic := '0';
  signal rst              : std_logic := '1';
  signal ena              : std_logic := '0';

  signal TBactive         : std_logic := '1';
  signal ITCM_tb_wr       : std_logic := '0';
  signal ITCM_tb_in       : std_logic_vector(Dwidth-1 downto 0) := (others => '0');
  signal ITCM_tb_addr_in  : std_logic_vector(Awidth-1 downto 0) := (others => '0');
  signal DTCM_tb_wr       : std_logic := '0';
  signal DTCM_tb_in       : std_logic_vector(Dwidth-1 downto 0) := (others => '0');
  signal DTCM_tb_addr_in  : std_logic_vector(Awidth-1 downto 0) := (others => '0');
  signal DTCM_tb_addr_out : std_logic_vector(Awidth-1 downto 0) := (others => '0');
  signal DTCM_tb_out      : std_logic_vector(Dwidth-1 downto 0);
  signal done             : std_logic;

  signal sim_done         : boolean := false;

begin

  ------------------------------------------------------------------------
  -- DUT instantiation
  ------------------------------------------------------------------------
  DUT : top
    generic map ( Dwidth => Dwidth, Awidth => Awidth, dept => DEPT )
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

  ------------------------------------------------------------------------
  -- Clock generator (stops cleanly once sim_done = true)
  ------------------------------------------------------------------------
  CLK_GEN : process
  begin
    while not sim_done loop
      clk <= '0';
      wait for CLK_PERIOD / 2;
      clk <= '1';
      wait for CLK_PERIOD / 2;
    end loop;
    wait;
  end process CLK_GEN;

  ------------------------------------------------------------------------
  -- Main stimulus process
  ------------------------------------------------------------------------
  STIM : process
    file out_file : text open write_mode is DTCM_OUT_FILE;
    variable Lout : line;
  begin

    --------------------------------------------------------------------
    -- PHASE 0 : reset / init all stimuli to known safe values
    --------------------------------------------------------------------
    rst        <= '1';
    ena        <= '0';
    TBactive   <= '1';
    ITCM_tb_wr <= '0';
    DTCM_tb_wr <= '0';
    ITCM_tb_in       <= (others => '0');
    ITCM_tb_addr_in  <= (others => '0');
    DTCM_tb_in       <= (others => '0');
    DTCM_tb_addr_in  <= (others => '0');
    DTCM_tb_addr_out <= (others => '0');

    wait until rising_edge(clk);
    wait until rising_edge(clk);

    --------------------------------------------------------------------
    -- PHASE 1 : load ITCM from the ITCM_INIT constant
    --   * one word per rising clock edge
    --   * we change signals on the falling edge so they are stable
    --     well before the rising edge that commits the write
    --------------------------------------------------------------------
    wait until falling_edge(clk);
    ITCM_tb_wr <= '1';

    for i in ITCM_INIT'range loop
      ITCM_tb_in      <= ITCM_INIT(i);
      ITCM_tb_addr_in <= conv_std_logic_vector(i, Awidth);
      wait until rising_edge(clk);      -- write commits here
      wait until falling_edge(clk);     -- safe to change signals again
    end loop;

    ITCM_tb_wr <= '0';
    report "TB: ITCM loaded, " &
           integer'image(ITCM_INIT'length) & " words." severity note;

    --------------------------------------------------------------------
    -- PHASE 2 : load DTCM from the DTCM_INIT constant
    --------------------------------------------------------------------
    DTCM_tb_wr <= '1';

    for i in DTCM_INIT'range loop
      DTCM_tb_in      <= DTCM_INIT(i);
      DTCM_tb_addr_in <= conv_std_logic_vector(i, Awidth);
      wait until rising_edge(clk);
      wait until falling_edge(clk);
    end loop;

    DTCM_tb_wr <= '0';
    report "TB: DTCM loaded, " &
           integer'image(DTCM_INIT'length) & " words." severity note;

    --------------------------------------------------------------------
    -- PHASE 3 : run the CPU
    --   * release reset, drop TBactive, enable FSM
    --   * wait for `done='1'` (with timeout)
    --------------------------------------------------------------------
    TBactive <= '0';
    rst      <= '0';
    ena      <= '1';

    wait until rising_edge(clk);
    report "TB: CPU running..." severity note;

    wait until (done = '1') for RUN_TIMEOUT;

    assert done = '1'
      report "TB ERROR: CPU did not assert `done` within RUN_TIMEOUT. " &
             "Check FSM transitions / program loaded into ITCM."
      severity failure;

    report "TB: `done` asserted - program completed." severity note;

    --------------------------------------------------------------------
    -- PHASE 4 : dump DTCM[0..DEPT-1] to DTCMout.txt
    --   * TBactive='1' gives us the DTCM read port (DTCM_tb_addr_out)
    --   * DTCM has combinational read in your file:
    --        RmemData <= sysRAM(conv_integer(RmemAddr));
    --     so DTCM_tb_out is valid one delta after the address changes;
    --     one rising edge per sample is plenty of margin.
    --------------------------------------------------------------------
    ena      <= '0';
    TBactive <= '1';

    wait until falling_edge(clk);

    for i in 0 to DEPT-1 loop
        DTCM_tb_addr_out <= conv_std_logic_vector(i, Awidth);
        wait for 1 ns;
        hwrite(Lout, DTCM_tb_out);
        writeline(out_file, Lout);
    end loop;

    file_close(out_file);
    report "TB: DTCM dumped to " & DTCM_OUT_FILE & "." severity note;

    --------------------------------------------------------------------
    -- PHASE 5 : stop the simulation cleanly
    --------------------------------------------------------------------
    sim_done <= true;
    wait for 2 * CLK_PERIOD;

    report "TB: simulation finished OK." severity note;
    assert false report "End of simulation." severity failure;
    -- ^ standard ModelSim trick: `failure` severity stops vsim;
    --   the message above is informational, not an error.
    wait;
  end process STIM;

end architecture sim;
