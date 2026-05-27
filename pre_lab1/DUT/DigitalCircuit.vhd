library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
--------------------------------------------------------- 
entity DigitalCircuit is
    generic (
        n : integer := 16
    );
    port (
        clk       : in  std_logic;
        ena       : in  std_logic;
        X_i         : in  std_logic_vector(n-1 downto 0);
        Y_i         : in  std_logic_vector(n-1 downto 0);
        timer_val : in  std_logic_vector(n-1 downto 0);
        PWMmode  : in  std_logic_vector(2 downto 0); 
        EQUY      : out std_logic;
        PWMout    : out std_logic
    );
end entity DigitalCircuit;
---------------------------------------------------------  
architecture rtl of DigitalCircuit is
    signal pwm_q  : std_logic := '0';
    signal equy_i : std_logic;
begin

    equy_i <= '1' when (timer_val = Y_i) else '0';
    EQUY   <= equy_i;

    process (clk)
    begin
        if (rising_edge(clk)) then
            if (ena = '1') then
                case PWMmode is
                    when "000" => 
                        -- Mode 0: Set/Reset 
                        if (equy_i = '1') then
                            pwm_q <= '0'; 
                        elsif (timer_val = X_i) then
                            pwm_q <= '1'; 
                        end if;

                    when "001" => 
                        -- Mode 1: Reset/Set 
                        if (equy_i = '1') then
                            pwm_q <= '1'; 
                        elsif (timer_val = X_i) then
                            pwm_q <= '0'; 
                        end if;

                    when "010" => 
                        -- Mode 2: Toggle
                        if (timer_val = X_i) then
                            pwm_q <= not pwm_q;
                        end if;

                    when others =>
                        pwm_q <= '0';
                end case;
            end if;
        end if;
    end process;
    PWMout <= pwm_q;
end rtl;
--------------------------------------------------------- 