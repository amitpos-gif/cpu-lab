LIBRARY ieee;
USE ieee.std_logic_1164.all;
--------------------------------------
ENTITY shifter IS
    GENERIC ( n : INTEGER := 16;
              k : INTEGER := 4);   -- k = log2(n)
    PORT (
        y     : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);  -- data to shift
        x     : IN  STD_LOGIC_VECTOR(k-1 DOWNTO 0);  -- shift amount (from X(k-1..0))
        alufn : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);    -- alufn(0) = dir: '0'=SHL, '1'=SHR
        res   : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0);  -- shifted result
        cout  : OUT STD_LOGIC                         -- carry out
    );
END shifter;
----------------------------------------------
ARCHITECTURE dfl OF shifter IS

    -- internal types for the barrel-shifter matrix
    SUBTYPE vector IS STD_LOGIC_VECTOR(n-1 DOWNTO 0);
    TYPE    matrix IS ARRAY (k DOWNTO 0) OF vector;

    SIGNAL stages  : matrix;                          -- k+1 rows: stage 0..k
    SIGNAL carries : STD_LOGIC_VECTOR(k DOWNTO 0);   -- carry chain
    SIGNAL dir     : STD_LOGIC;                       -- direction bit

BEGIN

    -------------------------------------------------------
    --  Extract the direction bit from alufn(0) --
    -------------------------------------------------------
    dir <= alufn(0);
    stages(0)  <= y;
    carries(0) <= '0';

    -------------------------------------------------------
    
    shifter_gen : FOR i IN 0 TO k-1 GENERATE

        -- Data path: pass-through / shift-left / shift-right
        stages(i+1) <= stages(i)
                           WHEN x(i) = '0'
                       ELSE stages(i)(n-1-2**i DOWNTO 0) & (2**i-1 DOWNTO 0 => '0')
                           WHEN dir = '0'
                       ELSE (2**i-1 DOWNTO 0 => '0') & stages(i)(n-1 DOWNTO 2**i);

        -- Carry: capture the bit at the shifting boundary
        
        carries(i+1) <= carries(i)
                            WHEN x(i) = '0'
                        ELSE stages(i)(n-2**i)
                            WHEN dir = '0'
                        ELSE stages(i)(2**i-1);

    END GENERATE;

    -------------------------------------------------------
    
    res  <= stages(k)  WHEN (alufn = "000" OR alufn = "001")
            ELSE (OTHERS => '0');

    cout <= carries(k) WHEN (alufn = "000" OR alufn = "001")
            ELSE '0';

END ARCHITECTURE dfl;