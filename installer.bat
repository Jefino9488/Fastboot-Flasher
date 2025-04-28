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
set "bootPath=%SCRIPT_PATH%\boot"
if not exist "%bootPath%" mkdir "%bootPath%"

:: Verify fastboot binary
if not exist "%TOOLS%\fastboot.exe" (
    echo Error: fastboot.exe not found in %TOOLS%.
    echo Please ensure platform tools are correctly installed.
    pause
    exit /b 1
)

:: Wait for device
:wait_for_device
echo Checking for device...
"%TOOLS%\fastboot.exe" devices >nul 2>&1
if errorlevel 1 (
    echo No device detected. Ensure the device is in fastboot mode and connected.
    echo Retrying in 5 seconds...
    timeout /t 5 >nul
    goto wait_for_device
)

:: Get product name
set device=unknown
for /f "tokens=2" %%D in ('"%TOOLS%\fastboot.exe" getvar product 2^>^&1') do set device=%%D
if "%device%"=="unknown" (
    echo Failed to retrieve product name.
    echo Retrying in 5 seconds...
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
    "%TOOLS%\fastboot.exe" erase metadata
    echo Erased metadata.
    "%TOOLS%\fastboot.exe" erase userdata
    echo Erased userdata.
    "%TOOLS%\fastboot.exe" erase cust
    echo Erased cust.
    echo Data formatted successfully.
) else (
    echo Skipping data formatting.
    "%TOOLS%\fastboot.exe" erase package_cache
    echo package_cache erased successfully.
)

:: Boot selection menu
:boot_menu
echo.
echo Boot Type:
echo 1. Magisk [magisk.img]
echo 2. KernelSU [ksu.img]
echo 3. Stock [boot.img]
echo.
echo Select boot image type:
set /p bootChoice=

if "%bootChoice%"=="1" (
    set "bootImage=magisk.img"
    echo Selected magisk.img
) else if "%bootChoice%"=="2" (
    set "bootImage=ksu.img"
    echo Selected ksu.img
) else if "%bootChoice%"=="3" (
    set "bootImage=boot.img"
    echo Selected boot.img
) else (
    echo Invalid boot image selection. Please select a valid boot.
    timeout /nobreak /t 5 >nul
    goto boot_menu
)

cd /d "%bootPath%"
echo.
echo Verifying selected boot image...
if not exist "%bootImage%" (
    echo %bootImage% is missing in boot directory. Aborting.
    pause
    exit /b 1
)

cd /d "%imagesPath%"
echo.
echo Verifying critical images...
if not exist "vendor_boot.img" (
    echo vendor_boot.img is missing. Aborting.
    pause
    exit /b 1
)
if not exist "super.img" (
    echo super.img is missing. Aborting.
    pause
    exit /b 1
)

echo.
echo Verifying additional images...
set "requiredImages=gz.img mcf_ota.img logo.img vbmeta_vendor.img gpueb.img dtbo.img vbmeta_system.img scp.img audio_dsp.img md1img.img vcp.img lk.img apusys.img ccu.img spmfw.img mcupm.img vbmeta.img mvpu_algo.img sspm.img vendor_boot.img pi_img.img dpm.img preloader_xaga.bin"
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
        exit /b 1
    )
)

echo.
echo Flashing images...
set "imageList=gz.img gz_a mcf_ota.img mcf_ota_a logo.img logo_a vbmeta_vendor.img vbmeta_vendor_a gpueb.img gpueb_a dtbo.img dtbo_a vbmeta_system.img vbmeta_system_a scp.img scp_a audio_dsp.img audio_dsp_a md1img.img md1img_a vcp.img vcp_a lk.img lk_a apusys.img apusys_a ccu.img ccu_a spmfw.img spmfw_a mcupm.img mcupm_a vbmeta.img vbmeta_a mvpu_algo.img mvpu_algo_a sspm.img sspm_a vendor_boot.img vendor_boot_a pi_img.img pi_img_a dpm.img dpm_a"
set i=0
for %%i in (%imageList%) do (
    set /a i+=1
    set "item[!i!]=%%i"
)

set j=1
:flash_loop
if defined item[!j!] (
    set "imgFile=!item[%j%]!"
    set /a k=%j%+1
    set "partition=!item[%k%]!"
    echo Flashing !imgFile! to !partition!...
    if /i "!imgFile:~0,6!"=="vbmeta" (
        "%TOOLS%\fastboot.exe" flash !partition! !imgFile! --disable-verity --disable-verification
    ) else (
        "%TOOLS%\fastboot.exe" flash !partition! !imgFile!
    )
    echo !imgFile! flashed successfully.
    set /a j+=2
    goto flash_loop
)

echo.
echo Flashing Engineering Preloader...
"%TOOLS%\fastboot.exe" flash preloader1 preloader_xaga.bin
echo Preloader1 flashed.
"%TOOLS%\fastboot.exe" flash preloader2 preloader_xaga.bin
echo Preloader2 flashed.
echo Preloader flashed successfully.

echo.
echo Flashing boot image...
cd /d "%bootPath%"
"%TOOLS%\fastboot.exe" flash boot_a %bootImage%
echo %bootImage% flashed successfully.

echo.
echo Flashing system image...
cd /d "%imagesPath%"
"%TOOLS%\fastboot.exe" flash super super.img
echo super.img flashed successfully.

echo.
echo Erasing frp...
"%TOOLS%\fastboot.exe" erase frp
echo Erased frp successfully.

echo.
echo Setting active slot...
"%TOOLS%\fastboot.exe" set_active a
echo Slot a activated successfully.

echo.
echo Press Enter to reboot (check if everything went good before reboot)...
pause
"%TOOLS%\fastboot.exe" reboot
echo Reboot initiated.
exit