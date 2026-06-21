@echo off
setlocal
set "SRC_PATH=%~1"
set "DEST_PATH=%~2"
set "CHOICE=%~3"
set "SCRIPT_PATH=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Content -LiteralPath '%~f0' | Select-Object -Skip 10 | Out-String | Invoke-Expression"
set "EXIT_CODE=%ERRORLEVEL%"
endlocal & exit /b %EXIT_CODE%

# PowerShell Code Starts Here
$SourcePath = $env:SRC_PATH

if ([string]::IsNullOrEmpty($SourcePath)) {
    Write-Host "[ERROR] No input detected." -ForegroundColor Red
    Write-Host "Please run this script via the 'Send To' context menu."
    Write-Host "`nPress Enter to close..."
    [void](Read-Host)
    exit 1
}

if (!(Test-Path $SourcePath)) {
    Write-Host "[ERROR] The selected item does not exist: $SourcePath" -ForegroundColor Red
    Write-Host "`nPress Enter to close..."
    [void](Read-Host)
    exit 1
}

$FolderName = Split-Path $SourcePath -Leaf
$IsFolder = Test-Path $SourcePath -PathType Container

# Register block clone C# structures/methods
$code = @"
using System;
using System.IO;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;

public static class BlockClone {
    private const uint FSCTL_DUPLICATE_EXTENTS_TO_FILE = 0x0009034c;

    [StructLayout(LayoutKind.Sequential)]
    private struct DUPLICATE_EXTENTS_DATA {
        public IntPtr FileHandle;
        public long SourceFileOffset;
        public long TargetFileOffset;
        public long ByteCount;
    }

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool DeviceIoControl(
        SafeFileHandle hDevice,
        uint dwIoControlCode,
        ref DUPLICATE_EXTENTS_DATA lpInBuffer,
        uint nInBufferSize,
        IntPtr lpOutBuffer,
        uint nOutBufferSize,
        out uint lpBytesReturned,
        IntPtr lpOverlapped
    );

    public static void CloneFile(string sourcePath, string targetPath) {
        sourcePath = Path.GetFullPath(sourcePath);
        targetPath = Path.GetFullPath(targetPath);

        FileInfo sourceInfo = new FileInfo(sourcePath);
        if (!sourceInfo.Exists) {
            throw new FileNotFoundException("Source file not found", sourcePath);
        }
        long size = sourceInfo.Length;

        if (File.Exists(targetPath)) {
            File.Delete(targetPath);
        }

        using (FileStream fs = File.Create(targetPath)) {
            if (size > 0) {
                fs.SetLength(size);
            }
        }

        if (size == 0) {
            return;
        }

        using (FileStream sourceStream = new FileStream(sourcePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
        using (FileStream targetStream = new FileStream(targetPath, FileMode.Open, FileAccess.Write, FileShare.ReadWrite)) {
            SafeFileHandle sourceHandle = sourceStream.SafeFileHandle;
            SafeFileHandle targetHandle = targetStream.SafeFileHandle;

            DUPLICATE_EXTENTS_DATA data = new DUPLICATE_EXTENTS_DATA {
                FileHandle = sourceHandle.DangerousGetHandle(),
                SourceFileOffset = 0,
                TargetFileOffset = 0,
                ByteCount = size
            };

            uint bytesReturned = 0;
            bool success = DeviceIoControl(
                targetHandle,
                FSCTL_DUPLICATE_EXTENTS_TO_FILE,
                ref data,
                (uint)Marshal.SizeOf(data),
                IntPtr.Zero,
                0,
                out bytesReturned,
                IntPtr.Zero
            );

            if (!success) {
                int error = Marshal.GetLastWin32Error();
                throw new System.ComponentModel.Win32Exception(error);
            }
        }
    }
}
"@

# Helper function for recursive cloning of directories
function Clone-Directory($src, $dst) {
    if (!(Test-Path $dst)) {
        New-Item -ItemType Directory -Path $dst | Out-Null
    }
    Get-ChildItem $src -Force | ForEach-Object {
        $srcPath = $_.FullName
        $dstPath = Join-Path $dst $_.Name
        if ($_.PSIsContainer) {
            Clone-Directory $srcPath $dstPath
        } else {
            [BlockClone]::CloneFile($srcPath, $dstPath)
        }
    }
}

$LinkPath = ""
$Choice = ""
$IsRelaunched = $false

if (-not [string]::IsNullOrEmpty($env:DEST_PATH) -and -not [string]::IsNullOrEmpty($env:CHOICE)) {
    $LinkPath = $env:DEST_PATH
    $Choice = $env:CHOICE
    $IsRelaunched = $true
}

if (-not $IsRelaunched) {
    while ($true) {
        Write-Host "`nSource Path: `"$SourcePath`""
        Write-Host "Name: `"$FolderName`""
        Write-Host "-------------------------------------------------------"
        Write-Host "DESTINATION SELECTION"
        Write-Host "-------------------------------------------------------"
        Write-Host "Please enter the FULL PATH for the new link/clone."
        Write-Host "(Include the name of the link itself)"
        Write-Host "`nExample: `"D:\MyLinks\$FolderName`" or `"C:\Archive\MyLinkName`""
        Write-Host "`n[Press ENTER without typing to open a GUI Folder Picker]"
        
        $inputPath = Read-Host "Full Destination Path"
        
        if ([string]::IsNullOrWhiteSpace($inputPath)) {
            if ($env:TEST_MODE -eq "1") {
                Write-Host "`n[ERROR] Target path cannot be empty in test mode." -ForegroundColor Red
                continue
            }
            Write-Host "`nOpening Folder Selection Window..."
            $app = New-Object -ComObject Shell.Application
            $folder = $app.BrowseForFolder(0, 'Select the PARENT folder for the link/clone:', 0, 0)
            if ($folder) {
                $SelectedDir = $folder.Self.Path
                $LinkPath = Join-Path $SelectedDir $FolderName
            } else {
                Write-Host "`n[CANCELED] No folder selected. Returning to selection..." -ForegroundColor Yellow
                continue
            }
        } else {
            $LinkPath = $inputPath
        }
        
        # Clean surrounding quotes
        $LinkPath = $LinkPath -replace '"', ''
        
        # Validate
        if (Test-Path $LinkPath) {
            Write-Host "`n[ERROR] The target path already exists: `"$LinkPath`"" -ForegroundColor Red
            Write-Host "Please enter a unique target path."
            continue
        }
        
        $ParentDir = Split-Path $LinkPath -Parent
        if (-not [string]::IsNullOrEmpty($ParentDir) -and -not (Test-Path $ParentDir)) {
            Write-Host "`n[ERROR] The parent directory does not exist: `"$ParentDir`"" -ForegroundColor Red
            Write-Host "Please create the parent folder first or enter another path."
            continue
        }
        
        break
    }

    while ($true) {
        Write-Host "`n-------------------------------------------------------"
        Write-Host "LINK/CLONE TYPE SELECTION"
        Write-Host "-------------------------------------------------------"
        
        if ($IsFolder) {
            Write-Host "[1] Directory Junction (Default)"
            Write-Host "[2] Directory Symbolic Link (Requires Dev Mode/Admin)"
            Write-Host "[3] Copy-on-Write Clone (ReFS/Dev Drive only)"
        } else {
            Write-Host "[1] Symbolic Link (Default, Requires Dev Mode/Admin)"
            Write-Host "[2] Hard Link"
            Write-Host "[3] Copy-on-Write Clone (ReFS/Dev Drive only)"
        }
        Write-Host ""
        
        $Choice = Read-Host "Enter choice [1-3] (Default: 1)"
        if ([string]::IsNullOrWhiteSpace($Choice)) {
            $Choice = "1"
        }
        
        if ($Choice -match '^[1-3]$') {
            break
        }
        Write-Host "Invalid choice. Please try again." -ForegroundColor Red
    }
} else {
    Write-Host "`nSource Path: `"$SourcePath`""
    Write-Host "Name: `"$FolderName`""
}

Write-Host "`nCreating..."
Write-Host "-------------------------------------------------------"
Write-Host "FROM: `"$LinkPath`""
Write-Host "TO:   `"$SourcePath`""
Write-Host "-------------------------------------------------------"

$OperationSuccess = $false
try {
    if ($Choice -eq "3") {
        # Lazy compile the C# P/Invoke helper
        Add-Type -TypeDefinition $code -ErrorAction Stop
        
        $createdTarget = $false
        if (!(Test-Path $LinkPath)) {
            $createdTarget = $true
        }
        
        try {
            if ($IsFolder) {
                Clone-Directory $SourcePath $LinkPath
            } else {
                [BlockClone]::CloneFile($SourcePath, $LinkPath)
            }
            Write-Host "`n[SUCCESS] Copy-on-Write Clone created successfully!" -ForegroundColor Green
            $OperationSuccess = $true
        } catch {
            if ($createdTarget -and (Test-Path $LinkPath)) {
                Remove-Item $LinkPath -Recurse -Force | Out-Null
            }
            throw
        }
    } else {
        if ($IsFolder) {
            if ($Choice -eq "1") {
                New-Item -ItemType Junction -Path $LinkPath -Value $SourcePath -ErrorAction Stop | Out-Null
            } else {
                New-Item -ItemType SymbolicLink -Path $LinkPath -Value $SourcePath -ErrorAction Stop | Out-Null
            }
        } else {
            if ($Choice -eq "1") {
                New-Item -ItemType SymbolicLink -Path $LinkPath -Value $SourcePath -ErrorAction Stop | Out-Null
            } else {
                New-Item -ItemType HardLink -Path $LinkPath -Value $SourcePath -ErrorAction Stop | Out-Null
            }
        }
        Write-Host "`n[SUCCESS] Link created successfully!" -ForegroundColor Green
        $OperationSuccess = $true
    }
} catch {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $isAccessError = ($_.Exception -is [System.UnauthorizedAccessException]) -or 
                     ($_.Exception.Message -like "*access*") -or 
                     ($_.Exception.Message -like "*denied*") -or
                     ($_.Exception.InnerException.Message -like "*access*") -or
                     ($_.Exception.InnerException.Message -like "*denied*")
    
    if (-not $isAdmin -and $isAccessError -and $env:TEST_MODE -ne "1") {
        Write-Host "`n[INFO] Access denied. Requesting administrative privileges..." -ForegroundColor Yellow
        try {
            $proc = Start-Process -FilePath "$env:SCRIPT_PATH" -ArgumentList $SourcePath, $LinkPath, $Choice -Verb RunAs -PassThru -Wait -ErrorAction Stop
            if ($proc.ExitCode -eq 0) {
                Write-Host "`n[SUCCESS] Link created successfully (elevated)!" -ForegroundColor Green
                $OperationSuccess = $true
            } else {
                Write-Host "`n[ERROR] Elevated operation failed." -ForegroundColor Red
            }
        } catch {
            Write-Host "`n[ERROR] Failed to elevate: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "`n[ERROR] Failed to perform the operation." -ForegroundColor Red
        Write-Host "$($_.Exception.Message)" -ForegroundColor Red
    }
}

if ($env:TEST_MODE -ne "1") {
    if ($IsRelaunched -and $OperationSuccess) {
        # Exit immediately for elevated process on success
    } else {
        Write-Host "`nPress Enter to close..."
        [void](Read-Host)
    }
}

if (-not $OperationSuccess) {
    exit 1
}