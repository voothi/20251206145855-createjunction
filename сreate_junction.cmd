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
echo Please enter the FULL PATH for the new junction.
echo (Include the name of the junction itself)
echo.
echo Example: "D:\MyLinks\%FolderName%" or "C:\Archive\MyLinkName"
echo.
echo [Press ENTER without typing to open a GUI Input Window]
echo.

set "LinkPath="
set /p "LinkPath=Full Junction Path: "

if defined LinkPath goto :ValidateTarget

:: --- STEP 2: GUI Input Fallback ---
echo.
echo Opening GUI Input Window...
echo (Please check your taskbar if the window is hidden)

set "PSFile=%TEMP%\AskPath_%RANDOM%.ps1"

(
    echo Add-Type -AssemblyName Microsoft.VisualBasic
    echo $msg = "Enter the FULL PATH for the new junction." + [Environment]::NewLine + [Environment]::NewLine + "Example: D:\Links\%FolderName%"
    echo $title = "Select Junction Destination"
    echo $default = "D:\Links\%FolderName%"
    echo $path = [Microsoft.VisualBasic.Interaction]::InputBox^($msg, $title, $default^)
    echo if ^(![string]::IsNullOrWhiteSpace^($path^)^) { $path }
) > "%PSFile%"

for /f "usebackq delims=" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%PSFile%"`) do (
    set "LinkPath=%%I"
)

del "%PSFile%"

:ValidateTarget
if "%LinkPath%"=="" (
    echo.
    echo [CANCELED] No path provided.
    goto :End
)

:: Remove surrounding quotes if user entered them
set "LinkPath=%LinkPath:"=%"

:: Validate that the link doesn't already exist
if exist "%LinkPath%\" (
    echo.
    echo [ERROR] The target path already exists as a folder:
    echo "%LinkPath%"
    echo Junction cannot be created over an existing folder.
    goto :End
)
if exist "%LinkPath%" (
    echo.
    echo [ERROR] The target path already exists as a file:
    echo "%LinkPath%"
    goto :End
)

:: Validate parent directory exists (a bit tricky in pure batch for arbitrary input, but let's try basic check)
for %%I in ("%LinkPath%") do set "ParentDir=%%~dpI"
if not exist "%ParentDir%" (
    echo.
    echo [ERROR] The parent directory does not exist:
    echo "%ParentDir%"
    echo Please create the parent folder first.
    goto :End
)

:: --- STEP 3: Create Junction ---
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
)

:End
echo.
echo Press any key to close...
pause >nul