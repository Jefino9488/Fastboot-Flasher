@echo off
cls
echo ========================================================
echo                 Fastboot Flasher
echo ========================================================
echo       Connect your device in fastboot mode.
echo --------------------------------------------------------
echo Waiting for device...
setlocal
set "SCRIPT_PATH=%~dp0"
set "TOOLS=%SCRIPT_PATH%tools\windows\platform-tools"
set PATH=%PATH%;%TOOLS%
if not exist %SCRIPT_PATH%\images mkdir %SCRIPT_PATH%\images
set "imagesPath=%SCRIPT_PATH%\images"

:wait_for_device
set device=unknown
for /f "tokens=2" %%D in ('fastboot getvar product 2^>^&1 ^| findstr /l /b /c:"product:"') do set device=%%D
if "%device%" equ "unknown" (
    echo No device detected. Waiting for device...
    timeout /t 5 >nul
    goto wait_for_device
)
if "%device%" neq "xaga" if "%device%" neq "xagapro" if "%device%" neq "xagain" (
    echo Compatible devices: xaga, xagapro, xagain
    echo Your device: %device%
    pause
    exit /B 1
)

cls
echo ========================================================
echo                 Fastboot Flasher
echo ========================================================
echo             Device detected: %device%
echo --------------------------------------------------------

echo Do you want to format data? (Y/N)
set /p formatData=

if /i "%formatData%" equ "Y" (
    echo Formatting data...
    fastboot erase metadata
    fastboot erase userdata
    echo Data formatted successfully.
) else (
    echo Skipping data formatting.
)

cd %imagesPath%
echo Verifying critical images...
if not exist boot.img (
    echo boot.img is missing. Aborting.
    pause
    exit
)
if not exist vendor_boot.img (
    echo vendor_boot.img is missing. Aborting.
    pause
    exit
)

echo Verifying additional images...
set "requiredImages=apusys.img audio_dsp.img ccu.img dpm.img dtbo.img gpueb.img gz.img lk.img mcf_ota.img mcupm.img md1img.img mvpu_algo.img pi_img.img scp.img spmfw.img sspm.img tee.img vcp.img vbmeta.img vendor_boot.img vbmeta_system.img vbmeta_vendor.img"
set "additionalRequiredImages=super.img"
setlocal enabledelayedexpansion

set "missingImages="
set "allRequiredImages=%requiredImages% %additionalRequiredImages%"

for %%i in (%allRequiredImages%) do (
    if not exist %%i (
        set "missingImages=!missingImages! %%i "
    )
)

if not exist preloader_xaga.bin if not exist preloader_xaga.img if not exist preloader_raw.img (
    set "missingImages=!missingImages! preloader_xaga.bin preloader_xaga.img preloader_raw.img"
)

if not "!missingImages!"=="" (
    echo Missing images: !missingImages!
    echo.
    echo Some required images are missing. Do you want to continue anyway?
    echo Type "yes" to continue.
    set /p continue=
    if /i "!continue!" neq "yes" (
        echo Aborting operation.
        pause
        endlocal
        exit
    )
)

echo Flashing all images...

for %%i in (%requiredImages%) do (
    echo Flashing %%i...
    fastboot flash %%~ni_a %%i
    echo %%i flashed successfully.
)

if exist logo.img (
    echo Flashing logo...
    fastboot flash logo_a logo.img
    echo Logo flashed successfully.
)

if exist %imagesPath%\preloader_xaga.bin (
    echo Flashing preloader...
    fastboot flash preloader1 preloader_xaga.bin
    fastboot flash preloader2 preloader_xaga.bin
    echo Preloader flashed successfully.
) else (
    if exist %imagesPath%\preloader_xaga.img (
        echo Flashing preloader...
        fastboot flash preloader1 preloader_xaga.img
        fastboot flash preloader2 preloader_xaga.img
        echo Preloader flashed successfully.
    ) else (
        if exist %imagesPath%\preloader_raw.img (
            echo Flashing preloader...
            fastboot flash preloader1 preloader_raw.img
            fastboot flash preloader2 preloader_raw.img
            echo Preloader flashed successfully.
        ) else (
            echo No preloader file found.
        )
    )
)

echo Flashing boot image...
fastboot flash boot_a %bootImage%
echo %bootImage% flashed successfully.

echo Flashing system image...
fastboot flash super super.img
echo super.img flashed successfully.

echo Setting active slot...
fastboot set_active a
echo Slot a activated successfully.

echo Press Enter to reboot.
pause
fastboot reboot
exit