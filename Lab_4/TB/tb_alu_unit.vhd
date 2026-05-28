LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE work.aux_package.all;

ENTITY tb_alu_unit_lab4 IS
END tb_alu_unit_lab4;

ARCHITECTURE rtb OF tb_alu_unit_lab4 IS

    CONSTANT n : INTEGER := 16;
    CONSTANT k : INTEGER := 4;

    SIGNAL Y_i      : STD_LOGIC_VECTOR(n-1 DOWNTO 0);
    SIGNAL X_i      : STD_LOGIC_VECTOR(n-1 DOWNTO 0);
    SIGNAL ALUFN_i  : STD_LOGIC_VECTOR(4 DOWNTO 0);
    SIGNAL ALUout_o : STD_LOGIC_VECTOR(n-1 DOWNTO 0);
    SIGNAL Nflag_o  : STD_LOGIC;
    SIGNAL Cflag_o  : STD_LOGIC;
    SIGNAL Zflag_o  : STD_LOGIC;
    SIGNAL Vflag_o  : STD_LOGIC;

    COMPONENT alu_unit
        GENERIC (
            n : INTEGER := 16;
            k : INTEGER := 4
        );
        PORT (
            Y_i      : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
            X_i      : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
            ALUFN_i  : IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
            ALUout_o : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0);
            Nflag_o  : OUT STD_LOGIC;
            Cflag_o  : OUT STD_LOGIC;
            Zflag_o  : OUT STD_LOGIC;
            Vflag_o  : OUT STD_LOGIC
        );
    END COMPONENT;

BEGIN

    DUT : alu_unit
        GENERIC MAP (
            n => n,
            k => k
        )
        PORT MAP (
            Y_i      => Y_i,
            X_i      => X_i,
            ALUFN_i  => ALUFN_i,
            ALUout_o => ALUout_o,
            Nflag_o  => Nflag_o,
            Cflag_o  => Cflag_o,
            Zflag_o  => Zflag_o,
            Vflag_o  => Vflag_o
        );

    stim_proc : PROCESS
    BEGIN

        --------------------------------------------------------------------
        -- Initial values
        --------------------------------------------------------------------
        Y_i     <= x"0000";
        X_i     <= x"0000";
        ALUFN_i <= "00000";
        WAIT FOR 50 ns;

        --------------------------------------------------------------------
        -- ARITHMETIC UNIT
        -- ALUFN(4 DOWNTO 3) = "01"
        --------------------------------------------------------------------

        --------------------------------------------------------------------
        -- ADD: ALUFN = 01000
        -- Operation: Y + X
        --------------------------------------------------------------------
        ALUFN_i <= "01000";

        -- 0 + 0 = 0
        Y_i <= x"0000";
        X_i <= x"0000";
        WAIT FOR 50 ns;

        -- 5 + 3 = 8
        Y_i <= x"0005";
        X_i <= x"0003";
        WAIT FOR 50 ns;

        -- 32767 + 1 = -32768, signed overflow
        Y_i <= x"7FFF";
        X_i <= x"0001";
        WAIT FOR 50 ns;

        -- 65535 + 1 = 0, carry out
        Y_i <= x"FFFF";
        X_i <= x"0001";
        WAIT FOR 50 ns;

        --------------------------------------------------------------------
        -- SUB: ALUFN = 01001
        -- Operation: Y - X
        --------------------------------------------------------------------
        ALUFN_i <= "01001";

        -- 5 - 3 = 2
        Y_i <= x"0005";
        X_i <= x"0003";
        WAIT FOR 50 ns;

        -- 3 - 5 = -2
        Y_i <= x"0003";
        X_i <= x"0005";
        WAIT FOR 50 ns;

        -- -32768 - 1 = 32767, signed overflow
        Y_i <= x"8000";
        X_i <= x"0001";
        WAIT FOR 50 ns;

        -- 0 - 0 = 0
        Y_i <= x"0000";
        X_i <= x"0000";
        WAIT FOR 50 ns;

        --------------------------------------------------------------------
        -- NEG: ALUFN = 01010
        -- Operation: -X = 0 - X
        --------------------------------------------------------------------
        ALUFN_i <= "01010";

        -- -5
        Y_i <= x"0000";
        X_i <= x"0005";
        WAIT FOR 50 ns;

        -- -0 = 0
        Y_i <= x"0000";
        X_i <= x"0000";
        WAIT FOR 50 ns;

        -- -(-32768), signed overflow
        Y_i <= x"0000";
        X_i <= x"8000";
        WAIT FOR 50 ns;

        --------------------------------------------------------------------
        -- Y + 2: ALUFN = 01011
        --------------------------------------------------------------------
        ALUFN_i <= "01011";

        -- 5 + 2 = 7
        Y_i <= x"0005";
        X_i <= x"AAAA"; -- X ignored
        WAIT FOR 50 ns;

        -- 65535 + 2 = 1, carry out
        Y_i <= x"FFFF";
        X_i <= x"5555"; -- X ignored
        WAIT FOR 50 ns;

        --------------------------------------------------------------------
        -- Y - 2: ALUFN = 01100
        --------------------------------------------------------------------
        ALUFN_i <= "01100";

        -- 5 - 2 = 3
        Y_i <= x"0005";
        X_i <= x"AAAA"; -- X ignored
        WAIT FOR 50 ns;

        -- 2 - 2 = 0
        Y_i <= x"0002";
        X_i <= x"5555"; -- X ignored
        WAIT FOR 50 ns;

        -- 0 - 2 = -2
        Y_i <= x"0000";
        X_i <= x"FFFF"; -- X ignored
        WAIT FOR 50 ns;

        --------------------------------------------------------------------
        -- SHIFTER UNIT
        -- ALUFN(4 DOWNTO 3) = "10"
        --------------------------------------------------------------------

        --------------------------------------------------------------------
        -- SHIFT LEFT: ALUFN = 10000
        -- Operation: Y << X(3 DOWNTO 0)
        --------------------------------------------------------------------
        ALUFN_i <= "10000";

        -- shift left by 0
        Y_i <= x"0001";
        X_i <= x"0000";
        WAIT FOR 50 ns;

        -- shift left by 1: 1 -> 2
        Y_i <= x"0001";
        X_i <= x"0001";
        WAIT FOR 50 ns;

        -- shift left by 4: 1 -> 16
        Y_i <= x"0001";
        X_i <= x"0004";
        WAIT FOR 50 ns;

        -- MSB shifted out
        Y_i <= x"8000";
        X_i <= x"0001";
        WAIT FOR 50 ns;

        -- pattern
        Y_i <= x"00AA";
        X_i <= x"0001";
        WAIT FOR 50 ns;

        --------------------------------------------------------------------
        -- SHIFT RIGHT: ALUFN = 10001
        -- Operation: Y >> X(3 DOWNTO 0)
        --------------------------------------------------------------------
        ALUFN_i <= "10001";

        -- shift right by 0
        Y_i <= x"8000";
        X_i <= x"0000";
        WAIT FOR 50 ns;

        -- shift right by 1
        Y_i <= x"8000";
        X_i <= x"0001";
        WAIT FOR 50 ns;

        -- shift right by 4
        Y_i <= x"8000";
        X_i <= x"0004";
        WAIT FOR 50 ns;

        -- LSB shifted out
        Y_i <= x"0001";
        X_i <= x"0001";
        WAIT FOR 50 ns;

        -- pattern
        Y_i <= x"00AA";
        X_i <= x"0001";
        WAIT FOR 50 ns;

        --------------------------------------------------------------------
        -- LOGIC UNIT
        -- ALUFN(4 DOWNTO 3) = "11"
        --------------------------------------------------------------------

        --------------------------------------------------------------------
        -- NOT Y: ALUFN = 11000
        --------------------------------------------------------------------
        ALUFN_i <= "11000";

        Y_i <= x"0000";
        X_i <= x"FFFF"; -- X ignored
        WAIT FOR 50 ns;

        Y_i <= x"FFFF";
        X_i <= x"0000"; -- X ignored
        WAIT FOR 50 ns;

        Y_i <= x"00AA";
        X_i <= x"0055"; -- X ignored
        WAIT FOR 50 ns;

        --------------------------------------------------------------------
        -- OR: ALUFN = 11001
        -- Operation: Y OR X
        --------------------------------------------------------------------
        ALUFN_i <= "11001";

        Y_i <= x"000F";
        X_i <= x"00F0";
        WAIT FOR 50 ns;

        Y_i <= x"00AA";
        X_i <= x"0055";
        WAIT FOR 50 ns;

        Y_i <= x"0000";
        X_i <= x"0000";
        WAIT FOR 50 ns;

        --------------------------------------------------------------------
        -- AND: ALUFN = 11010
        -- Operation: Y AND X
        --------------------------------------------------------------------
        ALUFN_i <= "11010";

        Y_i <= x"000F";
        X_i <= x"00F0";
        WAIT FOR 50 ns;

        Y_i <= x"00AA";
        X_i <= x"00AA";
        WAIT FOR 50 ns;

        Y_i <= x"FFFF";
        X_i <= x"000F";
        WAIT FOR 50 ns;

        --------------------------------------------------------------------
        -- XOR: ALUFN = 11011
        -- Operation: Y XOR X
        --------------------------------------------------------------------
        ALUFN_i <= "11011";

        Y_i <= x"000F";
        X_i <= x"00F0";
        WAIT FOR 50 ns;

        Y_i <= x"00AA";
        X_i <= x"0055";
        WAIT FOR 50 ns;

        Y_i <= x"FFFF";
        X_i <= x"FFFF";
        WAIT FOR 50 ns;

        --------------------------------------------------------------------
        -- NOR: ALUFN = 11100
        -- Operation: Y NOR X
        --------------------------------------------------------------------
        ALUFN_i <= "11100";

        Y_i <= x"0000";
        X_i <= x"0000";
        WAIT FOR 50 ns;

        Y_i <= x"FFFF";
        X_i <= x"0000";
        WAIT FOR 50 ns;

        --------------------------------------------------------------------
        -- NAND: ALUFN = 11101
        -- Operation: Y NAND X
        --------------------------------------------------------------------
        ALUFN_i <= "11101";

        Y_i <= x"FFFF";
        X_i <= x"FFFF";
        WAIT FOR 50 ns;

        Y_i <= x"000F";
        X_i <= x"00F0";
        WAIT FOR 50 ns;

        --------------------------------------------------------------------
        -- XNOR: ALUFN = 11110
        -- Operation: Y XNOR X
        --------------------------------------------------------------------
        ALUFN_i <= "11110";

        Y_i <= x"FFFF";
        X_i <= x"FFFF";
        WAIT FOR 50 ns;

        Y_i <= x"00AA";
        X_i <= x"0055";
        WAIT FOR 50 ns;

        --------------------------------------------------------------------
        -- INVALID / DEFAULT CASE
        --------------------------------------------------------------------
        ALUFN_i <= "00000";

        Y_i <= x"FFFF";
        X_i <= x"FFFF";
        WAIT FOR 50 ns;

        ALUFN_i <= "11111";

        Y_i <= x"00AA";
        X_i <= x"0055";
        WAIT FOR 50 ns;

        WAIT;

    END PROCESS;

END ARCHITECTURE rtb;