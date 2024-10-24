#!/bin/bash
echo "========================================================"
echo "                 Fastboot Flasher"
echo "========================================================"

SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
fastboot="$SCRIPT_PATH/tools/linux/platform-tools/fastboot"
if [ ! -f "$fastboot" ]; then
    echo "$fastboot not found."
    exit 1
fi

if [ ! -x "$fastboot" ]; then
    chmod +x "$fastboot" || { echo "$fastboot cannot be executed."; exit 1; }
fi

if [ ! -d "$SCRIPT_PATH/images" ]; then
    mkdir "$SCRIPT_PATH/images"
fi
imagesPath="$SCRIPT_PATH/images"

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
echo "Select boot image type:"
read -rp "" bootChoice

if [ "$bootChoice" = "1" ]; then
    bootImage="magisk_boot.img"
    echo "Selected magisk_boot.img"
elif [ "$bootChoice" = "2" ]; then
    bootImage="boot.img"
    echo "Selected boot.img"
else
    echo "Invalid boot image selection. Aborting."
    exit 1
fi

cd "$imagesPath" || exit

echo "Verifying critical images..."
if [ ! -f "$bootImage" ]; then
    echo "$bootImage is missing. Aborting."
    exit 1
fi
if [ ! -f "vendor_boot.img" ]; then
    echo "vendor_boot.img is missing. Aborting."
    exit 1
fi

requiredImages=(
    "dtbo.img" "vbmeta.img" "vendor_boot.img" "vbmeta_system.img" "super.img"
)

missingImages=()

for img in "${requiredImages[@]}"; do
    if [ ! -f "$img" ]; then
        missingImages+=("$img")
    fi
done

if [ ${#missingImages[@]} -ne 0 ]; then
    echo "Missing critical images: ${missingImages[*]}"
    echo "Some required images are missing. Do you want to continue anyway? (Type 'yes' to continue)"
    read -rp "" continue
    if [ "$continue" != "yes" ]; then
        echo "Aborting flash process."
        exit 1
    fi
fi

echo "Flashing all images..."

for img in *.img; do
    imgName="${img%.*}"
    if [ "$img" != "$bootImage" ] && [ "$img" != "super.img" ]; then
        echo "Flashing $img..."
        $fastboot flash "${imgName}_a" "$img"
        echo "$img flashed successfully."
    fi
done

echo "Flashing boot image..."
$fastboot flash boot_a "$bootImage"
echo "$bootImage flashed successfully."

echo "Flashing super image..."
$fastboot flash super super.img
echo "super.img flashed successfully."

echo "Setting active slot..."
$fastboot set_active a
echo "Slot a activated successfully."

echo "Flashing process completed. Rebooting..."
$fastboot reboot
