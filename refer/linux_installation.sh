#!/bin/bash

# Check if the script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo"
    exit 1
fi

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Define paths
SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)"
fastboot="$SCRIPT_PATH/tools/linux/fastboot"
imagesPath="$SCRIPT_PATH/images"

# Check if fastboot exists and is executable
if [ ! -f "$fastboot" ]; then
    printf "${RED}%s not found.${NC}\n" "$fastboot"
    exit 1
fi

if [ ! -x "$fastboot" ]; then
    chmod +x "$fastboot" || { printf "${RED}%s cannot be executed.${NC}\n" "$fastboot"; exit 1; }
fi

# Ask the user if they want to format data
printf "${BLUE}Do you want to format data? (Y/N): ${NC}"
read -r formatData

if [[ "$formatData" =~ ^[Yy]$ ]]; then
    printf "${BLUE}Formatting data...${NC}\n"
    "$fastboot" erase metadata
    "$fastboot" erase userdata
    "$fastboot" erase frp
    printf "${GREEN}Data formatted successfully.${NC}\n"
else
    printf "${BLUE}Skipping data formatting.${NC}\n"
fi

# Navigate to the images directory
if [ ! -d "$imagesPath" ]; then
    printf "${RED}Images directory %s not found. Aborting.${NC}\n" "$imagesPath"
    exit 1
fi
cd "$imagesPath" || exit 1

# Verify critical images
printf "${BLUE}Verifying critical images...${NC}\n"

requiredImages=(
    "apusys.img" "audio_dsp.img" "boot.img" "ccu.img" "dpm.img" "dtbo.img"
    "gpueb.img" "gz.img" "lk.img" "mcf_ota.img" "mcupm.img" "md1img.img"
    "mvpu_algo.img" "pi_img.img" "scp.img" "spmfw.img" "sspm.img" "tee.img"
    "vcp.img" "vbmeta.img" "vendor_boot.img" "vbmeta_system.img" "vbmeta_vendor.img"
)

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

if [ "${#missingImages[@]}" -ne 0 ]; then
    printf "${RED}Missing critical images:${NC}\n"
    for img in "${missingImages[@]}"; do
        printf "${RED} - %s${NC}\n" "$img"
    done

    printf "${BLUE}Some required images are missing. Do you want to continue anyway? (Type 'yes' to continue): ${NC}"
    read -r continue
    if [ "$continue" != "yes" ]; then
        printf "${RED}Aborting flash process.${NC}\n"
        exit 1
    fi
fi

# Start flashing process
printf "${BLUE}Starting the flashing process...${NC}\n"

# Flash preloader image if available
if [ -f "preloader_xaga.bin" ]; then
    "$fastboot" flash preloader1 preloader_xaga.bin
    "$fastboot" flash preloader2 preloader_xaga.bin
fi

# Flash each required image
for img in "${requiredImages[@]}"; do
    if [ -f "$img" ]; then
        partition_name="${img%.*}_a"
        "$fastboot" flash "$partition_name" "$img"
    fi
done

# Flash super image if available
if [ -f "super.img" ]; then
    "$fastboot" flash super super.img
fi

# Set the active slot to "a"
printf "${BLUE}Setting active slot...${NC}\n"
"$fastboot" set_active a
printf "${GREEN}Slot 'a' activated successfully.${NC}\n"

# Complete the process
printf "${BLUE}Flashing process completed. Rebooting...${NC}\n"
"$fastboot" reboot
sleep 5

exit 0
