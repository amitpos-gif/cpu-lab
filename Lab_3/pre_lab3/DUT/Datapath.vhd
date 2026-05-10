library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.aux_package.all;

-------------------------------------------------------------------
entity Datapath is
generic( Dwidth: integer:=16;
		 Awidth: integer:=6;
		 dept:   integer:=64);
  port (
    clk  : in std_logic;
    rst  : in std_logic;
    -- Control from CU (16 bits) --
    DTCM_wr      : in std_logic;   -- DTCM write enable
	  Cin          : in std_logic;   -- REG_C    ← ALU_result; flags ← ALU_flags
	  Cout         : in std_logic;   -- REG_C          → BUS_wire
	  DTCM_addr_in : in std_logic;   -- DTCM_addr_reg ← BUS_wire[5:0]
	  DTCM_out     : in std_logic;   -- DTCM_data      → BUS_wire
	  ALUFN        : in std_logic_vector(3 downto 0);
  	Ain          : in std_logic;                        -- REG_A    ← BUS_wire  AND selects RFaddr_rd=rb
	  RFin         : in std_logic;   
  	RFout        : in std_logic;    
    RFaddr_rd	 : in std_logic_vector(1 downto 0);       --00 = off  , 01 = rc  , 10 = rb , 11= ra --
	  RFaddr_wr	 : in std_logic;                          -- 0 = off  , 1 = wr from the data is ra --
    IRin         : in std_logic;                        -- ITCM_data -> to IR_reg
    PCin         : in std_logic;                        -- PC_next -> to PC_reg
    PCsel        : in std_logic_vector(1 downto 0);    -- '00'= "000000"  , '01'=PC+1+offset (jump target)  , "10" = PC+1 --
    Imm1_in      : in std_logic;                        -- SignExt(IR[7:0])→ BUS_wire  (8-bit imm)
    Imm2_in      : in std_logic;                        -- SignExt(IR[3:0])→ BUS_wire  (4-bit imm)
    -- Status to CU (15 bits) --
    mov_s  : out std_logic;   -- OPC = "1100"  move immediate
    done_s : out std_logic;   -- OPC = "1111"  program done
	  and_s  : out std_logic;   -- OPC = "0010"  bitwise AND
    or_s   : out std_logic;   -- OPC = "0011"  bitwise OR
    xor_s  : out std_logic;   -- OPC = "0100"  bitwise XOR
	  jnc_s  : out std_logic;   -- OPC = "1001"  jump if no carry
	  jc_s   : out std_logic;   -- OPC = "1000"  jump if carry
	  jmp_s  : out std_logic;   -- OPC = "0111"  unconditional jump
	  sub_s  : out std_logic;   -- OPC = "0001"  subtract
    add_s  : out std_logic;   -- OPC = "0000"  add
    ld_s   : out std_logic;   -- OPC = "1101"  load
    st_s   : out std_logic;   -- OPC = "1110"  store
    -- Status inputs from Datapath — ALU flags --
    Cflag  : out std_logic;   -- carry  flag
    Zflag  : out std_logic;   -- zero   flag
    Nflag  : out std_logic;   -- negative flag

    -- Testbench ports (green line) --
    TBactive         : in  std_logic;
    ITCM_tb_wr       : in  std_logic;
    ITCM_tb_in       : in  std_logic_vector(Dwidth-1 downto 0);
    ITCM_tb_addr_in  : in  std_logic_vector(Awidth-1  downto 0);
    DTCM_tb_wr       : in  std_logic;
    DTCM_tb_in       : in  std_logic_vector(Dwidth-1 downto 0);
    DTCM_tb_out      : out std_logic_vector(Dwidth-1 downto 0);
    DTCM_tb_addr_in  : in  std_logic_vector(Awidth-1  downto 0);
    DTCM_tb_addr_out : in  std_logic_vector(Awidth-1  downto 0)
  );
end entity Datapath;

------------------------------------------------------------------------
architecture rtl of Datapath is


  signal BUS_wire : std_logic_vector(Dwidth-1 downto 0);

  -- Pipeline registers --
  signal IR_reg        : std_logic_vector(Dwidth-1 downto 0) := (others => '0');
  signal PC_reg        : std_logic_vector(7  downto 0)       := (others => '0');
  signal REG_A         : std_logic_vector(Dwidth-1 downto 0) := (others => '0');
  signal REG_C         : std_logic_vector(Dwidth-1 downto 0) := (others => '0');
  signal DTCM_addr_reg : std_logic_vector(Awidth-1 downto 0) := (others => '0');

-- 
  -- ALU combinatorial outputs --
  signal ALU_result : std_logic_vector(Dwidth-1 downto 0);
  signal ALU_C      : std_logic;
  signal ALU_Z      : std_logic;
  signal ALU_N      : std_logic;

  -- Registered ALU flags --
  signal flag_C : std_logic := '0';
  signal flag_Z : std_logic := '0';
  signal flag_N : std_logic := '0';

  -- PC arithmetic --
  signal PC_plus1 : std_logic_vector(7 downto 0);
  signal PC_next  : std_logic_vector(7 downto 0);

  -- Sign-extended immediates --
  signal Imm1_sext : std_logic_vector(Dwidth-1 downto 0); -- SignExt(IR[7:0])
  signal Imm2_sext : std_logic_vector(Dwidth-1 downto 0); -- SignExt(IR[3:0])

  -- RF signals --
  signal RF_rdata      : std_logic_vector(Dwidth-1 downto 0); -- combinatorial RF output
  signal RF_read_addr  : std_logic_vector(3 downto 0);        -- output of read MUX
  signal RF_write_addr : std_logic_vector(3 downto 0);        -- output of write MUX

  -- Memory data signals --
  signal ITCM_data : std_logic_vector(Dwidth-1 downto 0); -- combinatorial from ITCM
  signal DTCM_data : std_logic_vector(Dwidth-1 downto 0); -- combinatorial from DTCM

  -- Memory port mux signals --
  signal ITCM_rd_addr : std_logic_vector(Awidth-1 downto 0);
  signal DTCM_rd_addr : std_logic_vector(Awidth-1 downto 0);
  signal DTCM_wr_addr : std_logic_vector(Awidth-1 downto 0);
  signal DTCM_wr_data : std_logic_vector(Dwidth-1 downto 0);
  signal DTCM_wr_en   : std_logic;

begin

---------------------------------------------------------------------------
---------------------- assert for Testbench -------------------------------
------------------------------$$ 1 $$-----------------------------------------
BUS_CONTENTION_CHECK : process(RFout, Imm1_in, Imm2_in, Cout, DTCM_out)
  variable drivers : integer;
begin
  drivers := 0;
  if RFout    = '1' then drivers := drivers + 1; end if;
  if Imm1_in  = '1' then drivers := drivers + 1; end if;
  if Imm2_in  = '1' then drivers := drivers + 1; end if;
  if Cout     = '1' then drivers := drivers + 1; end if;
  if DTCM_out = '1' then drivers := drivers + 1; end if;

  assert drivers <= 1
    report "BUS CONTENTION: " & integer'image(drivers) & " drivers active simultaneously!"
    severity ERROR;
end process;
--------------------------------$$ 2 $$---------------------------------------------
PC_BOUNDS_CHECK : process(clk)
begin
  if rising_edge(clk) then
    assert PC_reg < "01000000"
      report "PC OUT OF BOUNDS: PC = " & integer'image(conv_integer(PC_reg))
      severity WARNING;
  end if;
end process;
--------------------------------$$ 3 $$--------------------------------------------

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
  -- ITCM: always read from PC (CPU read-only during execution)
  ITCM_rd_addr <= PC_reg(5 downto 0);

  -- DTCM: read/write source mux (TB takes priority when TBactive='1')
  DTCM_rd_addr <= DTCM_tb_addr_out when TBactive = '1' else DTCM_addr_reg;
  DTCM_wr_addr <= DTCM_tb_addr_in  when TBactive = '1' else DTCM_addr_reg;
  DTCM_wr_data <= DTCM_tb_in       when TBactive = '1' else BUS_wire;
  DTCM_wr_en   <= DTCM_tb_wr       when TBactive = '1' else DTCM_wr;

  -- TB always sees DTCM output (used after 'done' to read results)
  DTCM_tb_out  <= DTCM_data;

  ------------------------------------------------------------------------------
  -- SECTION 2 - COMPONENT INSTANTIATIONS
  ------------------------------------------------------------------------------

	alu_inst : alu 
	generic map ( n => Dwidth) 
	port map (
		A      => REG_A,
		B      => BUS_wire,
		alufn  => ALUFN,   ---  from the control ---
		c      => ALU_result,
		C_flag => ALU_C,
		Z_flag => ALU_Z,
		N_flag => ALU_N
	);
	

  -- ITCM (Program Memory): combinatorial read, synchronous write (TB only)
  ITCM_INST : ProgMem
    generic map (Dwidth => 16, Awidth => 6, dept => 64)
    port map (
      clk      => clk,
      memEn    => ITCM_tb_wr,
      WmemData => ITCM_tb_in,
      WmemAddr => ITCM_tb_addr_in,
      RmemAddr => ITCM_rd_addr,
      RmemData => ITCM_data
    );

  -- DTCM (Data Memory): combinatorial read, synchronous write
  DTCM_INST : dataMem
    generic map (Dwidth => 16, Awidth => 6, dept => 64)
    port map (
      clk      => clk,
      memEn    => DTCM_wr_en,
      WmemData => DTCM_wr_data,
      WmemAddr => DTCM_wr_addr,
      RmemAddr => DTCM_rd_addr,
      RmemData => DTCM_data
    );

  -- Register File: combinatorial read, synchronous write --
  RF_INST : RF
    generic map (Dwidth => 16, Awidth => 4)
    port map (
      clk      => clk,
      rst      => rst,
      WregEn   => RFin,
      WregData => BUS_wire,
      WregAddr => RF_write_addr,   
      RregAddr => RF_read_addr,   
      RregData => RF_rdata
    );

  -------------- PAST 3 - BUS -----------------------------------------

  -- Puts the currently-selected RF register output onto the BUS
  RF_DRV : BidirPin
    generic map (width => 16)
    port map (Dout => RF_rdata, en => RFout, Din => open, IOpin => BUS_wire);

  -- Puts a sign-extended 8-bit immediate onto the BUS
  IMM1_DRV : BidirPin
    generic map (width => 16)
    port map (Dout => Imm1_sext, en => Imm1_in, Din => open, IOpin => BUS_wire);

  -- Puts a sign-extended 4-bit immediate onto the BUS
  IMM2_DRV : BidirPin
    generic map (width => 16)
    port map (Dout => Imm2_sext, en => Imm2_in, Din => open, IOpin => BUS_wire);

  -- Puts the ALU result (stored in REG-C) onto the BUS
  REGC_DRV : BidirPin
    generic map (width => 16)
    port map (Dout => REG_C, en => Cout, Din => open, IOpin => BUS_wire);

  -- Puts the data memory output onto the BUS
  DTCM_DRV : BidirPin
    generic map (width => 16)
    port map (Dout => DTCM_data, en => DTCM_out, Din => open, IOpin => BUS_wire);

  
  ------------ PART 4 - COMBINATORIAL LOGIC ------------------------------------

  -- Sign Extension --
  Imm1_sext <= (15 downto 8 => IR_reg(7)) & IR_reg(7 downto 0); -- 8-bit imm
  Imm2_sext <= (15 downto 4 => IR_reg(3)) & IR_reg(3 downto 0); -- 4-bit imm
  
  
-- PC Arithmetic --
PC_plus1 <= PC_reg + "00000001";

PC_next <= (others => '0')                              when PCsel = "00" else
           PC_reg + IR_reg(7 downto 0) + "00000001"    when PCsel = "01" else
           PC_plus1;                                    -- PCsel = "10"

  -- RF Address MUX --
  RF_read_addr <= IR_reg(3 downto 0)  when RFaddr_rd = "01" else  -- rc = IR[3:0]
                  IR_reg(7 downto 4)  when RFaddr_rd = "10" else  -- rb = IR[7:4]  
                  IR_reg(11 downto 8) when RFaddr_rd = "11" else  --ra = IR[11:8] --NEW!! 5\10 11:45
                (others => '0');                                 -- "00" = off

  RF_write_addr <= IR_reg(11 downto 8)  when RFaddr_wr = '1' else (others => '0');

  -- OPC Decoder (status flags to Control Unit) --
  add_s  <= '1' when IR_reg(15 downto 12) = "0000" else '0';
  sub_s  <= '1' when IR_reg(15 downto 12) = "0001" else '0';
  and_s  <= '1' when IR_reg(15 downto 12) = "0010" else '0';
  or_s   <= '1' when IR_reg(15 downto 12) = "0011" else '0';
  xor_s  <= '1' when IR_reg(15 downto 12) = "0100" else '0';
  jmp_s  <= '1' when IR_reg(15 downto 12) = "0111" else '0';
  jc_s   <= '1' when IR_reg(15 downto 12) = "1000" else '0';
  jnc_s  <= '1' when IR_reg(15 downto 12) = "1001" else '0';
  mov_s  <= '1' when IR_reg(15 downto 12) = "1100" else '0';
  ld_s   <= '1' when IR_reg(15 downto 12) = "1101" else '0';
  st_s   <= '1' when IR_reg(15 downto 12) = "1110" else '0';
  done_s <= '1' when IR_reg(15 downto 12) = "1111" else '0';

-----------------------------------------------------------------------------------

  -- Status flag outputs --
  Cflag <= flag_C;
  Zflag <= flag_Z;
  Nflag <= flag_N;

  ------------------------ part 5 - SEQUENTIAL REGISTERS -----------------------

  -- IR Register (Instruction Register) --
  IR_REG_PROC : process(clk, rst)
  begin
    if rst = '1' then
      IR_reg <= (others => '0');
    elsif rising_edge(clk) then
      if IRin = '1' then
        IR_reg <= ITCM_data;
      end if;
    end if;
  end process;

  -- PC Register (Program Counter) --
  PC_REG_PROC : process(clk, rst)
  begin
    if rst = '1' then
      PC_reg <= (others => '0');
    elsif rising_edge(clk) then
      if PCin = '1' then
        PC_reg <= PC_next;
      end if;
    end if;
  end process;

  -- REG-A (ALU A-input latch) --
  REGA_PROC : process(clk, rst)
  begin
    if rst = '1' then
      REG_A <= (others => '0');
    elsif rising_edge(clk) then
      if Ain = '1' then
        REG_A <= BUS_wire;
      end if;
    end if;
  end process;

  -- REG-C (ALU Master-Slave result register) --
  REGC_PROC : process(clk, rst)
  begin
    if rst = '1' then
      REG_C <= (others => '0');
    elsif rising_edge(clk) then
      if Cin = '1' then
        REG_C <= ALU_result;
      end if;
    end if;
  end process;

  -- ALU Flag Registers (latched on same clock as REG-C) --
  FLAG_PROC : process(clk, rst)
  begin
    if rst = '1' then
      flag_C <= '0'; flag_Z <= '0'; flag_N <= '0';
    elsif rising_edge(clk) then
      if Cin = '1' then
        flag_C <= ALU_C;
        flag_Z <= ALU_Z;
        flag_N <= ALU_N;
      end if;
    end if;
  end process;

  -- DTCM_ADDR_REG --
  DTCM_ADDR_PROC : process(clk, rst)
  begin
    if rst = '1' then
      DTCM_addr_reg <= (others => '0');
    elsif rising_edge(clk) then
      if DTCM_addr_in = '1' then
        DTCM_addr_reg <= BUS_wire(5 downto 0);
      end if;
    end if;
  end process;

end architecture rtl;
---------------------------------------------------------------------------------