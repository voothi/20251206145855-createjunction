@echo off
setlocal

:: 1. Check Input
if "%~1"=="" (
    echo [ERROR] No input detected.
    echo Please use the "Send to" context menu.
    pause
    exit /b
)

:: 2. Check if Source is a Folder
if not exist "%~1\" (
    echo [ERROR] Invalid target.
    echo Junctions (/J) can only be created for FOLDERS.
    pause
    exit /b
)

set "SourcePath=%~1"
set "FolderName=%~nx1"

echo.
echo Source: "%SourcePath%"
echo.
echo ==========================================
echo   Select the DESTINATION folder in the
echo   pop-up window...
echo ==========================================

:: 3. Open "Browse For Folder" Dialog via PowerShell
set "PSCmd="(new-object -COM 'Shell.Application').BrowseForFolder(0,'Select the folder where you want to create the Junction link:',0,0).self.path""

set "ParentDir="
for /f "usebackq delims=" %%I in (`powershell -NoProfile -Command %PSCmd%`) do set "ParentDir=%%I"

:: 4. Check if user cancelled
if not defined ParentDir (
    echo.
    echo [INFO] Operation cancelled by user.
    timeout /t 2 >nul
    exit /b
)

:: 5. Construct Final Path
:: The link will have the same name as the original folder
set "LinkPath=%ParentDir%\%FolderName%"

echo.
echo Creating Junction...
echo Link:   "%LinkPath%"
echo Target: "%SourcePath%"
echo.

:: 6. Create Junction
mklink /J "%LinkPath%" "%SourcePath%"

if %errorlevel%==0 (
    echo.
    echo [SUCCESS] Junction created successfully!
    timeout /t 3 >nul
) else (
    echo.
    echo [ERROR] Failed to create Junction.
    echo A folder with this name might already exist in the destination.
    pause
)