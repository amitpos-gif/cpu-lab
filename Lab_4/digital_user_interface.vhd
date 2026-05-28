LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE work.aux_package.all;
------------------------------------------
entity digital_user_interface is
    generic ( n : INTEGER := 16;
			  k : INTEGER := 4 );
    port (
        CLOCK_50 : in  std_logic;
        SW       : in  std_logic_vector(9 downto 0);
        KEY      : in  std_logic_vector(3 downto 0);

        LEDR     : out std_logic_vector(9 downto 0);
        HEX0    : out std_logic_vector(6 downto 0);  -- was (3 downto 0)
        HEX1    : out std_logic_vector(6 downto 0);
        HEX2    : out std_logic_vector(6 downto 0);
        HEX3    : out std_logic_vector(6 downto 0);
        HEX4    : out std_logic_vector(6 downto 0);
        HEX5    : out std_logic_vector(6 downto 0);

        pwm_out     : out std_logic
    );
end entity;
-------------------------------------------------------------------
architecture rtl of digital_user_interface is
  
    --pll wire
    signal clk_pll  : std_logic;
    signal pll_lock : std_logic;

    --internal regs
    signal reg_y_low  : std_logic_vector(7 downto 0) := (others => '0');
    signal reg_y_high : std_logic_vector(7 downto 0) := (others => '0');
    signal reg_x_low  : std_logic_vector(7 downto 0) := (others => '0');
    signal reg_x_high : std_logic_vector(7 downto 0) := (others => '0');
    signal reg_alufn  : std_logic_vector(7 downto 0) := (others => '0');
    signal hex10_data : std_logic_vector(7 downto 0);
    signal hex32_data : std_logic_vector(7 downto 0);
    signal rst_i      : std_logic;
    signal ena_i      : std_logic;
    --  ALU comp
    signal y_i        : std_logic_vector(n-1 downto 0);
    signal x_i        : std_logic_vector(n-1 downto 0);
    signal alufn_alu    : std_logic_vector(4 downto 0);
    signal alu_out      : std_logic_vector(7 downto 0);

    -- flags
    signal n_flag       : std_logic;
    signal c_flag       : std_logic;
    signal z_flag       : std_logic;
    signal v_flag       : std_logic;
    --KEYS
    signal key0_pressed : std_logic;
    signal key1_pressed : std_logic;
    signal key2_pressed : std_logic;
    signal key3_pressed : std_logic;

    -- PWM 
--the mode is form ALUfn in digital sytem file.
        --KEYS
        -- pressed     = '0' at the physical KEY input
        -- not pressed = '1' at the physical KEY input
        -- Internally, keyX_pressed = '1' means the button is pressed.
    begin
            key0_pressed <= not KEY(0);
            key1_pressed <= not KEY(1);
            key2_pressed <= not KEY(2);
            key3_pressed <= not KEY(3);  
    
    process(sw,key0_pressed,key1_pressed,key2_pressed,key3_pressed) --this process is responsible for the lines outside of digit system
        begin

        --term on key 0 when pushed the button is '0'
        if key0_pressed = '1' and SW(9) = '0' then
            reg_y_low <= SW(7 downto 0);
        elsif key0_pressed = '1' and SW(9) = '1' then
            reg_y_high <= SW(7 downto 0);
        end if;
        --term on key 1
        if key1_pressed = '1' and SW(9) = '0' then
            reg_x_low <= SW(7 downto 0);
        elsif key1_pressed = '1' and SW(9) = '1' then
            reg_x_high <= SW(7 downto 0);
        end if;
        --term on key 2
        if key2_pressed = '1' then
            reg_alufn <= SW(7 downto 0);
        end if;
        
    end process;
   -- HEX raw 7-bit values
    hex10_data <= reg_x_low when SW(9) = '0' else reg_x_high;
    hex32_data <= reg_y_low when SW(9) = '0' else reg_y_high;

    HEX0 <= hex_to_7seg(hex10_data(3 downto 0));
    HEX1 <= hex_to_7seg(hex10_data(7 downto 4));

    HEX2 <= hex_to_7seg(hex32_data(3 downto 0));
    HEX3 <= hex_to_7seg(hex32_data(7 downto 4));

        
    --from here start to set the digital system wires
    alufn_alu <=reg_alufn(4 downto 0);
    y_i <= reg_y_high & reg_y_low;
    x_i <= reg_x_high & reg_x_low;
    ena_i <= '1' when sw(8)  = '1' else '0';
    rst_i <= '1' when key3_pressed = '1' else '0';
        --PLL wires
    U_PLL : PLL
    port map (
        areset => '0', --check
        inclk0 => CLOCK_50,
        c0     => clk_pll,
        locked => pll_lock
    );
    --ALU wires

    U_DIGITAL_SYSTEM : digital_system
        generic map (
            n => n,
            k => k
        )
        port map (
            Y_i      => y_i,
            X_i      => x_i,
            clk_i    => clk_pll,
            ena_i    => ena_i,
            rst_i    => rst_i,
            ALUFN_i  => alufn_alu,

            ALUout_o => alu_out,
            Nflag_o  => n_flag,
            Cflag_o  => c_flag,
            Zflag_o  => z_flag,
            Vflag_o  => v_flag,

            pwm_o    => pwm_out
        );    
            -- ALU result to HEX5-HEX4
    HEX4 <= hex_to_7seg(alu_out(3 downto 0));
    HEX5 <= hex_to_7seg(alu_out(7 downto 4));
    -- LEDs for ALUFN and flags
    LEDR(9 downto 5) <= reg_alufn(4 downto 0);
    LEDR(4) <= '0'; -- off this led
    -- only show flags when not in PWM mode (ALUFN[4:3] != "00")
    LEDR(3) <= n_flag when alufn_alu(4 downto 3) /= "00" else '0';
    LEDR(2) <= c_flag when alufn_alu(4 downto 3) /= "00" else '0';
    LEDR(1) <= z_flag when alufn_alu(4 downto 3) /= "00" else '0';
    LEDR(0) <= v_flag when alufn_alu(4 downto 3) /= "00" else '0';
end architecture;

