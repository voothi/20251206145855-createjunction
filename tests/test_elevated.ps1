# Elevated Link/Junction Creation Test Suite

$ScriptDir = Split-Path $PSScriptRoot -Parent
$CreatorScript = Join-Path $ScriptDir "сreate_junction.cmd"
$Sandbox = Join-Path $PSScriptRoot "test_sandbox_elevated"

# Ensure clean sandbox
if (Test-Path $Sandbox) {
    Remove-Item $Sandbox -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $Sandbox | Out-Null

try {
    # Setup test 1: Junction (does not strictly require Admin but runs arguments flow)
    $srcJunction = New-Item -ItemType Directory -Path (Join-Path $Sandbox "SourceJunction")
    $dstJunction = Join-Path $Sandbox "TargetJunction"
    
    # Setup test 2: Symbolic Link (requires Admin/Elevation, with spaces and trailing backslashes)
    $srcSymlink = New-Item -ItemType Directory -Path (Join-Path $Sandbox "Source Symlink Dir\")
    $dstSymlink = Join-Path $Sandbox "Target Symlink Dir\"
    
    Write-Host "=======================================================" -ForegroundColor Cyan
    Write-Host "RUNNING ELEVATED OPERATION TESTS (UAC prompt(s) will appear)" -ForegroundColor Cyan
    Write-Host "Please click [Yes] in the UAC prompt(s) to proceed." -ForegroundColor Yellow
    Write-Host "=======================================================" -ForegroundColor Cyan

    # Test 1: Junction (Choice 1 for directory)
    Write-Host "`n[Test 1] Creating Directory Junction..." -ForegroundColor Yellow
    $argStr1 = "/c `"`"$CreatorScript`" `"$srcJunction`" `"$dstJunction`" 1`""
    $proc1 = Start-Process cmd.exe -ArgumentList $argStr1 -Verb RunAs -PassThru -Wait
    
    $jPassed = $false
    if ($proc1.ExitCode -eq 0 -and (Test-Path $dstJunction)) {
        $item = Get-Item $dstJunction
        if ($item.LinkType -eq "Junction") {
            Write-Host "  [PASS] Junction created successfully!" -ForegroundColor Green
            $jPassed = $true
        }
    }
    if (-not $jPassed) {
        Write-Host "  [FAIL] Junction creation failed (ExitCode: $($proc1.ExitCode))" -ForegroundColor Red
    }

    # Test 2: Directory Symbolic Link (Choice 2 for directory)
    Write-Host "`n[Test 2] Creating Directory Symbolic Link (spaces and trailing backslashes)..." -ForegroundColor Yellow
    $argStr2 = "/c `"`"$CreatorScript`" `"$srcSymlink`" `"$dstSymlink`" 2`""
    $proc2 = Start-Process cmd.exe -ArgumentList $argStr2 -Verb RunAs -PassThru -Wait
    
    $sPassed = $false
    if ($proc2.ExitCode -eq 0 -and (Test-Path $dstSymlink)) {
        $item = Get-Item $dstSymlink
        if ($item.LinkType -eq "SymbolicLink") {
            Write-Host "  [PASS] Directory Symbolic Link created successfully!" -ForegroundColor Green
            $sPassed = $true
        }
    }
    if (-not $sPassed) {
        Write-Host "  [FAIL] Directory Symbolic Link creation failed (ExitCode: $($proc2.ExitCode))" -ForegroundColor Red
    }

    Write-Host "`n=======================================================" -ForegroundColor Cyan
    if ($jPassed -and $sPassed) {
        Write-Host "ALL ELEVATION TESTS PASSED SUCCESSFULLY!" -ForegroundColor Green
    } else {
        Write-Host "SOME ELEVATION TESTS FAILED." -ForegroundColor Red
        exit 1
    }
} finally {
    # Clean up sandbox
    if (Test-Path $Sandbox) {
        Remove-Item $Sandbox -Recurse -Force -ErrorAction SilentlyContinue
    }
}
