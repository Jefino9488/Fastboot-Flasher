@echo off
cls
echo ========================================================
echo                 Fastboot Flasher
echo ========================================================
echo       Connect your device in fastboot mode.
echo --------------------------------------------------------
echo Waiting for device...
setlocal enabledelayedexpansion

set "SCRIPT_PATH=%~dp0"
set "TOOLS=%SCRIPT_PATH%tools\windows"
set PATH=%PATH%;%TOOLS%
set "imagesPath=%SCRIPT_PATH%images"
set "configFile=%SCRIPT_PATH%config.txt"

REM ========================================================
REM Parse config.txt
REM ========================================================
if not exist "%configFile%" (
    echo ERROR: config.txt not found!
    pause
    exit /B 1
)

for /f "usebackq tokens=1,* delims==" %%A in ("%configFile%") do (
    REM Skip comments
    set "line=%%A"
    if not "!line:~0,1!"=="#" (
        set "%%A=%%B"
    )
)

echo Configuration loaded:
echo   Device: %DEVICE%
echo   Compatible: %COMPATIBLE%
echo   Preloader: %PRELOADER%
echo   Disable Verity: %DISABLE_VERITY%
echo --------------------------------------------------------

REM ========================================================
REM Wait for device and validate
REM ========================================================
:wait_for_device
set device=unknown
for /f "tokens=2" %%D in ('fastboot getvar product 2^>^&1 ^| findstr /l /b /c:"product:"') do set device=%%D
if "%device%" equ "unknown" (
    echo No device detected. Waiting for device...
    timeout /t 5 >nul
    goto wait_for_device
)

REM Check if device is compatible
set "compatibleDevice=false"
for %%C in (%COMPATIBLE:,= %) do (
    if "%device%" equ "%%C" set "compatibleDevice=true"
)

if "%compatibleDevice%" equ "false" (
    echo ========================================================
    echo ERROR: Device not compatible!
    echo Your device: %device%
    echo Compatible devices: %COMPATIBLE%
    echo ========================================================
    pause
    exit /B 1
)

cls
echo ========================================================
echo                 Fastboot Flasher
echo ========================================================
echo             Device detected: %device%
echo --------------------------------------------------------

REM ========================================================
REM Format data prompt
REM ========================================================
echo Do you want to format data? (Y/N)
set /p formatData=

if /i "%formatData%" equ "Y" (
    echo Formatting data...
    fastboot erase metadata
    fastboot erase userdata
    fastboot erase frp
    echo Data formatted successfully.
) else (
    echo Skipping data formatting.
)

REM ========================================================
REM Verify images
REM ========================================================
cd "%imagesPath%"
echo.
echo Verifying images...

set "missingImages="
for %%I in (%IMAGES:,= %) do (
    if not exist "%%I" (
        set "missingImages=!missingImages! %%I"
    )
)

if not "!missingImages!"=="" (
    echo.
    echo WARNING: Missing images:!missingImages!
    echo.
    echo Some images are missing. Do you want to continue anyway?
    set /p continue=Type "yes" to continue: 
    if /i "!continue!" neq "yes" (
        echo Aborting operation.
        pause
        exit /B 1
    )
)

echo Verification completed.

REM ========================================================
REM Flash preloader (if exists)
REM ========================================================
if defined PRELOADER (
    if exist "%PRELOADER%" (
        echo.
        echo Flashing preloader...
        fastboot flash preloader1 "%PRELOADER%"
        fastboot flash preloader2 "%PRELOADER%"
        echo Preloader flashed successfully.
    )
)

REM ========================================================
REM Flash all images from config
REM ========================================================
echo.
echo Flashing images...

for %%I in (%IMAGES:,= %) do (
    if exist "%%I" (
        set "imgName=%%~nI"
        
        REM Skip special images (handled separately)
        if /i "%%I" neq "super.img" (
            REM Check if vbmeta image
            echo %%I | findstr /i "vbmeta" >nul
            if !errorlevel! equ 0 (
                if /i "%DISABLE_VERITY%" equ "yes" (
                    echo Flashing %%I with verity disabled...
                    fastboot flash !imgName!_a "%%I" --disable-verity --disable-verification
                ) else (
                    echo Flashing %%I...
                    fastboot flash !imgName!_a "%%I"
                )
            ) else (
                echo Flashing %%I...
                fastboot flash !imgName!_a "%%I"
            )
        )
    )
)

REM ========================================================
REM Flash super image
REM ========================================================
if exist "super.img" (
    echo.
    echo Flashing super image...
    fastboot flash super super.img
    echo super.img flashed successfully.
)

REM ========================================================
REM Set active slot and reboot
REM ========================================================
echo.
echo Setting active slot...
fastboot set_active a
echo Slot a activated successfully.

echo.
echo ========================================================
echo              Flashing completed!
echo ========================================================
echo Press Enter to reboot device.
pause
fastboot reboot
exit