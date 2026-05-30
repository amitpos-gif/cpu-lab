lIBRARY ieee;
USE ieee.std_logic_1164.all;

entity Logic is 
	generic (n : integer :=16); 
	port ( x, y : in std_logic_vector (n-1 downto 0) ;
	alufn : in std_logic_vector (2 downto 0); 
	z : out std_logic_vector (n-1 downto 0) ); 
	
end Logic ;

ARCHITECTURE dataflow of logic is
	begin
	with alufn select
		z<= not(y) when "000" ,
			(y or x) when "001",
			(y and x) when "010",
			(y xor x) when "011",
			(y nor x) when "100",
			(y nand x) when "101",
			(y xnor x) when "110",
			(others => '0') when others;

end dataflow; 
			