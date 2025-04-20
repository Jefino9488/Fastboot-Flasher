#!/bin/sh
printf "========================================================\n"
printf "                 Fastboot Flasher\n"
printf "========================================================\n"
printf "       Connect your device in fastboot mode.\n"
printf "========================================================\n"

SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)"
fastboot="$SCRIPT_PATH/tools/linux/platform-tools/fastboot"
if [ ! -f "$fastboot" ]; then
    printf "%s not found.\n" "$fastboot"
    exit 1
fi

if [ ! -x "$fastboot" ]; then
    chmod +x "$fastboot" || { printf "%s cannot be executed.\n" "$fastboot"; exit 1; }
fi

if [ ! -d "$SCRIPT_PATH/images" ]; then
    mkdir "$SCRIPT_PATH/images"
fi
imagesPath="$SCRIPT_PATH/images"

printf "Do you want to format data? (Y/N)\n"
read -r formatData

if [ "$formatData" = "Y" ] || [ "$formatData" = "y" ]; then
    printf "Formatting data...\n"
    "$fastboot" erase metadata
    "$fastboot" erase userdata
    printf "Data formatted successfully.\n"
else
    printf "Skipping data formatting.\n"
fi

printf "Boot Type:\n"
printf "1. Magisk [magisk_boot.img]\n"
printf "2. KernelSU [ksu_boot.img]\n"
printf "3. Default [boot.img]\n"
printf "Select boot image type:\n"
read -r bootChoice

if [ "$bootChoice" = "1" ]; then
    bootImage="magisk_boot.img"
    printf "Selected magisk_boot.img\n"
elif [ "$bootChoice" = "2" ]; then
    bootImage="ksu_boot.img"
    printf "Selected ksu_boot.img\n"
elif [ "$bootChoice" = "3" ]; then
    bootImage="boot.img"
    printf "Selected boot.img\n"
else
    printf "Invalid boot image selection. Please select a valid boot.\n"
    sleep 5
    exit 1
fi

cd "$imagesPath" || exit 1

printf "Verifying critical images...\n"
if [ ! -f "$bootImage" ]; then
    printf "%s is missing. Aborting.\n" "$bootImage"
    exit 1
fi
if [ ! -f "vendor_boot.img" ]; then
    printf "vendor_boot.img is missing. Aborting.\n"
    exit 1
fi

printf "Verifying additional images...\n"
requiredImages="dtbo.img vbmeta.img vendor_boot.img vbmeta_system.img super.img preloader_xaga.bin boot.img"
missingImages=""

for img in $requiredImages; do
    if [ ! -f "$img" ]; then
        missingImages="$missingImages $img"
    fi
done

if [ -n "$missingImages" ]; then
    printf "Missing images:%s\n" "$missingImages"
    printf "Some required images are missing. Do you want to continue anyway? (Type 'yes' to continue)\n"
    read -r continue
    if [ "$continue" != "yes" ]; then
        printf "Aborting operation.\n"
        exit 1
    fi
fi

printf "Flashing all images...\n"
for img in *.img; do
    imgName=$(echo "$img" | sed 's/\..*//')
    if [ "$img" != "boot.img" ] && [ "$img" != "magisk_boot.img" ] && [ "$img" != "ksu_boot.img" ] && [ "$img" != "super.img" ] && [ "$img" != "preloader_xaga.bin" ]; then
        printf "Flashing %s...\n" "$img"
        "$fastboot" flash "${img-name}_a" "$img"
        printf "%s flashed successfully.\n" "$img"
    fi
done

printf "Flashing Engineering Preloader...\n"
"$fastboot" flash preloader1 preloader_xaga.bin
"$fastboot" flash preloader2 preloader_xaga.bin

printf "Flashing boot image...\n"
"$fastboot" flash boot_a "$bootImage"
printf "%s flashed successfully.\n" "$bootImage"

printf "Flashing super image...\n"
"$fastboot" flash super super.img
printf "super.img flashed successfully.\n"

printf "Setting active slot...\n"
"$fastboot" set_active a
printf "Slot a activated successfully.\n"

printf "Press Enter to reboot (check if everything went good before reboot)...\n"
read -r
printf "Rebooting...\n"
"$fastboot" reboot