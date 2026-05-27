library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.aux_package.all;
----------------------------------------------------
entity tb_control_lab3 is
end entity tb_control_lab3;
-----------------------------------------------------
architecture sim of tb_control_lab3 is

    --clk,rst,ena,done - green path for TB
    signal clk : std_logic := '0';
    signal rst : std_logic := '0'; 
    signal ena : std_logic := '0';
    signal done: std_logic;
    
    --control output signals
     signal DTCM_wr      :  std_logic;   -- DTCM write enable
	 signal Cin          :  std_logic;   -- REG_C    ← ALU_result; flags ← ALU_flags
	 signal Cout         :  std_logic;   -- REG_C          → BUS_wire
	 signal DTCM_addr_in :  std_logic;   -- DTCM_addr_reg ← BUS_wire[5:0]
	 signal DTCM_out     :  std_logic;   -- DTCM_data      → BUS_wire
	 signal ALUFN        :  std_logic_vector(3 downto 0);
  	 signal Ain          :  std_logic;                        -- REG_A    ← BUS_wire  AND selects RFaddr_rd=rb
	 signal RFin         :  std_logic;   
  	 signal RFout        :  std_logic;    
     signal RFaddr_rd	 :  std_logic_vector(1 downto 0);       --00 = off  , 01 = rc  , 10 = rb --
	 signal RFaddr_wr	 :  std_logic;                          -- 0 = off  , 1 = wr from the data is ra --
     signal IRin         :  std_logic;                        -- ITCM_data -> to IR_reg
     signal PCin         :  std_logic;                        -- PC_next -> to PC_reg
     signal PCsel        :  std_logic_vector(1 downto 0);    -- '00'= "000000"  , '01'=PC+1+offset (jump target)  , "10" = PC+1 --
     signal Imm1_in      :  std_logic;                        -- SignExt(IR[7:0])→ BUS_wire  (8-bit imm)
     signal Imm2_in      :  std_logic;                        -- SignExt(IR[3:0])→ BUS_wire  (4-bit imm)
     


     --input's from the datapath ------------------------- default value is '0' for input
	 signal  mov_s :  std_logic :='0';   -- OPC = "1100"  move immediate
     signal done_s :  std_logic :='0';   -- OPC = "1111"  program done
	 signal and_s  :  std_logic :='0';   -- OPC = "0010"  bitwise AND
     signal or_s   :  std_logic :='0';   -- OPC = "0011"  bitwise OR
     signal xor_s  :  std_logic :='0';   -- OPC = "0100"  bitwise XOR
	 signal jnc_s  :  std_logic :='0';   -- OPC = "1001"  jump if no carry
	 signal jc_s   :  std_logic :='0';   -- OPC = "1000"  jump if carry
	 signal jmp_s  :  std_logic :='0';   -- OPC = "0111"  unconditional jump
	 signal sub_s  :  std_logic :='0';   -- OPC = "0001"  subtract
     signal add_s  :  std_logic :='0';   -- OPC = "0000"  add
     signal ld_s   :  std_logic :='0';   -- OPC = "1101"  load
     signal st_s   :  std_logic :='0';   -- OPC = "1110"  store
    -- Status inputs from Datapath — ALU flags --
     signal Cflag  :  std_logic :='0';   -- carry  flag
     signal Zflag  :  std_logic :='0';   -- zero   flag
     signal Nflag  :  std_logic :='0';   -- negative flag

begin
   DUT : Control
    port map (
        clk          => clk,
        rst          => rst,
        ena          => ena,

        -- Control output signals
        DTCM_wr      => DTCM_wr,
        Cin          => Cin,
        Cout         => Cout,
        DTCM_addr_in => DTCM_addr_in,
        DTCM_out     => DTCM_out,
        ALUFN        => ALUFN,
        Ain          => Ain,
        RFin         => RFin,
        RFout        => RFout,
        RFaddr_rd    => RFaddr_rd,
        RFaddr_wr    => RFaddr_wr,
        IRin         => IRin,
        PCin         => PCin,
        PCsel        => PCsel,
        Imm1_in      => Imm1_in,
        Imm2_in      => Imm2_in,
        done         => done,

        -- Inputs from Datapath
        mov_s        => mov_s,
        done_s       => done_s,
        and_s        => and_s,
        or_s         => or_s,
        xor_s        => xor_s,
        jnc_s        => jnc_s,
        jc_s         => jc_s,
        jmp_s        => jmp_s,
        sub_s        => sub_s,
        add_s        => add_s,
        ld_s         => ld_s,
        st_s         => st_s,

        -- Status inputs from Datapath
        Cflag        => Cflag,
        Zflag        => Zflag,
        Nflag        => Nflag
    );
    --clk genration 20 ns period
    clk <= not clk after 10 ns;
     
STIM : process

    procedure clear_all_instr is
    begin
        mov_s  <= '0';
        done_s <= '0';
        and_s  <= '0';
        or_s   <= '0';
        xor_s  <= '0';
        jnc_s  <= '0';
        jc_s   <= '0';
        jmp_s  <= '0';
        sub_s  <= '0';
        add_s  <= '0';
        ld_s   <= '0';
        st_s   <= '0';
    end procedure;


    procedure test_rtype(    --    test_rtype(add_s, "ADD", "0000");

        signal op_s           : out std_logic;
        constant op_name      : in string;
        constant expected_alu : in std_logic_vector(3 downto 0)
    ) is
    begin
        clear_all_instr;

        ----------------------------------------------------------------
        -- step 1: FETCH
        -- FSM is already in FETCH here
        ----------------------------------------------------------------
        wait for 1 ns;

        assert IRin = '1'
            report op_name & " FETCH failed: IRin should be 1"
            severity error;

        assert PCsel = "10"
            report op_name & " FETCH failed: PCsel should be 10"
            severity error;

        assert PCin = '0'
            report op_name & " FETCH failed: PCin should be 0 in FETCH"
            severity error;


        ----------------------------------------------------------------
        -- step 2: DECODE1
        ----------------------------------------------------------------
        op_s <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        assert RFaddr_rd = "01"
            report op_name & " DECODE1 failed: RFaddr_rd should be 01"
            severity error;

        assert RFout = '1'
            report op_name & " DECODE1 failed: RFout should be 1"
            severity error;

        assert Ain = '1'
            report op_name & " DECODE1 failed: Ain should be 1"
            severity error;

        assert RFin = '0'
            report op_name & " DECODE1 failed: RFin should be 0"
            severity error;

        assert DTCM_wr = '0'
            report op_name & " DECODE1 failed: DTCM_wr should be 0"
            severity error;


        ----------------------------------------------------------------
        -- step 3: DECODE2 + EXECUTE    
        ----------------------------------------------------------------
        wait until rising_edge(clk);
        wait for 1 ns;

        assert ALUFN = expected_alu
            report op_name & " EX failed: wrong ALUFN"
            severity error;

        assert RFaddr_rd = "10"
            report op_name & " EX failed: RFaddr_rd should be 10"
            severity error;

        assert RFout = '1'
            report op_name & " EX failed: RFout should be 1"
            severity error;

        assert Cin = '1'
            report op_name & " EX failed: Cin should be 1"
            severity error;

        assert RFin = '0'
            report op_name & " EX failed: RFin should be 0"
            severity error;

        assert DTCM_wr = '0'
            report op_name & " EX failed: DTCM_wr should be 0"
            severity error;


        ----------------------------------------------------------------
        -- step 4: WRITEBACK
        ----------------------------------------------------------------
        wait until rising_edge(clk);
        wait for 1 ns;

        assert Cout = '1'
            report op_name & " WB failed: Cout should be 1"
            severity error;

        assert RFin = '1'
            report op_name & " WB failed: RFin should be 1"
            severity error;

        assert RFaddr_wr = '1'
            report op_name & " WB failed: RFaddr_wr should be 1"
            severity error;

        assert PCin = '1'
            report op_name & " WB failed: PCin should be 1"
            severity error;

        assert DTCM_wr = '0'
            report op_name & " WB failed: DTCM_wr should be 0"
            severity error;

        -- finish current instruction
        op_s <= '0';

        -- return to FETCH for next instruction
        wait until rising_edge(clk);
        wait for 1 ns;

    end procedure;


    procedure test_jtype(
        signal op_s              : out std_logic;
        constant op_name         : in string;
        constant cflag_value     : in std_logic;
        constant expected_pcsel  : in std_logic_vector(1 downto 0)
    ) is
    begin
        clear_all_instr;

        ----------------------------------------------------------------
        -- step 1: FETCH
        ----------------------------------------------------------------
        wait for 1 ns;

        assert IRin = '1'
            report op_name & " FETCH failed: IRin should be 1"
            severity error;

        assert PCsel = "10"
            report op_name & " FETCH failed: PCsel should be 10"
            severity error;


        ----------------------------------------------------------------
        -- step 2: DECODE1 / JUMP decision
        ----------------------------------------------------------------
        Cflag <= cflag_value;
        op_s  <= '1';

        wait until rising_edge(clk); --wait for the current state
        wait for 1 ns;

        assert PCin = '1'
            report op_name & " JUMP failed: PCin should be 1"
            severity error;

        assert PCsel = expected_pcsel
            report op_name & " JUMP failed: wrong PCsel"
            severity error;

        assert DTCM_wr = '0'
            report op_name & " JUMP failed: DTCM_wr should be 0"
            severity error;

        assert RFin = '0'
            report op_name & " JUMP failed: RFin should be 0"
            severity error;

        op_s  <= '0';
        Cflag <= '0';

        -- return to FETCH for next instruction
        wait until rising_edge(clk);
        wait for 1 ns;

    end procedure;


    procedure test_ld(
        signal op_s      : out std_logic;
        constant op_name : in string
    ) is
    begin
        clear_all_instr;

        ----------------------------------------------------------------
        -- step 1: FETCH
        ----------------------------------------------------------------
        wait for 1 ns;

        assert IRin = '1'
            report op_name & " FETCH failed: IRin should be 1"
            severity error;


        ----------------------------------------------------------------
        -- step 2: DECODE1
        -- LD/ST: read rb -> REG_A
        ----------------------------------------------------------------
        op_s <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        assert RFout = '1'
            report op_name & " DECODE1 failed: RFout should be 1"
            severity error;

        assert Ain = '1'
            report op_name & " DECODE1 failed: Ain should be 1"
            severity error;

        assert RFaddr_rd = "10"
            report op_name & " DECODE1 failed: RFaddr_rd should be 10"
            severity error;


        ----------------------------------------------------------------
        -- step 3: S_LDST_EX1
        -- effective address = rb + imm4 -> REG_C
        ----------------------------------------------------------------
        wait until rising_edge(clk);
        wait for 1 ns;

        assert Imm2_in = '1'
            report op_name & " LDST_EX1 failed: Imm2_in should be 1"
            severity error;

        assert ALUFN = "0000"
            report op_name & " LDST_EX1 failed: ALUFN should be ADD"
            severity error;

        assert Cin = '1'
            report op_name & " LDST_EX1 failed: Cin should be 1"
            severity error;


        ----------------------------------------------------------------
        -- step 4: S_LDST_EX2
        -- REG_C -> DTCM_addr_reg
        ----------------------------------------------------------------
        wait until rising_edge(clk);
        wait for 1 ns;

        assert Cout = '1'
            report op_name & " LDST_EX2 failed: Cout should be 1"
            severity error;

        assert DTCM_addr_in = '1'
            report op_name & " LDST_EX2 failed: DTCM_addr_in should be 1"
            severity error;


        ----------------------------------------------------------------
        -- step 5: S_LD_EX3
        -- DTCM_data -> RF[ra]
        ----------------------------------------------------------------
        wait until rising_edge(clk);
        wait for 1 ns;

        assert DTCM_out = '1'
            report op_name & " LD_EX3 failed: DTCM_out should be 1"
            severity error;

        assert RFin = '1'
            report op_name & " LD_EX3 failed: RFin should be 1"
            severity error;

        assert RFaddr_wr = '1'
            report op_name & " LD_EX3 failed: RFaddr_wr should be 1"
            severity error;

        assert PCin = '1'
            report op_name & " LD_EX3 failed: PCin should be 1"
            severity error;

        assert DTCM_wr = '0'
            report op_name & " LD_EX3 failed: DTCM_wr should be 0"
            severity error;

        op_s <= '0';

        -- return to FETCH for next instruction
        wait until rising_edge(clk);
        wait for 1 ns;

    end procedure;


    procedure test_st(
        signal op_s      : out std_logic;
        constant op_name : in string
    ) is
    begin
        clear_all_instr;

        ----------------------------------------------------------------
        -- step 1: FETCH
        ----------------------------------------------------------------
        wait for 1 ns;

        assert IRin = '1'
            report op_name & " FETCH failed: IRin should be 1"
            severity error;


        ----------------------------------------------------------------
        -- step 2: DECODE1
        -- LD/ST: read rb -> REG_A
        ----------------------------------------------------------------
        op_s <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        assert RFout = '1'
            report op_name & " DECODE1 failed: RFout should be 1"
            severity error;

        assert Ain = '1'
            report op_name & " DECODE1 failed: Ain should be 1"
            severity error;

        assert RFaddr_rd = "10"
            report op_name & " DECODE1 failed: RFaddr_rd should be 10"
            severity error;


        ----------------------------------------------------------------
        -- step 3: S_LDST_EX1
        -- effective address = rb + imm4 -> REG_C
        ----------------------------------------------------------------
        wait until rising_edge(clk);
        wait for 1 ns;

        assert Imm2_in = '1'
            report op_name & " LDST_EX1 failed: Imm2_in should be 1"
            severity error;

        assert ALUFN = "0000"
            report op_name & " LDST_EX1 failed: ALUFN should be ADD"
            severity error;

        assert Cin = '1'
            report op_name & " LDST_EX1 failed: Cin should be 1"
            severity error;


        ----------------------------------------------------------------
        -- step 4: S_LDST_EX2
        -- REG_C -> DTCM_addr_reg
        ----------------------------------------------------------------
        wait until rising_edge(clk);
        wait for 1 ns;

        assert Cout = '1'
            report op_name & " LDST_EX2 failed: Cout should be 1"
            severity error;

        assert DTCM_addr_in = '1'
            report op_name & " LDST_EX2 failed: DTCM_addr_in should be 1"
            severity error;


        ----------------------------------------------------------------
        -- step 5: S_ST_EX3
        -- RF[ra] -> DTCM
        ----------------------------------------------------------------
        wait until rising_edge(clk);
        wait for 1 ns;

        assert RFout = '1'
            report op_name & " ST_EX3 failed: RFout should be 1"
            severity error;

        assert RFaddr_rd = "11"
            report op_name & " ST_EX3 failed: RFaddr_rd should be 11"
            severity error;

        assert DTCM_wr = '1'
            report op_name & " ST_EX3 failed: DTCM_wr should be 1"
            severity error;

        assert PCin = '1'
            report op_name & " ST_EX3 failed: PCin should be 1"
            severity error;

        assert RFin = '0'
            report op_name & " ST_EX3 failed: RFin should be 0"
            severity error;

        op_s <= '0';

        -- return to FETCH for next instruction
        wait until rising_edge(clk);
        wait for 1 ns;

    end procedure;


    procedure test_mov(
        signal op_s      : out std_logic;
        constant op_name : in string
    ) is
    begin
        clear_all_instr;

        ----------------------------------------------------------------
        -- step 1: FETCH
        ----------------------------------------------------------------
        wait for 1 ns;

        assert IRin = '1'
            report op_name & " FETCH failed: IRin should be 1"
            severity error;

        assert PCsel = "10"
            report op_name & " FETCH failed: PCsel should be 10"
            severity error;

        assert PCin = '0'
            report op_name & " FETCH failed: PCin should be 0 in FETCH"
            severity error;


        ----------------------------------------------------------------
        -- step 2: DECODE1
        -- MOV: no register pre-read needed
        ----------------------------------------------------------------
        op_s <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        assert RFout = '0'
            report op_name & " DECODE1 failed: RFout should be 0"
            severity error;

        assert Ain = '0'
            report op_name & " DECODE1 failed: Ain should be 0"
            severity error;

        assert RFin = '0'
            report op_name & " DECODE1 failed: RFin should be 0"
            severity error;

        assert DTCM_wr = '0'
            report op_name & " DECODE1 failed: DTCM_wr should be 0"
            severity error;


        ----------------------------------------------------------------
        -- step 3: MOV_EX
        -- imm8 -> BUS -> RF[ra]
        ----------------------------------------------------------------
        wait until rising_edge(clk);
        wait for 1 ns;

        assert Imm1_in = '1'
            report op_name & " MOV_EX failed: Imm1_in should be 1"
            severity error;

        assert RFin = '1'
            report op_name & " MOV_EX failed: RFin should be 1"
            severity error;

        assert RFaddr_wr = '1'
            report op_name & " MOV_EX failed: RFaddr_wr should be 1"
            severity error;

        assert PCin = '1'
            report op_name & " MOV_EX failed: PCin should be 1"
            severity error;

        assert DTCM_wr = '0'
            report op_name & " MOV_EX failed: DTCM_wr should be 0"
            severity error;

        assert RFout = '0'
            report op_name & " MOV_EX failed: RFout should be 0"
            severity error;

        op_s <= '0';

        -- return to FETCH for next instruction
        wait until rising_edge(clk);
        wait for 1 ns;

    end procedure;


    procedure test_done(
        signal op_s      : out std_logic;
        constant op_name : in string
    ) is
    begin
        clear_all_instr;

        ----------------------------------------------------------------
        -- step 1: FETCH
        ----------------------------------------------------------------
        wait for 1 ns;

        assert IRin = '1'
            report op_name & " FETCH failed: IRin should be 1"
            severity error;

        assert PCsel = "10"
            report op_name & " FETCH failed: PCsel should be 10"
            severity error;

        assert PCin = '0'
            report op_name & " FETCH failed: PCin should be 0 in FETCH"
            severity error;


        ----------------------------------------------------------------
        -- step 2: DECODE1
        -- DONE instruction detected
        ----------------------------------------------------------------
        op_s <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        assert done = '0'
            report op_name & " DECODE1 failed: done should still be 0"
            severity error;

        assert DTCM_wr = '0'
            report op_name & " DECODE1 failed: DTCM_wr should be 0"
            severity error;

        assert RFin = '0'
            report op_name & " DECODE1 failed: RFin should be 0"
            severity error;

        assert RFout = '0'
            report op_name & " DECODE1 failed: RFout should be 0"
            severity error;


        ----------------------------------------------------------------
        -- step 3: S_DONE
        ----------------------------------------------------------------
        wait until rising_edge(clk);
        wait for 1 ns;

        assert done = '1'
            report op_name & " failed: done should be 1 in S_DONE"
            severity error;

        assert DTCM_wr = '0'
            report op_name & " DONE state failed: DTCM_wr should be 0"
            severity error;

        assert RFin = '0'
            report op_name & " DONE state failed: RFin should be 0"
            severity error;

        assert RFout = '0'
            report op_name & " DONE state failed: RFout should be 0"
            severity error;

        assert PCin = '0'
            report op_name & " DONE state failed: PCin should be 0"
            severity error;

        op_s <= '0';

    end procedure;


begin -- begin of the process

    ----------------------------------------------------------------
    -- Reset
    ----------------------------------------------------------------
    rst <= '1';
    ena <= '0';

    clear_all_instr;

    wait until rising_edge(clk);
    wait until rising_edge(clk);

    rst <= '0';
    ena <= '1';

    wait for 1 ns;


    ----------------------------------------------------------------
    -- R-type arithmetic / logic tests
    ----------------------------------------------------------------
    test_rtype(add_s, "ADD", "0000");
    test_rtype(sub_s, "SUB", "0001");
    test_rtype(and_s, "AND", "0010");
    test_rtype(or_s,  "OR",  "0011");
    test_rtype(xor_s, "XOR", "0100");

    report "All R-type tests finished successfully" severity note;


    ----------------------------------------------------------------
    -- J-type jump tests
    ----------------------------------------------------------------
    test_jtype(jmp_s, "JMP",    '0', "01");

    test_jtype(jc_s,  "JC_C1",  '1', "01");
    test_jtype(jc_s,  "JC_C0",  '0', "10");

    test_jtype(jnc_s, "JNC_C0", '0', "01");
    test_jtype(jnc_s, "JNC_C1", '1', "10");


    ----------------------------------------------------------------
    -- I-type / MOV test
    ----------------------------------------------------------------
    test_mov(mov_s, "MOV");


    ----------------------------------------------------------------
    -- Memory tests
    ----------------------------------------------------------------
    test_ld(ld_s, "LD");
    test_st(st_s, "ST");


    ----------------------------------------------------------------
    -- DONE test
    -- keep DONE last, because FSM stays in S_DONE until reset
    ----------------------------------------------------------------
    test_done(done_s, "DONE");


    ----------------------------------------------------------------
    -- End simulation
    ----------------------------------------------------------------
    report "All Control tests finished successfully" severity note;

    wait;

end process STIM;

end architecture sim;