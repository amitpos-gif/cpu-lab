# ALU Operation Addition Guide - REAL TIME Implementation Instructions

## Overview
This document provides **REAL TIME** guidance on where and how to add new operations to your ALU. The ALU is structured with multiple functional units that are selected via the `ALUFN_i` input signal.

---

## ALU Architecture Structure

The ALU uses a **5-bit operation code** `ALUFN_i[4:0]`:
- **ALUFN_i[4:3]** = Unit Selection (which functional unit to use)
- **ALUFN_i[2:0]** = Operation Selection (specific operation within that unit)

### Current Functional Units:
```
ALUFN_i[4:3] = "00" → RESERVED (not currently used - REAL TIME expansion point)
ALUFN_i[4:3] = "01" → Adder/Subtractor Unit (AdderSub.vhd)
ALUFN_i[4:3] = "10" → Barrel Shifter Unit (Shifter.vhd)
ALUFN_i[4:3] = "11" → Logic Unit (Logic.vhd)
```

---

## REAL TIME Step 1: Understand Current Operations

### A. Adder/Subtractor Operations (ALUFN_i[4:3] = "01")
**File:** `AdderSub.vhd`

Current operations with `alufn[2:0]`:
```vhdl
"000" → Y + X     (addition)
"001" → Y - X     (subtraction)
"010" → neg(X)    (0 - X, negation)
"011" → Y + 2     (addition with constant)
"100" → Y - 2     (subtraction with constant)
"101" → AVAILABLE (REAL TIME: free slot)
"110" → AVAILABLE (REAL TIME: free slot)
"111" → AVAILABLE (REAL TIME: free slot)
```

### B. Barrel Shifter Operations (ALUFN_i[4:3] = "10")
**File:** `Shifter.vhd`

Current operations with `alufn[2:0]`:
```vhdl
"000" → Shift Left (direction = 0)
"001" → Shift Right (direction = 1)
"010" → AVAILABLE (REAL TIME: free slot)
"011" → AVAILABLE (REAL TIME: free slot)
"100" → AVAILABLE (REAL TIME: free slot)
"101" → AVAILABLE (REAL TIME: free slot)
"110" → AVAILABLE (REAL TIME: free slot)
"111" → AVAILABLE (REAL TIME: free slot)
```

### C. Logic Operations (ALUFN_i[4:3] = "11")
**File:** `Logic.vhd`

Current operations with `alufn[2:0]`:
```vhdl
"000" → NOT(Y)
"001" → Y OR X
"010" → Y AND X
"011" → Y XOR X
"100" → Y NOR X
"101" → Y NAND X
"110" → Y XNOR X
"111" → AVAILABLE (REAL TIME: free slot)
```

---

## REAL TIME Step 2: Where to Add New Operations

### Option A: Add to Existing Unit (RECOMMENDED - Fastest)

**REAL TIME LOCATION 1: AdderSub.vhd**
If adding arithmetic operation, modify the WITH/SELECT statements around lines 30-45:

```vhdl
-- REAL TIME: Find this section in AdderSub.vhd lines ~30
WITH alufn SELECT
    A_in <= X      WHEN "000",   ---- Y + X ----
            X      WHEN "001",   ---- Y - X ----
            X      WHEN "010",   ---- neg(X) ----
            const2 WHEN "011",   ---- Y + 2 ----
            const2 WHEN "100",   ---- Y - 2 ----
            -- REAL TIME: ADD NEW OPERATION HERE (e.g., "101")
            zeros  WHEN OTHERS;
```

**REAL TIME LOCATION 2: Logic.vhd**
If adding bitwise logic operation, modify lines 15-22:

```vhdl
-- REAL TIME: Find this section in Logic.vhd lines ~15
with alufn select
    z <= not(y) when "000",
         (y or x) when "001",
         (y and x) when "010",
         (y xor x) when "011",
         (y nor x) when "100",
         (y nand x) when "101",
         (y xnor x) when "110",
         -- REAL TIME: ADD NEW OPERATION HERE (e.g., "111")
         (others => '0') when others;
```

**REAL TIME LOCATION 3: Shifter.vhd**
If adding shift variant, modify lines 30-44:

```vhdl
-- REAL TIME: Find this section in Shifter.vhd lines ~30
shifter_gen : FOR i IN 0 TO k-1 GENERATE
    stages(i+1) <= stages(i)
                       WHEN x(i) = '0'
                   ELSE stages(i)(n-1-2**i DOWNTO 0) & (2**i-1 DOWNTO 0 => '0')
                       WHEN dir = '0'
                   ELSE (2**i-1 DOWNTO 0 => '0') & stages(i)(n-1 DOWNTO 2**i);
    -- REAL TIME: Shifter logic is here - modify for new shift types
END GENERATE;
```

---

## REAL TIME Step 3: Add Support in Main ALU Controller

**File:** `alu_unit.vhd`

### REAL TIME Location 4: Update Input Multiplexers (lines 50-56)

```vhdl
-- REAL TIME: Update input routing around line 50
addsub_x <= X_i WHEN ALUFN_i(4 DOWNTO 3) = "01" ELSE (OTHERS => '0');
addsub_y <= Y_i WHEN ALUFN_i(4 DOWNTO 3) = "01" ELSE (OTHERS => '0');

logic_x  <= X_i WHEN ALUFN_i(4 DOWNTO 3) = "11" ELSE (OTHERS => '0');
logic_y  <= Y_i WHEN ALUFN_i(4 DOWNTO 3) = "11" ELSE (OTHERS => '0');

shift_y  <= Y_i               WHEN ALUFN_i(4 DOWNTO 3) = "10" ELSE (OTHERS => '0');
shift_x  <= X_i(k-1 DOWNTO 0) WHEN ALUFN_i(4 DOWNTO 3) = "10" ELSE (OTHERS => '0');
-- REAL TIME: If creating NEW unit, add inputs here
```

### REAL TIME Location 5: Update Output Multiplexer (lines 84-89)

```vhdl
-- REAL TIME: Find output mux around line 84
WITH ALUFN_i(4 DOWNTO 3) SELECT
    mux_out <= addsub_res       WHEN "01",
               shift_res        WHEN "10",
               logic_res        WHEN "11",
               (OTHERS => '0')  WHEN OTHERS;
-- REAL TIME: If adding new unit (ALUFN_i[4:3]="00"), update this mux
```

### REAL TIME Location 6: Update Carry Output Mux (lines 95-100)

```vhdl
-- REAL TIME: Find carry mux around line 95
WITH ALUFN_i(4 DOWNTO 3) SELECT
    carry_out <= addsub_cout WHEN "01",
                 shift_cout  WHEN "10",
                 '0'         WHEN OTHERS;
-- REAL TIME: If new unit generates carry, update here
```

### REAL TIME Location 7: Update Overflow Flag Logic (lines 117-125)

```vhdl
-- REAL TIME: V-flag logic is around line 117
WITH ALUFN_i(2 DOWNTO 0) SELECT
    sub_flag <= '0' WHEN "000",   -- Y + X (addition)
                '1' WHEN "001",   -- Y - X (subtraction)
                '1' WHEN "010",   -- neg(X)
                '0' WHEN "011",   -- Y + 2
                '1' WHEN "100",   -- Y - 2
                -- REAL TIME: Set sub_flag for new arithmetic ops
                '0' WHEN OTHERS;
```

---

## REAL TIME Step 4: Create Entirely New Functional Unit

If you need operations that don't fit existing units:

### REAL TIME Location 8: Create New Unit File
```vhdl
-- File: Multiplier.vhd (example for new unit)
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY multiplier IS
    GENERIC ( n : INTEGER := 8 );
    PORT (
        X     : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
        Y     : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
        alufn : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);  -- operation select
        res   : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0);
        cout  : OUT STD_LOGIC
    );
END multiplier;
```

### REAL TIME Location 9: Add Component Declaration
**File:** `aux_package.vhd` (around line 50+)

```vhdl
-- REAL TIME: Add this in aux_package.vhd after other components
component multiplier is
    GENERIC ( n : INTEGER := 8 );
    PORT (
        X     : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
        Y     : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
        alufn : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        res   : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0);
        cout  : OUT STD_LOGIC
    );
end component;
```

### REAL TIME Location 10: Instantiate in alu_unit.vhd
**File:** `alu_unit.vhd` (after shifter instantiation, around line 70)

```vhdl
-- REAL TIME: Add new unit instantiation around line 75
    MULT_INST : multiplier
        GENERIC MAP (n => n)
        PORT MAP (
            x     => X_i,              -- REAL TIME: route proper inputs
            y     => Y_i,              -- REAL TIME: route proper inputs
            alufn => ALUFN_i(2 DOWNTO 0),
            res   => mult_res,
            cout  => mult_cout
        );
```

### REAL TIME Location 11: Add Internal Signals (line 30)
**File:** `alu_unit.vhd`

```vhdl
-- REAL TIME: Add signals for new unit around line 30
    SIGNAL mult_res   : STD_LOGIC_VECTOR(n-1 DOWNTO 0);
    SIGNAL mult_cout  : STD_LOGIC;
```

### REAL TIME Location 12: Update ALL Multiplexers in alu_unit.vhd
- Update input routing (REAL TIME LOCATION 4)
- Update output mux (REAL TIME LOCATION 5) - add "WHEN "00""
- Update carry mux (REAL TIME LOCATION 6) - handle mult_cout

---

## REAL TIME Checklist for Adding New Operation

When adding a new operation **REAL TIME checklist**:

- [ ] Decide: Add to existing unit or create new unit?
- [ ] **If existing unit:**
  - [ ] Modify the unit file (AdderSub.vhd / Logic.vhd / Shifter.vhd)
  - [ ] Add operation case to WITH/SELECT statement
  - [ ] Test with testbench
  
- [ ] **If new unit:**
  - [ ] Create new entity file
  - [ ] Add component to aux_package.vhd
  - [ ] Add internal signals to alu_unit.vhd (REAL TIME LOCATION 11)
  - [ ] Instantiate unit in alu_unit.vhd (REAL TIME LOCATION 10)
  - [ ] Update input mux in alu_unit.vhd (REAL TIME LOCATION 4)
  - [ ] Update output mux in alu_unit.vhd (REAL TIME LOCATION 5)
  - [ ] Update carry mux if needed (REAL TIME LOCATION 6)
  - [ ] Update overflow logic if needed (REAL TIME LOCATION 7)

- [ ] Update testbench with new ALUFN codes
- [ ] Verify flags (N, C, Z, V) are set correctly
- [ ] Simulate and verify on hardware

---

## REAL TIME Example: Adding Multiply Operation

**Step 1 - REAL TIME:** Create Multiplier.vhd with multiply logic for alufn[2:0] values

**Step 2 - REAL TIME:** Add to aux_package.vhd component declarations

**Step 3 - REAL TIME:** In alu_unit.vhd add signals:
```vhdl
SIGNAL mult_res : STD_LOGIC_VECTOR(n-1 DOWNTO 0);
SIGNAL mult_cout : STD_LOGIC;
```

**Step 4 - REAL TIME:** Instantiate multiplier (use "00" for ALUFN[4:3])

**Step 5 - REAL TIME:** Update mux outputs in alu_unit.vhd:
```vhdl
WITH ALUFN_i(4 DOWNTO 3) SELECT
    mux_out <= mult_res         WHEN "00",     -- REAL TIME: new!
               addsub_res       WHEN "01",
               shift_res        WHEN "10",
               logic_res        WHEN "11",
               (OTHERS => '0')  WHEN OTHERS;
```

---

## REAL TIME Files to Modify Summary

When adding new operations, **REAL TIME** track changes in these files:

| **File** | **Real-Time Location** | **Purpose** |
|----------|----------------------|-----------|
| `AdderSub.vhd` | REAL TIME LOCATION 1 | Add arithmetic ops |
| `Logic.vhd` | REAL TIME LOCATION 2 | Add bitwise ops |
| `Shifter.vhd` | REAL TIME LOCATION 3 | Add shift variants |
| `alu_unit.vhd` | REAL TIME LOCATIONS 4-7 | Route inputs/outputs |
| `aux_package.vhd` | Line 50+ | Declare new components |
| `ALU_unit_Wrapper.vhd` | Typically no changes | Wrapper unchanged |

---

## Notes
- **REAL TIME searches:** Use "REAL TIME" keyword to find all critical modification points in the code
- Default n (width) = 8 bits, k (shift amount bits) = 3 
- Operation codes are hardwired in WITH/SELECT statements
- Flags are computed combinatorially (real-time updates)
- The wrapper (ALU_unit_Wrapper.vhd) adds pipeline stage at clock edge

