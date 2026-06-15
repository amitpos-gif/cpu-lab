library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.aux_package.all;

entity tb_adder is
end tb_adder;

architecture rtb of tb_adder is
    constant m : integer := 8;

    signal cout     : std_logic;
    signal alufn_adder : std_logic_vector(2 downto 0);
    signal x, y, s  : std_logic_vector(m-1 downto 0);

    component AdderSub
        generic (n : integer := 8);
        port (x_adder, y_adder : in std_logic_vector(n-1 downto 0);
              alufn_adder : in std_logic_vector(2 downto 0);
              res_out_Adder : out std_logic_vector(n-1 downto 0);
              c_out_Adder : out std_logic);
    end component;

begin

    L0 : AdderSub
        generic map (n => m)
        port map(
            x_adder => x,
            y_adder => y,
            alufn_adder => alufn_adder,
            res_out_Adder => s,
            c_out_Adder => cout
        );

    tb : process
    begin
        -- Initialize signals
        alufn_adder <= "000";
        x <= "00000000";
        y <= "00000000";
        wait for 0 ns;  -- Let time 0 settle
        
        ----------------------------------------------------------------
        -- ADD
        ----------------------------------------------------------------

        -- 0 + 0
        wait for 50 ns;

        -- 0 + 1
        x <= "00000001"; y <= "00000000";
        wait for 50 ns;

        -- 1 + 1
        x <= "00000001"; y <= "00000001";
        wait for 50 ns;

        -- carry chain short
        x <= "00000001"; y <= "00001111";
        wait for 50 ns;

        -- carry chain longer
        x <= "00000001"; y <= "00111111";
        wait for 50 ns;

        -- carry chain almost full
        x <= "00000001"; y <= "01111111";
        wait for 50 ns;

        -- max + 1
        x <= "00000001"; y <= "11111111";
        wait for 50 ns;

        -- max + max
        x <= "11111111"; y <= "11111111";
        wait for 50 ns;

        ----------------------------------------------------------------
        -- SUB
        ----------------------------------------------------------------
        alufn_adder <= "001";

        -- 0 - 0
        x <= "00000000"; y <= "00000000";
        wait for 50 ns;

        -- 1 - 1
        x <= "00000001"; y <= "00000001";
        wait for 50 ns;

        -- 0 - 1
        x <= "00000001"; y <= "00000000";
        wait for 50 ns;

        -- max - 1
        x <= "00000001"; y <= "11111111";
        wait for 50 ns;

        -- 2 - max
        x <= "11111111"; y <= "00000010";
        wait for 50 ns;

        -- regular number
        x <= "00000101"; y <= "00001010";
        wait for 50 ns;

        ----------------------------------------------------------------
        -- alufn_adder = "010" (x + 0)
        ----------------------------------------------------------------
        alufn_adder <= "010";

        -- x + 0 test 1
        x <= "00000101"; y <= "11111111";
        wait for 50 ns;

        -- x + 0 test 2
        x <= "10101010"; y <= "01010101";
        wait for 50 ns;

        -- x + 0 test 3
        x <= "11111111"; y <= "00000000";
        wait for 50 ns;

        ----------------------------------------------------------------
        -- alufn_adder = "011" (2 + y)
        ----------------------------------------------------------------
        alufn_adder <= "011";

        -- 2 + 0
        x <= "00000000"; y <= "00000000";
        wait for 50 ns;

        -- 2 + 1
        x <= "00000000"; y <= "00000001";
        wait for 50 ns;

        -- 2 + 5
        x <= "00000000"; y <= "00000101";
        wait for 50 ns;

        -- 2 + max
        x <= "00000000"; y <= "11111111";
        wait for 50 ns;

        ----------------------------------------------------------------
        -- alufn_adder = "100" (2 - y)
        ----------------------------------------------------------------
        alufn_adder <= "100";

        -- 2 - 0
        x <= "00000000"; y <= "00000000";
        wait for 50 ns;

        -- 2 - 1
        x <= "00000000"; y <= "00000001";
        wait for 50 ns;

        -- 2 - 2
        x <= "00000000"; y <= "00000010";
        wait for 50 ns;

        -- 2 - 5
        x <= "00000000"; y <= "00000101";
        wait for 50 ns;

        -- 2 - max
        x <= "00000000"; y <= "11111111";
        wait for 50 ns;

        ----------------------------------------------------------------
        -- alufn_adder = "111" (invalid/others case)
        ----------------------------------------------------------------
        alufn_adder <= "111";

        -- invalid case test 1
        x <= "00000101"; y <= "00001010";
        wait for 50 ns;

        -- invalid case test 2
        x <= "11111111"; y <= "00000000";
        wait for 50 ns;

        wait;
    end process;

end architecture rtb;