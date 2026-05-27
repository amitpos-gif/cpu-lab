library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--------------------------------------------------------
package aux_package is
	component top is
	GENERIC (n : INTEGER := 8;
		   k : integer := 3;   -- k=log2(n)
		   m : integer := 4	); -- m=2^(k-1)
	PORT 
	(  
		Y_i,X_i: IN STD_LOGIC_VECTOR (n-1 DOWNTO 0);
		ALUFN_i : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
		ALUout_o: OUT STD_LOGIC_VECTOR(n-1 downto 0);
		Nflag_o,Cflag_o,Zflag_o,Vflag_o: OUT STD_LOGIC 
	); -- Zflag,Cflag,Nflag,Vflag
	end component;
---------------------------------------------------------  
	component FA is
		PORT (xi, yi, cin: IN std_logic;
			      s, cout: OUT std_logic);
	end component;
---------------------------------------------------------	
component AdderSub is 
    generic (n : integer := 8);
	port (
	      x_adder,y_adder :in std_logic_vector(n-1 downto 0);
		  alufn_adder : in STD_LOGIC_VECTOR(2 downto 0);
		  res_out_Adder : OUT std_logic_vector(n-1 downto 0);  --3 input 2 output
		  c_out_Adder : out std_logic);
end component;
---------------------------------------------------------------
component Shifter is
	GENERIC (n : INTEGER := 8;
		   k : integer := 3); --k = log_2_(n)
	port(inp_shifter : in std_logic_vector(n-1 downto 0);-- y vector
	     x_control : in std_logic_vector(k-1 downto 0); --x vector
		 alufn_shifter :in std_logic_vector(2 downto 0); --alufn(0) is the dir
		 outp_shifter : out std_logic_vector(n-1 downto 0);
		 cout_shifter: out std_logic);
end component;
--------------------------------------------------------------------
component logic is
     generic (n : integer := 8);
	 port(x_logic,y_logic :in std_logic_vector(n-1 downto 0);
	      alufn_in_logic : in std_logic_vector(2 downto 0); 
		  logic_out: out std_logic_vector(n-1 downto 0));
end component;
	
	
	
	
	
	
	
	
	
	
	
	
	
	
end aux_package;

