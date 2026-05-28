library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--------------------------------------------------------
package aux_package is

	component top is
		GENERIC (	n : INTEGER := 8;
					k : integer := 3 );
		PORT (  Y_i,X_i: IN STD_LOGIC_VECTOR (n-1 DOWNTO 0);
				ALUFN_i : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
				ALUout_o: OUT STD_LOGIC_VECTOR(n-1 downto 0);
				Nflag_o,Cflag_o,Zflag_o,Vflag_o: OUT STD_LOGIC );
	end component;

---------------------------------------------------------
	component FA is
		PORT (	xi, yi, cin: IN std_logic;
			    s, cout: OUT std_logic);
	end component;

---------------------------------------------------------
	component adder_subtractor is
		GENERIC ( n : INTEGER := 8 );
		PORT (
			X     : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
			Y     : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
			alufn : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
			res   : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0);
			cout  : OUT STD_LOGIC);
	end component;

---------------------------------------------------------
	component Shifter is
		GENERIC ( n : INTEGER := 8;
				  k : INTEGER := 3);
		port (	y     : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
				x     : IN  STD_LOGIC_VECTOR(k-1 DOWNTO 0);
				alufn : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
				res   : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0);
				cout  : OUT STD_LOGIC );
	end component;

---------------------------------------------------------
	component Logic is
		generic (n : integer := 8);
		port (	x, y  : in std_logic_vector (n-1 downto 0);
				alufn : in std_logic_vector (2 downto 0);
				z     : out std_logic_vector (n-1 downto 0) );
	end component;

----------------------------------------------------------
	component alu_unit is
		generic ( n : INTEGER := 8;
				  k : INTEGER := 3 );
		port (  Y_i      : in  std_logic_vector (n-1 downto 0);
				X_i      : in  std_logic_vector (n-1 downto 0);
				ALUFN_i  : in  std_logic_vector (4 downto 0);
				ALUout_o : out std_logic_vector (n-1 downto 0);
				Nflag_o  : out std_logic;
				Cflag_o  : out std_logic;
				Zflag_o  : out std_logic;
				Vflag_o  : out std_logic );
	end component;

----------------------------------------------------------
	component bit_Timer is
		generic ( n : integer := 16 );
		port (
			clk       : in  std_logic;
			rst       : in  std_logic;
			ena       : in  std_logic;
			EQUY      : in  std_logic;
			timer_val : out std_logic_vector(n-1 downto 0)
		);
	end component;

----------------------------------------------------------
	component digit_circ is
		GENERIC ( n : INTEGER := 16 );
		PORT (
			y_i        : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
			x_i        : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
			timer_i    : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
			ena_i      : in  STD_LOGIC;
			clk_i      : in  std_logic;
			pwm_mode_i : in  std_logic_vector(1 downto 0);
			pwm_out    : out std_logic;
			equy_out   : out std_logic
		);
	end component;

----------------------------------------------------------
	component pwm_output_unit is
		GENERIC ( n : INTEGER := 16 );
		PORT (
			x_i      : in  std_logic_vector (n-1 downto 0);
			y_i      : in  std_logic_vector (n-1 downto 0);
			ALUFN_i  : in  std_logic_vector(1 downto 0);
			ena_i    : in  std_logic;
			clk_i    : in  std_logic;
			rst_i    : in  std_logic;
			pwmout_o : out std_logic
		);
	end component;

----------------------------------------------------------
	component sync_digital_circ is
		generic ( n : INTEGER := 16 );
		port (
			Y_i     : in  std_logic_vector (n-1 downto 0);
			X_i     : in  std_logic_vector (n-1 downto 0);
			clk_i   : in  std_logic;
			ena_i   : in  std_logic;
			rst_i   : in  std_logic;
			ALUFN_i : in  std_logic_vector (4 downto 0);
			pwm_o   : out std_logic
		);
	end component;

----------------------------------------------------------
	component PLL is
		port (
			areset : in  std_logic := '0';
			inclk0 : in  std_logic := '0';
			c0     : out std_logic;
			locked : out std_logic
		);
	end component;

----------------------------------------------------------
	component digital_system is
		generic ( n : integer := 16;
				  k : integer := 4 );
		port (
			Y_i      : in  std_logic_vector (n-1 downto 0);
			X_i      : in  std_logic_vector (n-1 downto 0);
			clk_i    : in  std_logic;
			ena_i    : in  std_logic;
			rst_i    : in  std_logic;
			ALUFN_i  : in  std_logic_vector (4 downto 0);
			ALUout_o : out std_logic_vector (7 downto 0);
			Nflag_o  : out std_logic;
			Cflag_o  : out std_logic;
			Zflag_o  : out std_logic;
			Vflag_o  : out std_logic;
			pwm_o    : out std_logic
		);
	end component;

----------------------------------------------------------
	-- function DECLARATION only (body is in package body below)
	function hex_to_7seg (nibble : std_logic_vector(3 downto 0))
			 return std_logic_vector;

end aux_package;

----------------------------------------------------------
-- Package body: contains function implementations
----------------------------------------------------------
package body aux_package is

	function hex_to_7seg (nibble : std_logic_vector(3 downto 0))
			 return std_logic_vector is
	begin
		case nibble is
			when x"0"   => return "1000000"; -- 0
			when x"1"   => return "1111001"; -- 1
			when x"2"   => return "0100100"; -- 2
			when x"3"   => return "0110000"; -- 3
			when x"4"   => return "0011001"; -- 4
			when x"5"   => return "0010010"; -- 5
			when x"6"   => return "0000010"; -- 6
			when x"7"   => return "1111000"; -- 7
			when x"8"   => return "0000000"; -- 8
			when x"9"   => return "0010000"; -- 9
			when x"A"   => return "0001000"; -- A
			when x"B"   => return "0000011"; -- b
			when x"C"   => return "1000110"; -- C
			when x"D"   => return "0100001"; -- d
			when x"E"   => return "0000110"; -- E
			when x"F"   => return "0001110"; -- F
			when others => return "1111111"; -- all OFF
		end case;
	end function;

end aux_package;
