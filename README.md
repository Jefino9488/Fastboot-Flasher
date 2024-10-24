# Fastboot Flasher

## Overview

Welcome to the Fastboot Flasher! This tool is designed to simplify and secure the process of flashing ROMs, boot images on Android devices. Whether you're a beginner or an experienced user, this tool streamlines the flashing process with a user-friendly interface.

## Features

- **Working Directory Setup:**
  - Automatically creates necessary directories (`images`) if they are not already present.
  - ```bash
    Any Folder
    ├── installer.bat
    ├── tools
    │   └── linux
    │   │        └──platform-tools (extracted platform tools)
    │   └── windows
    │            └──platform-tools (extracted platform tools)
    └── images
        └── (place required images here)
    ```

- **Boot Image Flashing:**
  - Easily flash Magisk or default boot images with a straightforward selection process.
  - Automatically detects the presence of `magisk_boot.img` and `boot.img` in the `images` folder.
  - Place boot images according to the following naming conventions:
    - `magisk_boot.img` for Magisk patched boot image
    - `boot.img` for default boot image

- **ROM Flashing:**
  - Flash ROMs with a simple selection process.
  - Automatically detects the presence of ROM images in the `images` folder.
  - Place ROM images in the `images` folder.

- **Verification and Error Handling:**
  - Ensures the availability of required images before proceeding with the flashing process.
  - Returns to the main menu if selected images are not present in the `images` folder.
  - If required images are missing, it will show the following error message:
    - `Some required images are missing!`
    - Shows the list of missing images.
    - Asks whether to continue the flashing process with the available images:
      - ```bash
        Some required images are missing. Do you want to continue anyway?
        Type "yes" to continue.
        ```
      - If the user types `yes`, it will continue the flashing process with the available images.
      - If the user types anything other than `yes`, it will return to the main menu.

## Compatible Devices

The Fastboot Flasher checks for the compatibility of the connected device before proceeding with the flashing process.
Add your device name to the `compactable_list.txt` file to make it compatible with the Fastboot Flasher.

## Usage

### Prerequisites

1. Connect your Android device in fastboot mode.
2. Place the required images in the `images` folder.
3. Run the `installer.bat` file.
4. Follow the on-screen instructions.

## Important Notes

- Ensure boot images and ROM images are placed in the `images` folder before starting the flashing process.
- Refer to the [Usage](#usage) section for a step-by-step guide on flashing.

## Support and Community

- Join our [XAGA Community](https://t.me/XAGA_Community) for updates and support.
- Report issues to [@Jefino9488](https://t.me/Jefino9488).

## Disclaimer

This is self-developed software created to make the flashing process easy and secure. Use it at your own risk.

### Thank You

Thank you for choosing the Fastboot Flasher. Happy flashing!

--- 

Feel free to adjust any sections further if needed!