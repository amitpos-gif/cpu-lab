library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE work.aux_package.all;
--------------------------------------------------------
entity Shifter is
    GENERIC (
        n : INTEGER := 16;
        k : integer := 4   -- k = log2(n)
    );
    port(
        inp_shifter   : in  std_logic_vector(n-1 downto 0); -- vector to shift
        x_control     : in  std_logic_vector(k-1 downto 0); -- shift amount
        alufn_shifter : in  std_logic_vector(3 downto 0);   -- ALUFN from ALU
        outp_shifter  : out std_logic_vector(n-1 downto 0);
        cout_shifter  : out std_logic
    );
end Shifter;
--------------------------------------------------------------------------------
architecture dtf_shifter of Shifter is
    subtype vector is std_logic_vector(n-1 downto 0);
    type matrix is array (k DOWNTO 0) of vector;

    signal stages         : matrix;
    signal c_temp_shifter : std_logic_vector(k downto 0);
begin

    -- Enable shifter only for ALUFN codes:
    -- "0101" = shift left
    
    stages(0) <= inp_shifter when (alufn_shifter = "0101") --changed here
                 else (others => '0');

    c_temp_shifter(0) <= '0';

    stage : for i in 0 to k-1 generate

        -- If x_control(i)='0', keep the previous stage.
        -- If x_control(i)='1', shift by 2**i places.
        stages(i+1) <= stages(i) when x_control(i) = '0' else
                       stages(i)(n-2**i-1 downto 0) & std_logic_vector(conv_unsigned(0, 2**i))
                            when alufn_shifter = "0101" else
                       std_logic_vector(conv_unsigned(0, 2**i)) & stages(i)(n-1 downto 2**i);

        -- Carry is the last bit that was shifted out in the active stage.
        c_temp_shifter(i+1) <= c_temp_shifter(i) when x_control(i) = '0' else
                               stages(i)(n-2**i) when alufn_shifter = "0101" else
                               stages(i)(2**i-1);

    end generate;

    outp_shifter  <= stages(k);
    cout_shifter  <= c_temp_shifter(k);

end dtf_shifter;
