library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE work.aux_package.all;
-------------------------------------------------------------------
entity alu is
    generic (n:integer :=16;
             k: integer :=4);
    port(
        A,B :in std_logic_vector(n-1 downto 0 ); --ra - A, rb - B
        alufn:in std_logic_vector(3 downto 0 );
        C  :out std_logic_vector(n-1 downto 0); --c like in the draw
        C_flag, Z_flag,N_flag: out std_logic
    );
    end alu;
-------------------------------------------------------------------
architecture dtf_alu of alu is
    signal x_adder_inp, y_adder_inp : std_logic_vector(n-1 downto 0); --input for the adder
    signal x_logic_inp, y_logic_inp : std_logic_vector(n-1 downto 0);-- input for the logic
    signal x_shifter_inp, y_shifter_inp : std_logic_vector(n-1 downto 0); --input for the shifter
    signal out_adder : std_logic_vector(n-1 downto 0);--output of DDER
	signal cout_adder : std_logic;--carry of adder
    signal out_logic : std_logic_vector(n-1 downto 0);--output lodic
    signal out_shifter : std_logic_vector(n-1 downto 0);--output shifter
    signal cout_shifter : std_logic;--carry of shifter
    signal alu_result : std_logic_vector(n-1 downto 0);  -- Internal ALU result
	signal alufn_int : std_logic_vector(3 downto 0);-- aluf internal
begin -- orgenize the inputs
alufn_int <= alufn; --real time change here lines 29 + 30
x_adder_inp   <= A when (alufn_int = "0001" or alufn_int = "0000") else (others => '0'); -- the input will be as original for 0000/0001
y_adder_inp   <= B when (alufn_int = "0001" or alufn_int = "0000") else (others => '0'); -- the input will be as original for 0000/0001                for all the cases if alufn not match input will be vector of '0'

x_logic_inp <= A when (alufn_int = "0010" or alufn_int = "0011" or alufn_int = "0100") else (others => '0'); -- the input will be as original for 0010/0011/0100
y_logic_inp <= B when (alufn_int = "0010" or alufn_int = "0011" or alufn_int = "0100") else (others => '0'); -- the input will be as original for 0010/0011/0100

x_shifter_inp <= A when (alufn_int = "0101") else (others => '0'); -- the input will be as original for 0101
y_shifter_inp <= B when (alufn_int = "0101") else (others => '0'); -- the input will be as original for 0101

Adder_sub: AdderSub
    generic map(n =>n)
    port map(
    x_adder => x_adder_inp,
	y_adder => y_adder_inp,
	alufn_adder => alufn,
	res_out_Adder => out_adder,
	c_out_Adder => cout_adder  
    );

logic_unit: logic 
	generic map(n => n)
	port map(
	x_logic => x_logic_inp,
	y_logic => y_logic_inp,
	alufn_in_logic => alufn,
	logic_out => out_logic
		);

shifter_unit: Shifter
	generic map(n => n, k => k)
	port map(
	inp_shifter => y_shifter_inp,
	x_control => x_shifter_inp(3 downto 0),
	alufn_shifter => alufn,
	outp_shifter => out_shifter,
	cout_shifter => cout_shifter
		);


with alufn select --real time
		alu_result <= out_adder when "0001" | "0000",    -- choosing what will be the output
     	              out_logic when "0010" | "0011"| "0100",
                      out_shifter when "0101" ,
		        (others => '0') when others;
C <= alu_result; -- assign  internal signal tothe output

with alufn select
            C_flag <= cout_adder when "0001" | "0000",
                      cout_shifter when "0101",
                             '0' when others;

with alufn select --real time 
			N_flag <=   out_adder(n-1) when "0001" | "0000",    -- choosing what will be the n flag
				    	out_logic(n-1) when "0010" | "0011"| "0100",
                        out_shifter(n-1) when "0101",
						'0' when others;

Z_flag <= '1' when alu_result = (n-1 downto 0 => '0') else '0';
    
end dtf_alu;