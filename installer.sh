#!/bin/bash

clear
echo "========================================================"
echo "                 Fastboot Flasher"
echo "========================================================"
SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
fastboot=tools/linux/platform-tools/fastboot
[ ! -f $fastboot ] && echo "$fastboot not found." && exit 1
[ ! -x $fastboot ] && ! chmod +x $fastboot && echo "$fastboot cannot be executed." && exit 1

if [ ! -d "$SCRIPT_PATH/images" ]; then
    mkdir "$SCRIPT_PATH/images"
fi
imagesPath="$SCRIPT_PATH/images"

main_menu() {
    clear
    echo "========================================================"
    echo "                 Fastboot Flasher"
    echo "========================================================"
    echo "Main Menu:"
    echo "1. Flash ROM"
    echo "2. Additional Options"
    echo "3. Exit / Reboot"
    echo "========================================================"
    read -rp "Enter your choice (1/2/3): " option
    echo

    case $option in
        1)
            flash_rom
            ;;
        2)
            additional_options
            ;;
        3)
            $fastboot reboot
            echo "Exiting script."
            read -rp "Press any key to exit..." -n1 -s
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
    read -rp "" formatData

    if [[ "$formatData" =~ ^[Yy]$ ]]; then
        echo "Formatting data..."
        $fastboot erase metadata
        $fastboot erase userdata
        echo "Data formatted successfully."
    else
        echo "Skipping data formatting."
    fi

    echo "Boot Type:"
    echo "1. Magisk [magisk_boot.img]"
    echo "2. Default [boot.img]"
    echo
    echo "Select boot image type:"
    read -rp "" bootChoice
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

    cd "$imagesPath" || exit
    echo "Verifying critical images..."
    if [ ! -f "boot.img" ]; then
        echo "boot.img is missing. Aborting."
        read -rp "Press any key to return to main menu..." -n1 -s
        main_menu
    fi
    if [ ! -f "vendor_boot.img" ]; then
        echo "vendor_boot.img is missing. Aborting."
        read -rp "Press any key to return to main menu..." -n1 -s
        main_menu
    fi


# Verifying the existence of additional images
echo "Verifying additional images..."

# List of required images
    requiredImages=(
        "apusys.img" "audio_dsp.img" "ccu.img" "dpm.img" "dtbo.img" "gpueb.img" 
        "gz.img" "lk.img" "mcf_ota.img" "mcupm.img" "md1img.img" "mvpu_algo.img" 
        "pi_img.img" "scp.img" "spmfw.img" "sspm.img" "tee.img" 
        "vcp.img" "vbmeta.img" "vendor_boot.img" "vbmeta_system.img" "vbmeta_vendor.img"
    )

 # Additional required files
    additionalRequiredFiles=(
        "super.img" "preloader_xaga.bin"
    )

# Check for missing images
missingImages=()

for img in "${requiredImages[@]}" "${additionalRequiredFiles[@]}"; do
    if [ ! -f "$img" ]; then
        missingImages+=("$img")
    fi
done

# if any images are missing
if [ ${#missingImages[@]} -ne 0 ]; then
    echo "Missing images: ${missingImages[*]}"
    echo
    echo "Some required images are missing. Do you want to continue anyway?"
    echo 'Type "yes" to continue.'
    read -rp "" continue
    if [ "$continue" != "yes" ]; then
        echo "Returning to main menu."
        read -rp "Press any key to return to main menu..." -n1 -s
        main_menu
    fi
fi

echo "Flashing all images..."

for img in "${requiredImages[@]}"; do
    echo "Flashing $img..."
    $fastboot flash "${img%.*}_a" "$img"
    echo "$img flashed successfully."
done

# Flash super image
if [ -f "super.img" ]; then
    echo "Flashing super image..."
    $fastboot flash super super.img
    echo "super.img flashed successfully."
fi

# Flash preloader image
    if [ -f "preloader_xaga.bin" ]; then
        echo "Flashing preloader image..."
        $fastboot flash preloader1 preloader_xaga.bin
        $fastboot flash preloader2 preloader_xaga.bin
        echo "preloader_xaga.bin flashed successfully."
    fi



if [ -f "logo.img" ]; then
    echo "Flashing logo..."
    $fastboot flash logo_a logo.img
    echo "Logo flashed successfully."
fi

if [ -n "$bootImage" ]; then
    echo "Flashing boot image..."
    $fastboot flash boot_a "$bootImage"
    echo "$bootImage flashed successfully."
else
    echo "No boot image specified. Skipping boot image flash."
fi

    echo "Setting active slot..."
    $fastboot set_active a
    echo "Slot a activated successfully."

    echo "Press Enter to reboot and return to main menu."
    read -rp "" -n1 -s
    $fastboot reboot
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
    echo "4. Custom Command"
    echo "5. Return to Main Menu"
    echo "========================================================"
    read -rp "Enter your choice (1/2/3/4/5): " option
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
            custom_command
            ;;
        5)
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
    read -rp "" bootChoice
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
        cd "$imagesPath" || exit
        echo "Flashing $bootImage..."
        $fastboot flash boot_a "$bootImage"
        echo "$bootImage flashed successfully."
    else
        echo "$bootImage not found."
    fi

    read -rp "Press any key to return to additional options..." -n1 -s
    additional_options
}

flash_vendor_boot() {
    echo "Vendor Boot Type:"
    echo "1. Stock Vendor Boot [vendor_boot.img]"
    echo "2. TWRP Vendor Boot [twrp_vendor_boot.img]"
    echo
    echo "Select vendor boot image type:"
    read -rp "" vendorBootChoice
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
        cd "$imagesPath" || exit
        echo "Flashing $vendorBootImage..."
        $fastboot flash vendor_boot_a "$vendorBootImage"
        echo "$vendorBootImage flashed successfully."
    else
        echo "$vendorBootImage not found."
    fi

    read -rp "Press any key to return to additional options..." -n1 -s
    additional_options
}

format_data() {
    echo "Formatting data..."
    $fastboot erase metadata
    $fastboot erase userdata
    echo "Data formatted successfully."
    read -rp "Press any key to return to additional options..." -n1 -s
    additional_options
}

custom_command() {
    echo "Enter the command you want to execute:"
    read -rp "" customCommand
    echo

    if [[ "$customCommand" == fastboot* ]]; then
        customCommand="$fastboot ${customCommand#fastboot}"
    fi

    echo "Executing command: $customCommand"
    eval "$customCommand"
    read -rp "Press any key to return to additional options..." -n1 -s
    additional_options
}

main_menu
