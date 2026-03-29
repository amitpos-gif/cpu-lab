library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.aux_package.all;

entity tb_logic is
end tb_logic;

architecture rtb of tb_logic is
    constant n : integer := 8;

    signal x : std_logic_vector(n-1 downto 0);
    signal y : std_logic_vector(n-1 downto 0);
    signal alufn_in_logic : std_logic_vector(2 downto 0);
    signal logic_out : std_logic_vector(n-1 downto 0);

    component logic
        generic (n : integer := 8);
        port (x, y : in std_logic_vector(n-1 downto 0);
              alufn_in_logic : in std_logic_vector(2 downto 0);
              logic_out : out std_logic_vector(n-1 downto 0));
    end component;

begin

    DUT : logic
        generic map (n => n)
        port map(
            x => x,
            y => y,
            alufn_in_logic => alufn_in_logic,
            logic_out => logic_out
        );

    tb : process
    begin
        -- Initialize
        x <= "00000000";
        y <= "00000000";
        alufn_in_logic <= "000";
        wait for 0 ns;

        ----------------------------------------------------------------
        -- alufn_in_logic = "000" : NOT(y)
        ----------------------------------------------------------------
        alufn_in_logic <= "000";

        -- NOT(0)
        y <= "00000000";
        wait for 50 ns;

        -- NOT(1111_1111)
        y <= "11111111";
        wait for 50 ns;

        -- NOT(1010_1010)
        y <= "10101010";
        wait for 50 ns;

        -- NOT(0101_0101)
        y <= "01010101";
        wait for 50 ns;

        -- NOT(1111_0000)
        y <= "11110000";
        wait for 50 ns;

        ----------------------------------------------------------------
        -- alufn_in_logic = "001" : y OR x
        ----------------------------------------------------------------
        alufn_in_logic <= "001";

        -- 0 OR 0
        x <= "00000000";
        y <= "00000000";
        wait for 50 ns;

        -- 1 OR 0
        x <= "00000001";
        y <= "00000000";
        wait for 50 ns;

        -- 1 OR 1
        x <= "00000001";
        y <= "00000001";
        wait for 50 ns;

        -- 1111_1111 OR 0000_0000
        x <= "11111111";
        y <= "00000000";
        wait for 50 ns;

        -- 1010_1010 OR 0101_0101
        x <= "10101010";
        y <= "01010101";
        wait for 50 ns;

        -- 1111_0000 OR 0000_1111
        x <= "11110000";
        y <= "00001111";
        wait for 50 ns;

        ----------------------------------------------------------------
        -- alufn_in_logic = "010" : y AND x
        ----------------------------------------------------------------
        alufn_in_logic <= "010";

        -- 0 AND 0
        x <= "00000000";
        y <= "00000000";
        wait for 50 ns;

        -- 1 AND 1
        x <= "00000001";
        y <= "00000001";
        wait for 50 ns;

        -- 1 AND 0
        x <= "00000001";
        y <= "00000000";
        wait for 50 ns;

        -- 1111_1111 AND 0000_0000
        x <= "11111111";
        y <= "00000000";
        wait for 50 ns;

        -- 1010_1010 AND 0101_0101
        x <= "10101010";
        y <= "01010101";
        wait for 50 ns;

        -- 1111_0000 AND 1100_1100
        x <= "11110000";
        y <= "11001100";
        wait for 50 ns;

        ----------------------------------------------------------------
        -- alufn_in_logic = "011" : y XOR x
        ----------------------------------------------------------------
        alufn_in_logic <= "011";

        -- 0 XOR 0
        x <= "00000000";
        y <= "00000000";
        wait for 50 ns;

        -- 1 XOR 0
        x <= "00000001";
        y <= "00000000";
        wait for 50 ns;

        -- 1 XOR 1
        x <= "00000001";
        y <= "00000001";
        wait for 50 ns;

        -- 1111_1111 XOR 0000_0000
        x <= "11111111";
        y <= "00000000";
        wait for 50 ns;

        -- 1010_1010 XOR 0101_0101
        x <= "10101010";
        y <= "01010101";
        wait for 50 ns;

        -- 1111_0000 XOR 0000_1111
        x <= "11110000";
        y <= "00001111";
        wait for 50 ns;

        ----------------------------------------------------------------
        -- alufn_in_logic = "100" : y NOR x
        ----------------------------------------------------------------
        alufn_in_logic <= "100";

        -- 0 NOR 0
        x <= "00000000";
        y <= "00000000";
        wait for 50 ns;

        -- 1 NOR 0
        x <= "00000001";
        y <= "00000000";
        wait for 50 ns;

        -- 1 NOR 1
        x <= "00000001";
        y <= "00000001";
        wait for 50 ns;

        -- 1111_1111 NOR 0000_0000
        x <= "11111111";
        y <= "00000000";
        wait for 50 ns;

        -- 0101_0101 NOR 1010_1010
        x <= "10101010";
        y <= "01010101";
        wait for 50 ns;

        ----------------------------------------------------------------
        -- alufn_in_logic = "101" : y NAND x
        ----------------------------------------------------------------
        alufn_in_logic <= "101";

        -- 0 NAND 0
        x <= "00000000";
        y <= "00000000";
        wait for 50 ns;

        -- 1 NAND 1
        x <= "00000001";
        y <= "00000001";
        wait for 50 ns;

        -- 1 NAND 0
        x <= "00000001";
        y <= "00000000";
        wait for 50 ns;

        -- 1111_1111 NAND 1111_1111
        x <= "11111111";
        y <= "11111111";
        wait for 50 ns;

        -- 1010_1010 NAND 1010_1010
        x <= "10101010";
        y <= "10101010";
        wait for 50 ns;

        ----------------------------------------------------------------
        -- alufn_in_logic = "110" : y XNOR x
        ----------------------------------------------------------------
        alufn_in_logic <= "110";

        -- 0 XNOR 0
        x <= "00000000";
        y <= "00000000";
        wait for 50 ns;

        -- 1 XNOR 0
        x <= "00000001";
        y <= "00000000";
        wait for 50 ns;

        -- 1 XNOR 1
        x <= "00000001";
        y <= "00000001";
        wait for 50 ns;

        -- 1111_1111 XNOR 1111_1111
        x <= "11111111";
        y <= "11111111";
        wait for 50 ns;

        -- 1010_1010 XNOR 0101_0101
        x <= "10101010";
        y <= "01010101";
        wait for 50 ns;

        -- 1111_0000 XNOR 1111_0000
        x <= "11110000";
        y <= "11110000";
        wait for 50 ns;

        ----------------------------------------------------------------
        -- alufn_in_logic = "111" (others) : Should output zeros
        ----------------------------------------------------------------
        alufn_in_logic <= "111";

        x <= "11111111";
        y <= "11111111";
        wait for 50 ns;

        x <= "10101010";
        y <= "01010101";
        wait for 50 ns;

        wait;
    end process;

end architecture rtb;
