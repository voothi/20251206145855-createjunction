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




:AskPath
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

:: If not defined or only spaces, fall through to GUI
if not defined LinkPath goto :ShowGUI
set "TestInput=%LinkPath: =%"


if "%TestInput%"=="" (
    set "LinkPath="
    goto :ShowGUI
)

:: Trim leading spaces
for /f "tokens=*" %%A in ("%LinkPath%") do set "LinkPath=%%A"

goto :ValidateTarget

:ShowGUI
:: --- STEP 2: GUI Input Fallback (Folder Tree) ---
echo.
echo Opening Folder Selection Window...
echo (Please check your taskbar if the window is hidden)

set "PSFile=%TEMP%\AskPath_%RANDOM%.ps1"

(
    echo $app = New-Object -COM 'Shell.Application'
    echo $folder = $app.BrowseForFolder(0, 'Select the PARENT folder for the junction:', 0, 0^)
    echo if ^($folder^) { $folder.Self.Path }
) > "%PSFile%"

set "SelectedDir="
for /f "usebackq delims=" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%PSFile%"`) do (
    set "SelectedDir=%%I"
)

del "%PSFile%"

if defined SelectedDir (
    :: If user picked a folder via GUI, append the junction name
    set "LinkPath=%SelectedDir%\%FolderName%"
)



:ValidateTarget
if "%LinkPath%"=="" (
    echo.
    echo [CANCELED] No path provided. Returning to selection...
    goto :AskPath
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