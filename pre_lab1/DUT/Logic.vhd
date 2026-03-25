LIBRARY ieee;
USE ieee.std_logic_1164.all;
--------------------------------------------------------
entity logic is
     generic (n : integer := 8);
	 port(x,y :in std_logic_vector(n-1 downto 0);
	      ALUFN : in std_logic_vector(2 downto 0);
		  logic_out: out std_logic_vector(n-1 downto 0));
end logic;
------------------------------------------------------------------------
architecture logic_dtf of logic is
begin
     with ALUFN select
	 logic_out <= not(y) when   "000", 
	              y or x when   "001",
				  y and x when  "010",
				  y xor x when  "011",
				  y nor x when  "100",
				  y nand x when "101",
				  y xnor x when "110",
				  (others => '0') when others;
end logic_dtf;