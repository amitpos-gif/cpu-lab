LIBRARY ieee;
USE ieee.std_logic_1164.all;
--------------------------------------------------------
entity	BS is
	generic (n : integer := 8);
	port(inp in: std_logic_vector(7 downto 0);
	     x_control in: std_logic_vector(2 downto 0);
		 dir in: std_logic;
		 outp out: std_logic_vector(7 downto 0));
end BS;
--------------------------------------------------------------------------------

		 
		 