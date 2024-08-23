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

cd "$imagesPath" || exit
echo "Verifying critical images..."
if [ ! -f "boot.img" ]; then
    echo "boot.img is missing. Aborting."
    exit 1
fi
if [ ! -f "vendor_boot.img" ]; then
    echo "vendor_boot.img is missing. Aborting."
    exit 1
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
    "super.img"
)

# Check for missing images
missingImages=()

for img in "${requiredImages[@]}"; do
    if [ ! -f "$img" ]; then
        missingImages+=("$img")
    fi
done

# Check for the presence of any preloader file
if [ ! -f "preloader_xaga.bin" ] && [ ! -f "preloader_xaga.img" ] && [ ! -f "preloader_raw.img" ]; then
    missingImages+=("preloader_xaga.bin or preloader_xaga.img or preloader_raw.img")
fi

for img in "${additionalRequiredFiles[@]}"; do
    if [ ! -f "$img" ]; then
        missingImages+=("$img")
    fi
done

# If any images are missing
if [ ${#missingImages[@]} -ne 0 ]; then
    echo "Missing images: ${missingImages[*]}"
    echo
    echo "Some required images are missing. Do you want to continue anyway?"
    echo 'Type "yes" to continue.'
    read -rp "" continue
    if [ "$continue" != "yes" ]; then
        echo "Aborting flash process."
        exit 1
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
if [ -f "$imagesPath/preloader_xaga.bin" ]; then
    echo "Flashing preloader image..."
    $fastboot flash preloader1 preloader_xaga.bin
    $fastboot flash preloader2 preloader_xaga.bin
    echo "preloader_xaga.bin flashed successfully."
elif [ -f "$imagesPath/preloader_xaga.img" ]; then
    echo "Flashing preloader image..."
    $fastboot flash preloader1 preloader_xaga.img
    $fastboot flash preloader2 preloader_xaga.img
    echo "preloader_xaga.img flashed successfully."
elif [ -f "$imagesPath/preloader_raw.img" ]; then
    echo "Flashing preloader image..."
    $fastboot flash preloader1 preloader_raw.img
    $fastboot flash preloader2 preloader_raw.img
    echo "preloader_raw.img flashed successfully."
else
    echo "No preloader file found."
fi

if [ -f "logo.img" ]; then
    echo "Flashing logo..."
    $fastboot flash logo_a logo.img
    echo "Logo flashed successfully."
fi

echo "Setting active slot..."
$fastboot set_active a
echo "Slot a activated successfully."

echo "Flashing process completed. Rebooting..."
$fastboot reboot
