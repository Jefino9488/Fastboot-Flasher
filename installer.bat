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

:: Read compatible devices from external file
set "deviceFile=%SCRIPT_PATH%compatible_devices.txt"
set "compatibleDevices="

if exist "%deviceFile%" (
    set /p compatibleDevices=<"%deviceFile%"
) else (
    echo Compatible devices file not found. Using default list.
    set "compatibleDevices=xaga xagapro xagain"
)

set deviceFound=false

:: Loop through each device in the compatible list
for %%i in (%compatibleDevices%) do (
    if /i "%%i"=="%device%" (
        set deviceFound=true
        goto :device_compatible
    )
)

if "%deviceFound%"=="false" (
    echo Compatible devices: %compatibleDevices%
    echo Your device: %device%
    pause
    exit /B 1
)

:device_compatible
echo Device %device% is compatible.


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

:: Boot Image Selection
echo Boot Type:
echo 1. Magisk [magisk_boot.img]
echo 2. Default [boot.img]
echo.
echo Select boot image type:
set /p bootChoice=
echo.

:: Set bootImage variable based on user choice
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

:: Define required images list (excluding boot.img and magisk_boot.img)
set "requiredImages=super.img vbmeta.img vbmeta_system.img vbmeta_vendor.img"

echo Verifying required images in the folder...

:: Initialize variable to store missing images
set "missingImages="

:: Check if each required image exists in the images folder
for %%i in (%requiredImages%) do (
    if not exist %%i (
        set "missingImages=!missingImages! %%i"
    )
)

:: If there are missing images, inform the user
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

echo Flashing all images in the folder, excluding boot and magisk_boot...

:: Flash all found .img files, but skip boot.img and magisk_boot.img
for %%i in (*.img) do (
    if /i "%%~nxi" neq "boot.img" if /i "%%~nxi" neq "magisk_boot.img" (
        set imgName=%%~ni
        echo Flashing %%i...
        fastboot flash !imgName!_a %%i
        echo %%i flashed successfully.
    )
)

:: Flash the selected boot image only
if exist %imagesPath%\%bootImage% (
    echo Flashing %bootImage%...
    fastboot flash boot_a %bootImage%
    echo %bootImage% flashed successfully.
) else (
    echo %bootImage% not found. Aborting.
    pause
    call :main_menu
)

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
echo 2. Format Data
echo 3. Custom Command
echo 4. Return to Main Menu
echo ========================================================
set /p option=Enter your choice (1/2/3/4):
echo.

if "%option%" equ "1" (
    call :flash_boot
) else if "%option%" equ "2" (
    call :format_data
) else if "%option%" equ "3" (
    call :custom_command
) else if "%option%" equ "4" (
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

:: Set bootImage variable based on user choice for additional options
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

:: Flash the selected boot image only
if exist %imagesPath%\%bootImage% (
    echo Flashing %bootImage%...
    fastboot flash boot_a %bootImage%
    echo %bootImage% flashed successfully.
) else (
    echo %bootImage% not found.
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
