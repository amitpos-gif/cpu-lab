LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

ENTITY tb_digital_user_interface IS
END tb_digital_user_interface;

ARCHITECTURE sim OF tb_digital_user_interface IS

    CONSTANT n : INTEGER := 16;
    CONSTANT k : INTEGER := 4;

    SIGNAL CLOCK_50 : STD_LOGIC := '0';
    SIGNAL SW       : STD_LOGIC_VECTOR(9 DOWNTO 0) := (others => '0');
    SIGNAL KEY      : STD_LOGIC_VECTOR(3 DOWNTO 0) := (others => '1');

    SIGNAL LEDR     : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL HEX0     : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL HEX1     : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL HEX2     : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL HEX3     : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL HEX4     : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL HEX5     : STD_LOGIC_VECTOR(6 DOWNTO 0);

    SIGNAL pwm_out  : STD_LOGIC;

    --------------------------------------------------------------------
    -- 7-segment decoder used only for testbench assertions.
    -- DE10-Standard HEX displays are active-low:
    -- '0' turns a segment on, '1' turns it off.
    --------------------------------------------------------------------
    FUNCTION to_7seg(hex : STD_LOGIC_VECTOR(3 DOWNTO 0)) RETURN STD_LOGIC_VECTOR IS
    BEGIN
        CASE hex IS
            WHEN "0000" => RETURN "1000000"; -- 0
            WHEN "0001" => RETURN "1111001"; -- 1
            WHEN "0010" => RETURN "0100100"; -- 2
            WHEN "0011" => RETURN "0110000"; -- 3
            WHEN "0100" => RETURN "0011001"; -- 4
            WHEN "0101" => RETURN "0010010"; -- 5
            WHEN "0110" => RETURN "0000010"; -- 6
            WHEN "0111" => RETURN "1111000"; -- 7
            WHEN "1000" => RETURN "0000000"; -- 8
            WHEN "1001" => RETURN "0010000"; -- 9
            WHEN "1010" => RETURN "0001000"; -- A
            WHEN "1011" => RETURN "0000011"; -- b
            WHEN "1100" => RETURN "1000110"; -- C
            WHEN "1101" => RETURN "0100001"; -- d
            WHEN "1110" => RETURN "0000110"; -- E
            WHEN "1111" => RETURN "0001110"; -- F
            WHEN OTHERS => RETURN "1111111"; -- off
        END CASE;
    END FUNCTION;


BEGIN

    --------------------------------------------------------------------
    -- DUT
    --------------------------------------------------------------------
    DUT : ENTITY work.digital_user_interface
        GENERIC MAP (
            n => n,
            k => k
        )
        PORT MAP (
            CLOCK_50 => CLOCK_50,
            SW       => SW,
            KEY      => KEY,

            LEDR     => LEDR,
            HEX0     => HEX0,
            HEX1     => HEX1,
            HEX2     => HEX2,
            HEX3     => HEX3,
            HEX4     => HEX4,
            HEX5     => HEX5,

            pwm_out  => pwm_out
        );

    --------------------------------------------------------------------
    -- 50 MHz clock: period = 20 ns
    --------------------------------------------------------------------
    clk_proc : PROCESS
    BEGIN
        WHILE true LOOP
            CLOCK_50 <= '0';
            WAIT FOR 10 ns;
            CLOCK_50 <= '1';
            WAIT FOR 10 ns;
        END LOOP;
    END PROCESS;

    --------------------------------------------------------------------
    -- Stimulus
    -- DE10 KEY is active-low:
    -- not pressed = '1'
    -- pressed     = '0'
    --------------------------------------------------------------------
    stim_proc : PROCESS
    BEGIN

        ----------------------------------------------------------------
        -- Initial state
        -- Current DUT HEX mapping:
        --   HEX1-HEX0 display X
        --   HEX3-HEX2 display Y
        --   HEX5-HEX4 display ALU result
        ----------------------------------------------------------------
        SW  <= (others => '0');
        KEY <= (others => '1');
        WAIT FOR 25000 ns;

        ----------------------------------------------------------------
        -- Load Y low = 0x34
        -- KEY0 pressed, SW9 = 0
        ----------------------------------------------------------------
        SW(9) <= '0';
        SW(8) <= '1';
        SW(7 DOWNTO 0) <= x"34";

        KEY(0) <= '0';
        WAIT FOR 25000 ns;
        KEY(0) <= '1';
        WAIT FOR 25000 ns;

        ASSERT HEX2 = to_7seg(x"4")
            REPORT "ERROR: HEX2 should display Y low nibble = 4"
            SEVERITY error;

        ASSERT HEX3 = to_7seg(x"3")
            REPORT "ERROR: HEX3 should display Y high nibble = 3"
            SEVERITY error;

        ----------------------------------------------------------------
        -- Load Y high = 0x12
        -- KEY0 pressed, SW9 = 1
        ----------------------------------------------------------------
        SW(9) <= '1';
        SW(7 DOWNTO 0) <= x"12";

        KEY(0) <= '0';
        WAIT FOR 25000 ns;
        KEY(0) <= '1';
        WAIT FOR 25000 ns;

        ASSERT HEX2 = to_7seg(x"2")
            REPORT "ERROR: HEX2 should display Y high low nibble = 2"
            SEVERITY error;

        ASSERT HEX3 = to_7seg(x"1")
            REPORT "ERROR: HEX3 should display Y high high nibble = 1"
            SEVERITY error;

        ----------------------------------------------------------------
        -- Load X low = 0x78
        -- KEY1 pressed, SW9 = 0
        ----------------------------------------------------------------
        SW(9) <= '0';
        SW(7 DOWNTO 0) <= x"78";

        KEY(1) <= '0';
        WAIT FOR 25000 ns;
        KEY(1) <= '1';
        WAIT FOR 25000 ns;

        ASSERT HEX0 = to_7seg(x"8")
            REPORT "ERROR: HEX0 should display X low nibble = 8"
            SEVERITY error;

        ASSERT HEX1 = to_7seg(x"7")
            REPORT "ERROR: HEX1 should display X high nibble = 7"
            SEVERITY error;

        ----------------------------------------------------------------
        -- Load X high = 0x56
        -- KEY1 pressed, SW9 = 1
        ----------------------------------------------------------------
        SW(9) <= '1';
        SW(7 DOWNTO 0) <= x"56";

        KEY(1) <= '0';
        WAIT FOR 25000 ns;
        KEY(1) <= '1';
        WAIT FOR 25000 ns;

        ASSERT HEX0 = to_7seg(x"6")
            REPORT "ERROR: HEX0 should display X high low nibble = 6"
            SEVERITY error;

        ASSERT HEX1 = to_7seg(x"5")
            REPORT "ERROR: HEX1 should display X high high nibble = 5"
            SEVERITY error;

        ----------------------------------------------------------------
        -- Load ALUFN = 0x08
        -- KEY2 pressed
        ----------------------------------------------------------------
        SW(7 DOWNTO 0) <= x"08";

        KEY(2) <= '0';
        WAIT FOR 25000 ns;
        KEY(2) <= '1';
        WAIT FOR 25000 ns;

        ASSERT LEDR(9 DOWNTO 5) = "01000"
            REPORT "ERROR: LEDR(9 downto 5) should display ALUFN(4 downto 0) = 01000"
            SEVERITY error;

        ----------------------------------------------------------------
        -- Change SW without pressing KEY.
        -- Registers should keep previous values.
        ----------------------------------------------------------------
        SW(7 DOWNTO 0) <= x"FF";
        WAIT FOR 25000 ns;

        ASSERT LEDR(9 DOWNTO 5) = "01000"
            REPORT "ERROR: ALUFN changed without KEY2 press"
            SEVERITY error;

        ----------------------------------------------------------------
        -- Simulation finished
        ----------------------------------------------------------------
        REPORT "Testbench finished successfully"
            SEVERITY note;

        WAIT;

    END PROCESS;

END ARCHITECTURE sim;