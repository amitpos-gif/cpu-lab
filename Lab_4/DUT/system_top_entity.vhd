library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE work.aux_package.all;
------------------------------------------
entity system_top_entity is
    generic ( n : INTEGER := 16;
              k : INTEGER := 4 );
    port (  Y_i      : in std_logic_vector (n-1 downto 0);
            X_i      : in std_logic_vector (n-1 downto 0);
            clk_i    : in std_logic;
            ena_i    : in std_logic;
            rst_i    : in std_logic;
            ALUFN_i  : in std_logic_vector (4 downto 0);
            ALUout_o : out std_logic_vector (n-1 downto 0);
            Nflag_o  : out std_logic;
            Cflag_o  : out std_logic;
            Zflag_o  : out std_logic;
            Vflag_o  : out std_logic;
            pwm_o    : out std_logic
            ); 

end system_top_entity;
------------------------------------------
architecture struct of system_top_entity is
begin
    SYNC_DIGITAL_CIRC_INST : sync_digital_circ
        GENERIC MAP (n => n)
        PORT MAP (
            Y_i => Y_i,
            X_i => X_i,
            clk_i => clk_i,
            ena_i => ena_i,
            rst_i => rst_i,
            ALUFN_i => ALUFN_i,
            pwm_o => pwm_o
        );

    ALU_UNIT_INST : alu_unit
        GENERIC MAP (n => n, k => k)
        PORT MAP (
            x_i => X_i,
            y_i => Y_i,
            ALUFN_i => ALUFN_i,
            aluout_o => ALUout_o,
            Nflag_o => Nflag_o,
            Cflag_o => Cflag_o,
            Zflag_o => Zflag_o,
            Vflag_o => Vflag_o
        );

end struct;
    
