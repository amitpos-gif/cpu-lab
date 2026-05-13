library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.aux_package.all;

------------------------------------------------------------
entity tb_ex5_check is
end entity tb_ex5_check;
------------------------------------------------------------

architecture sim of tb_ex5_check is

    constant Dwidth     : integer := 16;
    constant Awidth     : integer := 6;
    constant DEPT       : integer := 64;
    constant CLK_PERIOD : time    := 20 ns;
    constant RUN_TIMEOUT: time    := 50 us;

    type word_array_t is array (natural range <>) of std_logic_vector(Dwidth-1 downto 0);

    ----------------------------------------------------------------
    -- ITCM content
    ----------------------------------------------------------------
    constant ITCM_INIT : word_array_t(0 to 24) := (
        0  => X"C100",   -- mov r1,arr1
        1  => X"C20E",   -- mov r2,arr2
        2  => X"C31C",   -- mov r3,res
        3  => X"C400",   -- mov r4,0
        4  => X"C501",   -- mov r5,1
        5  => X"C60E",   -- mov r6,14

        6  => X"D710",   -- ld r7,0(r1)
        7  => X"D820",   -- ld r8,0(r2)

        8  => X"2945",   -- and r9,r4,r5
        9  => X"1B95",   -- sub r11,r9,r5
        10 => X"9003",   -- jlo 3

        11 => X"0A78",   -- add r10,r7,r8
        12 => X"EA30",   -- st r10,0(r3)
        13 => X"7002",   -- jmp 2

        14 => X"1A78",   -- sub r10,r7,r8
        15 => X"EA30",   -- st r10,0(r3)

        16 => X"0115",   -- add r1,r1,r5
        17 => X"0225",   -- add r2,r2,r5
        18 => X"0335",   -- add r3,r3,r5
        19 => X"0445",   -- add r4,r4,r5

        20 => X"1A46",   -- sub r10,r4,r6
        21 => X"90F0",   -- jlo -16

        22 => X"F000",   -- done
        23 => X"0000",   -- nop
        24 => X"70FE"    -- jmp -2
    );

    ----------------------------------------------------------------
    -- DTCM initial content
    ----------------------------------------------------------------
    constant DTCM_INIT : word_array_t(0 to 41) := (
        -- arr1
        0  => X"003F",
        1  => X"021E",
        2  => X"00F5",
        3  => X"00BE",
        4  => X"005B",
        5  => X"0056",
        6  => X"004E",
        7  => X"0040",
        8  => X"0053",
        9  => X"0010",
        10 => X"0018",
        11 => X"003E",
        12 => X"004F",
        13 => X"0013",

        -- arr2
        14 => X"000D",
        15 => X"0138",
        16 => X"008D",
        17 => X"00A0",
        18 => X"005C",
        19 => X"0058",
        20 => X"0047",
        21 => X"003F",
        22 => X"003B",
        23 => X"000E",
        24 => X"002B",
        25 => X"000C",
        26 => X"0047",
        27 => X"005A",

        -- res
        28 => X"0000",
        29 => X"0000",
        30 => X"0000",
        31 => X"0000",
        32 => X"0000",
        33 => X"0000",
        34 => X"0000",
        35 => X"0000",
        36 => X"0000",
        37 => X"0000",
        38 => X"0000",
        39 => X"0000",
        40 => X"0000",
        41 => X"0000"
    );

    ----------------------------------------------------------------
    -- Expected res content
    ----------------------------------------------------------------
    constant RES_EXPECTED : word_array_t(0 to 13) := (
        0  => X"0032",
        1  => X"0356",
        2  => X"0068",
        3  => X"015E",
        4  => X"FFFF",
        5  => X"00AE",
        6  => X"0007",
        7  => X"007F",
        8  => X"0018",
        9  => X"001E",
        10 => X"FFED",
        11 => X"004A",
        12 => X"0008",
        13 => X"006D"
    );

    component top is
        generic (
            Dwidth : integer := 16;
            Awidth : integer := 6;
            dept   : integer := 64
        );
        port (
            clk              : in  std_logic;
            rst              : in  std_logic;
            ena              : in  std_logic;
            TBactive         : in  std_logic;

            ITCM_tb_wr       : in  std_logic;
            ITCM_tb_in       : in  std_logic_vector(Dwidth-1 downto 0);
            ITCM_tb_addr_in  : in  std_logic_vector(Awidth-1 downto 0);

            DTCM_tb_wr       : in  std_logic;
            DTCM_tb_in       : in  std_logic_vector(Dwidth-1 downto 0);
            DTCM_tb_out      : out std_logic_vector(Dwidth-1 downto 0);
            DTCM_tb_addr_in  : in  std_logic_vector(Awidth-1 downto 0);
            DTCM_tb_addr_out : in  std_logic_vector(Awidth-1 downto 0);

            done             : out std_logic
        );
    end component;

    signal clk              : std_logic := '0';
    signal rst              : std_logic := '1';
    signal ena              : std_logic := '0';

    signal TBactive         : std_logic := '1';
    signal ITCM_tb_wr       : std_logic := '0';
    signal ITCM_tb_in       : std_logic_vector(Dwidth-1 downto 0) := (others => '0');
    signal ITCM_tb_addr_in  : std_logic_vector(Awidth-1 downto 0) := (others => '0');

    signal DTCM_tb_wr       : std_logic := '0';
    signal DTCM_tb_in       : std_logic_vector(Dwidth-1 downto 0) := (others => '0');
    signal DTCM_tb_out      : std_logic_vector(Dwidth-1 downto 0);
    signal DTCM_tb_addr_in  : std_logic_vector(Awidth-1 downto 0) := (others => '0');
    signal DTCM_tb_addr_out : std_logic_vector(Awidth-1 downto 0) := (others => '0');

    signal done             : std_logic;
    signal sim_done         : boolean := false;

begin

    DUT : top
        generic map (
            Dwidth => Dwidth,
            Awidth => Awidth,
            dept   => DEPT
        )
        port map (
            clk              => clk,
            rst              => rst,
            ena              => ena,
            TBactive         => TBactive,

            ITCM_tb_wr       => ITCM_tb_wr,
            ITCM_tb_in       => ITCM_tb_in,
            ITCM_tb_addr_in  => ITCM_tb_addr_in,

            DTCM_tb_wr       => DTCM_tb_wr,
            DTCM_tb_in       => DTCM_tb_in,
            DTCM_tb_out      => DTCM_tb_out,
            DTCM_tb_addr_in  => DTCM_tb_addr_in,
            DTCM_tb_addr_out => DTCM_tb_addr_out,

            done             => done
        );

    ----------------------------------------------------------------
    -- Clock
    ----------------------------------------------------------------
    CLK_GEN : process
    begin
        while not sim_done loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process CLK_GEN;

    ----------------------------------------------------------------
    -- Stimulus
    ----------------------------------------------------------------
    STIM : process
    begin

        ----------------------------------------------------------------
        -- Reset and safe defaults
        ----------------------------------------------------------------
        rst        <= '1';
        ena        <= '0';
        TBactive   <= '1';

        ITCM_tb_wr <= '0';
        DTCM_tb_wr <= '0';

        wait until rising_edge(clk);
        wait until rising_edge(clk);

        ----------------------------------------------------------------
        -- Load ITCM
        ----------------------------------------------------------------
        wait until falling_edge(clk);
        ITCM_tb_wr <= '1';

        for i in ITCM_INIT'range loop
            ITCM_tb_addr_in <= conv_std_logic_vector(i, Awidth);
            ITCM_tb_in      <= ITCM_INIT(i);

            wait until rising_edge(clk);
            wait until falling_edge(clk);
        end loop;

        ITCM_tb_wr <= '0';
        report "TB: ITCM loaded" severity note;

        ----------------------------------------------------------------
        -- Load DTCM
        ----------------------------------------------------------------
        DTCM_tb_wr <= '1';

        for i in DTCM_INIT'range loop
            DTCM_tb_addr_in <= conv_std_logic_vector(i, Awidth);
            DTCM_tb_in      <= DTCM_INIT(i);

            wait until rising_edge(clk);
            wait until falling_edge(clk);
        end loop;

        DTCM_tb_wr <= '0';
        report "TB: DTCM loaded" severity note;

        ----------------------------------------------------------------
        -- Run CPU
        ----------------------------------------------------------------
        TBactive <= '0';
        rst      <= '0';
        ena      <= '1';

        wait until rising_edge(clk);
        report "TB: CPU running" severity note;

        wait until (done = '1') for RUN_TIMEOUT;

        assert done = '1'
            report "TB ERROR: done was not asserted"
            severity failure;

        report "TB: done asserted" severity note;

        ----------------------------------------------------------------
        -- Check only res[0..13], addresses 28..41
        ----------------------------------------------------------------
        ena      <= '0';
        TBactive <= '1';

        wait for 5 ns;

        for i in 0 to 13 loop
            DTCM_tb_addr_out <= conv_std_logic_vector(28 + i, Awidth);

            -- DTCM read should settle here
            wait for 5 ns;

            assert DTCM_tb_out = RES_EXPECTED(i)
                report "RES mismatch at index " & integer'image(i)
                severity error;
        end loop;

        report "TB: EX5 result check finished successfully" severity note;

        sim_done <= true;
        wait for 2 * CLK_PERIOD;

        assert false report "End of simulation" severity failure;
        wait;

    end process STIM;

end architecture sim;