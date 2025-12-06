@echo off
setlocal

:: --- STEP 1: Check Input ---
if "%~1"=="" (
    echo [ERROR] No input detected.
    echo Please run this script via the "Send To" context menu.
    goto :End
)

if not exist "%~1\" (
    echo [ERROR] The selected item is NOT a folder.
    echo Junctions can only be created for folders.
    goto :End
)

set "SourcePath=%~1"
set "FolderName=%~nx1"

echo.
echo Source: "%SourcePath%"
echo.
echo -------------------------------------------------------
echo Opening Folder Selection Dialog...
echo (Please check your taskbar if the window is hidden)
echo -------------------------------------------------------

:: --- STEP 2: Create a temporary PowerShell script ---
:: This avoids syntax errors with quotes in CMD
set "PSFile=%TEMP%\ChooseFolder_%RANDOM%.ps1"

(
    echo $app = New-Object -COM 'Shell.Application'
    echo $folder = $app.BrowseForFolder(0, 'Select the DESTINATION folder:', 0, 0^)
    echo if ^($folder^) { $folder.Self.Path }
) > "%PSFile%"

:: --- STEP 3: Run the PowerShell script and capture output ---
set "TargetDir="
for /f "usebackq delims=" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%PSFile%"`) do (
    set "TargetDir=%%I"
)

:: Clean up temp file
del "%PSFile%"

:: --- STEP 4: Validate Selection ---
if "%TargetDir%"=="" (
    echo.
    echo [CANCELED] No folder selected or operation canceled.
    goto :End
)

:: --- STEP 5: Create Junction ---
set "LinkPath=%TargetDir%\%FolderName%"

echo.
echo Creating Junction...
echo -------------------------------------------------------
echo FROM: "%LinkPath%"
echo TO:   "%SourcePath%"
echo -------------------------------------------------------

mklink /J "%LinkPath%" "%SourcePath%"

if %errorlevel%==0 (
    echo.
    echo [SUCCESS] Junction created successfully!
) else (
    echo.
    echo [ERROR] Failed to create Junction.
    echo Check if the folder name already exists in the destination.
)

:End
echo.
echo Press any key to close...
pause >nul