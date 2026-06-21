# Automated Test Suite for Link and Clone Creator

$code = @'
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;
using System.IO;

public class FileTestHelper {
    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    private static extern bool GetFileInformationByHandle(SafeFileHandle hFile, out BY_HANDLE_FILE_INFORMATION lpFileInformation);

    [StructLayout(LayoutKind.Sequential)]
    private struct BY_HANDLE_FILE_INFORMATION {
        public uint FileAttributes;
        public System.Runtime.InteropServices.ComTypes.FILETIME CreationTime;
        public System.Runtime.InteropServices.ComTypes.FILETIME LastAccessTime;
        public System.Runtime.InteropServices.ComTypes.FILETIME LastWriteTime;
        public uint VolumeSerialNumber;
        public uint FileSizeHigh;
        public uint FileSizeLow;
        public uint NumberOfLinks;
        public uint FileIndexHigh;
        public uint FileIndexLow;
    }

    public static string GetFileId(string filePath) {
        using (var fs = new FileStream(filePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite)) {
            BY_HANDLE_FILE_INFORMATION info;
            if (GetFileInformationByHandle(fs.SafeFileHandle, out info)) {
                return info.VolumeSerialNumber.ToString() + "-" + info.FileIndexHigh.ToString() + "-" + info.FileIndexLow.ToString();
            }
        }
        return null;
    }
}
'@

# Inject hard link validation helper
Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue

# Enable non-interactive test mode to bypass GUI popups and end-of-script pauses
$env:TEST_MODE = "1"

$ScriptDir = Split-Path $PSScriptRoot -Parent
$CreatorScript = Join-Path $ScriptDir "сreate_junction.cmd"
$Sandbox = Join-Path $PSScriptRoot "test_sandbox"

$testsPassed = 0
$testsFailed = 0

function Assert-True($condition, $message) {
    if ($condition) {
        Write-Host "  [PASS] $message" -ForegroundColor Green
        $global:testsPassed++
    } else {
        Write-Host "  [FAIL] $message" -ForegroundColor Red
        $global:testsFailed++
    }
}

function Setup-Sandbox {
    if (Test-Path $Sandbox) {
        Remove-Item $Sandbox -Recurse -Force | Out-Null
    }
    New-Item -ItemType Directory -Path $Sandbox | Out-Null
}

function Teardown-Sandbox {
    if (Test-Path $Sandbox) {
        Remove-Item $Sandbox -Recurse -Force | Out-Null
    }
}

# Run the tests
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "RUNNING LINK & CLONE CREATOR AUTOMATED TESTS" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

try {
    # ----------------------------------------------------
    # Test Case 1: Directory Junction (Folder Option 1)
    # ----------------------------------------------------
    Setup-Sandbox
    Write-Host "`nTest Case 1: Directory Junction" -ForegroundColor Yellow
    $src = New-Item -ItemType Directory -Path (Join-Path $Sandbox "SourceFolder")
    $dst = Join-Path $Sandbox "TargetJunction"
    
    # Run script with options: Target Path, Option 1 (Junction)
    $inputs = "$dst`n1`n"
    $inputs | cmd.exe /c `"`"$CreatorScript`" `"$src`"`" | Out-Null
    
    Assert-True (Test-Path $dst) "Target path exists"
    if (Test-Path $dst) {
        $item = Get-Item $dst
        Assert-True ($item.Attributes -match "ReparsePoint") "Target has ReparsePoint attribute"
        Assert-True ($item.LinkType -eq "Junction") "Target LinkType is Junction"
    }

    # ----------------------------------------------------
    # Test Case 2: Directory Symbolic Link (Folder Option 2)
    # ----------------------------------------------------
    Setup-Sandbox
    Write-Host "`nTest Case 2: Directory Symbolic Link" -ForegroundColor Yellow
    $src = New-Item -ItemType Directory -Path (Join-Path $Sandbox "SourceFolder")
    $dst = Join-Path $Sandbox "TargetSymlinkDir"
    
    $inputs = "$dst`n2`n"
    $output = $inputs | cmd.exe /c `"`"$CreatorScript`" `"$src`"`" 2>&1 | Out-String
    
    if ($output -match "privilege" -or $output -match "sufficient") {
        Write-Host "  [SKIP] Directory Symlink skipped due to privilege restrictions." -ForegroundColor Yellow
    } else {
        Assert-True (Test-Path $dst) "Target path exists"
        if (Test-Path $dst) {
            $item = Get-Item $dst
            Assert-True ($item.Attributes -match "ReparsePoint") "Target has ReparsePoint attribute"
            Assert-True ($item.LinkType -eq "SymbolicLink") "Target LinkType is SymbolicLink"
        }
    }

    # ----------------------------------------------------
    # Test Case 3: File Symbolic Link (File Option 1)
    # ----------------------------------------------------
    Setup-Sandbox
    Write-Host "`nTest Case 3: File Symbolic Link" -ForegroundColor Yellow
    $src = Join-Path $Sandbox "SourceFile.txt"
    Set-Content -Path $src -Value "File Content"
    $dst = Join-Path $Sandbox "TargetSymlinkFile.txt"
    
    $inputs = "$dst`n1`n"
    $output = $inputs | cmd.exe /c `"`"$CreatorScript`" `"$src`"`" 2>&1 | Out-String
    
    if ($output -match "privilege" -or $output -match "sufficient") {
        Write-Host "  [SKIP] File Symlink skipped due to privilege restrictions." -ForegroundColor Yellow
    } else {
        Assert-True (Test-Path $dst) "Target path exists"
        if (Test-Path $dst) {
            $item = Get-Item $dst
            Assert-True ($item.Attributes -match "ReparsePoint") "Target has ReparsePoint attribute"
            Assert-True ($item.LinkType -eq "SymbolicLink") "Target LinkType is SymbolicLink"
        }
    }

    # ----------------------------------------------------
    # Test Case 4: File Hard Link (File Option 2)
    # ----------------------------------------------------
    Setup-Sandbox
    Write-Host "`nTest Case 4: File Hard Link" -ForegroundColor Yellow
    $src = Join-Path $Sandbox "SourceFile.txt"
    Set-Content -Path $src -Value "Hello Hardlink"
    $dst = Join-Path $Sandbox "TargetHardlink.txt"
    
    $inputs = "$dst`n2`n"
    $inputs | cmd.exe /c `"`"$CreatorScript`" `"$src`"`" | Out-Null
    
    Assert-True (Test-Path $dst) "Target path exists"
    if (Test-Path $dst) {
        $srcId = [FileTestHelper]::GetFileId($src)
        $dstId = [FileTestHelper]::GetFileId($dst)
        Assert-True ($srcId -eq $dstId) "Both files share the identical file index on disk"
    }

    # ----------------------------------------------------
    # Test Case 5: File Copy-on-Write Clone Failure on NTFS (File Option 3)
    # ----------------------------------------------------
    Setup-Sandbox
    Write-Host "`nTest Case 5: File CoW Clone NTFS error handling" -ForegroundColor Yellow
    $src = Join-Path $Sandbox "SourceFile.txt"
    Set-Content -Path $src -Value "Hello CoW"
    $dst = Join-Path $Sandbox "TargetCoW.txt"
    
    $inputs = "$dst`n3`n"
    $output = $inputs | cmd.exe /c `"`"$CreatorScript`" `"$src`"`" 2>&1 | Out-String
    
    # We are on NTFS, so it must fail with filesystem error
    Assert-True ($output -match "Failed" -or $output -match "incorrect") "Fails with error status"
    Assert-True (!(Test-Path $dst)) "Target file is cleaned up and does not remain on disk"

    # ----------------------------------------------------
    # Test Case 6: Target Path Already Exists Validation
    # ----------------------------------------------------
    Setup-Sandbox
    Write-Host "`nTest Case 6: Target path already exists validation" -ForegroundColor Yellow
    $src = Join-Path $Sandbox "SourceFile.txt"
    Set-Content -Path $src -Value "Hello Source"
    $dst = Join-Path $Sandbox "TargetExists.txt"
    Set-Content -Path $dst -Value "Hello Target"
    $dummy = Join-Path $Sandbox "TargetNonExists.txt"
    
    # Input sequence: 
    # 1st attempt: $dst (exists -> error & loops back)
    # 2nd attempt: $dummy (does not exist -> loops exit)
    # 3rd input: 2 (creates hard link)
    $inputs = "$dst`n$dummy`n2`n"
    $output = $inputs | cmd.exe /c `"`"$CreatorScript`" `"$src`"`" 2>&1 | Out-String
    Assert-True ($output -match "already exists") "Validation blocks creation on existing path"
    Assert-True (Test-Path $dummy) "Target path successfully falls back to new location"
    # ----------------------------------------------------
    # Test Case 7: Direct Argument Invocation (Junction)
    # ----------------------------------------------------
    Setup-Sandbox
    Write-Host "`nTest Case 7: Direct Argument Invocation (Junction)" -ForegroundColor Yellow
    $src = New-Item -ItemType Directory -Path (Join-Path $Sandbox "SourceFolder")
    $dst = Join-Path $Sandbox "TargetJunctionArgs"
    
    cmd.exe /c `"`"$CreatorScript`" `"$src`" `"$dst`" 1`"
    $exitCode = $LASTEXITCODE
    
    Assert-True ($exitCode -eq 0) "Script exits with code 0"
    Assert-True (Test-Path $dst) "Target path exists"
    if (Test-Path $dst) {
        $item = Get-Item $dst
        Assert-True ($item.LinkType -eq "Junction") "Target LinkType is Junction"
    }

    # ----------------------------------------------------
    # Test Case 8: Direct Argument Invocation with Spaces
    # ----------------------------------------------------
    Setup-Sandbox
    Write-Host "`nTest Case 8: Direct Argument Invocation with Spaces" -ForegroundColor Yellow
    $src = New-Item -ItemType Directory -Path (Join-Path $Sandbox "Source Folder Spaces")
    $dst = Join-Path $Sandbox "Target Junction Spaces"
    
    cmd.exe /c `"`"$CreatorScript`" `"$src`" `"$dst`" 1`"
    $exitCode = $LASTEXITCODE
    
    Assert-True ($exitCode -eq 0) "Script exits with code 0 for path with spaces"
    Assert-True (Test-Path $dst) "Target path with spaces exists"
    if (Test-Path $dst) {
        $item = Get-Item $dst
        Assert-True ($item.LinkType -eq "Junction") "Target LinkType is Junction"
    }

    # ----------------------------------------------------
    # Test Case 9: Interactive Input with Surrounding Quotes
    # ----------------------------------------------------
    Setup-Sandbox
    Write-Host "`nTest Case 9: Interactive Input with Surrounding Quotes" -ForegroundColor Yellow
    $src = New-Item -ItemType Directory -Path (Join-Path $Sandbox "SourceFolder")
    $dst = Join-Path $Sandbox "TargetJunctionQuotes"
    
    # Input with explicit surrounding double quotes
    $inputs = "`"$dst`"`n1`n"
    $inputs | cmd.exe /c `"`"$CreatorScript`" `"$src`"`" | Out-Null
    
    Assert-True (Test-Path $dst) "Target path with surrounding quotes is resolved"
    if (Test-Path $dst) {
        $item = Get-Item $dst
        Assert-True ($item.LinkType -eq "Junction") "Target LinkType is Junction"
    }

} finally {
    $env:TEST_MODE = $null
    Teardown-Sandbox
}

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "TEST SUMMARY" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "Passed: $testsPassed" -ForegroundColor Green
if ($testsFailed -gt 0) {
    Write-Host "Failed: $testsFailed" -ForegroundColor Red
    exit 1
} else {
    Write-Host "All run tests passed successfully!" -ForegroundColor Green
    exit 0
}
