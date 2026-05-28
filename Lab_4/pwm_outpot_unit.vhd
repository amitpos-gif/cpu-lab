library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE work.aux_package.all;
------------------------------------
entity pwm_output_unit is
      GENERIC (n : INTEGER := 16
    ); 
  PORT 
  (
    x_i      : in std_logic_vector (n-1 downto 0);  --- a for the second layer  ---
    y_i      : IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
    ALUFN_i  : IN std_logic_vector(1 downto 0);
    ena_i    : in std_logic;
    clk_i    : in  std_logic;
    rst_i    : in  std_logic;
    pwmout_o : out std_logic );

END entity pwm_output_unit;
-----------------------------------s-----------------------------
architecture struct of pwm_output_unit is
    signal timer_q : std_logic_vector(n-1 downto 0);
    signal equy_i : std_logic;
begin    
    PWM_INST : digit_circ
        GENERIC MAP (n => n)
        PORT MAP (
            y_i => y_i,
            x_i => x_i,
            timer_i => timer_q,
            ena_i => ena_i,
            clk_i => clk_i,
            pwm_mode_i => ALUFN_i,
            pwm_out => pwmout_o,
            equy_out => equy_i
        );
        
    TIMER_INST : bit_Timer
        GENERIC MAP (n => n)
        PORT MAP (
            clk => clk_i,
            rst => rst_i,
            ena => ena_i,
            EQUY => equy_i,
            timer_val => timer_q
        );

end struct;
