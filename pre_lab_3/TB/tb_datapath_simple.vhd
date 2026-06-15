-- ============================================================
-- tb_datapath_simple.vhd
--
-- What we are testing:
--   A single ADD instruction only:
--   add R1, R2, R3  ->  R[1] <- R[2] + R[3]
--
-- Test plan:
--   Step 1: Load R2=5 and R3=3 into the register file
--   Step 2: Manually run the 4 ADD cycles (no CU)
--   Step 3: Check that Zflag=0 and the result 8 was stored correctly
-- ============================================================

library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.aux_package.all;

entity tb_datapath_simple is
end entity tb_datapath_simple;

architecture sim of tb_datapath_simple is

  -- Clock and reset
  signal clk : std_logic := '0';
  signal rst : std_logic := '0';

  -- Control signals (normally driven by the CU)
  -- We drive them manually here to isolate the Datapath
  signal DTCM_wr      : std_logic := '0';
  signal Cin          : std_logic := '0';
  signal Cout         : std_logic := '0';
  signal DTCM_addr_in : std_logic := '0';
  signal DTCM_out     : std_logic := '0';
  signal ALUFN        : std_logic_vector(3 downto 0) := "0000";
  signal Ain          : std_logic := '0';
  signal RFin         : std_logic := '0';
  signal RFout        : std_logic := '0';
  signal RFaddr_rd    : std_logic_vector(1 downto 0) := "00";
  signal RFaddr_wr    : std_logic := '0';
  signal IRin         : std_logic := '0';
  signal PCin         : std_logic := '0';
  signal PCsel        : std_logic_vector(1 downto 0) := "10";
  signal Imm1_in      : std_logic := '0';
  signal Imm2_in      : std_logic := '0';

  -- Status flags returned by the Datapath
  signal Cflag  : std_logic;
  signal Zflag  : std_logic;
  signal Nflag  : std_logic;
  signal add_s  : std_logic;
  signal sub_s  : std_logic;
  signal and_s  : std_logic;
  signal or_s   : std_logic;
  signal xor_s  : std_logic;
  signal mov_s  : std_logic;
  signal ld_s   : std_logic;
  signal st_s   : std_logic;
  signal jmp_s  : std_logic;
  signal jc_s   : std_logic;
  signal jnc_s  : std_logic;
  signal done_s : std_logic;

  -- Testbench green-line ports (direct memory access)
  signal TBactive         : std_logic := '1';
  signal ITCM_tb_wr       : std_logic := '0';
  signal ITCM_tb_in       : std_logic_vector(15 downto 0) := (others => '0');
  signal ITCM_tb_addr_in  : std_logic_vector(5 downto 0)  := (others => '0');
  signal DTCM_tb_wr       : std_logic := '0';
  signal DTCM_tb_in       : std_logic_vector(15 downto 0) := (others => '0');
  signal DTCM_tb_out      : std_logic_vector(15 downto 0);
  signal DTCM_tb_addr_in  : std_logic_vector(5 downto 0)  := (others => '0');
  signal DTCM_tb_addr_out : std_logic_vector(5 downto 0)  := (others => '0');

begin

  -- ============================================================
  -- Datapath instantiation (Device Under Test)
  -- ============================================================
  DUT : Datapath
    generic map (Dwidth => 16, Awidth => 6, dept => 64)
    port map (
      clk              => clk,
      rst              => rst,
      DTCM_wr          => DTCM_wr,
      Cin              => Cin,
      Cout             => Cout,
      DTCM_addr_in     => DTCM_addr_in,
      DTCM_out         => DTCM_out,
      ALUFN            => ALUFN,
      Ain              => Ain,
      RFin             => RFin,
      RFout            => RFout,
      RFaddr_rd        => RFaddr_rd,
      RFaddr_wr        => RFaddr_wr,
      IRin             => IRin,
      PCin             => PCin,
      PCsel            => PCsel,
      Imm1_in          => Imm1_in,
      Imm2_in          => Imm2_in,
      mov_s            => mov_s,
      done_s           => done_s,
      and_s            => and_s,
      or_s             => or_s,
      xor_s            => xor_s,
      jnc_s            => jnc_s,
      jc_s             => jc_s,
      jmp_s            => jmp_s,
      sub_s            => sub_s,
      add_s            => add_s,
      ld_s             => ld_s,
      st_s             => st_s,
      Cflag            => Cflag,
      Zflag            => Zflag,
      Nflag            => Nflag,
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

  -- ============================================================
  -- Clock generator: 20 ns period (50 MHz)
  -- ============================================================
  clk <= not clk after 10 ns;

  -- ============================================================
  -- Main stimulus process
  -- ============================================================
  STIM : process
  begin

  
    ---- Step 0: RESET ----
  
    rst <= '1';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    rst <= '0';
    wait for 5 ns;  -- short settling time

    
    ---- Step 1: Load the ADD instruction into ITCM ----
 
    TBactive        <= '1';     -- TB mode: we control the memories directly
    ITCM_tb_addr_in <= "000000"; -- first adrees of mem prog - 6 bit --
    ITCM_tb_in      <= x"0123";  -- the code 0000,0001,0010,0011  coding in x'abit - stend for add R1, R2, R3 -
    ITCM_tb_wr      <= '1';      -- the wr bit up for wirting in to the itcm prog meme ---
    wait until rising_edge(clk); --  crieiting the witing for the instraction to go to the prog meme
    ITCM_tb_wr      <= '0';       --- then we set the wr bit to 0 
    wait for 5 ns;

    report "Step 1: ADD instruction (0x0123) written to ITCM address 0" severity NOTE;

  
    ---- Step 2: Load values into R2 and R3 ----

    -- Write synthetic MOV R2=5 to ITCM address 1
    ITCM_tb_addr_in <= "000001";  -- adrees 1 to the prog meme
    ITCM_tb_in      <= x"C205";  -- thw insrection coded - mov the const 5 to thr resister R_2
    ITCM_tb_wr      <= '1';  --  Anibeling the wariting
    wait until rising_edge(clk); -- witing until the clk for the informesing to go on 
    ITCM_tb_wr      <= '0';  -- wr bit down
    wait for 5 ns;

    -- Write synthetic MOV R3=3 to ITCM address 2
    ITCM_tb_addr_in <= "000010";  -- addres 2 in the prog meme
    ITCM_tb_in      <= x"C303";   -- the instraction cosisng in to the 16 bit code of - moving the const 3 to R_3
    ITCM_tb_wr      <= '1';  --  wr Anibeling
    wait until rising_edge(clk);  -- witing untile clk up ans the actiong is going on
    ITCM_tb_wr      <= '0'; -- wr bit down 
    wait for 5 ns;

    report "Step 2: Synthetic MOV instructions written to ITCM" severity NOTE;

  
    ---- Step 3: Switch to CPU execution mode and drive signals manually ----
   
    TBactive <= '0';  
    wait for 5 ns;

    
    ---- FETCH of MOV R2=5  (reads from ITCM[1]) ----
    ---- First advance PC from 0 to 1  - for moving the const 5 to R_2 ----
    
    PCin  <= '1'; 
    PCsel <= "10";  -- PC = PC+1  (0 -> 1)
    wait until rising_edge(clk);
    PCin  <= '0';

    --- AT THISPOINT THE NETX INSTRCTION IS MOV(R2, 5) ----
    -- FETCH: latch IR from ITCM[1]
    IRin  <= '1';
    PCin  <= '1';
    PCsel <= "10";  ---- PC will advance to PC+1 = 1+1 = 2 after this ----
    wait until rising_edge(clk);
    ---- shoting down all the control bit bafore the privios clk arising ----
    IRin  <= '0';
    PCin  <= '0';
    wait for 5 ns;

    ---- MOV EXECUTE: Imm1_in puts 0x0005 on BUS, RFin writes it to R2  ----
    ----- RFaddr_wr='1' -> write address comes from IR[11:8]="0010" = R2 -----
    Imm1_in   <= '1';
    RFin      <= '1';
    RFaddr_wr <= '1';
    wait until rising_edge(clk);
    ---- shoting down all the control bit bafore the privios clk arising ----
    Imm1_in   <= '0';
    RFin      <= '0';
    RFaddr_wr <= '0';
    wait for 5 ns;

    report "Step 3a: R2 loaded with value 5" severity NOTE;

    -- FETCH of MOV R3=3  (reads from ITCM[2])
    --- remember ? the pc is all-rady on 2  - the corect position od the next instraction - mov()
 
    IRin  <= '1';
    PCin  <= '1';
    PCsel <= "10";
    wait until rising_edge(clk);
    IRin  <= '0';
    PCin  <= '0';
    wait for 5 ns;

    -- MOV EXECUTE: Imm1_in puts 0x0003 on BUS, RFin writes it to R3
    -- RFaddr_wr='1' -> write address comes from IR[11:8]="0011" = R3
    Imm1_in   <= '1';
    RFin      <= '1';
    RFaddr_wr <= '1';
    wait until rising_edge(clk);
    Imm1_in   <= '0';
    RFin      <= '0';
    RFaddr_wr <= '0';
    wait for 5 ns;

    report "Step 3b: R3 loaded with value 3" severity NOTE;

    -- ===================================================
    -- ADD instruction: 4 cycles
    -- Instruction: add R1, R2, R3  (IR = 0x0123)
    -- ===================================================

    -- Cycle 1 - FETCH: latch ADD instruction from ITCM[0]
    -- PC is currently at 3, so first reset it back to 0
    PCin  <= '1';
    PCsel <= "00";  -- PC <- 0  --- by seting the pcsel to 00 we resteting the program conter to 000000 - axactly where the add instraction is.
    wait until rising_edge(clk);
    PCin  <= '0';
    wait for 5 ns;

    IRin  <= '1';         -- IR <- ITCM[0] = 0x0123
    PCin  <= '1';
    PCsel <= "10";        -- PC <- PC+1 = 1
    wait until rising_edge(clk);
    IRin  <= '0';
    PCin  <= '0';
    wait for 5 ns;

    -- Check: did the IR decoder recognise ADD?
    assert add_s = '1'
      report "FAIL: add_s should be 1 after FETCH of 0x0123"
      severity ERROR;
    report "FETCH: add_s=1 - OK  (IR=0x0123 loaded)" severity NOTE;

    -- Cycle 2 - DECODE: R2(rb) -> BUS -> REG_A
    -- RFaddr_rd="10" -> reads from IR[7:4]="0010" = R2
    RFout     <= '1';
    Ain       <= '1';
    RFaddr_rd <= "10";
    wait until rising_edge(clk);
    RFout     <= '0';
    Ain       <= '0';
    RFaddr_rd <= "00";
    wait for 5 ns;

    report "DECODE: R2(=5) -> REG_A - OK" severity NOTE;

    -- Cycle 3 - EXECUTE: R3(rc) -> BUS ; ALU computes ; REG_C <- result
    -- RFaddr_rd="01" -> reads from IR[3:0]="0011" = R3
    -- ALUFN="0000"   -> ADD operation
    -- Cin='1'        -> latches ALU result into REG_C and captures flags
    RFout     <= '1';
    Cin       <= '1';
    ALUFN     <= "0000";
    RFaddr_rd <= "01";
    wait until rising_edge(clk);
    RFout     <= '0';
    Cin       <= '0';
    RFaddr_rd <= "00";
    wait for 5 ns;

    -- Flag checks after EXECUTE
    -- Expected: 5 + 3 = 8
    --   Zflag must be 0  (result is not zero)
    --   Cflag must be 0  (no carry out)
    --   Nflag must be 0  (result is positive)
    assert Zflag = '0'
      report "FAIL: Zflag should be 0  (5+3=8, result is not zero)"
      severity ERROR;

    assert Cflag = '0'
      report "FAIL: Cflag should be 0  (no carry for 5+3)"
      severity ERROR;

    assert Nflag = '0'
      report "FAIL: Nflag should be 0  (8 is a positive number)"
      severity ERROR;

    report "EXECUTE: Zflag=0, Cflag=0, Nflag=0 - OK  (5+3=8)" severity NOTE;

    -- Cycle 4 - WRITEBACK: REG_C(=8) -> BUS -> RF[R1]
    -- Cout='1'      -> drives REG_C onto BUS
    -- RFin='1'      -> writes BUS value into the register file
    -- RFaddr_wr='1' -> write address comes from IR[11:8]="0001" = R1
    Cout      <= '1';
    RFin      <= '1';
    RFaddr_wr <= '1';
    wait until rising_edge(clk);
    Cout      <= '0';
    RFin      <= '0';
    RFaddr_wr <= '0';
    wait for 5 ns;

    report "WRITEBACK: REG_C(=8) -> R1 - OK" severity NOTE;

    -- ----------------------------------------------------------
    -- Step 4: Final verification
    -- Store REG_C to DTCM[0] then read it back via the green-line port.
    -- DTCM_addr_reg is still 0 from reset (we never changed it),
    -- so writing with DTCM_wr='1' stores to address 0.
    -- ----------------------------------------------------------

    -- Cout='1'    -> BUS = REG_C = 8
    -- DTCM_wr='1' -> DTCM[DTCM_addr_reg=0] <- 8
    Cout    <= '1';
    DTCM_wr <= '1';
    wait until rising_edge(clk);
    Cout    <= '0';
    DTCM_wr <= '0';
    wait for 5 ns;

    -- Read DTCM[0] back via the green-line port (combinatorial read, no clock needed)
    TBactive         <= '1';
    DTCM_tb_addr_out <= "000000";
    wait for 5 ns;

    assert DTCM_tb_out = x"0008"
      report "FAIL: DTCM[0] = " &
             integer'image(conv_integer(unsigned(DTCM_tb_out))) &
             "  expected 8"
      severity ERROR;

    if DTCM_tb_out = x"0008" then
      report "SUCCESS: DTCM[0] = 8 - ADD instruction worked correctly!" severity NOTE;
    end if;

    -- ----------------------------------------------------------
    -- End of simulation
    -- ----------------------------------------------------------
    report "=== Simulation finished ===" severity NOTE;
    wait;  -- stop the simulation permanently

  end process STIM;

end architecture sim;
