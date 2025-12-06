@echo off
setlocal enableextensions

echo --- DIAGNOSTICS START ---

:: 1. Check Input
if "%~1"=="" (
    echo [ERROR] No input detected.
    echo Please use "Send To".
    goto :FinalEnd
)

:: 2. Check if Folder
if not exist "%~1\" (
    echo [ERROR] Target is not a folder.
    echo You selected: "%~1"
    goto :FinalEnd
)

set "SourcePath=%~1"
echo Source Folder: "%SourcePath%"

:: 3. Detect Desktop (Stable Method)
:: By default, assume standard Desktop
set "RealDesktop=%USERPROFILE%\Desktop"

:: Check if OneDrive Desktop exists and use it if found
if defined OneDrive (
    if exist "%OneDrive%\Desktop" (
        set "RealDesktop=%OneDrive%\Desktop"
        echo [INFO] OneDrive Desktop detected.
    )
)

echo Target Desktop: "%RealDesktop%"

:: 4. Construct Path
set "DestPath=%RealDesktop%\%~n1 - Junction"
echo Link Path: "%DestPath%"

:: 5. Execute
echo.
echo Attempting to create junction...
echo ------------------------------
mklink /J "%DestPath%" "%SourcePath%"
echo ------------------------------

if %errorlevel%==0 (
    echo [SUCCESS] Created successfully!
) else (
    echo [ERROR] Code: %errorlevel%. Check permissions or if name exists.
)

:FinalEnd
echo.
echo Press any key to close...
pause