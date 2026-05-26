library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE work.aux_package.all;
------------------------------------
entity sync_digital_circ is 
    generic ( n : INTEGER := 16
               );
    port (  Y_i      : in std_logic_vector (n-1 downto 0); --- b for the shert digital ---
            X_i      : in std_logic_vector (n-1 downto 0);
            clk_i    : in std_logic;
            ena_i    : in std_logic;
            rst_i    : in std_logic;
            ALUFN_i  : in std_logic_vector (4 downto 0);
            pwm_o  : out std_logic
            ); 

end sync_digital_circ;
----------------------------------------------------------------
architecture struct of sync_digital_circ is
    signal pwm_y : std_logic_vector(n-1 downto 0);
    signal pwm_x : std_logic_vector(n-1 downto 0);
    signal pwm_enable : std_logic;
begin
    pwm_y <= y_i WHEN ALUFN_i(4 DOWNTO 3) = "00" ELSE (OTHERS => '0');
    pwm_x <= x_i WHEN ALUFN_i(4 DOWNTO 3) = "00" ELSE (OTHERS => '0');
    pwm_enable <= ena_i when ALUFN_i(4 DOWNTO 3) = "00" ELSE '0';

    PWM_OUTPOT_UNIT_INST : pwm_outpot_unit
        GENERIC MAP (n => n)
        PORT MAP (
            x_i => pwm_x,
            y_i => pwm_y,
            ALUFN_i => ALUFN_i(2 downto 0), --- this is the mode of the pwm_outpot_unit ---
            ena_i => pwm_enable,
            clk_i => clk_i,
            rst_i => rst_i,
            pwmout_o => pwm_o
        );

end struct;


