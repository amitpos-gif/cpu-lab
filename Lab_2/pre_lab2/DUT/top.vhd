LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE work.aux_package.all;
--------------------------------------------------------------
entity top is
	generic (
		n : positive := 8 ;
		m : positive := 7 ;
		k : positive := 3
	); -- where k=log2(m+1)
	port(
		rst,ena,clk : in std_logic;
		x : in std_logic_vector(n-1 downto 0);
		DetectionCode : in integer range 0 to 3;
		detector : out std_logic
	);
end top;
------------- complete the top Architecture code --------------
architecture arc_sys of top is
	signal  x_sample_j1: std_logic_vector(n-1 downto 0);
	signal  x_sample_j2: std_logic_vector(n-1 downto 0);
	signal  valid      : std_logic;
	signal  diff : std_logic_vector(2 downto 0);
	
begin
	sample : PROCESS(clk, rst)  -- first process sample x just if rising edge & ena =1 
			begin
			if (rst = '1') then
				x_sample_j1 <=(others =>'0');
				x_sample_j2 <=(others =>'0');
			elsif rising_edge(clk) then
				if ena = '1' then
					x_sample_j1 <= x;
					x_sample_j2 <= x_sample_j1;
				end if;
			end if;
		end PROCESS sample;
	
	Adder_inst: Adder
		generic map(n => length)
		port map (a => x_sample_j1,
				  b => x_sample_j2, 
				  c => '1', --c = 1 makes sub
				  s => diff);

	sub	: process(DetectionCode, diff) --combinatorical process- no need for the clock
		 begin
			if (DetectionCode = 0 and diff = 1) then 
    			valid <= '1';
			elsif (DetectionCode = 1 and diff = 2) then
    			valid <= '1';
			elsif (DetectionCode = 2 and diff = 3) then
    			valid <= '1';
			elsif (DetectionCode = 3 and diff = 4) then
    			valid <= '1';
			else
    			valid <= '0';
			end if;
			
			
		

			

			
				

	
				
	
	
	
end arc_sys;







