@echo off
chcp 65001 >nul
setlocal

:: 1. Check if a path was passed (via Send To)
if "%~1"=="" (
    echo Error: No input detected.
    echo Please use the "Send to" context menu.
    pause
    exit /b
)

:: 2. Check if the input is a Directory
:: (Junctions cannot be created for individual files)
if not exist "%~1\" (
    echo Error: Invalid target.
    echo Junctions (/J) can only be created for FOLDERS.
    echo You selected a file: "%~nx1"
    pause
    exit /b
)

:: 3. Set Paths
:: Source: The folder you right-clicked on
set "SourcePath=%~1"
:: Destination: Your Desktop + Folder Name + " - Junction" suffix
set "DestPath=%USERPROFILE%\Desktop\%~n1 - Junction"

:: 4. Execution
echo ==================================================
echo Creating Directory Junction...
echo Source:      "%SourcePath%"
echo Destination: "%DestPath%"
echo ==================================================
echo.

mklink /J "%DestPath%" "%SourcePath%"

:: 5. Result Verification
if %errorlevel%==0 (
    echo.
    echo [SUCCESS] Junction created on your Desktop.
    timeout /t 2 >nul
) else (
    echo.
    echo [ERROR] Failed to create Junction.
    echo A file/folder with this name might already exist on the Desktop.
    pause
)