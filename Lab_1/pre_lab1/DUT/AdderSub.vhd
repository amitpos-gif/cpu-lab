LIBRARY ieee;
USE ieee.std_logic_1164.all;
--------------------------------------------------------
entity AdderSub is 
    generic (n : integer := 0);
	port (cin_Adder :in std_logic;
	      x,y :in std_logic_vector(n-1 downto 0);
		  sub_cont : in std_logic;
		  res_out_Adder : OUT std_logic_vector(n-1 downto 0);
		  c_out_Adder : out std_logic);
end AdderSub;
--------------------------------------------------------
architecture dtf_AdderSub of AdderSub is
component FA IS
	PORT (a, b, cin: IN std_logic;
			  s, cout: OUT std_logic);
END component;
signal       reg : std_logic_vector(n-1 downto 0);
			 x_xor : std_logic_vector(n-1 downto 0);

begin
	x_xor(0) <= x(0) xor sub_cont
	x_xor(i) <= x(i) xor sub_cont
	first_adder : FA port map(
					a => x_xor(0),
					b => y(0),
					cin => sub_cont,
					s => res_out_Adder(0)
					cout => reg(0));
	rest_adder	: for i in 1 to n-1 generate
				
			chain: port map(
				   a => x_xor(i),
				   b => y(i),
				   cin =>reg(i-1),
				   s => s(i),
				   cout => reg(i));
		end generate;
		c_out_Adder <= reg(n-1);
END dtf_AdderSub;

					
					
					
