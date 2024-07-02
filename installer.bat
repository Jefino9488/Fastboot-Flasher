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

:main_menu
cls
echo ========================================================
echo                 Fastboot Flasher
echo ========================================================
echo             Device detected: %device%
echo --------------------------------------------------------
echo Main Menu:
echo 1. Flash ROM
echo 2. Additional Options
echo 3. Exit / Reboot
echo ========================================================
set /p option=Enter your choice (1/2/3):
echo.

if "%option%" equ "1" (
    call :flash_rom
) else if "%option%" equ "2" (
    call :additional_options
) else if "%option%" equ "3" (
    fastboot reboot
    echo Exiting script.
    pause
    exit
) else (
    echo Invalid option. Please enter a valid option.
    goto main_menu
)

:flash_rom
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
    goto flash_rom
)

cd %imagesPath%
echo Verifying critical images...
if not exist boot.img (
    echo boot.img is missing. Aborting.
    pause
    call :main_menu
)
if not exist vendor_boot.img (
    echo vendor_boot.img is missing. Aborting.
    pause
    call :main_menu
)

echo Verifying additional images...
set "requiredImages=apusys.img audio_dsp.img ccu.img dpm.img dtbo.img gpueb.img gz.img lk.img mcf_ota.img mcupm.img md1img.img mvpu_algo.img pi_img.img scp.img spmfw.img sspm.img tee.img vcp.img vbmeta.img vendor_boot.img vbmeta_system.img vbmeta_vendor.img"
set "additionalRequiredImages=super.img preloader_xaga.bin"
setlocal enabledelayedexpansion

set "missingImages="
set "allRequiredImages=%requiredImages% %additionalRequiredImages%"

for %%i in (%allRequiredImages%) do (
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
        echo Returning to main menu.
        pause
        endlocal
        call :main_menu
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

echo Press Enter to reboot and return to main menu.
pause
fastboot reboot
call :main_menu

:additional_options
cls
echo ========================================================
echo                   Additional Options
echo ========================================================
echo 1. Flash Boot Image
echo 2. Flash Vendor Boot
echo 3. Format Data
echo 4. Custom Command
echo 5. Return to Main Menu
echo ========================================================
set /p option=Enter your choice (1/2/3/4/5):
echo.

if "%option%" equ "1" (
    call :flash_boot
) else if "%option%" equ "2" (
    call :flash_vendor_boot
) else if "%option%" equ "3" (
    call :format_data
) else if "%option%" equ "4" (
    call :custom_command
) else if "%option%" equ "5" (
    call :main_menu
) else (
    echo Invalid option. Please enter a valid option.
    goto additional_options
)

:flash_boot
cd %imagesPath%
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
    goto flash_boot
)

if exist %imagesPath%\%bootImage% (
    echo Flashing %bootImage%...
    fastboot flash boot_a %bootImage%
    echo %bootImage% flashed successfully.
) else (
    echo %bootImage% not found.
)

pause
call :additional_options

:flash_vendor_boot
cd %imagesPath%
echo Vendor Boot Type:
echo 1. Stock Vendor Boot [vendor_boot.img]
echo 2. TWRP Vendor Boot [twrp_vendor_boot.img]
echo.
echo Select vendor boot image type:
set /p vendorBootChoice=
echo.

if "%vendorBootChoice%" equ "1" (
    set vendorBootImage=vendor_boot.img
    echo Selected vendor_boot.img
) else if "%vendorBootChoice%" equ "2" (
    set vendorBootImage=twrp_vendor_boot.img
    echo Selected twrp_vendor_boot.img
) else (
    echo Invalid vendor boot image selection. Please select a valid vendor boot.
    timeout /nobreak /t 5 >nul 2>&1
    goto flash_vendor_boot
)

if exist %imagesPath%\%vendorBootImage% (
    echo Flashing %vendorBootImage%...
    fastboot flash vendor_boot_a %vendorBootImage%
    echo %vendorBootImage% flashed successfully.
) else (
    echo %vendorBootImage% not found.
)

pause
call :additional_options

:format_data
echo Formatting data...
fastboot erase metadata
fastboot erase userdata
echo Data formatted successfully.
pause
call :additional_options

:custom_command
cd %imagesPath%
echo Enter the command you want to execute:
set /p customCommand=
echo.

echo Executing command: %customCommand%
%customCommand%
pause
call :additional_options
