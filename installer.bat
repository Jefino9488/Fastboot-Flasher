@echo off
setlocal enabledelayedexpansion
cls
echo ========================================================
echo                 Fastboot Flasher
echo ========================================================
echo       Connect your device in fastboot mode.
echo --------------------------------------------------------
echo Waiting for device...

:: Set paths
set "SCRIPT_PATH=%~dp0"
set "TOOLS=%SCRIPT_PATH%tools\windows\platform-tools"
set PATH=%PATH%;%TOOLS%
if not exist "%SCRIPT_PATH%\images" mkdir "%SCRIPT_PATH%\images"
set "imagesPath=%SCRIPT_PATH%\images"

:: Wait for device
:wait_for_device
set device=unknown
for /f "tokens=2" %%D in ('fastboot getvar product 2^>^&1 ^| findstr /l /b /c:"product:"') do set device=%%D
if "%device%"=="unknown" (
    echo No device detected. Waiting for device...
    timeout /t 5 >nul
    goto wait_for_device
)

cls
echo ========================================================
echo                 Fastboot Flasher
echo ========================================================
echo             Device detected: %device%
echo --------------------------------------------------------

:: Ask to format data
echo Do you want to format data? (Y/N)
set /p formatData=
if /i "%formatData%"=="Y" (
    echo Formatting data...
    fastboot erase metadata
    fastboot erase userdata
    echo Data formatted successfully.
) else (
    echo Skipping data formatting.
)

:: Boot selection menu
:boot_menu
echo.
echo Boot Type:
echo 1. Magisk [magisk_boot.img]
echo 2. KernelSU [ksu_boot.img]
echo 3. Default [boot.img]
echo.
echo Select boot image type:
set /p bootChoice=

if "%bootChoice%"=="1" (
    set "bootImage=magisk_boot.img"
    echo Selected magisk_boot.img
) else if "%bootChoice%"=="2" (
    set "bootImage=ksu_boot.img"
    echo Selected ksu_boot.img
) else if "%bootChoice%"=="3" (
    set "bootImage=boot.img"
    echo Selected boot.img
) else (
    echo Invalid boot image selection. Please select a valid boot.
    timeout /nobreak /t 5 >nul
    goto boot_menu
)

cd /d "%imagesPath%"
echo.
echo Verifying critical images...
if not exist "%bootImage%" (
    echo Selected boot image is missing. Aborting.
    pause
    exit
)
if not exist "vendor_boot.img" (
    echo vendor_boot.img is missing. Aborting.
    pause
    exit
)

echo.
echo Verifying additional images...
set "requiredImages=dtbo.img vbmeta.img vendor_boot.img vbmeta_system.img super.img preloader_xaga.bin boot.img"
set "missingImages="

for %%i in (%requiredImages%) do (
    if not exist "%%i" (
        set "missingImages=!missingImages! %%i"
    )
)

if not "!missingImages!"=="" (
    echo Missing images:!missingImages!
    echo.
    echo Some required images are missing. Do you want to continue anyway?
    echo Type "yes" to continue.
    set /p continue=
    if /i "!continue!" neq "yes" (
        echo Aborting operation.
        pause
        exit
    )
)

echo.
echo Flashing all images...
for %%i in (*.img) do (
    set "imgName=%%~ni"
    if /i "%%~nxi" neq "boot.img" if /i "%%~nxi" neq "magisk_boot.img" if /i "%%~nxi" neq "super.img" if /i "%%~nxi" neq "ksu_boot.img" if /i "%%~nxi" neq "preloader_xaga.bin" if /i "%%~nxi" neq "cust.img" if /i "%%~nxi" neq "img" (
        echo Flashing %%i...
        fastboot flash !imgName!_a %%i
        echo %%i flashed successfully.
    )
)

:: Flash preloader only if file exists

echo.
echo Flashing Engineering Preloader...
fastboot flash preloader1 preloader_xaga.bin
fastboot flash preloader2 preloader_xaga.bin

echo.
echo Flashing boot image...
fastboot flash boot_a %bootImage%
echo %bootImage% flashed successfully.

echo.
echo Flashing system image...
fastboot flash super super.img
echo super.img flashed successfully.

echo.
echo Setting active slot...
fastboot set_active a
echo Slot a activated successfully.

echo.
echo Press Enter to reboot (check if everything went good before reboot)...
pause
fastboot reboot
exit