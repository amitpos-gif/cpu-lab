LIBRARY ieee;
USE ieee.std_logic_1164.all;
--------------------------------------------------------
ENTITY FA IS
	PORT (xi_FA, yi_FA, cin_FA: IN std_logic;
			  s_FA, cout_FA: OUT std_logic);
END FA;
--------------------------------------------------------
ARCHITECTURE dataflow OF FA IS
BEGIN
	s_FA <= xi_FA XOR yi_FA XOR cin_FA;
	cout_FA <= (xi_FA AND yi_FA) OR (xi_FA AND cin_FA) OR(yi_FA AND cin_FA);
END dataflow;

