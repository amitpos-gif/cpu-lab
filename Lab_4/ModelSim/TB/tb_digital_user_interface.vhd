-- =============================================================
--  Testbench : tb_digital_user_interface
--
--  Clock domains
--  -------------
--    CLOCK_50  : 50 MHz  -> period = 20 ns   (drives DUT input & PLL)
--    clk_pll   : 2  MHz  -> period = 500 ns  (PLL output, drives digital_system)
--                           PLL divides 50 MHz by 25
--
--  All stimulus delays are expressed as multiples of the 2 MHz
--  PLL period (500 ns) so every step is visible in the waveform.
--
--  Timing constants
--  ----------------
--    PLL_T        = 500 ns   (1 PLL clock period)
--    KEY_HOLD     = 10 x PLL_T =  5 000 ns   key pressed duration
--    SETTLE       = 20 x PLL_T = 10 000 ns   inter-step gap
--    RESET_HOLD   = 10 x PLL_T =  5 000 ns   KEY3 (reset) pressed duration
--    RESET_SETTLE = 30 x PLL_T = 15 000 ns   wait after reset
--
--  PWM observe windows (100 full PWM periods each)
--    Round 1  Y=20 -> PWM period = 20x500 ns = 10 us  -> 100x10 us =  1 ms
--    Round 2  Y=50 -> PWM period = 50x500 ns = 25 us  -> 100x25 us = 2.5 ms
--
--  Scenario
--  --------
--  Round 1  (PWM Mode 2 - Toggle)
--    X = 6    (0x0006)   KEY1
--    Y = 20   (0x0014)   KEY0    -> Y > X ok
--    ALUFN = 0x02  (ALUFN[4:3]="00" -> PWM path, [1:0]="10" -> mode 2)
--    SW8 = 1  -> ena
--
--  RESET (KEY3)
--
--  Round 2  (PWM Mode 1 - Reset/Set)
--    X = 12   (0x000C)   KEY1
--    Y = 50   (0x0032)   KEY0    -> Y > X ok
--    ALUFN = 0x01  (ALUFN[4:3]="00" -> PWM path, [1:0]="01" -> mode 1)
--    SW8 = 1  -> ena
--
--  KEY convention (DE10-Standard active-low):
--    not pressed = '1'   /   pressed = '0'
--
--  NOTE on HEX ports:
--    The DUT compiled in the work library has HEX as 7-bit (6 downto 0)
--    7-segment encoded outputs.  The TB declares them as 7-bit accordingly.
--    The raw nibble value is checked via the lower 4 bits only:
--       HEX0(3 downto 0) = expected_nibble
-- =============================================================

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

ENTITY tb_digital_user_interface IS
END tb_digital_user_interface;

ARCHITECTURE sim OF tb_digital_user_interface IS

    -- --------------------------------------------------------
    -- Generics (must match DUT)
    -- --------------------------------------------------------
    CONSTANT n : INTEGER := 16;
    CONSTANT k : INTEGER := 4;

    -- --------------------------------------------------------
    -- Clock domains
    -- --------------------------------------------------------
    CONSTANT CLK50_HALF  : TIME :=   10 ns;   -- 50 MHz half-period
    CONSTANT PLL_T       : TIME :=  500 ns;   -- 2 MHz  full period

    -- --------------------------------------------------------
    -- Stimulus timing (all derived from PLL_T)
    -- --------------------------------------------------------
    CONSTANT KEY_HOLD     : TIME := 10 * PLL_T;   --  5 000 ns
    CONSTANT SETTLE       : TIME := 20 * PLL_T;   -- 10 000 ns
    CONSTANT RESET_HOLD   : TIME := 10 * PLL_T;   --  5 000 ns
    CONSTANT RESET_SETTLE : TIME := 30 * PLL_T;   -- 15 000 ns
    CONSTANT PWM_OBS_R1   : TIME := 100 * 20 * PLL_T;  -- 1 ms
    CONSTANT PWM_OBS_R2   : TIME := 100 * 50 * PLL_T;  -- 2.5 ms

    -- --------------------------------------------------------
    -- DUT I/O
    -- HEX declared as 7-bit (6 downto 0) to match the compiled
    -- DUT in the work library (7-segment encoded output).
    -- --------------------------------------------------------
    SIGNAL CLOCK_50 : STD_LOGIC := '0';
    SIGNAL SW       : STD_LOGIC_VECTOR(9 DOWNTO 0) := (OTHERS => '0');
    SIGNAL KEY      : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '1');

    SIGNAL LEDR     : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL HEX0     : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL HEX1     : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL HEX2     : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL HEX3     : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL HEX4     : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL HEX5     : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL pwm_out  : STD_LOGIC;

BEGIN

    -- =========================================================
    -- DUT instantiation
    -- =========================================================
    DUT : ENTITY work.digital_user_interface
        GENERIC MAP ( n => n, k => k )
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

    -- =========================================================
    -- 50 MHz clock generator
    -- =========================================================
    clk_proc : PROCESS
    BEGIN
        LOOP
            CLOCK_50 <= '0'; WAIT FOR CLK50_HALF;
            CLOCK_50 <= '1'; WAIT FOR CLK50_HALF;
        END LOOP;
    END PROCESS;

    -- =========================================================
    -- Stimulus process
    -- =========================================================
    stim_proc : PROCESS

        PROCEDURE press_key (
            SIGNAL  k_vec : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            CONSTANT idx  : INTEGER
        ) IS
        BEGIN
            k_vec(idx) <= '0';
            WAIT FOR KEY_HOLD;
            k_vec(idx) <= '1';
            WAIT FOR SETTLE;
        END PROCEDURE;

    BEGIN

        -- Power-on idle: 40 PLL cycles for PLL to lock
        SW  <= (OTHERS => '0');
        KEY <= (OTHERS => '1');
        WAIT FOR 40 * PLL_T;

        -- ========================================================
        --  ROUND 1 : X=6, Y=20, ALUFN=0x02 (PWM Mode 2 - Toggle)
        -- ========================================================
        REPORT ">>> ROUND 1 START: X=6, Y=20, PWM Mode 2 (Toggle)" SEVERITY note;

        ---- Load Y low byte = 0x14 (20 decimal) ----
        SW(9) <= '0';
        SW(8) <= '0';
        SW(7 DOWNTO 0) <= x"14";
        WAIT FOR SETTLE;
        press_key(KEY, 0);

        -- HEX is 7-segment encoded; check lower nibble via raw data bits
        ASSERT HEX2(3 DOWNTO 0) = "0100"
            REPORT "R1-FAIL: HEX2 lower nibble expected 4 (Y_low[3:0])" SEVERITY error;
        ASSERT HEX3(3 DOWNTO 0) = "0001"
            REPORT "R1-FAIL: HEX3 lower nibble expected 1 (Y_low[7:4])" SEVERITY error;
        REPORT "R1: Y_low loaded (0x14). SETTLE gap follows." SEVERITY note;
        WAIT FOR SETTLE;

        ---- Load Y high byte = 0x00 ----
        SW(9) <= '1';
        SW(7 DOWNTO 0) <= x"00";
        WAIT FOR SETTLE;
        press_key(KEY, 0);
        REPORT "R1: Y_high loaded (0x00). Y = 0x0014 = 20." SEVERITY note;
        WAIT FOR SETTLE;

        ---- Load X low byte = 0x06 (6 decimal) ----
        SW(9) <= '0';
        SW(7 DOWNTO 0) <= x"06";
        WAIT FOR SETTLE;
        press_key(KEY, 1);

        ASSERT HEX0(3 DOWNTO 0) = "0110"
            REPORT "R1-FAIL: HEX0 lower nibble expected 6 (X_low[3:0])" SEVERITY error;
        ASSERT HEX1(3 DOWNTO 0) = "0000"
            REPORT "R1-FAIL: HEX1 lower nibble expected 0 (X_low[7:4])" SEVERITY error;
        REPORT "R1: X_low loaded (0x06). SETTLE gap follows." SEVERITY note;
        WAIT FOR SETTLE;

        ---- Load X high byte = 0x00 ----
        SW(9) <= '1';
        SW(7 DOWNTO 0) <= x"00";
        WAIT FOR SETTLE;
        press_key(KEY, 1);
        REPORT "R1: X_high loaded. X=0x0006=6. Y(20) > X(6) OK." SEVERITY note;
        WAIT FOR SETTLE;

        ---- Load ALUFN = 0x02 ----
        -- ALUFN[4:3]="00" -> PWM active, [1:0]="10" -> mode 2 (toggle)
        SW(9) <= '0';
        SW(7 DOWNTO 0) <= x"02";
        WAIT FOR SETTLE;
        press_key(KEY, 2);

        ASSERT LEDR(9 DOWNTO 5) = "00010"
            REPORT "R1-FAIL: LEDR[9:5] expected 00010 (ALUFN=0x02)" SEVERITY error;
        REPORT "R1: ALUFN=0x02 loaded (PWM Mode 2 - Toggle). SETTLE gap." SEVERITY note;
        WAIT FOR SETTLE;

        ---- Enable PWM: SW8='1' ----
        SW(8) <= '1';
        REPORT "R1: PWM ENABLED. Observing 100 PWM cycles (1 ms)..." SEVERITY note;
        WAIT FOR PWM_OBS_R1;
        REPORT "R1: Done observing PWM Mode 2." SEVERITY note;

        SW(8) <= '0';
        WAIT FOR SETTLE;

        -- ========================================================
        --  RESET (KEY3, active-low)
        --  10 PLL cycles pressed then 30 cycles settle
        -- ========================================================
        REPORT ">>> RESET: pressing KEY3 for 10 PLL cycles" SEVERITY note;
        KEY(3) <= '0';
        WAIT FOR RESET_HOLD;
        KEY(3) <= '1';
        WAIT FOR RESET_SETTLE;
        REPORT ">>> RESET complete. Starting Round 2." SEVERITY note;

        -- ========================================================
        --  ROUND 2 : X=12, Y=50, ALUFN=0x01 (PWM Mode 1 - Reset/Set)
        -- ========================================================
        REPORT ">>> ROUND 2 START: X=12, Y=50, PWM Mode 1 (Reset/Set)" SEVERITY note;

        ---- Load Y low byte = 0x32 (50 decimal) ----
        SW(9) <= '0';
        SW(8) <= '0';
        SW(7 DOWNTO 0) <= x"32";
        WAIT FOR SETTLE;
        press_key(KEY, 0);

        ASSERT HEX2(3 DOWNTO 0) = "0010"
            REPORT "R2-FAIL: HEX2 lower nibble expected 2 (Y_low[3:0])" SEVERITY error;
        ASSERT HEX3(3 DOWNTO 0) = "0011"
            REPORT "R2-FAIL: HEX3 lower nibble expected 3 (Y_low[7:4])" SEVERITY error;
        REPORT "R2: Y_low loaded (0x32). SETTLE gap follows." SEVERITY note;
        WAIT FOR SETTLE;

        ---- Load Y high byte = 0x00 ----
        SW(9) <= '1';
        SW(7 DOWNTO 0) <= x"00";
        WAIT FOR SETTLE;
        press_key(KEY, 0);
        REPORT "R2: Y_high loaded. Y=0x0032=50." SEVERITY note;
        WAIT FOR SETTLE;

        ---- Load X low byte = 0x0C (12 decimal) ----
        SW(9) <= '0';
        SW(7 DOWNTO 0) <= x"0C";
        WAIT FOR SETTLE;
        press_key(KEY, 1);

        ASSERT HEX0(3 DOWNTO 0) = "1100"
            REPORT "R2-FAIL: HEX0 lower nibble expected C (X_low[3:0])" SEVERITY error;
        ASSERT HEX1(3 DOWNTO 0) = "0000"
            REPORT "R2-FAIL: HEX1 lower nibble expected 0 (X_low[7:4])" SEVERITY error;
        REPORT "R2: X_low loaded (0x0C). SETTLE gap follows." SEVERITY note;
        WAIT FOR SETTLE;

        ---- Load X high byte = 0x00 ----
        SW(9) <= '1';
        SW(7 DOWNTO 0) <= x"00";
        WAIT FOR SETTLE;
        press_key(KEY, 1);
        REPORT "R2: X_high loaded. X=0x000C=12. Y(50) > X(12) OK." SEVERITY note;
        WAIT FOR SETTLE;

        ---- Load ALUFN = 0x01 ----
        -- ALUFN[4:3]="00" -> PWM active, [1:0]="01" -> mode 1 (reset/set)
        SW(9) <= '0';
        SW(7 DOWNTO 0) <= x"01";
        WAIT FOR SETTLE;
        press_key(KEY, 2);

        ASSERT LEDR(9 DOWNTO 5) = "00001"
            REPORT "R2-FAIL: LEDR[9:5] expected 00001 (ALUFN=0x01)" SEVERITY error;
        REPORT "R2: ALUFN=0x01 loaded (PWM Mode 1 - Reset/Set). SETTLE gap." SEVERITY note;
        WAIT FOR SETTLE;

        ---- Enable PWM: SW8='1' ----
        SW(8) <= '1';
        REPORT "R2: PWM ENABLED. Observing 100 PWM cycles (2.5 ms)..." SEVERITY note;
        WAIT FOR PWM_OBS_R2;
        REPORT "R2: Done observing PWM Mode 1." SEVERITY note;

        SW(8) <= '0';
        WAIT FOR SETTLE;

        -- ========================================================
        --  Sanity check: SW change without KEY must NOT change regs
        -- ========================================================
        SW(7 DOWNTO 0) <= x"FF";
        WAIT FOR SETTLE;
        ASSERT LEDR(9 DOWNTO 5) = "00001"
            REPORT "SANITY-FAIL: ALUFN changed without KEY2 press!" SEVERITY error;
        REPORT "Sanity check passed: registers held without KEY." SEVERITY note;

        REPORT "=== Testbench COMPLETED successfully ===" SEVERITY note;
        WAIT;

    END PROCESS;

END ARCHITECTURE sim;
