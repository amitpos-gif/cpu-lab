library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE work.aux_package.all;
--------------------------------------------------------
entity AdderSub is 
    generic (n : integer := 16);
	port (
	      x_adder,y_adder :in std_logic_vector(n-1 downto 0);
		  alufn_adder : in STD_LOGIC_VECTOR(3 downto 0);
		  res_out_Adder : OUT std_logic_vector(n-1 downto 0);  --3 input 2 output
		  c_out_Adder : out std_logic);
end AdderSub;
--------------------------------------------------------
architecture dtf_AdderSub of AdderSub is  --dtf = data flow
--------------------------------------------------------
signal       c_wire: std_logic_vector(n-1 downto 0);
signal		 x_xor : std_logic_vector(n-1 downto 0);
signal       sub_cont : std_logic; --0 = add, 1 = subtract (alufn_adder(0))
-------------------------------------------------------
begin
	--Control: alufn_adder(0) = 0 for ADD, 1 for SUBTRACT
	sub_cont <= alufn_adder(0);			

	x_xor(0) <= x_adder(0) xor sub_cont; 

	first_adder : FA port map(
				xi => x_xor(0),
				yi => y_adder(0),
				cin => sub_cont,
				s => res_out_Adder(0),
				cout => c_wire(0));
	rest_adder	: for i in 1 to n-1 generate
		x_xor(i) <= x_adder(i) xor sub_cont;	
		chain: FA port map(
			   xi => x_xor(i),
			   yi => y_adder(i),
			   cin =>c_wire(i-1),
			   s => res_out_Adder(i),
			   cout => c_wire(i));
	end generate;
		c_out_Adder <= c_wire(n-1);
END dtf_AdderSub;

					
					
					
