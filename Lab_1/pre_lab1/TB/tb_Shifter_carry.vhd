library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.aux_package.all;

entity tb_shifter_carry is
end tb_shifter_carry;

architecture rtb of tb_shifter_carry is
    constant n : integer := 8;
    constant k : integer := 3;

    signal inp_shifter : std_logic_vector(n-1 downto 0);
    signal x_control : std_logic_vector(k-1 downto 0);
    signal alufn_shifter : std_logic_vector(2 downto 0);
    signal outp_shifter : std_logic_vector(n-1 downto 0);
    signal cout_shifter : std_logic;

    component Shifter
        generic (n : integer := 8;
                 k : integer := 3);
        port (inp_shifter : in std_logic_vector(n-1 downto 0);
              x_control : in std_logic_vector(k-1 downto 0);
              alufn_shifter : in std_logic_vector(2 downto 0);
              outp_shifter : out std_logic_vector(n-1 downto 0);
              cout_shifter : out std_logic);
    end component;

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
        -- Initialize
        inp_shifter <= "00000000";
        x_control <= "000";
        alufn_shifter <= "000";
        wait for 0 ns;

        ----------------------------------------------------------------
        -- LEFT SHIFT - CARRY OUT TESTS
        -- For left shift, cout should be the bit that's shifted out (MSB)
        ----------------------------------------------------------------
        alufn_shifter <= "000";

        -- Test 1: Left shift by 1, input MSB=0, should have cout=0
        inp_shifter <= "01111111";  -- MSB=0
        x_control <= "001";
        wait for 50 ns;

        -- Test 2: Left shift by 1, input MSB=1, should have cout=1
        inp_shifter <= "10000000";  -- MSB=1
        x_control <= "001";
        wait for 50 ns;

        -- Test 3: Left shift by 2, check carry chain
        inp_shifter <= "11000000";  -- First two MSBs are 1
        x_control <= "001";
        wait for 50 ns;

        inp_shifter <= "11000000";
        x_control <= "010";
        wait for 50 ns;

        -- Test 4: Left shift by 1 with alternating pattern
        inp_shifter <= "10101010";  -- MSB=1
        x_control <= "001";
        wait for 50 ns;

        -- Test 5: Left shift by 7, should carry out MSB
        inp_shifter <= "10000000";
        x_control <= "111";
        wait for 50 ns;

        -- Test 6: Left shift by 1, different pattern
        inp_shifter <= "11111111";  -- All 1s
        x_control <= "001";
        wait for 50 ns;

        -- Test 7: Left shift by 3 with mixed bits
        inp_shifter <= "11110000";
        x_control <= "001";
        wait for 50 ns;

        inp_shifter <= "11110000";
        x_control <= "011";
        wait for 50 ns;

        ----------------------------------------------------------------
        -- RIGHT SHIFT - CARRY OUT TESTS
        -- For right shift, cout should be the bit that's shifted out (LSB)
        ----------------------------------------------------------------
        alufn_shifter <= "001";

        -- Test 1: Right shift by 1, input LSB=0, should have cout=0
        inp_shifter <= "11111110";  -- LSB=0
        x_control <= "001";
        wait for 50 ns;

        -- Test 2: Right shift by 1, input LSB=1, should have cout=1
        inp_shifter <= "11111111";  -- LSB=1
        x_control <= "001";
        wait for 50 ns;

        -- Test 3: Right shift by 2
        inp_shifter <= "11111101";  -- Bit[1]=0, Bit[0]=1
        x_control <= "001";
        wait for 50 ns;

        inp_shifter <= "11111101";
        x_control <= "010";
        wait for 50 ns;

        -- Test 4: Right shift by 1 with alternating pattern
        inp_shifter <= "10101010";  -- LSB=0
        x_control <= "001";
        wait for 50 ns;

        -- Test 5: Right shift by 7
        inp_shifter <= "00000001";  -- LSB=1
        x_control <= "111";
        wait for 50 ns;

        -- Test 6: Right shift by 1, all zeros except LSB
        inp_shifter <= "00000001";  -- LSB=1
        x_control <= "001";
        wait for 50 ns;

        -- Test 7: Right shift by 2 with mixed bits
        inp_shifter <= "11110000";
        x_control <= "001";
        wait for 50 ns;

        inp_shifter <= "11110000";
        x_control <= "010";
        wait for 50 ns;

        -- Test 8: Right shift checking LSB before each shift
        inp_shifter <= "10101011";  -- LSB=1
        x_control <= "001";
        wait for 50 ns;

        ----------------------------------------------------------------
        -- LEFT SHIFT ON ZEROS
        -- Shifting zeros should always produce cout=0
        ----------------------------------------------------------------
        alufn_shifter <= "010";

        inp_shifter <= "00000000";
        x_control <= "001";
        wait for 50 ns;

        inp_shifter <= "00000000";
        x_control <= "111";
        wait for 50 ns;

        ----------------------------------------------------------------
        -- RIGHT SHIFT ON ZEROS
        -- Shifting zeros should always produce cout=0
        ----------------------------------------------------------------
        alufn_shifter <= "011";

        inp_shifter <= "00000000";
        x_control <= "001";
        wait for 50 ns;

        inp_shifter <= "00000000";
        x_control <= "111";
        wait for 50 ns;

        ----------------------------------------------------------------
        -- NO SHIFT - COUT SHOULD PROPAGATE
        ----------------------------------------------------------------
        alufn_shifter <= "000";

        -- No shift (x_control = "000"), cout chain starts with 0
        inp_shifter <= "11111111";
        x_control <= "000";
        wait for 50 ns;

        alufn_shifter <= "001";

        inp_shifter <= "11111111";
        x_control <= "000";
        wait for 50 ns;

        wait;
    end process;

end architecture rtb;
