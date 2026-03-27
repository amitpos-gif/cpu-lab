library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE work.aux_package.all;
--------------------------------------------------------
entity Shifter is
	GENERIC (n : INTEGER := 8;
		   k : integer := 3); --k = log_2_(n)
	port(inp_shifter : in std_logic_vector(n-1 downto 0);-- y vector
	     x_control : in std_logic_vector(k-1 downto 0); --x vector
		 alufn_shifter :in std_logic_vector(2 downto 0); --alufn(0) is the dir
		 outp_shifter : out std_logic_vector(n-1 downto 0)
		 cout_shifter: out std_logic);
end Shifter;
--------------------------------------------------------------------------------
architecture dtf_shifter of Shifter is
	subtype vector is std_logic_vector(n-1 downto 0);
	type matrix is array (k DOWNTO 0) of vector;
	signal stages : matrix; --row is the shifted vector, colomn is the #step 
	signal c_temp_shifter: std_logic_vector(k downto 0);
	signal check_alufn : std_logic_vector(1 downto 0);-- check alufn (2 downto 1)
	

begin
	check_alufn <= alufn_shifter(2 downto 1) or "00";
	stages(0) <= inp_shifter when check_alufn = "00" else (others => '0'); --if alufn !=00 ill do a shift on 0's vector.
	c_temp_shifter(0)<= 0;
	stages : for i in 0 to k-1 generate
		stages(i+1) <= stage(i)  when x_control(i) = '0' else
			stages(i) (n-2**i-1 downto 0) & stage(2**i - 1 downto 0 => '0') when alufn_shifter(0) ='0' else
			(2**i-1 downto 0 => '0') & stages(i)(n-1 downto 2**i);
---------------------- carry---------------------------------------------------
		c_temp_shifter(i+1) <= c_temp_shifter(i) when x_control = '0' else
			stages(i)(n-2**i-1) when alufn_shifter(0) ='0' else
				stages(i)(2**i-1) else;
    end generate;

		outp_shifter <= stages(k);
		cout_shifter <= c_out_temp_shifter(k);
	end dtf_shifter;




	
		 
		 