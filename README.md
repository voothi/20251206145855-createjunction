# Windows Junction Creator (Context Menu)

A powerful Windows Batch script that allows you to create **Directory Junctions** (`mklink /J`) directly from the Windows File Explorer context menu via the "Send to" feature.

It gives you full control over where the junction is created, offering both **Console Input** and a **GUI Folder Picker**.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) 

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Source Code](#source-code)
- [License](#license)

---

## Features

*   **Hybrid Input:**
    *   **Console:** Paste the full path directly (great for power users).
    *   **GUI:** Press *Enter* to open a Folder Selection window (great for browsing).
*   **Full Control:** You specify the **full path**, including the name of the new junction link.
*   **Smart Validation:** Checks if the parent folder exists and prevents overwriting existing files/folders.
*   **Safety Loops:** If you cancel the selection or make a mistake, the script loops back instead of closing, allowing you to try again.
*   **Clean Input:** Automatically trims accidental leading spaces from pasted paths.

[Return to Top](#table-of-contents)

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

1.  **Right-click** the source folder you want to link **TO**.
2.  Select **Send to** -> **Create Junction**.
3.  A console window will appear asking for the **Full Junction Path**.
    *   **Option A (Manual):** Paste or type the full path (e.g., `D:\Games\MyLink`) and press Enter.
    *   **Option B (GUI):** Just press **Enter** (empty input). A folder picker window will open. Select the *parent directory*, and the script will automatically name the link same as the source.
4.  The Junction is created immediately.

> **Note:** Directory Junctions act like hard links for folders. Deleting the junction **does not** delete the original files.

[Return to Top](#table-of-contents)

## Source Code

*(Please refer to the `create_junction.cmd` file in this repository for the latest version)*

[Return to Top](#table-of-contents)

## License

This project is open source and available under the [MIT License](LICENSE).

[Return to Top](#table-of-contents)