library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.aux_package.all;

----------------------------------------------------
entity tb_control_ena_freeze is
end entity tb_control_ena_freeze;
----------------------------------------------------

architecture sim of tb_control_ena_freeze is

    signal clk  : std_logic := '0';
    signal rst  : std_logic := '0';
    signal ena  : std_logic := '0';
    signal done : std_logic;

    -- Control output signals
    signal DTCM_wr      : std_logic;
    signal Cin          : std_logic;
    signal Cout         : std_logic;
    signal DTCM_addr_in : std_logic;
    signal DTCM_out     : std_logic;
    signal ALUFN        : std_logic_vector(3 downto 0);
    signal Ain          : std_logic;
    signal RFin         : std_logic;
    signal RFout        : std_logic;
    signal RFaddr_rd    : std_logic_vector(1 downto 0);
    signal RFaddr_wr    : std_logic;
    signal IRin         : std_logic;
    signal PCin         : std_logic;
    signal PCsel        : std_logic_vector(1 downto 0);
    signal Imm1_in      : std_logic;
    signal Imm2_in      : std_logic;

    -- Inputs from datapath
    signal mov_s  : std_logic := '0';
    signal done_s : std_logic := '0';
    signal and_s  : std_logic := '0';
    signal or_s   : std_logic := '0';
    signal xor_s  : std_logic := '0';
    signal jnc_s  : std_logic := '0';
    signal jc_s   : std_logic := '0';
    signal jmp_s  : std_logic := '0';
    signal sub_s  : std_logic := '0';
    signal add_s  : std_logic := '0';
    signal ld_s   : std_logic := '0';
    signal st_s   : std_logic := '0';

    signal Cflag  : std_logic := '0';
    signal Zflag  : std_logic := '0';
    signal Nflag  : std_logic := '0';

begin

    DUT : Control
        port map (
            clk          => clk,
            rst          => rst,
            ena          => ena,

            mov_s        => mov_s,
            done_s       => done_s,
            and_s        => and_s,
            or_s         => or_s,
            xor_s        => xor_s,
            jnc_s        => jnc_s,
            jc_s         => jc_s,
            jmp_s        => jmp_s,
            sub_s        => sub_s,
            add_s        => add_s,
            ld_s         => ld_s,
            st_s         => st_s,

            Cflag        => Cflag,
            Zflag        => Zflag,
            Nflag        => Nflag,

            DTCM_wr      => DTCM_wr,
            Cin          => Cin,
            Cout         => Cout,
            DTCM_addr_in => DTCM_addr_in,
            DTCM_out     => DTCM_out,
            ALUFN        => ALUFN,
            Ain          => Ain,
            RFin         => RFin,
            RFout        => RFout,
            RFaddr_rd    => RFaddr_rd,
            RFaddr_wr    => RFaddr_wr,
            IRin         => IRin,
            PCin         => PCin,
            PCsel        => PCsel,
            Imm1_in      => Imm1_in,
            Imm2_in      => Imm2_in,
            done         => done
        );

    -- 20 ns clock period
    clk <= not clk after 10 ns;


    STIM : process

        procedure clear_all_instr is
        begin
            mov_s  <= '0';
            done_s <= '0';
            and_s  <= '0';
            or_s   <= '0';
            xor_s  <= '0';
            jnc_s  <= '0';
            jc_s   <= '0';
            jmp_s  <= '0';
            sub_s  <= '0';
            add_s  <= '0';
            ld_s   <= '0';
            st_s   <= '0';
        end procedure;

    begin

        ----------------------------------------------------------------
        -- Reset
        ----------------------------------------------------------------
        rst <= '1';
        ena <= '0';

        clear_all_instr;

        wait until rising_edge(clk);
        wait until rising_edge(clk);

        rst <= '0';
        ena <= '1';

        wait for 1 ns;


        ----------------------------------------------------------------
        -- Step 1: Check FETCH
        -- After reset, FSM should be in S_FETCH
        ----------------------------------------------------------------
        assert IRin = '1'
            report "FETCH failed: IRin should be 1"
            severity error;

        assert PCsel = "10"
            report "FETCH failed: PCsel should be 10"
            severity error;

        assert PCin = '0'
            report "FETCH failed: PCin should be 0"
            severity error;


        ----------------------------------------------------------------
        -- Step 2: Start ADD instruction and move to DECODE1
        ----------------------------------------------------------------
        add_s <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        -- In DECODE1 for R-type
        assert RFaddr_rd = "01"
            report "DECODE1 failed before freeze: RFaddr_rd should be 01"
            severity error;

        assert RFout = '1'
            report "DECODE1 failed before freeze: RFout should be 1"
            severity error;

        assert Ain = '1'
            report "DECODE1 failed before freeze: Ain should be 1"
            severity error;


        ----------------------------------------------------------------
        -- Step 3: Freeze FSM using ena = 0
        ----------------------------------------------------------------
        ena <= '0';

        -- First frozen clock cycle
        wait until rising_edge(clk);
        wait for 1 ns;

        assert RFaddr_rd = "01"
            report "ENA freeze failed cycle 1: RFaddr_rd changed"
            severity error;

        assert RFout = '1'
            report "ENA freeze failed cycle 1: RFout changed"
            severity error;

        assert Ain = '1'
            report "ENA freeze failed cycle 1: Ain changed"
            severity error;

        assert Cin = '0'
            report "ENA freeze failed cycle 1: FSM moved to EX, Cin should still be 0"
            severity error;


        -- Second frozen clock cycle
        wait until rising_edge(clk);
        wait for 1 ns;

        assert RFaddr_rd = "01"
            report "ENA freeze failed cycle 2: RFaddr_rd changed"
            severity error;

        assert RFout = '1'
            report "ENA freeze failed cycle 2: RFout changed"
            severity error;

        assert Ain = '1'
            report "ENA freeze failed cycle 2: Ain changed"
            severity error;

        assert Cin = '0'
            report "ENA freeze failed cycle 2: FSM moved to EX, Cin should still be 0"
            severity error;


        ----------------------------------------------------------------
        -- Step 4: Release freeze using ena = 1
        ----------------------------------------------------------------
        ena <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        -- Now FSM should continue from DECODE1 to EX
        assert ALUFN = "0000"
            report "Release from freeze failed: ALUFN should be ADD"
            severity error;

        assert RFaddr_rd = "10"
            report "Release from freeze failed: RFaddr_rd should be 10 in EX"
            severity error;

        assert RFout = '1'
            report "Release from freeze failed: RFout should be 1 in EX"
            severity error;

        assert Cin = '1'
            report "Release from freeze failed: Cin should be 1 in EX"
            severity error;


        ----------------------------------------------------------------
        -- Step 5: Continue to WRITEBACK
        ----------------------------------------------------------------
        wait until rising_edge(clk);
        wait for 1 ns;

        assert Cout = '1'
            report "WB failed after freeze: Cout should be 1"
            severity error;

        assert RFin = '1'
            report "WB failed after freeze: RFin should be 1"
            severity error;

        assert RFaddr_wr = '1'
            report "WB failed after freeze: RFaddr_wr should be 1"
            severity error;

        assert PCin = '1'
            report "WB failed after freeze: PCin should be 1"
            severity error;


        ----------------------------------------------------------------
        -- Finish
        ----------------------------------------------------------------
        add_s <= '0';

        report "ENA freeze test finished successfully" severity note;

        wait;

    end process STIM;

end architecture sim;