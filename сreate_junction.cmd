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
echo Source Folder: "%SourcePath%"
echo Junction Name: "%FolderName%"
echo.
echo -------------------------------------------------------
echo DESTINATION SELECTION
echo -------------------------------------------------------
echo Please enter the PARENT directory where the junction will be created.
echo (Do NOT include the junction name in the path)
echo.
echo Example: If you enter "D:\MyLinks", the junction will be "D:\MyLinks\%FolderName%"
echo.
echo [Press ENTER without typing to open a GUI Input Window]
echo.

set "TargetDir="
set /p "TargetDir=Destination Parent Path: "

if defined TargetDir goto :ValidateTarget

:: --- STEP 2: GUI Input Fallback ---
echo.
echo Opening GUI Input Window...
echo (Please check your taskbar if the window is hidden)

set "PSFile=%TEMP%\AskPath_%RANDOM%.ps1"

(
    echo Add-Type -AssemblyName Microsoft.VisualBasic
    echo $msg = "Enter the PARENT DIRECTORY path where the junction will be created." + [Environment]::NewLine + [Environment]::NewLine + "The junction will be named: %FolderName%" + [Environment]::NewLine + [Environment]::NewLine + "Do NOT include the junction name in the path."
    echo $title = "Select Junction Destination"
    echo $path = [Microsoft.VisualBasic.Interaction]::InputBox^($msg, $title, ""^)
    echo if ^(![string]::IsNullOrWhiteSpace^($path^)^) { $path }
) > "%PSFile%"

for /f "usebackq delims=" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%PSFile%"`) do (
    set "TargetDir=%%I"
)

del "%PSFile%"

:ValidateTarget
if "%TargetDir%"=="" (
    echo.
    echo [CANCELED] No folder provided.
    goto :End
)

:: Remove surrounding quotes if user entered them
set "TargetDir=%TargetDir:"=%"

if not exist "%TargetDir%\" (
    echo.
    echo [ERROR] Destination directory does not exist:
    echo "%TargetDir%"
    echo Please ensure the parent folder exists.
    goto :End
)

:: --- STEP 3: Create Junction ---
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
    echo Check if "%FolderName%" already exists in "%TargetDir%".
)

:End
echo.
echo Press any key to close...
pause >nul