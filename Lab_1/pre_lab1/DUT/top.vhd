LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE work.aux_package.all;
-------------------------------------
ENTITY top IS
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
END top;
------------- complete the top Architecture code --------------
ARCHITECTURE struct OF top IS 
	signal x_adder_inp, y_adder_inp : std_logic_vector(n-1 downto 0);
	signal x_shift_inp : std_logic_vector(k-1 downto 0);
	signal y_shift_inp : std_logic_vector(n-1 downto 0);
	signal x_logic_inp, y_logic_inp : std_logic_vector(n-1 downto 0);
	
	signal out_adder : std_logic_vector(n-1 downto 0);
	signal cout_adder : std_logic;
	signal out_shift : std_logic_vector(n-1 downto 0);
	signal cout_shift : std_logic;
	signal out_logic : std_logic_vector(n-1 downto 0);
	
	signal alu_result : std_logic_vector(n-1 downto 0);  -- Internal ALU result
	signal alufn : std_logic_vector(2 downto 0);
	

begin
		alufn <= ALUFN_i(2 downto 0);
		x_adder_inp   <= X_i when ALUFN_i(4 downto 3) = "01" else (others => '0');
		y_adder_inp   <= Y_i when ALUFN_i(4 downto 3) = "01" else (others => '0');
	
		x_shift_inp <= X_i(k-1 downto 0) when ALUFN_i(4 downto 3) = "10" else (others => '0');
		y_shift_inp <= Y_i when ALUFN_i(4 downto 3) = "10" else (others => '0');

		x_logic_inp <= X_i when ALUFN_i(4 downto 3) = "11" else (others => '0');
		y_logic_inp <= Y_i when ALUFN_i(4 downto 3) = "11" else (others => '0');

	Adder_sub: AdderSub 
		generic map(n => n)
		port map(
			x_adder => x_adder_inp,
			y_adder => y_adder_inp,
			alufn_adder => alufn,
			res_out_Adder => out_adder,
			c_out_Adder => cout_adder
		);

	shifter_unit: Shifter 
		generic map(n => n, k => k)
		port map(
			inp_shifter => y_shift_inp,
			x_control => x_shift_inp,                      -- all three port map - connecting the ports of the modules
			alufn_shifter => alufn,
			outp_shifter => out_shift,
			cout_shifter => cout_shift
		);
			
	logic_unit: logic 
		generic map(n => n)
		port map(
			x_logic => x_logic_inp,
			y_logic => y_logic_inp,
			alufn_in_logic => alufn,
			logic_out => out_logic
		);
	
		with ALUFN_i(4 downto 3) select
			alu_result <= out_adder when "01",    -- choosing what will be the output
						  out_logic when "11",
						  out_shift when "10",
						  (others => '0') when others;
		
		ALUout_o <= alu_result;  -- Assign internal signal to output
		with ALUFN_i(4 downto 3) select
			Cflag_o <=  cout_adder when "01",    -- choosing what will be the  c flag
						cout_shift when "10",
						'0' when others;
		
		with ALUFN_i(4 downto 3) select
			Nflag_o <=  out_adder(n-1) when "01",    -- choosing what will be the n flag
				    	out_logic(n-1) when "11",
						out_shift(n-1) when "10",
						'0' when others;
		
	
		Zflag_o <= '1' when alu_result = (n-1 downto 0 => '0') else '0';	

		-- Overflow Flag Computation (V flag)
		-- ADD operation (alufn = "000"): V = (Pos + Pos = Neg) OR (Neg + Neg = Pos)
		-- SUB operation (alufn = "001"): V = (Pos - Neg = Neg) OR (Neg - Pos = Pos)
		Vflag_o <= (x_adder_inp(n-1) AND y_adder_inp(n-1) AND NOT out_adder(n-1)) OR 
		           (NOT x_adder_inp(n-1) AND NOT y_adder_inp(n-1) AND out_adder(n-1))
		           when ALUFN_i(4 downto 3) = "01" AND alufn = "000" else  -- ADD
		           (NOT x_adder_inp(n-1) AND y_adder_inp(n-1) AND NOT out_adder(n-1)) OR 
		           (x_adder_inp(n-1) AND NOT y_adder_inp(n-1) AND out_adder(n-1))
		           when ALUFN_i(4 downto 3) = "01" AND alufn = "001" else  -- SUB
		           '0' ;  -- No overflow for shift or logic operations
		
			 
END struct;

