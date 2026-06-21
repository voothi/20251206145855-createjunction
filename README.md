# Windows Link and Clone Creator (Context Menu)

A powerful Windows script that allows you to create **Directory Junctions**, **Symbolic Links**, **Hard Links**, and **Copy-on-Write (CoW) Clones** directly from the Windows File Explorer context menu via the "Send to" feature.

It works for both files and folders, giving you full control over where the link/clone is created, offering both **Console Input** and a **GUI Folder Picker**.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) 

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Link and Copy Type Comparison (Restrictions)](#link-and-copy-type-comparison-restrictions)
- [Running Tests](#running-tests)
- [Source Code](#source-code)
- [License](#license)

---

## Features

*   **Support for Files and Folders:** Works seamlessly for both file inputs and folder inputs.
*   **Multiple Link Types:**
    *   **Directory Junctions:** Standard junctions (`mklink /J`) for folders.
    *   **Symbolic Links:** Soft links for files or folders (`mklink`/`mklink /D`). (Requires Developer Mode, automatically prompts for Administrator privileges if needed).
    *   **Hard Links:** Hard links for files (`mklink /H`).
    *   **Copy-on-Write (CoW) Clones:** Hardware-accelerated file duplication (block cloning) on ReFS and Dev Drive volumes using raw Windows file systems APIs. (Recursively copies and clones directories if selected on folders).
*   **Hybrid Input:**
    *   **Console:** Paste the full path directly (great for power users).
    *   **GUI:** Press *Enter* to open a Folder Selection window (great for browsing).
*   **Full Control:** You specify the **full path**, including the name of the new link/clone.
*   **Smart Validation:** Checks if the parent folder exists and prevents overwriting existing files/folders.
*   **Safety Loops:** If you cancel the selection or make a mistake, the script loops back instead of closing, allowing you to try again.
*   **Clean Input:** Automatically trims accidental leading spaces from pasted paths.
*   **Auto-Elevation:** Automatically requests Administrator privileges via UAC if required (e.g. for creating Symbolic Links without Developer Mode).

## Installation

1.  **Download/Create the script:**
    *   Create a file named `create_junction.cmd`.
    *   Paste the code from the **[Source Code](#source-code)** section below.
    *   Save it in a safe location (e.g., `C:\Scripts\`).

2.  **Open the "Send To" folder:**
    *   Press `Win + R` -> type `shell:sendto` -> Press Enter.

3.  **Create the Shortcut:**
    *   **Right-click + Drag** your `create_junction.cmd` into the "SendTo" folder.
    *   Select **"Create shortcuts here"**.
    *   Rename the shortcut to **`Create Junction`**.

[Return to Top](#table-of-contents)

## Usage

1.  **Right-click** the source file or folder you want to link/clone **TO**.
2.  Select **Send to** -> **Create Junction** (or whatever name you chose for your shortcut).
3.  A console window will appear asking for the **Full Destination Path**.
    *   **Option A (Manual):** Paste or type the full path (e.g., `D:\Games\MyLink`) and press Enter.
    *   **Option B (GUI):** Just press **Enter** (empty input). A folder picker window will open. Select the *parent directory*, and the script will automatically name the link same as the source.
4.  Next, a **Link/Clone Type Selection** menu will appear. Enter the number [1-3] of the operation you want to perform:
    *   **If linking a folder:** Choice 1 (Directory Junction), Choice 2 (Directory Symbolic Link), Choice 3 (Copy-on-Write Clone).
    *   **If linking a file:** Choice 1 (Symbolic Link), Choice 2 (Hard Link), Choice 3 (Copy-on-Write Clone).
5.  The operation will be executed immediately, and a success or error message will be displayed.

> **Note:** Directory Junctions act like hard links for folders. Deleting any type of link or Copy-on-Write clone **does not** delete or affect the original files/folders. Copy-on-Write clones are real, independent copies on disk that share physical data blocks at the file system level until modified.

[Return to Top](#table-of-contents)

## Link and Copy Type Comparison (Restrictions)

| Link / Copy Type | Same Drive Only? | Breaks if Original is Deleted? | Edits Sync Together? | Windows Command Examples (CMD / PowerShell) |
| --- | --- | --- | --- | --- |
| **Directory Junction** (`/J`) | No (Can cross drives, folders only) | Yes (Becomes a broken folder link) | Yes (Modifications inside the folder affect original) | `mklink /J "D:\Target" "C:\Source"` |
| **Hard Link** (`/H`) | Yes (Strictly same NTFS partition) | No (File stays alive under the new path) | Yes (Both paths point to the exact same data) | `mklink /H "C:\Target\AGENTS.md" "C:\Source\AGENTS.md"` |
| **Symbolic Link** (Symlink) | No (Works across different drives) | Yes (Becomes a broken shortcut) | Yes (Modifying the link changes the original file) | `mklink "D:\Target\AGENTS.md" "C:\Source\AGENTS.md"` |
| **CoW Clone** (Block Clone) | Yes (Strictly same ReFS / Dev Drive) | No (Acts as an independent copy) | No (Edits remain isolated to each file) | `Copy-Item -Path "C:\Src\AGENTS.md" -Destination "C:\Dst\AGENTS.md"` |

[Return to Top](#table-of-contents)

## Running Tests

An automated test suite is available under the `tests/` directory to verify the link and clone creation functionality.

To run the tests, execute the following command in PowerShell from the repository root:
```powershell
powershell -ExecutionPolicy Bypass -File tests/test.ps1
```

The test suite will prepare a temporary sandbox, run operations non-interactively using automated inputs, validate the output structures (including hard link shared filesystem index validation), and clean up afterwards.

[Return to Top](#table-of-contents)

## Source Code

*(Please refer to the `create_junction.cmd` file in this repository for the latest version)*

[Return to Top](#table-of-contents)

## License

This project is open source and available under the [MIT License](LICENSE).

[Return to Top](#table-of-contents)