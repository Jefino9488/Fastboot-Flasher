# Universal Fastboot All-In-One Flasher


## Overview

Welcome to the Universal Fastboot All-In-One Flasher! This tool is designed to simplify and secure the process of flashing ROMs, boot images, and TWRP on Android devices. Whether you're a beginner or an experienced user, this tool streamlines the flashing process with a user-friendly interface.

---

## Features

- **Working Dir Setup:**
  - The tool automatically creates working dir (`boot`, `twrp`, and `images`) if they are not already present.
  - ```bash
    Any Folder
    ├── Flasher.exe
    ├── boot
    │   ├── magisk_boot.img
    │   ├── ksu_boot.img
    │   └── boot.img
    ├── images
    │   └── images # refer placeholder images
    └── vendor_boot
        ├── recovery.img
        └── vendor_boot.img
    ```

- **Boot Image Flashing:**
  - Easily flash Magisk, Ksu, or default boot images with a straightforward selection process.
  - The tool automatically detects the presence of Magisk, Ksu and boot images in the `boot` folder.
  - place boot images according to the following naming convention:
    - `magisk_boot.img` for Magisk patched boot image
    - `ksu_boot.img` for Ksu patched boot image
    - `boot.img` for default boot image

- **TWRP Flashing:**
  - Flash TWRP with a simple selection process.
  - The tool automatically detects the presence of TWRP image in the `twrp` folder.
  - place TWRP image according to the following naming convention:
    - `twrp_vendor_boot.img` for TWRP recovery image
    - `vendor_boot.img` for  vendor boot image

- **ROM Flashing:**
  - Flash ROMs with a simple selection process.
  - The tool automatically detects the presence of ROM images in the `images` folder.
  - place ROM images according to the following naming convention:
    - `apusys.img`
    `audio_dsp.img`
    `ccu.img`
    `dpm.img`
    `dtbo.img`
    `gpueb.img`
    `gz.img`
    `lk.img`
    `logo.img(optional)`
    `mcf_ota.img`
    `mcupm.img`
    `md1img.img`
    `mvpu_algo.img`
    `pi_img.img`
    `preloader_raw.img`
    `scp.img`
    `spmfw.img`
    `sspm.img`
    `tee.img`
    `vcp.img`
    `vbmeta.img`
    `vbmeta_system.img`
    `vbmeta_vendor.img`
    `super.img`
    `cust.img(optional)`

- **Verification and Error Handling:**
  - The tool ensures the availability of required images before proceeding with the flashing process.
  - Returns to the main menu if selected `boot` or `TWRP` images are not present in the respective folders.
  - If required images are missing it will show the following error message:
    - `Error: Missing required images!`
    - and shows the missing images list.
    - It will ask whether to continue the flashing process with the available images.
    - ```bash
      Some required images are missing!!!. Do you want to continue anyway?
      Type "yes" to continue.
      ```
    - If the user types `yes` it will continue the flashing process with the available images.
    - If the user types `other than yes` it will return to the main menu.
  - **STATUS**
  - The tool shows the avaailablity of boot and TWRP images in the respective folders.
  - While flashing boot or twrp images.
    - if available it will show and mark as `available`.
    - if not available it will show and mark as `missing`.
    - ```bash
      Boot Type:
       1. Magisk [magisk_boot.img] [%magisk_boot%]
       2. Ksu [ksu_boot.img] [%ksu_boot%]
       3. Default [boot.img] [%boot%]
      ```
    - ```bash
      TWRP Type:
       1. TWRP [recovery.img] [%recovery%]
       2. Vendor Boot [vendor_boot.img] [%vendor_boot%]
        ```
    - if selected boot or twrp status is `missing` it will return to the main menu.
---

## Usage

### Prerequisites

1. Connect your Android device in fastboot mode.
2. Place the required images in the respective folders (`boot`, `twrp`, `images`).
3. Run the `Fastboot_installer.exe` file.
4. Follow the on-screen instructions.

### Flashing Process

1. Choose an option from the main menu:
   - 1: Flash Full ROM
   - 2: Flash Boot Image
   - 3: Flash TWRP
   - 4: Format Data
   - 5: Exit

2. Follow the on-screen instructions for the selected option.

---

## Important Notes

- Ensure boot and TWRP images are placed in the respective folders (`boot`, `twrp`) before starting the flashing process.

- Refer to the [Usage](#usage) section for a step-by-step guide on flashing.

---

## Support and Community

- Join our [XAGA Community](https://t.me/XAGA_Community) for updates and support.

- Report issues to [@Jefino9488](https://t.me/Jefino9488).

---

## Disclaimer

This is a self-developed software created to make the flashing process easy and secure. Use it at your own risk.



### Thank You

Thank you for choosing the Universal Fastboot All-In-One Flasher. Happy flashing!

---
