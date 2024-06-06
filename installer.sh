#!/bin/bash

clear
echo "========================================================"
echo "                 Fastboot Flasher"
echo "========================================================"
echo "       Connect your device in fastboot mode."
echo "--------------------------------------------------------"
echo "Waiting for device..."
SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
TOOLS="$SCRIPT_PATH/tools/linux/platform-tools"
export PATH=$PATH:$TOOLS

if [ ! -d "$SCRIPT_PATH/images" ]; then
    mkdir "$SCRIPT_PATH/images"
fi
imagesPath="$SCRIPT_PATH/images"

wait_for_device() {
    device=$(fastboot getvar product 2>&1 | grep -oP "(?<=product: )[^\r\n]+")

    if [ -z "$device" ]; then
        echo "No device detected. Waiting for device..."
        sleep 5
        wait_for_device
    fi

    if [ "$device" != "xaga" ] && [ "$device" != "xagapro" ] && [ "$device" != "xagain" ]; then
        echo "Compatible devices: xaga, xagapro, xagain"
        echo "Your device: $device"
        read -p "Press any key to exit..." -n1 -s
        exit 1
    fi
}

wait_for_device

main_menu() {
    clear
    echo "========================================================"
    echo "                 Fastboot Flasher"
    echo "========================================================"
    echo "             Device detected: $device"
    echo "--------------------------------------------------------"
    echo "Main Menu:"
    echo "1. Flash ROM"
    echo "2. Additional Options"
    echo "3. Exit / Reboot"
    echo "========================================================"
    read -p "Enter your choice (1/2/3): " option
    echo

    case $option in
        1)
            flash_rom
            ;;
        2)
            additional_options
            ;;
        3)
            fastboot reboot
            echo "Exiting script."
            read -p "Press any key to exit..." -n1 -s
            exit
            ;;
        *)
            echo "Invalid option. Please enter a valid option."
            main_menu
            ;;
    esac
}

flash_rom() {
    echo "Do you want to format data? (Y/N)"
    read -p "" formatData

    if [[ "$formatData" =~ ^[Yy]$ ]]; then
        echo "Formatting data..."
        fastboot erase metadata
        fastboot erase userdata
        echo "Data formatted successfully."
    else
        echo "Skipping data formatting."
    fi

    echo "Boot Type:"
    echo "1. Magisk [magisk_boot.img]"
    echo "2. Default [boot.img]"
    echo
    echo "Select boot image type:"
    read -p "" bootChoice
    echo

    case $bootChoice in
        1)
            bootImage=magisk_boot.img
            echo "Selected magisk_boot.img"
            ;;
        2)
            bootImage=boot.img
            echo "Selected boot.img"
            ;;
        *)
            echo "Invalid boot image selection. Please select a valid boot."
            sleep 5
            flash_rom
            ;;
    esac

    cd "$imagesPath"
    echo "Verifying critical images..."
    if [ ! -f "boot.img" ]; then
        echo "boot.img is missing. Aborting."
        read -p "Press any key to return to main menu..." -n1 -s
        main_menu
    fi
    if [ ! -f "vendor_boot.img" ]; then
        echo "vendor_boot.img is missing. Aborting."
        read -p "Press any key to return to main menu..." -n1 -s
        main_menu
    fi

    echo "Verifying additional images..."
    requiredImages=("apusys.img" "audio_dsp.img" "ccu.img" "dpm.img" "dtbo.img" "gpueb.img" "gz.img" "lk.img" "mcf_ota.img" "mcupm.img" "md1img.img" "mvpu_algo.img" "pi_img.img" "preloader_xaga.bin" "scp.img" "spmfw.img" "sspm.img" "tee.img" "vcp.img" "vbmeta.img" "vendor_boot.img" "vbmeta_system.img" "vbmeta_vendor.img" "super.img")
    missingImages=()

    for img in "${requiredImages[@]}"; do
        if [ ! -f "$img" ]; then
            missingImages+=("$img")
        fi
    done

    if [ ${#missingImages[@]} -ne 0 ]; then
        echo "Missing images: ${missingImages[*]}"
        echo
        echo "Some required images are missing. Do you want to continue anyway?"
        echo 'Type "yes" to continue.'
        read -p "" continue
        if [ "$continue" != "yes" ]; then
            echo "Returning to main menu."
            read -p "Press any key to return to main menu..." -n1 -s
            main_menu
        fi
    fi

    echo "Flashing all images..."

    for img in "${requiredImages[@]}"; do
        echo "Flashing $img..."
        fastboot flash "${img%.*}_a" "$img"
        echo "$img flashed successfully."
    done

    if [ -f "logo.img" ]; then
        echo "Flashing logo..."
        fastboot flash logo_a logo.img
        echo "Logo flashed successfully."
    fi

    echo "Flashing boot image..."
    fastboot flash boot_a "$bootImage"
    echo "$bootImage flashed successfully."

    echo "Setting active slot..."
    fastboot set_active a
    echo "Slot a activated successfully."

    echo "Press Enter to reboot and return to main menu."
    read -p "" -n1 -s
    fastboot reboot
    main_menu
}

additional_options() {
    clear
    echo "========================================================"
    echo "                   Additional Options"
    echo "========================================================"
    echo "1. Flash Boot Image"
    echo "2. Flash Vendor Boot"
    echo "3. Format Data"
    echo "4. Return to Main Menu"
    echo "========================================================"
    read -p "Enter your choice (1/2/3/4): " option
    echo

    case $option in
        1)
            flash_boot
            ;;
        2)
            flash_vendor_boot
            ;;
        3)
            format_data
            ;;
        4)
            main_menu
            ;;
        *)
            echo "Invalid option. Please enter a valid option."
            additional_options
            ;;
    esac
}

flash_boot() {
    echo "Boot Type:"
    echo "1. Magisk [magisk_boot.img]"
    echo "2. Default [boot.img]"
    echo
    echo "Select boot image type:"
    read -p "" bootChoice
    echo

    case $bootChoice in
        1)
            bootImage=magisk_boot.img
            echo "Selected magisk_boot.img"
            ;;
        2)
            bootImage=boot.img
            echo "Selected boot.img"
            ;;
        *)
            echo "Invalid boot image selection. Please select a valid boot."
            sleep 5
            flash_boot
            ;;
    esac

    if [ -f "$imagesPath/$bootImage" ]; then
        echo "Flashing $bootImage..."
        fastboot flash boot_a "$bootImage"
        echo "$bootImage flashed successfully."
    else
        echo "$bootImage not found."
    fi

    read -p "Press any key to return to additional options..." -n1 -s
    additional_options
}

flash_vendor_boot() {
    echo "Vendor Boot Type:"
    echo "1. Stock Vendor Boot [vendor_boot.img]"
    echo "2. TWRP Vendor Boot [twrp_vendor_boot.img]"
    echo
    echo "Select vendor boot image type:"
    read -p "" vendorBootChoice
    echo

    case $vendorBootChoice in
        1)
            vendorBootImage=vendor_boot.img
            echo "Selected vendor_boot.img"
            ;;
        2)
            vendorBootImage=twrp_vendor_boot.img
            echo "Selected twrp_vendor_boot.img"
            ;;
        *)
            echo "Invalid vendor boot image selection. Please select a valid vendor boot."
            sleep 5
            flash_vendor_boot
            ;;
    esac

    if [ -f "$imagesPath/$vendorBootImage" ]; then
        echo "Flashing $vendorBootImage..."
        fastboot flash vendor_boot_a "$vendorBootImage"
        echo "$vendorBootImage flashed successfully."
    else
        echo "$vendorBootImage not found."
    fi

    read -p "Press any key to return to additional options..." -n1 -s
    additional_options
}

format_data() {
    echo "Formatting data..."
    fastboot erase metadata
    fastboot erase userdata
    echo "Data formatted successfully."
    read -p "Press any key to return to additional options..." -n1 -s
    additional_options
}

main_menu
# End of script