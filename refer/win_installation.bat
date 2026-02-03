@echo off
cls
setlocal

REM Enable ANSI escape codes
for /f "tokens=2 delims=: " %%i in ('chcp') do set "cp=%%i"
chcp 65001 > nul

if not exist "tools\windows\fastboot.exe" (
   powershell -Command "Write-Host 'ERROR: Important files for flashing are missing.' -ForegroundColor Red"
   echo.
   powershell -Command "Write-Host 'Possible solutions:' -ForegroundColor Blue"
   powershell -Command "Write-Host '1. Redownload the ROM package.' -ForegroundColor Blue"
   powershell -Command "Write-Host '2. Make sure all files are extracted.' -ForegroundColor Blue"
   pause
   chcp %cp% > nul
   exit
)

set /p formatData=Do you want to format data for a clean flash? (Y/N):

if /i "%formatData%" equ "Y" (
    powershell -Command "Write-Host 'Formatting data...' -ForegroundColor Green"
    tools\windows\fastboot.exe erase metadata
    tools\windows\fastboot.exe erase userdata
    tools\windows\fastboot.exe erase frp
) else (
    powershell -Command "Write-Host 'Skipping data formatting.' -ForegroundColor Blue"
)

echo.

set "requiredImages=apusys.img audio_dsp.img ccu.img dpm.img boot.img vendor_boot.img dtbo.img gpueb.img gz.img lk.img mcf_ota.img mcupm.img md1img.img mvpu_algo.img pi_img.img preloader_xaga.bin scp.img spmfw.img sspm.img tee.img vcp.img vbmeta.img vbmeta_system.img vbmeta_vendor.img super.img"

setlocal enabledelayedexpansion
set "missingImages="

for %%i in (%requiredImages%) do (
    if not exist images\%%i (
        set "missingImages=!missingImages! %%i "
    )
)

if not "!missingImages!"=="" (
    echo.
    powershell -Command "Write-Host 'Missing images:!missingImages!' -ForegroundColor Red"
    echo.
    powershell -Command "Write-Host 'Some required images are missing. Do you want to continue anyway?' -ForegroundColor Blue"
    set /p continue=Type "yes" to continue: 
    if /i "!continue!" neq "yes" (
        pause
        endlocal
        chcp %cp% > nul
        exit
    )
)

echo.
powershell -Command "Write-Host 'Verification completed. Continuing...' -ForegroundColor Blue"

echo.
powershell -Command "Write-Host 'Starting the flashing process...' -ForegroundColor Blue"
echo.

tools\windows\fastboot.exe flash apusys_a images\apusys.img
tools\windows\fastboot.exe flash audio_dsp_a images\audio_dsp.img
tools\windows\fastboot.exe flash ccu_a images\ccu.img
tools\windows\fastboot.exe flash dpm_a images\dpm.img
tools\windows\fastboot.exe flash dtbo_a images\dtbo.img
tools\windows\fastboot.exe flash gpueb_a images\gpueb.img
tools\windows\fastboot.exe flash gz_a images\gz.img
tools\windows\fastboot.exe flash lk_a images\lk.img
tools\windows\fastboot.exe flash mcf_ota_a images\mcf_ota.img
tools\windows\fastboot.exe flash mcupm_a images\mcupm.img
tools\windows\fastboot.exe flash md1img_a images\md1img.img
tools\windows\fastboot.exe flash mvpu_algo_a images\mvpu_algo.img
tools\windows\fastboot.exe flash pi_img_a images\pi_img.img
tools\windows\fastboot.exe flash preloader1 images\preloader_xaga.bin
tools\windows\fastboot.exe flash preloader2 images\preloader_xaga.bin
tools\windows\fastboot.exe flash scp_a images\scp.img
tools\windows\fastboot.exe flash spmfw_a images\spmfw.img
tools\windows\fastboot.exe flash sspm_a images\sspm.img
tools\windows\fastboot.exe flash tee_a images\tee.img
tools\windows\fastboot.exe flash vcp_a images\vcp.img
tools\windows\fastboot.exe flash vbmeta_a images\vbmeta.img --disable-verity --disable-verification
tools\windows\fastboot.exe flash vbmeta_system_a images\vbmeta_system.img
tools\windows\fastboot.exe flash vbmeta_vendor_a images\vbmeta_vendor.img
tools\windows\fastboot.exe flash boot_a images\boot.img
tools\windows\fastboot.exe flash vendor_boot_a images\vendor_boot.img
tools\windows\fastboot.exe flash super images\super.img
tools\windows\fastboot.exe set_active a

echo.
powershell -Command "Write-Host 'Flashing process completed.' -ForegroundColor Green"
echo.
powershell -Command "Write-Host 'Click enter to reboot.' -ForegroundColor Blue"
pause
tools\windows\fastboot.exe reboot
exit
