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

set "compatibleDevice=false"
for /f "delims=" %%i in (compatible_list.txt) do (
    if "%device%" equ "%%i" set "compatibleDevice=true"
)

if "%compatibleDevice%" equ "false" (
    echo Compatible devices are listed in compactable_list.txt
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
:boot_menu
echo Boot Type:
echo 1. Magisk [magisk_boot.img]
echo 2. Default [boot.img]
echo.
echo Select boot image type:
set /p bootChoice=
echo.

if "%bootChoice%" equ "1" (
    set bootImage=magisk_boot.img
    echo Selected magisk_boot.img
) else if "%bootChoice%" equ "2" (
    set bootImage=boot.img
    echo Selected boot.img
) else (
    echo Invalid boot image selection. Please select a valid boot.
    timeout /nobreak /t 5 >nul 2>&1
    goto boot_menu
)

cd %imagesPath%
echo Verifying critical images...
if not exist %bootImage% (
    echo Selected boot image is missing. Aborting.
    pause
    exit
)
if not exist vendor_boot.img (
    echo vendor_boot.img is missing. Aborting.
    pause
    exit
)

echo Verifying additional images...
set "requiredImages=dtbo.img vbmeta.img vendor_boot.img vbmeta_system.img super.img"
setlocal enabledelayedexpansion

set "missingImages="

for %%i in (%requiredImages%) do (
    if not exist %%i (
        set "missingImages=!missingImages! %%i "
    )
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
for %%i in (*.img) do (
    set imgName=%%~ni
    if /i "%%~nxi" neq "boot.img" if /i "%%~nxi" neq "magisk_boot.img" if /i "%%~nxi" neq "super.img" (
        echo Flashing %%i...
        fastboot flash !imgName!_a %%i
        echo %%i flashed successfully.
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