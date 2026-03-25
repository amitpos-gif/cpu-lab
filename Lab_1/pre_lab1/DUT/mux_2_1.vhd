library ieee;
use iee.std_logic_1164.all;
-------------------------------------------------------------------------
entity MUX_2_1;
	port(input : in std_logic_vector(1 downto 0);
		 control : in std_logic;
		 m_out : out std_logic );
end MUX_2_1;
-------------------------------------------------------------------------
architecture mux_2_1_dtf of MUX_2_1 is
begin
	m_out 	<= (input(0) and not(control)) or ( control and input(1));
	end mux_2_1_dtf;