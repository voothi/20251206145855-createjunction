# Windows Junction Creator (Context Menu)

A simple, lightweight Windows Batch script that allows you to create **Directory Junctions** (`mklink /J`) directly from the Windows File Explorer context menu via the "Send to" feature.

It creates the junction on your **Desktop**, allowing you to easily move it wherever you need it afterwards.

## 🚀 Features

*   **No external software:** Uses native Windows `mklink` command.
*   **Safety checks:** Ensures the selected item is a folder (Junctions do not work on files).
*   **Convenient:** Creates the link on the Desktop with a clear name (`TargetName - Junction`).
*   **English Interface:** Clear success/error messages in the console window.

## 📥 Installation

You do not need to install any program. You only need to place a shortcut to the script in your "Send to" folder.

1.  **Download/Create the script:**
    *   Create a file named `create_junction.cmd`.
    *   Paste the code from the [Source Code](#-source-code) section below into the file.
    *   Save it in a safe location (e.g., `C:\Scripts\` or `Documents`).

2.  **Open the "Send To" folder:**
    *   Press `Win + R` on your keyboard to open the Run dialog.
    *   Type the following command and press Enter:
        ```text
        shell:sendto
        ```

3.  **Create the Shortcut:**
    *   **Right-click** and **drag** your `create_junction.cmd` file into the opened "SendTo" folder.
    *   Release the button and select **"Create shortcuts here"**.

4.  **Rename the Shortcut (Optional):**
    *   Rename the newly created shortcut to something friendly, e.g., **`Create Junction`**.
    *   *Note:* The name you give the shortcut is the name that will appear in your right-click menu.

## 🛠 Usage

1.  Navigate to any folder in Windows Explorer.
2.  **Right-click** the folder.
3.  Select **Send to** -> **Create Junction**.
4.  A console window will appear briefly.
5.  Check your **Desktop** for the new junction point.

> **Note:** Directory Junctions function like "hard links" for folders. They point to the original location. If you delete the Junction, the original data remains. However, if you open the Junction and delete files *inside* it, the files are deleted from the original location.

## 💻 Source Code

Save this code as `create_junction.cmd`:

```batch
@echo off
setlocal

:: 1. Check if a path was passed (via Send To)
if "%~1"=="" (
    echo Error: No input detected.
    echo Please use the "Send to" context menu.
    pause
    exit /b
)

:: 2. Check if the input is a Directory
if not exist "%~1\" (
    echo Error: Invalid target.
    echo Junctions (/J) can only be created for FOLDERS.
    echo You selected a file: "%~nx1"
    pause
    exit /b
)

:: 3. Set Paths
set "SourcePath=%~1"
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
    pause
)
```

## 📄 License

This project is open source and available under the [MIT License](LICENSE). Feel free to modify and distribute.