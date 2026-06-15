library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity tb_alu_lab_3 is
end tb_alu_lab_3;

architecture sim of tb_alu_lab_3 is

    constant n : integer := 16;
    --input
    signal A      : std_logic_vector(n-1 downto 0);
    signal B      : std_logic_vector(n-1 downto 0);
    signal alufn  : std_logic_vector(3 downto 0);
    -- output
    signal C      : std_logic_vector(n-1 downto 0);
    signal C_flag : std_logic;
    signal Z_flag : std_logic;
    signal N_flag : std_logic;

begin

    --------------------------------------------------------------------
    -- Unit Under Test
    --------------------------------------------------------------------
    uut: entity work.alu
        generic map (
            n => n
        )
        port map (
            A      => A,
            B      => B,
            alufn  => alufn,
            C      => C,
            C_flag => C_flag,
            Z_flag => Z_flag,
            N_flag => N_flag
        );

    --------------------------------------------------------------------
    -- Stimulus process
    --------------------------------------------------------------------
    stim_proc: process
    begin

        ----------------------------------------------------------------
        -- ADD: 3 + 5 = 8
        ----------------------------------------------------------------
        A     <= x"0003";
        B     <= x"0005";
        alufn <= "0000";
        wait for 10 ns;

        assert C = x"0008"
        report "ERROR ADD: 3 + 5 should be 0008"
        severity error;

        assert C_flag = '0'
        report "ERROR ADD: C_flag should be 0"
        severity error;

        assert Z_flag = '0'
        report "ERROR ADD: Z_flag should be 0"
        severity error;

        assert N_flag = '0'
        report "ERROR ADD: N_flag should be 0"
        severity error;


        ----------------------------------------------------------------
        -- ADD with carry: FFFF + 1 = 0000, carry = 1
        ----------------------------------------------------------------
        A     <= x"FFFF";
        B     <= x"0001";
        alufn <= "0000";
        wait for 10 ns;

        assert C = x"0000"
        report "ERROR ADD CARRY: FFFF + 1 should be 0000"
        severity error;

        assert C_flag = '1'
        report "ERROR ADD CARRY: C_flag should be 1"
        severity error;

        assert Z_flag = '1'
        report "ERROR ADD CARRY: Z_flag should be 1"
        severity error;

        assert N_flag = '0'
        report "ERROR ADD CARRY: N_flag should be 0"
        severity error;


        ----------------------------------------------------------------
        -- SUB according to your current AdderSub:
        -- current implementation does B - A
        -- A = 3, B = 5 => B - A = 2
        ----------------------------------------------------------------
        A     <= x"0003";
        B     <= x"0005";
        alufn <= "0001";
        wait for 10 ns;

        assert C = x"0002"
        report "ERROR SUB CURRENT: B - A = 5 - 3 should be 0002"
        severity error;

        assert Z_flag = '0'
        report "ERROR SUB CURRENT: Z_flag should be 0"
        severity error;

        assert N_flag = '0'
        report "ERROR SUB CURRENT: N_flag should be 0"
        severity error;


        ----------------------------------------------------------------
        -- SUB negative according to your current AdderSub:
        -- A = 5, B = 3 => B - A = -2 = FFFE
        ----------------------------------------------------------------
        A     <= x"0005";
        B     <= x"0003";
        alufn <= "0001";
        wait for 10 ns;

        assert C = x"FFFE"
        report "ERROR SUB CURRENT NEGATIVE: B - A = 3 - 5 should be FFFE"
        severity error;

        assert N_flag = '1'
        report "ERROR SUB CURRENT NEGATIVE: N_flag should be 1"
        severity error;


        ----------------------------------------------------------------
        -- SUB zero:
        -- A = 7, B = 7 => B - A = 0
        ----------------------------------------------------------------
        A     <= x"0007";
        B     <= x"0007";
        alufn <= "0001";
        wait for 10 ns;

        assert C = x"0000"
        report "ERROR SUB ZERO: 7 - 7 should be 0000"
        severity error;

        assert Z_flag = '1'
        report "ERROR SUB ZERO: Z_flag should be 1"
        severity error;

        assert N_flag = '0'
        report "ERROR SUB ZERO: N_flag should be 0"
        severity error;


        ----------------------------------------------------------------
        -- AND: 00F0 and 0F0F = 0000
        ----------------------------------------------------------------
        A     <= x"00F0";
        B     <= x"0F0F";
        alufn <= "0010";
        wait for 10 ns;

        assert C = x"0000"
        report "ERROR AND: 00F0 AND 0F0F should be 0000"
        severity error;

        assert C_flag = '0'
        report "ERROR AND: C_flag should be 0"
        severity error;

        assert Z_flag = '1'
        report "ERROR AND: Z_flag should be 1"
        severity error;

        assert N_flag = '0'
        report "ERROR AND: N_flag should be 0"
        severity error;


        ----------------------------------------------------------------
        -- OR: 00F0 or 0F0F = 0FFF
        ----------------------------------------------------------------
        A     <= x"00F0";
        B     <= x"0F0F";
        alufn <= "0011";
        wait for 10 ns;

        assert C = x"0FFF"
        report "ERROR OR: 00F0 OR 0F0F should be 0FFF"
        severity error;

        assert C_flag = '0'
        report "ERROR OR: C_flag should be 0"
        severity error;

        assert Z_flag = '0'
        report "ERROR OR: Z_flag should be 0"
        severity error;

        assert N_flag = '0'
        report "ERROR OR: N_flag should be 0"
        severity error;


        ----------------------------------------------------------------
        -- XOR: 00FF xor 0F0F = 0FF0
        ----------------------------------------------------------------
        A     <= x"00FF";
        B     <= x"0F0F";
        alufn <= "0100";
        wait for 10 ns;

        assert C = x"0FF0"
        report "ERROR XOR: 00FF XOR 0F0F should be 0FF0"
        severity error;

        assert C_flag = '0'
        report "ERROR XOR: C_flag should be 0"
        severity error;

        assert Z_flag = '0'
        report "ERROR XOR: Z_flag should be 0"
        severity error;

        assert N_flag = '0'
        report "ERROR XOR: N_flag should be 0"
        severity error;


        ----------------------------------------------------------------
        -- XOR zero: AAAA xor AAAA = 0000
        ----------------------------------------------------------------
        A     <= x"AAAA";
        B     <= x"AAAA";
        alufn <= "0100";
        wait for 10 ns;

        assert C = x"0000"
        report "ERROR XOR ZERO: AAAA XOR AAAA should be 0000"
        severity error;

        assert Z_flag = '1'
        report "ERROR XOR ZERO: Z_flag should be 1"
        severity error;


        ----------------------------------------------------------------
        -- N flag test with logic:
        -- 8000 OR 0001 = 8001, MSB = 1
        ----------------------------------------------------------------
        A     <= x"8000";
        B     <= x"0001";
        alufn <= "0011";
        wait for 10 ns;

        assert C = x"8001"
        report "ERROR OR N_FLAG: 8000 OR 0001 should be 8001"
        severity error;

        assert N_flag = '1'
        report "ERROR OR N_FLAG: N_flag should be 1"
        severity error;


        ----------------------------------------------------------------
        -- Unsupported ALUFN: output should be zero
        ----------------------------------------------------------------
        A     <= x"1234";
        B     <= x"5678";
        alufn <= "1111";
        wait for 10 ns;

        assert C = x"0000"
        report "ERROR unsupported ALUFN: C should be 0000"
        severity error;

        assert C_flag = '0'
        report "ERROR unsupported ALUFN: C_flag should be 0"
        severity error;

        assert Z_flag = '1'
        report "ERROR unsupported ALUFN: Z_flag should be 1"
        severity error;

        assert N_flag = '0'
        report "ERROR unsupported ALUFN: N_flag should be 0"
        severity error;


        ----------------------------------------------------------------
        -- End simulation
        ----------------------------------------------------------------
        report "ALU testbench finished successfully"
        severity note;

        wait;

    end process;

end sim;