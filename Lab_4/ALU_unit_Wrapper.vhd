library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.aux_package.all;

entity ALU_unit_Wrapper is
    generic (
        n : integer := 8;
        k : integer := 3;   -- k=log2(n)
        m : integer := 4    -- m=2^(k-1)
    );
    port (
        CLK      : in  std_logic;
        RST      : in  std_logic;
        X_i      : in  std_logic_vector(n-1 downto 0);
        Y_i      : in  std_logic_vector(n-1 downto 0);
        ALUFN_i  : in  std_logic_vector(4 downto 0);
        ALUout_o : out std_logic_vector(n-1 downto 0);
        Nflag_o  : out std_logic;
        Cflag_o  : out std_logic;
        Zflag_o  : out std_logic;
        Vflag_o  : out std_logic
    );
end ALU_unit_Wrapper;

architecture behavior of ALU_unit_Wrapper is

    signal X_reg     : std_logic_vector(n-1 downto 0);
    signal Y_reg     : std_logic_vector(n-1 downto 0);
    signal ALUFN_reg : std_logic_vector(4 downto 0);

    signal ALUout_alu : std_logic_vector(n-1 downto 0);
    signal Nflag_alu  : std_logic;
    signal Cflag_alu  : std_logic;
    signal Zflag_alu  : std_logic;
    signal Vflag_alu  : std_logic;

begin

    process(CLK, RST)
    begin
        if RST = '1' then
            X_reg     <= (others => '0');
            Y_reg     <= (others => '0');
            ALUFN_reg <= (others => '0');
            
            ALUout_o  <= (others => '0');
            Nflag_o   <= '0';
            Cflag_o   <= '0';
            Zflag_o   <= '0';
            Vflag_o   <= '0';
            
        elsif rising_edge(CLK) then
            X_reg     <= X_i;
            Y_reg     <= Y_i;
            ALUFN_reg <= ALUFN_i;
            
            ALUout_o  <= ALUout_alu;
            Nflag_o   <= Nflag_alu;
            Cflag_o   <= Cflag_alu;
            Zflag_o   <= Zflag_alu;
            Vflag_o   <= Vflag_alu;
        end if;
    end process;

    ALU_inst: alu_unit
        generic map (
            n => n,
            k => k
        )
        port map (
            X_i      => X_reg,
            Y_i      => Y_reg,
            ALUFN_i  => ALUFN_reg,
            ALUout_o => ALUout_alu,
            Nflag_o  => Nflag_alu,
            Cflag_o  => Cflag_alu,
            Zflag_o  => Zflag_alu,
            Vflag_o  => Vflag_alu
        );

end behavior;