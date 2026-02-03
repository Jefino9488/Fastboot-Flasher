#!/bin/bash

# ========================================================
#                 Fastboot Flasher
# ========================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Paths
SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)"
fastboot="$SCRIPT_PATH/tools/linux/fastboot"
imagesPath="$SCRIPT_PATH/images"
configFile="$SCRIPT_PATH/config.txt"

printf "${BLUE}========================================================${NC}\n"
printf "${BLUE}                 Fastboot Flasher${NC}\n"
printf "${BLUE}========================================================${NC}\n"

# ========================================================
# Check fastboot
# ========================================================
if [ ! -f "$fastboot" ]; then
    printf "${RED}%s not found.${NC}\n" "$fastboot"
    exit 1
fi

if [ ! -x "$fastboot" ]; then
    chmod +x "$fastboot" || { printf "${RED}%s cannot be executed.${NC}\n" "$fastboot"; exit 1; }
fi

# ========================================================
# Parse config.txt
# ========================================================
if [ ! -f "$configFile" ]; then
    printf "${RED}ERROR: config.txt not found!${NC}\n"
    exit 1
fi

# Read config file (skip comments)
while IFS='=' read -r key value; do
    # Skip empty lines and comments
    [[ -z "$key" || "$key" =~ ^# ]] && continue
    # Remove leading/trailing whitespace
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | xargs)
    declare "$key=$value"
done < "$configFile"

printf "${BLUE}Configuration loaded:${NC}\n"
printf "  Device: %s\n" "$DEVICE"
printf "  Compatible: %s\n" "$COMPATIBLE"
printf "  Preloader: %s\n" "$PRELOADER"
printf "  Disable Verity: %s\n" "$DISABLE_VERITY"
printf "${BLUE}--------------------------------------------------------${NC}\n"

# ========================================================
# Format data prompt
# ========================================================
printf "${BLUE}Do you want to format data? (Y/N): ${NC}"
read -r formatData

if [[ "$formatData" =~ ^[Yy]$ ]]; then
    printf "${YELLOW}Formatting data...${NC}\n"
    "$fastboot" erase metadata
    "$fastboot" erase userdata
    "$fastboot" erase frp
    printf "${GREEN}Data formatted successfully.${NC}\n"
else
    printf "${BLUE}Skipping data formatting.${NC}\n"
fi

# ========================================================
# Navigate to images directory
# ========================================================
if [ ! -d "$imagesPath" ]; then
    printf "${RED}Images directory %s not found. Aborting.${NC}\n" "$imagesPath"
    exit 1
fi
cd "$imagesPath" || exit 1

# ========================================================
# Verify images
# ========================================================
printf "\n${BLUE}Verifying images...${NC}\n"

# Convert comma-separated to array
IFS=',' read -ra IMAGE_ARRAY <<< "$IMAGES"

missingImages=""
for img in "${IMAGE_ARRAY[@]}"; do
    if [ ! -f "$img" ]; then
        missingImages="$missingImages $img"
    fi
done

if [ -n "$missingImages" ]; then
    printf "${YELLOW}WARNING: Missing images:%s${NC}\n" "$missingImages"
    printf "${BLUE}Some images are missing. Do you want to continue anyway? (Type 'yes' to continue): ${NC}"
    read -r continueFlash
    if [ "$continueFlash" != "yes" ]; then
        printf "${RED}Aborting flash process.${NC}\n"
        exit 1
    fi
fi

printf "${GREEN}Verification completed.${NC}\n"

# ========================================================
# Flash preloader (if exists)
# ========================================================
if [ -n "$PRELOADER" ] && [ -f "$PRELOADER" ]; then
    printf "\n${BLUE}Flashing preloader...${NC}\n"
    "$fastboot" flash preloader1 "$PRELOADER"
    "$fastboot" flash preloader2 "$PRELOADER"
    printf "${GREEN}Preloader flashed successfully.${NC}\n"
fi

# ========================================================
# Flash all images from config
# ========================================================
printf "\n${BLUE}Flashing images...${NC}\n"

for img in "${IMAGE_ARRAY[@]}"; do
    if [ -f "$img" ]; then
        imgName="${img%.*}"
        
        # Skip super.img (handled separately)
        if [ "$img" != "super.img" ]; then
            # Check if vbmeta image
            if [[ "$img" == *"vbmeta"* ]]; then
                if [ "$DISABLE_VERITY" = "yes" ]; then
                    printf "Flashing %s with verity disabled...\n" "$img"
                    "$fastboot" flash "${imgName}_a" "$img" --disable-verity --disable-verification
                else
                    printf "Flashing %s...\n" "$img"
                    "$fastboot" flash "${imgName}_a" "$img"
                fi
            else
                printf "Flashing %s...\n" "$img"
                "$fastboot" flash "${imgName}_a" "$img"
            fi
        fi
    fi
done

# ========================================================
# Flash super image
# ========================================================
if [ -f "super.img" ]; then
    printf "\n${BLUE}Flashing super image...${NC}\n"
    "$fastboot" flash super super.img
    printf "${GREEN}super.img flashed successfully.${NC}\n"
fi

# ========================================================
# Set active slot and reboot
# ========================================================
printf "\n${BLUE}Setting active slot...${NC}\n"
"$fastboot" set_active a
printf "${GREEN}Slot 'a' activated successfully.${NC}\n"

printf "\n${GREEN}========================================================${NC}\n"
printf "${GREEN}              Flashing completed!${NC}\n"
printf "${GREEN}========================================================${NC}\n"
printf "${BLUE}Rebooting device...${NC}\n"
"$fastboot" reboot

exit 0
