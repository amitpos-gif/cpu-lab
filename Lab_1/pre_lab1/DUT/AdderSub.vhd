library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE work.aux_package.all;
--------------------------------------------------------
entity AdderSub is 
    generic (n : integer := 8);
	port (
	      x_adder,y_adder :in std_logic_vector(n-1 downto 0);
		  alufn_adder : in STD_LOGIC_VECTOR(2 downto 0);
		  res_out_Adder : OUT std_logic_vector(n-1 downto 0);  --3 input 2 output
		  c_out_Adder : out std_logic);
end AdderSub;
--------------------------------------------------------
architecture dtf_AdderSub of AdderSub is  --dtf = data flow
--------------------------------------------------------
signal       c_wire: std_logic_vector(n-1 downto 0);
signal		 x_in : std_logic_vector(n-1 downto 0);	
signal		 x_xor : std_logic_vector(n-1 downto 0);
signal 		 y_in : std_logic_vector(n-1 downto 0);
signal       sub_cont : std_logic; --is internal signal and not an external output, we can see this from the draw
-------------------------------------------------------
begin
	with alufn_adder select
    y_in <= y_adder               when "000",
            y_adder               when "001",
            (others => '0') when "010",
            y_adder               when "011",
            y_adder               when "100",
            (others => '0') when others;                           -- 3 with/select - covering all options
	with alufn_adder select
	x_in <= x_adder               when "000",
            x_adder               when "001",
            x_adder               when "010",
            conv_std_logic_vector(2, n) when "011",
            conv_std_logic_vector(2, n) when "100",
            (others => '0') when others;	
			
	with alufn_adder select
	sub_cont <= '0'               when "000",
                '1'               when "001",          --0 is add, 1 sub
            	'1'               when "010",
           	    '0' 		      when "011",
            	'1' 		      when "100",
            	'0'				  when others;			




	x_xor(0) <= x_in(0) xor sub_cont; 

	first_adder : FA port map(
				xi => x_xor(0),
				yi => y_in(0),
				cin => sub_cont,
				s => res_out_Adder(0),
				cout => c_wire(0));
	rest_adder	: for i in 1 to n-1 generate
		x_xor(i) <= x_in(i) xor sub_cont;	
		chain: FA port map(
			   xi => x_xor(i),
			   yi => y_in(i),
			   cin =>c_wire(i-1),
			   s => res_out_Adder(i),
			   cout => c_wire(i));
	end generate;
		c_out_Adder <= c_wire(n-1);
END dtf_AdderSub;

					
					
					
