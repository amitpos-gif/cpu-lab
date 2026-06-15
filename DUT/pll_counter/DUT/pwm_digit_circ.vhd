library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all; 
USE work.aux_package.all;
------------------------------------
ENTITY pwm_digit_circ is
      GENERIC (n : INTEGER := 16
	); 
  PORT 
  (  
	      y_i, x_i: IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
		  timer_i : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
          ena_i   : in  STD_LOGIC;
          clk_i   : in  std_logic;
          pwm_mode_i: in std_logic;
          pwm_out : out std_logic_vector(1 downto 0);
          equy_out: out std_logic;
          
            
  ); 
END pwm_digit_circ;
----------------------------------------------------------------
Architecture struct of pwm_digit_circ is
    signal equy_w : std_logic;
    signal pwm_out_w : std_logic := '0';
   
---------------------------------------------------------------
begin

    equy_w <= '1' when (timer_i = Y_i) else '0';
    equy_out <= equy_w;

    process(clk)
    begin
        if (rising_edge(clk_i)) then
            if (ena_i = '1')
                case pwm_mode_i is
                    --mode 0 -> x is responsible for the '0'
                    when "000" => 
                        if (equy_i ='1') then
                            pwm_out_w <= '0';
                        elsif timer_i = x_i then
                            pwm_out_w <= '1';
                        end
                        --mode 1
                    when "001" => 
                        if (equy_i ='1') then
                            pwm_out_w <= '1';
                        elsif timer_i = x_i then
                            pwm_out_w <= '0';
                        end
                    --mode2
                    when "010" => 
                        if timer_i = X_i then 
                            pwm_out_w <= not pwm_out_w;
                        end if;
                    
                    when others => 
                        pwm_out_w <= '0';
                end case;
            end if;
        end if;
    end process;
pwm_out <= pwm_out_w;
end struct;