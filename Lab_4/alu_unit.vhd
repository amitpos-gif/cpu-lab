LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE work.aux_package.all;
-------------------------------------
entity alu_unit is 
	generic ( n : INTEGER := 8;
			  k : INTEGER := 3 );
		  
	port (  Y_i      : in std_logic_vector (n-1 downto 0);
			X_i      : in std_logic_vector (n-1 downto 0);
			ALUFN_i  : in std_logic_vector (4 downto 0 );
			ALUout_o : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0);
			Nflag_o  : OUT STD_LOGIC;
			Cflag_o  : OUT STD_LOGIC;
			Zflag_o  : OUT STD_LOGIC;
			Vflag_o  : OUT STD_LOGIC  ) ; 
			
end alu_unit ;
-------------------------------------

architecture struct OF alu_unit IS

 --- internal signal output's unit ---
	SIGNAL addsub_res  : STD_LOGIC_VECTOR(n-1 DOWNTO 0);
    SIGNAL addsub_cout : STD_LOGIC;
    SIGNAL logic_res   : STD_LOGIC_VECTOR(n-1 DOWNTO 0);
    SIGNAL shift_res   : STD_LOGIC_VECTOR(n-1 DOWNTO 0);
    SIGNAL shift_cout  : STD_LOGIC;
	
--- internal signal input's unit ---
	SIGNAL addsub_x : STD_LOGIC_VECTOR(n-1 DOWNTO 0);
    SIGNAL addsub_y : STD_LOGIC_VECTOR(n-1 DOWNTO 0);
    SIGNAL logic_x  : STD_LOGIC_VECTOR(n-1 DOWNTO 0);
    SIGNAL logic_y  : STD_LOGIC_VECTOR(n-1 DOWNTO 0);
    SIGNAL shift_y  : STD_LOGIC_VECTOR(n-1 DOWNTO 0);
    SIGNAL shift_x  : STD_LOGIC_VECTOR(k-1 DOWNTO 0);
	
--- mux ootput's for result ---
	SIGNAL mux_out   : STD_LOGIC_VECTOR(n-1 DOWNTO 0);
    SIGNAL carry_out : STD_LOGIC;
	
	SIGNAL sub_flag     : STD_LOGIC;   -- '1' when operation is subtraction
    SIGNAL x_eff_sign   : STD_LOGIC;   -- effective MSB of X operand

begin
	
	addsub_x <= X_i WHEN ALUFN_i(4 DOWNTO 3) = "01" ELSE (OTHERS => '0');
    addsub_y <= Y_i WHEN ALUFN_i(4 DOWNTO 3) = "01" ELSE (OTHERS => '0');

    logic_x  <= X_i WHEN ALUFN_i(4 DOWNTO 3) = "11" ELSE (OTHERS => '0');
    logic_y  <= Y_i WHEN ALUFN_i(4 DOWNTO 3) = "11" ELSE (OTHERS => '0');

    shift_y  <= Y_i               WHEN ALUFN_i(4 DOWNTO 3) = "10" ELSE (OTHERS => '0');
    shift_x  <= X_i(k-1 DOWNTO 0) WHEN ALUFN_i(4 DOWNTO 3) = "10" ELSE (OTHERS => '0');
	
	 -- Adder/Subtractor: ALUFN[2:0] selects the arithmetic operation
    ADDSUB_INST : adder_subtractor
        GENERIC MAP (n => n)
        PORT MAP (
            x     => addsub_x,
            y     => addsub_y,
            alufn => ALUFN_i(2 DOWNTO 0),
            res   => addsub_res,
            cout  => addsub_cout
        );

    -- Logic unit: ALUFN[2:0] selects the bitwise operation
    LOGIC_INST : Logic
        GENERIC MAP (n => n)
        PORT MAP (
            x     => logic_x,
            y     => logic_y,
            alufn => ALUFN_i(2 DOWNTO 0),
            z     => logic_res
        );

    -- Barrel Shifter: ALUFN[2:0] selects shift direction
    SHIFT_INST : Shifter
        GENERIC MAP (n => n, k => k)
        PORT MAP (
            y     => shift_y,
            x     => shift_x,
            alufn => ALUFN_i(2 DOWNTO 0),
            res   => shift_res,
            cout  => shift_cout
        );
--------------------------------------------------------------
--- moving the result of the curent opcode for the mux_out ---
--------------------------------------------------------------
	WITH ALUFN_i(4 DOWNTO 3) SELECT
        mux_out <= addsub_res       WHEN "01",
                   shift_res        WHEN "10",
                   logic_res        WHEN "11",
                   (OTHERS => '0')  WHEN OTHERS;

    ALUout_o <= mux_out;
	
--------------------------------------------------------------
--- moving the cout of the curent opcode for the carry_out ---
--------------------------------------------------------------
	
	WITH ALUFN_i(4 DOWNTO 3) SELECT
        carry_out <= addsub_cout WHEN "01",
                     shift_cout  WHEN "10",
                     '0'         WHEN OTHERS;
					 
-------------------------------------------------------
					 
	--- we use the msb of the mux_out signal that represent the ressult for the N flag: ---
    Nflag_o <= mux_out(n-1);

    --- if all the mux_out bits are Zero - Z flag up '1' : ---
    Zflag_o <= '1' WHEN mux_out = (n-1 downto 0 => '0') ELSE '0' ;

    -- C flag (Carry): carry-out from arithmetic or shift : ---
    Cflag_o <= carry_out;
	
	----- for the v_flag we will need to sepert in to 2 ops
	----- wheter hapend adding operetion or Subtract operation
	 
	----- for that we will nedded the sub_flag bit : ----
	WITH ALUFN_i(2 DOWNTO 0) SELECT
        sub_flag <= '0' WHEN "000",   -- Y + X   (addition)
                    '1' WHEN "001",   -- Y - X   (subtraction)
                    '1' WHEN "010",   -- neg(X)  (subtraction: 0 - X)
                    '0' WHEN "011",   -- Y + 2   (addition)
                    '1' WHEN "100",   -- Y - 2   (subtraction)
                    '0' WHEN OTHERS;
	
	---- we will find the effective sign of x insid the Adder/Subtractor unit ----
    x_eff_sign <= addsub_x(n-1) XOR sub_flag;
	
	----- this "(addsub_y(n-1) XNOR x_eff_sign)"     - represent the qw - "thy have the same sign ? " -----
	----- this "(addsub_y(n-1) XOR addsub_res(n-1))" - represent the qw - "the sign flip?"            -----
	----- if both of the qw's are correct - sumthig not good hependd  (+) + (+) = (-)  / (-) + (-) = (+)  : mining over flou -----
    Vflag_o <= (addsub_y(n-1) XNOR x_eff_sign) AND (addsub_y(n-1) XOR addsub_res(n-1));
	

END struct;