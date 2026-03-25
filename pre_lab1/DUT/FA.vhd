LIBRARY ieee;
USE ieee.std_logic_1164.all;
--------------------------------------------------------
ENTITY FA IS
	PORT (a, b, cin: IN std_logic;
			  s, cout: OUT std_logic);
END FA;
--------------------------------------------------------
ARCHITECTURE dataflow OF FA IS
BEGIN
	s <= a XOR b XOR cin;
	cout <= (a AND b) OR (a AND cin) OR(b AND cin);
END dataflow;

