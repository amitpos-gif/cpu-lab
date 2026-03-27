library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE work.aux_package.all;
--------------------------------------------------------
entity logic is
     generic (n : integer := 8);
	 port(x,y :in std_logic_vector(n-1 downto 0);
	      alufn_in_logic : in std_logic_vector(2 downto 0); 
		  logic_out: out std_logic_vector(n-1 downto 0));
end logic;
------------------------------------------------------------------------
architecture logic_dtf of logic is
begin
     with alufn_in_logic select
	 logic_out <= not(y) when   "000", 
	              y or x when   "001",
				  y and x when  "010",
				  y xor x when  "011",
				  y nor x when  "100",
				  y nand x when "101",
				  y xnor x when "110",
				  (others => '0') when others;
end logic_dtf;