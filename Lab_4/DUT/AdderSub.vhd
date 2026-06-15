LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE work.aux_package.all;
--------------------------------------------
ENTITY adder_subtractor IS
    GENERIC ( n : INTEGER := 8 );
    PORT (
        X     : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
        Y     : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
        alufn : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        res   : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0);
        cout  : OUT STD_LOGIC
    );
END adder_subtractor;
------------------------------------------------
ARCHITECTURE Structural OF adder_subtractor IS

    SIGNAL carry    : STD_LOGIC_VECTOR(n-1 DOWNTO 0);
    SIGNAL A_in     : STD_LOGIC_VECTOR(n-1 DOWNTO 0);
    SIGNAL B_in     : STD_LOGIC_VECTOR(n-1 DOWNTO 0);
    SIGNAL A_mod    : STD_LOGIC_VECTOR(n-1 DOWNTO 0);
	signal the_res  : STD_LOGIC_VECTOR(n-1 DOWNTO 0);
    SIGNAL sub_flag : STD_LOGIC;
    SIGNAL const2   : STD_LOGIC_VECTOR(n-1 DOWNTO 0);
    SIGNAL zeros    : STD_LOGIC_VECTOR(n-1 DOWNTO 0);
    SIGNAL merge_res : STD_LOGIC_VECTOR(n-1 DOWNTO 0);

begin
   
	const2 <= (1 => '1', OTHERS => '0');   -- "00...010" the +2 constant 
    zeros  <= (OTHERS => '0');              -- "00...000" the zero ustput
    merge_res <= Y(3 downto 0) & X(3 downto 0); 
	---
	WITH alufn SELECT
        A_in <= X      WHEN "000",   ---- Y + X ----
                X      WHEN "001",   ---- Y - X ----
                X      WHEN "010",   ---- neg(X) ----
                const2 WHEN "011",   ---- Y + 2 ----
                const2 WHEN "100",   ---- Y - 2 ----
                zeros  WHEN OTHERS;
	---
	WITH alufn SELECT
        B_in <= Y     WHEN "000",    ---- Y + X ----
                Y     WHEN "001",    ---- Y - X ----
                zeros WHEN "010",    ---- neg(X) => 0 - X  ----
                Y     WHEN "011",    ---- Y + 2 ----
                Y     WHEN "100",    ---- Y - 2 ----
                zeros WHEN OTHERS;
	---
    WITH alufn SELECT
        sub_flag <= '0' WHEN "000",  ---- addition ----
                    '1' WHEN "001",  ---- subtraction ----
                    '1' WHEN "010",  ---- negation (0 - X) ----
                    '0' WHEN "011",  ---- addition ----
                    '1' WHEN "100",  ---- subtraction ----
                    '0' WHEN OTHERS;
	---
	GEN_XOR: FOR i IN 0 TO n-1 GENERATE
        A_mod(i) <= A_in(i) XOR sub_flag;
    END GENERATE GEN_XOR;
	---
	
    FA_0: FA PORT MAP (
			xi   => A_mod(0),
			yi   => B_in(0),
			cin  => sub_flag,
			s    => the_res(0),
			cout => carry(0)
);
   
	
    
    GEN_FA: FOR i IN 1 TO n-1 GENERATE
		FA_i: FA PORT MAP (
			xi   => A_mod(i),
			yi   => B_in(i),
			cin  => carry(i-1),
			s    => the_res(i),
			cout => carry(i)
		);
	END GENERATE GEN_FA;
  
	
    cout <= carry(n-1);
    with alufn SELECT
        res <= the_res when "000"|"001"|"010"|"011"|"100",
                merge_res when "101",
                zeros when OTHERS;
	
end Structural;