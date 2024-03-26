@echo off
cls
echo.
echo -----------------------------------------------------------------------------------------------------------------------
echo Disclaimer :
echo This is a self developed software just to make the flashing easy and secure.
echo.
echo Usage :
echo.
echo 1. while running the exe it forms 3 folder[boot,twrp,images] if not present already.
echo.
echo 2. If u need to flash boot or twrp img , dont forget to add boot and twrp imgs as follows :-
echo.
echo      In boot folder : rename your boot as follows
echo             ~ magisk_boot.img
echo             ~ ksu_boot.img
echo             ~ boot.img
echo.
echo      In twrp folder : rename your twrp or vendor_boot as follows
echo             ~ vendor_boot.img
echo             ~ twrp_vendor_boot.img
echo.
echo 3. Other than this just follow the process.!Returns to menu if file is missing.
echo.
echo for updates join @XAGAUpdates                                                    Owned by @XAGA_Community
echo for support join @XAGA_Community                                                 Report Issues : @Jefino9488
echo.
echo.
echo                                               THANK YOU
echo -----------------------------------------------------------------------------------------------------------------------
pause
:menu
setlocal
set "SCRIPT_PATH=%~dp0"
set "PATH=%b2eincfilepath%"
if not exist %SCRIPT_PATH%\vendor_boot mkdir %SCRIPT_PATH%\vendor_boot
if not exist %SCRIPT_PATH%\boot mkdir %SCRIPT_PATH%\boot
if not exist %SCRIPT_PATH%\images mkdir %SCRIPT_PATH%\images

if exist boot\magisk_boot.img (
    set magisk_boot=available
) else (
    set magisk_boot=missing
)
if exist boot\ksu_boot.img (
    set ksu_boot=available
) else (
    set ksu_boot=missing
)
if exist boot\boot.img (
    set boot=available
) else (
    set boot=missing
)

if exist vendor_boot\vendor_boot.img (
	set vendor_boot=available
) else (
    set vendor_boot=missing
)
if exist vendor_boot\twrp_vendor_boot.img (
    set twrp_vendor_boot=available
) else (
    set twrp_vendor_boot=missing
)

cls
echo          ....Universal Fastboot All IN One Flasher...
echo              connect your device in fastboot mode
echo.
echo Main Menu.
echo 1. Flash Full ROM
echo 2. Flash Boot Image
echo 3. Flash TWRP
echo 4. Format Data
echo 5. Exit (also reboot your device from fastboot)
echo.

set /p option=Enter your choice (1/2/3/4):
echo.

if "%option%" equ "1" (
    set flashRom=true
    set format=false
    set flashBoot=false
    set flashTWRP=false
) else if "%option%" equ "2" (
    set flashRom=false
    set flashBoot=true
    set format=false
    set flashTWRP=false
) else if "%option%" equ "3" (
    set flashRom=false
    set flashBoot=false
    set format=false
    set flashTWRP=true
) else if "%option%" equ "4" (
    set format=true
    set flashRom=false
    set flashBoot=false
    set flashTWRP=false
    call :select_format
) else if "%option%" equ "5" (
    fastboot reboot
    echo Exiting script.
    pause
    exit
) else (
    echo Invalid option. Please enter a valid option.
    goto menu
)

if "%flashRom%"=="true" (
    call :flash_rom
) else if "%flashBoot%"=="true" (
    call :flash_boot
) else if "%flashTWRP%"=="true" (
    call :flash_twrp
)


:flash_rom
:select_format
echo Data:
echo Do you want to format data? (Y/N)
set /p formatData=

if /i "%formatData%" equ "Y" (
    echo Formatting data...
    fastboot erase metadata
    fastboot erase userdata
    echo Data formatted successfully.
    timeout /nobreak /t 3 >nul 2>&1
) else (
    echo Skipping data formatting.
)

if "%format%"=="true" (
    pause
    goto menu
)

set slot=a

echo Fixed slot %slot%.

echo.
:flash_boot
if exist boot\magisk_boot.img (
    set magisk_boot=available
) else (
    set magisk_boot=missing
)
if exist boot\ksu_boot.img (
    set ksu_boot=available
) else (
    set ksu_boot=missing
)
if exist boot\boot.img (
    set boot=available
) else (
    set boot=missing
)
echo Boot Type:
echo 1. Magisk [magisk_boot.img] [%magisk_boot%]
echo 2. Ksu [ksu_boot.img] [%ksu_boot%]
echo 3. Default [boot.img] [%boot%]
echo.
echo Select boot image type:
set /p bootChoice=
echo.

if "%bootChoice%" equ "1" (
    set bootImage=magisk_boot.img
	echo Selected magisk_boot.img
    set availablity=%magisk_boot%
) else if "%bootChoice%" equ "2" (
    set bootImage=ksu_boot.img
	echo Selected ksu_boot.img
    set availablity=%ksu_boot%
) else if "%bootChoice%" equ "3" (
    set bootImage=boot.img
	echo Selected boot.img
    set availablity=%boot%
) else (
    echo Invalid boot image selection. Please Select A Valid Boot.
    timeout /nobreak /t 5 >nul 2>&1
    goto flash_boot
)

if "%flashBoot%"=="true" (
    if "%availablity%"=="available" (
        cd boot
        echo.
        echo Flashing Boot Image...
        fastboot flash boot %bootImage%
        echo Boot Image flashed successfully.
        pause
        cd ..
        call :menu
    ) else (
        echo selected boot not available
		echo Returning to main menu
        pause
        call :menu
    )
)

if "%flashRom%"=="true" (
    set vendorBootImage=vendor_boot.img
    goto :checker
)

:flash_twrp
echo.
echo Vendor Boot:
echo 1. Normal Vendor Boot {No twrp} [%vendor_boot%]
echo 2. TWRP Vendor Boot {installs twrp} [%twrp_vendor_boot%]
echo.

set /p vendorBootChoice=Enter your choice (1/2):

if "%vendorBootChoice%" equ "1" (
    set vendorBootImage=vendor_boot.img
	echo Selected %vendorBootChoice% vendor_boot.img
	set availablity=%vendor_boot%
) else if "%vendorBootChoice%" equ "2" (
    set vendorBootImage=twrp_vendor_boot.img
	echo Selected %vendorBootChoice% twrp_vendor_boot.img
	set availablity=%twrp_vendor_boot%
) else (
    echo Invalid vendor boot image selection. Please select a valid option.
    pause
    goto flash_twrp
)

if "%flashTWRP%"=="true" (
    if "%availablity%"=="available" (
        cd twrp
        echo.
        echo Flashing vendor_boot...
        fastboot flash vendor_boot_a %vendorBootImage%
        echo vendor_boot flashed successfully.
        pause
        cd ..
        call :menu
    ) else (
        echo selected vendor_boot not available
		echo Returning to main menu
        pause
        call :menu
    )
)

:checker
echo.
echo Start the flashing process? (Y/N)
set /p confirm=

if /i "%confirm%" neq "Y" (
    echo Returning to main menu.
    pause
    call :menu
)

echo Verifying configurations...
echo Please wait...
timeout /nobreak /t 5 >nul 2>&1
if exist boot\%bootImage% (
    set bootimg=available
) else (
    set bootimg=missing
)

if exist vendor_boot\%vendorBootImage% (
    set twrpimg=available
) else (
    set twrpimg=missing
)

if "%flashRom%"=="true" (
    if /i "%bootimg%"=="missing" (
        echo Boot image is missing. Aborting.
        pause
        goto :menu
    ) else if /i "%twrpimg%"=="missing" (
        echo vendor_boot image is missing. Aborting...
        pause
        goto :menu
    )
)


set "requiredImages=apusys.img audio_dsp.img ccu.img dpm.img dtbo.img gpueb.img gz.img lk.img mcf_ota.img mcupm.img md1img.img mvpu_algo.img pi_img.img preloader_raw.img scp.img spmfw.img sspm.img tee.img vcp.img vbmeta.img vbmeta_system.img vbmeta_vendor.img super.img"



setlocal enabledelayedexpansion
set "missingImages="

for %%i in (%requiredImages%) do (
    if not exist images\%%i (
        set "missingImages=!missingImages! %%i "
    )
)

if not "!missingImages!"=="" (
    echo Missing images: !missingImages!
    echo.
    echo Some required images are missing!!!. Do you want to continue anyway?
    echo Type "yes" to continue.
    set /p continue=
    if /i "!continue!" neq "yes" (
        echo Returning to main menu.
        pause
        endlocal
        call :menu
    )
)

echo All requiredImages Satisfied

timeout /nobreak /t 6 >nul 2>&1

echo Verification complete. Continuing...
goto :flash_images

:flash_images
cd images
timeout /nobreak /t 3 >nul 2>&1
echo Flashing images...
echo.
fastboot set_active %slot%

echo Flashing apusys...
fastboot flash apusys_a apusys.img
echo apusys flashed successfully.

echo Flashing audio_dsp...
fastboot flash audio_dsp_a audio_dsp.img
echo audio_dsp flashed successfully.

echo Flashing ccu...
fastboot flash ccu_a ccu.img
echo ccu flashed successfully.

echo Flashing dpm...
fastboot flash dpm_a dpm.img
echo dpm flashed successfully.

echo Flashing dtbo...
fastboot flash dtbo_a dtbo.img
echo dtbo flashed successfully.

echo Flashing gpueb...
fastboot flash gpueb_a gpueb.img
echo gpueb flashed successfully.

echo Flashing gz...
fastboot flash gz_a gz.img
echo gz flashed successfully.

echo Flashing lk...
fastboot flash lk_a lk.img
echo lk flashed successfully.

if exist logo.img (
    echo Flashing logo...
    fastboot flash logo_a %logoPath%
    echo Logo flashed successfully.
)

echo Flashing mcf_ota...
fastboot flash mcf_ota_a mcf_ota.img
echo mcf_ota flashed successfully.

echo Flashing mcupm...
fastboot flash mcupm_a mcupm.img
echo mcupm flashed successfully.

echo Flashing md1img...
fastboot flash md1img_a md1img.img
echo md1img flashed successfully.

echo Flashing mvpu_algo...
fastboot flash mvpu_algo_a mvpu_algo.img
echo mvpu_algo flashed successfully.

echo Flashing pi_img...
fastboot flash pi_img_a pi_img.img
echo pi_img flashed successfully.

echo Flashing preloader_bin..
fastboot flash preloader1 preloader_raw.img
fastboot flash preloader2 preloader_raw.img
echo preloader bin flashed successfully.

echo Flashing scp...
fastboot flash scp_a scp.img
echo scp flashed successfully.

echo Flashing spmfw...
fastboot flash spmfw_a spmfw.img
echo spmfw flashed successfully.

echo Flashing sspm...
fastboot flash sspm_a sspm.img
echo sspm flashed successfully.

echo Flashing tee...
fastboot flash tee_a tee.img
echo tee flashed successfully.

echo Flashing vcp...
fastboot flash vcp_a vcp.img
echo vcp flashed successfully.

echo Flashing vbmeta...
fastboot flash vbmeta_a vbmeta.img --disable-verity --disable-verification
echo vbmeta flashed successfully.

echo Flashing vbmeta_system...
fastboot flash vbmeta_system_a vbmeta_system.img
echo vbmeta_system flashed successfully.

echo Flashing vbmeta_vendor...
fastboot flash vbmeta_vendor_a vbmeta_vendor.img
echo vbmeta_vendor flashed successfully.

call :twrp_flasher
call :boot_flasher

echo Flashing System Image...
fastboot flash super super.img
echo System Image flashed successfully.

echo Setting active Slot.
fastboot set_active %slot%
echo Activated Slot %slot% successfully.
echo press enter to reboot (!!! Verify if all images flashed succesfully)
pause
pause
echo Returning to Main menu
pause
cd ..
call :menu

:boot_flasher
cd ..
cd boot
echo Flashing Boot Image...
fastboot flash boot_%slot% %bootImage%
echo Boot Image flashed successfully.
cd ..
cd images
goto :eof

:twrp_flasher
cd ..
cd vendor_boot
echo Flashing vendor_boot...
fastboot flash vendor_boot_a %vendorBootImage%
echo vendor_boot flashed successfully.
cd ..
cd images
goto :eof