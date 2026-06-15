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
	signal  diff : std_logic_vector( n-1 downto 0);
	
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
		generic map(length => n)
		port map (a => x_sample_j1,
				  b => x_sample_j2, 
				  cin => '1', --c = 1 makes sub
				  cout => open,
				  s => diff);

	sub	: process(DetectionCode, diff) --combinatorical process- no need for the clock
		 begin
			if (DetectionCode = 0 and conv_integer(diff) = 1) then 
    			valid <= '1';
			elsif (DetectionCode = 1 and conv_integer(diff) = 2) then
    			valid <= '1';
			elsif (DetectionCode = 2 and conv_integer(diff) = 3) then
    			valid <= '1';
			elsif (DetectionCode = 3 and conv_integer(diff) = 4) then
    			valid <= '1';
			else
    			valid <= '0';
			end if;
	end process sub;
	
det_proc : process(clk, rst) -- detect the num of valid sampels
    variable count : integer range 0 to m+1; --the range because the system know how many bits requiers, need to be greater then m!!
begin
    if (rst ='1') then  --async condition
        detector <= '0';
        count := 0;

    elsif rising_edge(clk) then
        if ena = '1' then --check ena
            if valid = '1' then --check valid or not
                if count < m+1 then
                    count := count + 1;
                end if;

                if count > m then   --check if condition is happens
                    detector <= '1';
                else
                    detector <= '0';
                end if;

            else      -- valid = 0
                count := 0;
                detector <= '0';
            end if;
        end if;
    end if;
end process det_proc;
		
end arc_sys;







