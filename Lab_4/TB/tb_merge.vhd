library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity tb_merge_alu is
end entity;

architecture sim of tb_merge_alu is

    constant n : integer := 8;
    constant k : integer := 3;

    signal Y_i      : std_logic_vector(n-1 downto 0) := (others => '0');
    signal X_i      : std_logic_vector(n-1 downto 0) := (others => '0');
    signal ALUFN_i  : std_logic_vector(4 downto 0) := (others => '0');
    signal ALUout_o : std_logic_vector(n-1 downto 0);

    signal Nflag_o  : std_logic;
    signal Cflag_o  : std_logic;
    signal Zflag_o  : std_logic;
    signal Vflag_o  : std_logic;

begin

    --------------------------------------------------------------------
    -- DUT: ALU
    --------------------------------------------------------------------
    DUT : entity work.alu_unit
        generic map (
            n => n,
            k => k
        )
        port map (
            Y_i      => Y_i,
            X_i      => X_i,
            ALUFN_i  => ALUFN_i,
            ALUout_o => ALUout_o,
            Nflag_o  => Nflag_o,
            Cflag_o  => Cflag_o,
            Zflag_o  => Zflag_o,
            Vflag_o  => Vflag_o
        );

    --------------------------------------------------------------------
    -- Stimulus
    --------------------------------------------------------------------
    stim_proc : process
    begin

        report "Starting MERGE instruction test";

        ----------------------------------------------------------------
        -- Test 1:
        -- Y = AB, X = CD
        -- Expected:
        -- Y(3 downto 0) = B
        -- X(3 downto 0) = D
        -- Result = BD
        ----------------------------------------------------------------
        Y_i <= x"AB";
        X_i <= x"CD";
        ALUFN_i <= "01101";
        wait for 20 ns;

        assert ALUout_o = x"BD"
            report "ERROR Test 1: merge(AB,CD) should be BD"
            severity error;

        ----------------------------------------------------------------
        -- Test 2:
        -- Y = 12, X = 34
        -- Expected:
        -- Y low nibble = 2
        -- X low nibble = 4
        -- Result = 24
        ----------------------------------------------------------------
        Y_i <= x"12";
        X_i <= x"34";
        ALUFN_i <= "01101";
        wait for 20 ns;

        assert ALUout_o = x"24"
            report "ERROR Test 2: merge(12,34) should be 24"
            severity error;

        ----------------------------------------------------------------
        -- Test 3:
        -- Y = F0, X = 0F
        -- Expected:
        -- Y low nibble = 0
        -- X low nibble = F
        -- Result = 0F
        ----------------------------------------------------------------
        Y_i <= x"F0";
        X_i <= x"0F";
        ALUFN_i <= "01101";
        wait for 20 ns;

        assert ALUout_o = x"0F"
            report "ERROR Test 3: merge(F0,0F) should be 0F"
            severity error;

        ----------------------------------------------------------------
        -- Test 4:
        -- Y = 5A, X = C3
        -- Expected:
        -- Y low nibble = A
        -- X low nibble = 3
        -- Result = A3
        ----------------------------------------------------------------
        Y_i <= x"5A";
        X_i <= x"C3";
        ALUFN_i <= "01101";
        wait for 20 ns;

        assert ALUout_o = x"A3"
            report "ERROR Test 4: merge(5A,C3) should be A3"
            severity error;

        report "MERGE instruction test finished successfully";
        wait;

    end process;

end architecture;