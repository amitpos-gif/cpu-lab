# run_tests_2_3_4.ps1
# Runs ModelSim on tests 2, 3, 4 (man_compiled) and compares with RARS output.

$BASE  = "C:\Users\amitp\OneDrive\Desktop\Comp_Lab\Lab_5"
$VSIM  = "C:\intelFPGA\20.1\modelsim_ase\win32aloem\vsim.exe"
$IFETCH = "$BASE\DUT\RV32IM PIPLINE\IFETCH.VHD"
$DMEM   = "$BASE\DUT\RV32IM PIPLINE\DMEMORY.VHD"
$SIM    = "$BASE\SIM"

$tests = @(
    [pscustomobject]@{
        Num    = 2
        ITCM   = "C:/Users/amitp/OneDrive/Desktop/Comp_Lab/Lab_5/BENCHMARKS/test2/RV32IM/man_compiled/bin/M9K-intel/ITCM.hex"
        DTCM   = "C:/Users/amitp/OneDrive/Desktop/Comp_Lab/Lab_5/BENCHMARKS/test2/RV32IM/man_compiled/bin/M9K-intel/DTCM.hex"
        OutDir = "$BASE\BENCHMARKS\test2\RV32IM\man_compiled\output\MODELSIM"
        RARS   = "$BASE\BENCHMARKS\test2\RV32IM\man_compiled\output\RARS\DTCM.h"
    },
    [pscustomobject]@{
        Num    = 3
        ITCM   = "C:/Users/amitp/OneDrive/Desktop/Comp_Lab/Lab_5/BENCHMARKS/test3/RV32IM/man_compiled/bin/M9K-intel/ITCM.hex"
        DTCM   = "C:/Users/amitp/OneDrive/Desktop/Comp_Lab/Lab_5/BENCHMARKS/test3/RV32IM/man_compiled/bin/M9K-intel/DTCM.hex"
        OutDir = "$BASE\BENCHMARKS\test3\RV32IM\man_compiled\output\MODELSIM"
        RARS   = "$BASE\BENCHMARKS\test3\RV32IM\man_compiled\output\RARS\DTCM.h"
    },
    [pscustomobject]@{
        Num    = 4
        ITCM   = "C:/Users/amitp/OneDrive/Desktop/Comp_Lab/Lab_5/BENCHMARKS/test4/RV32IM/man_compiled/bin/M9K-intel/ITCM.hex"
        DTCM   = "C:/Users/amitp/OneDrive/Desktop/Comp_Lab/Lab_5/BENCHMARKS/test4/RV32IM/man_compiled/bin/M9K-intel/DTCM.hex"
        OutDir = "$BASE\BENCHMARKS\test4\RV32IM\man_compiled\output\MODELSIM"
        RARS   = "$BASE\BENCHMARKS\test4\RV32IM\man_compiled\output\RARS\DTCM.h"
    }
)

function Patch-InitFile($filePath, $newPath) {
    $txt = [System.IO.File]::ReadAllText($filePath)
    $txt = $txt -replace '(init_file\s*=>\s*)"[^"]*"', "`$1`"$newPath`""
    # Write UTF-8 without BOM (PowerShell 5.1 Set-Content adds BOM which breaks ModelSim)
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($filePath, $txt, $utf8NoBom)
}

function Compare-DTCM($simMemPath, $rarsPath) {
    $simVals = @{}
    foreach ($line in (Get-Content $simMemPath)) {
        if ($line -match '^\s*([0-9a-fA-F]+)\s*:\s*([0-9a-fA-F]+)') {
            $addr = [Convert]::ToInt32($Matches[1], 16)
            $simVals[$addr] = $Matches[2].ToUpper().PadLeft(8, '0')
        }
    }
    $rarsVals = Get-Content $rarsPath | Where-Object { $_.Trim() -ne "" }

    $mismatches = 0
    $shown = 0
    for ($i = 0; $i -lt $rarsVals.Count; $i++) {
        $exp = $rarsVals[$i].Trim().ToUpper().PadLeft(8, '0')
        $got = if ($simVals.ContainsKey($i)) { $simVals[$i] } else { "00000000" }
        if ($exp -ne $got) {
            $mismatches++
            if ($shown -lt 10) {
                Write-Host ("    word 0x{0:X3} ({0,4}): expected {1}  got {2}" -f $i, $exp, $got) -ForegroundColor Yellow
                $shown++
            } elseif ($shown -eq 10) {
                Write-Host "    ... (more mismatches omitted)" -ForegroundColor Yellow
                $shown++
            }
        }
    }
    return [pscustomobject]@{ Total = $rarsVals.Count; Mismatches = $mismatches }
}

$results = @()
Set-Location $SIM

foreach ($t in $tests) {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  TEST $($t.Num)" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan

    Patch-InitFile $IFETCH $t.ITCM
    Patch-InitFile $DMEM   $t.DTCM
    Write-Host "  Patched init_file paths."

    if (-not (Test-Path $t.OutDir)) {
        New-Item -ItemType Directory -Path $t.OutDir | Out-Null
        Write-Host "  Created output directory."
    }

    $outFwd = $t.OutDir -replace '\\', '/'
    $doContent = @(
        'set SRC {C:/Users/amitp/OneDrive/Desktop/Comp_Lab/Lab_5/DUT/RV32IM PIPLINE}',
        "set OUT {$outFwd}",
        'if {[file exists work]} { vdel -all -lib work }',
        'vlib work',
        'vmap work work',
        'vcom -work work -2008 -explicit "$SRC/cond_compilation_package.vhd"',
        'vcom -work work -2008 -explicit "$SRC/const_package.vhd"',
        'vcom -work work -2008 -explicit "$SRC/aux_package.vhd"',
        'vcom -work work -2008 -explicit "$SRC/CONTROL.VHD"',
        'vcom -work work -2008 -explicit "$SRC/IDECODE.vhd"',
        'vcom -work work -2008 -explicit "$SRC/IFETCH.VHD"',
        'vcom -work work -2008 -explicit "$SRC/EXECUTE.VHD"',
        'vcom -work work -2008 -explicit "$SRC/MUL_STAGE1.VHD"',
        'vcom -work work -2008 -explicit "$SRC/MUL_STAGE2.VHD"',
        'vcom -work work -2008 -explicit "$SRC/DMEMORY.VHD"',
        'vcom -work work -2008 -explicit "$SRC/WB_MUX.vhd"',
        'vcom -work work -2008 -explicit "$SRC/IF_ID_REG.vhd"',
        'vcom -work work -2008 -explicit "$SRC/ID_EX_REG.vhd"',
        'vcom -work work -2008 -explicit "$SRC/ex_mem_reg.vhd"',
        'vcom -work work -2008 -explicit "$SRC/MEM_WB_REG.vhd"',
        'vcom -work work -2008 -explicit "$SRC/forwarding_unit.vhd"',
        'vcom -work work -2008 -explicit "$SRC/STALL_UNIT.vhd"',
        'vcom -work work -2008 -explicit "$SRC/FLUSH_UNIT.vhd"',
        'vcom -work work -2008 -explicit "$SRC/RV32I_CORE_PIPLINE.vhd"',
        'vcom -work work -2008 -explicit "$SRC/tb_RV32I.vhd"',
        'vsim -c -L altera_mf -voptargs=+acc work.tb_RV32I',
        'run 20 us',
        'mem save -o "$OUT/DTCM_PIPLINE.mem" -f mti -data hex -addr hex -startaddress 0 -endaddress 2047 -wordsperline 1 sim:/tb_RV32I/CORE/DMEM_inst/data_memory/MEMORY/m_mem_data_a',
        'quit -f'
    )
    $doFile = "$SIM\run_test_$($t.Num).do"
    Set-Content $doFile $doContent -Encoding utf8
    Write-Host "  Running simulation..."

    $output = & $VSIM -c -do $doFile 2>&1
    $errors = $output | Where-Object { $_ -match "\*\* Error:" }
    if ($errors) {
        Write-Host "  COMPILE/SIM ERRORS:" -ForegroundColor Red
        $errors | Select-Object -First 5 | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
        $results += [pscustomobject]@{ Test = $t.Num; Status = "ERROR" }
        continue
    }

    $outMem = "$($t.OutDir)\DTCM_PIPLINE.mem"
    if (-not (Test-Path $outMem)) {
        Write-Host "  ERROR: DTCM_PIPLINE.mem not found after simulation." -ForegroundColor Red
        $results += [pscustomobject]@{ Test = $t.Num; Status = "NO_OUTPUT" }
        continue
    }

    Write-Host "  Comparing with RARS..."
    $cmp = Compare-DTCM $outMem $t.RARS
    if ($cmp.Mismatches -eq 0) {
        Write-Host "  PASS - all $($cmp.Total) words match RARS" -ForegroundColor Green
        $results += [pscustomobject]@{ Test = $t.Num; Status = "PASS"; Words = $cmp.Total }
    } else {
        $msg = "  FAIL - {0}/{1} words differ" -f $cmp.Mismatches, $cmp.Total
        Write-Host $msg -ForegroundColor Red
        $results += [pscustomobject]@{ Test = $t.Num; Status = "FAIL"; Mismatches = $cmp.Mismatches; Words = $cmp.Total }
    }
}

# Restore test1 paths
Write-Host ""
Write-Host "Restoring IFETCH/DMEMORY to test1 paths..." -ForegroundColor Gray
Patch-InitFile $IFETCH "C:/Users/amitp/OneDrive/Desktop/Comp_Lab/Lab_5/BENCHMARKS/test1/RV32IM/RV32IM PIPELINE/man_compiled/bin/M9K-intel/ITCM.hex"
Patch-InitFile $DMEM   "C:/Users/amitp/OneDrive/Desktop/Comp_Lab/Lab_5/BENCHMARKS/test1/RV32IM/RV32IM PIPELINE/man_compiled/bin/M9K-intel/DTCM.hex"

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  SUMMARY" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
foreach ($r in $results) {
    $color = if ($r.Status -eq "PASS") { "Green" } else { "Red" }
    Write-Host ("  Test {0}: {1}" -f $r.Test, $r.Status) -ForegroundColor $color
}
