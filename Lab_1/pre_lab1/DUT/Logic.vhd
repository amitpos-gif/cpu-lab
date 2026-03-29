library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE work.aux_package.all;
--------------------------------------------------------
entity logic is
     generic (n : integer := 8);
	 port(x_logic,y_logic :in std_logic_vector(n-1 downto 0);
	      alufn_in_logic : in std_logic_vector(2 downto 0); 
		  logic_out: out std_logic_vector(n-1 downto 0));
end logic;
------------------------------------------------------------------------
architecture logic_dtf of logic is
begin
     with alufn_in_logic select
	 logic_out <= not(y_logic) when   "000", 
	              y_logic or x_logic when   "001",
				  y_logic and x_logic when  "010",
				  y_logic xor x_logic when  "011",
				  y_logic nor x_logic when  "100",
				  y_logic nand x_logic when "101",
				  y_logic xnor x_logic when "110",
				  (others => '0') when others;
end logic_dtf;