library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.aux_package.all;

entity tb_shifter is
end tb_shifter;

architecture rtb of tb_shifter is
    constant n : integer := 8;
    constant k : integer := 3;

    signal inp_shifter : std_logic_vector(n-1 downto 0);
    signal x_control : std_logic_vector(k-1 downto 0);
    signal alufn_shifter : std_logic_vector(2 downto 0);
    signal outp_shifter : std_logic_vector(n-1 downto 0);
    signal cout_shifter : std_logic;

begin

    DUT : Shifter
        generic map (n => n, k => k)
        port map(
            inp_shifter => inp_shifter,
            x_control => x_control,
            alufn_shifter => alufn_shifter,
            outp_shifter => outp_shifter,
            cout_shifter => cout_shifter
        );

    tb : process
    begin
        -- Initialize signals
        inp_shifter <= "00000000";
        x_control <= "000";
        alufn_shifter <= "000";
        wait for 0 ns;

        ----------------------------------------------------------------
        -- LEFT SHIFT - alufn_shifter(0) = '0', alufn_shifter(2:1) = "00"
        ----------------------------------------------------------------
        alufn_shifter <= "000";  -- Left shift, shift input

        -- Left shift 0 positions
        x_control <= "000";
        inp_shifter <= "00000001";
        wait for 50 ns;

        -- Left shift 1 position
        x_control <= "001";
        inp_shifter <= "00000001";
        wait for 50 ns;

        -- Left shift 2 positions
        x_control <= "010";
        inp_shifter <= "00000001";
        wait for 50 ns;

        -- Left shift 3 positions
        x_control <= "011";
        inp_shifter <= "00000001";
        wait for 50 ns;

        -- Left shift 4 positions (should show carry out)
        x_control <= "100";
        inp_shifter <= "10000000";
        wait for 50 ns;

        -- Left shift 7 positions (max shift)
        x_control <= "111";
        inp_shifter <= "10000000";
        wait for 50 ns;

        -- Left shift with pattern
        x_control <= "010";
        inp_shifter <= "10101010";
        wait for 50 ns;

        ----------------------------------------------------------------
        -- RIGHT SHIFT - alufn_shifter(0) = '1', alufn_shifter(2:1) = "00"
        ----------------------------------------------------------------
        alufn_shifter <= "001";  -- Right shift, shift input

        -- Right shift 0 positions
        x_control <= "000";
        inp_shifter <= "10000000";
        wait for 50 ns;

        -- Right shift 1 position
        x_control <= "001";
        inp_shifter <= "10000000";
        wait for 50 ns;

        -- Right shift 2 positions
        x_control <= "010";
        inp_shifter <= "10000000";
        wait for 50 ns;

        -- Right shift 3 positions
        x_control <= "011";
        inp_shifter <= "10000000";
        wait for 50 ns;

        -- Right shift 4 positions
        x_control <= "100";
        inp_shifter <= "00000001";
        wait for 50 ns;

        -- Right shift 7 positions (max shift)
        x_control <= "111";
        inp_shifter <= "10000000";
        wait for 50 ns;

        -- Right shift with pattern
        x_control <= "010";
        inp_shifter <= "10101010";
        wait for 50 ns;

        ----------------------------------------------------------------
        -- LEFT SHIFT ON ZEROS - alufn_shifter(0) = '0', alufn_shifter(2:1) != "00"
        ----------------------------------------------------------------
        alufn_shifter <= "010";  -- Left shift, shift zeros

        x_control <= "001";
        inp_shifter <= "11111111";
        wait for 50 ns;

        x_control <= "011";
        inp_shifter <= "10101010";
        wait for 50 ns;

        x_control <= "111";
        inp_shifter <= "11111111";
        wait for 50 ns;

        ----------------------------------------------------------------
        -- RIGHT SHIFT ON ZEROS - alufn_shifter(0) = '1', alufn_shifter(2:1) != "00"
        ----------------------------------------------------------------
        alufn_shifter <= "011";  -- Right shift, shift zeros

        x_control <= "001";
        inp_shifter <= "11111111";
        wait for 50 ns;

        x_control <= "010";
        inp_shifter <= "00000001";
        wait for 50 ns;

        x_control <= "100";
        inp_shifter <= "10101010";
        wait for 50 ns;

        ----------------------------------------------------------------
        -- INVALID ALUFN - alufn_shifter = "100", "101", "110"
        ----------------------------------------------------------------
        alufn_shifter <= "100";

        x_control <= "010";
        inp_shifter <= "11001100";
        wait for 50 ns;

        alufn_shifter <= "110";

        x_control <= "011";
        inp_shifter <= "01010101";
        wait for 50 ns;

        wait;
    end process;

end architecture rtb;
