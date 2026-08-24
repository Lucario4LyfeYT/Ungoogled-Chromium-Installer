@echo off
setlocal EnableDelayedExpansion
title ungoogled-chromium installer

set "DEFAULT_DIR=C:\Program Files\ungoogledchromium"
set "CONFIG_DIR=%USERPROFILE%\Documents\UnChrome"
set "CONFIG_FILE=%CONFIG_DIR%\uc_installer_config.txt"
set "ARCH=x64"
set "REPO=ungoogled-software/ungoogled-chromium-windows"

if not exist "%CONFIG_DIR%" mkdir "%CONFIG_DIR%" 2>nul
if not exist "%CONFIG_DIR%" (
    echo.
    echo WARNING: couldn't create "%CONFIG_DIR%" to remember your install path.
    echo You'll be asked to choose a path every time you run this.
    echo.
)

if exist "%CONFIG_FILE%" (
    set /p INSTALL_DIR=<"%CONFIG_FILE%"
    echo.
    echo Current install location: !INSTALL_DIR!
    set "CHANGEPATH="
    set /p "CHANGEPATH=Change it? [y/N]: "
    if /i "!CHANGEPATH!"=="y" call :ask_path
) else (
    call :ask_path
)

echo.
echo Install location: %INSTALL_DIR%

if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%" 2>nul
>"%INSTALL_DIR%\__write_test.tmp" echo test 2>nul
if not exist "%INSTALL_DIR%\__write_test.tmp" (
    echo.
    echo Can't write to "%INSTALL_DIR%".
    echo That folder needs administrator rights. Either:
    echo   - right-click this file and choose "Run as administrator", or
    echo   - delete "%CONFIG_FILE%" and pick a different folder next time
    echo     you run it.
    echo.
    pause
    exit /b 1
)
del /q "%INSTALL_DIR%\__write_test.tmp" >nul 2>&1

set "INSTALLED_VER="
if exist "%INSTALL_DIR%\version.txt" (
    set /p INSTALLED_VER=<"%INSTALL_DIR%\version.txt"
)

if defined INSTALLED_VER (
    echo Currently installed version: %INSTALLED_VER%
) else (
    echo Not currently installed. This will be a fresh install.
)

echo.
echo Checking latest available version...

set "PS_LATEST=[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { (Invoke-RestMethod -Uri 'https://api.github.com/repos/%REPO%/releases/latest' -Headers @{'User-Agent'='uc-installer'}).tag_name } catch { '' }"

set "TMP_OUT=%TEMP%\uc_latest_%RANDOM%.txt"
powershell -NoProfile -Command "%PS_LATEST%" > "%TMP_OUT%" 2>nul
set "LATEST_VER="
set /p LATEST_VER=<"%TMP_OUT%"
del /q "%TMP_OUT%" >nul 2>&1

if not defined LATEST_VER (
    echo Could not reach GitHub to check the latest version. Check your internet connection and try again.
    goto :end
)

echo Latest available version: %LATEST_VER%

if not defined INSTALLED_VER (
    echo.
    echo Installing ungoogled-chromium %LATEST_VER% for the first time...
    call :do_install "%LATEST_VER%"
    goto :end
)

if "%INSTALLED_VER%"=="%LATEST_VER%" (
    echo.
    echo You already have the latest version installed. Nothing to do.
    goto :end
)

echo.
set /p "DOUPDATE=A new version is available (installed: %INSTALLED_VER%, latest: %LATEST_VER%). Update now? [Y/N]: "
if /i "%DOUPDATE%"=="Y" (
    call :do_install "%LATEST_VER%"
) else (
    echo Skipping update.
)
goto :end


:ask_path
echo.
echo Where should ungoogled-chromium be installed?
echo Press Enter to use the default: %DEFAULT_DIR%
set "INSTALL_DIR="
set /p "INSTALL_DIR=Install path: "
if "!INSTALL_DIR!"=="" (
    set "INSTALL_DIR=%DEFAULT_DIR%"
) else (
    for %%A in ("!INSTALL_DIR!") do set "BASENAME=%%~nxA"
    if /i not "!BASENAME!"=="ungoogledchromium" (
        set "APPENDSUB="
        set /p "APPENDSUB=Append \ungoogledchromium so it gets its own folder? [Y/n]: "
        if /i not "!APPENDSUB!"=="n" set "INSTALL_DIR=!INSTALL_DIR!\ungoogledchromium"
    )
)

if exist "%CONFIG_DIR%" (
    echo !INSTALL_DIR!>"%CONFIG_FILE%"
    if exist "%CONFIG_FILE%" (
        echo Saved your install path to "%CONFIG_FILE%".
    ) else (
        echo WARNING: failed to write "%CONFIG_FILE%" - you'll be asked again next run.
    )
)
goto :eof


:do_install
set "VER=%~1"
set "DL_URL=https://github.com/%REPO%/releases/download/%VER%/ungoogled-chromium_%VER%_windows_%ARCH%.zip"
set "TMP_ZIP=%TEMP%\uc_%RANDOM%.zip"
set "TMP_EXTRACT=%TEMP%\uc_extract_%RANDOM%"

echo.
echo Downloading %DL_URL%
echo (this is a full browser build, so it may take a few minutes)

where curl.exe >nul 2>&1
if not errorlevel 1 (
    curl.exe -L --fail --silent --show-error -o "%TMP_ZIP%" "%DL_URL%"
    if errorlevel 1 (
        echo Download via curl failed. Aborting.
        goto :eof
    )
) else (
    set "PS_DOWNLOAD=[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ProgressPreference = 'SilentlyContinue'; try { Invoke-WebRequest -Uri '%DL_URL%' -OutFile '%TMP_ZIP%' -UseBasicParsing } catch { Write-Host 'DOWNLOAD_FAILED'; exit 1 }"
    powershell -NoProfile -Command "%PS_DOWNLOAD%"
    if errorlevel 1 (
        echo Download failed. Aborting.
        goto :eof
    )
)

echo Extracting...
if exist "%TMP_EXTRACT%" rmdir /s /q "%TMP_EXTRACT%"
powershell -NoProfile -Command "Expand-Archive -Path '%TMP_ZIP%' -DestinationPath '%TMP_EXTRACT%' -Force"
if errorlevel 1 (
    echo Extraction failed. Aborting.
    del /q "%TMP_ZIP%" >nul 2>&1
    goto :eof
)

set "SUBFOLDER="
for /f "delims=" %%D in ('dir "%TMP_EXTRACT%" /b /ad') do set "SUBFOLDER=%%D"
if not defined SUBFOLDER (
    echo Unexpected archive layout. Aborting.
    goto :eof
)

set "PS_FINDPROC=Get-Process -Name chrome -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq '%INSTALL_DIR%\chrome.exe' } | Select-Object -ExpandProperty Id"

set "TMP_PIDS=%TEMP%\uc_pids_%RANDOM%.txt"
powershell -NoProfile -Command "%PS_FINDPROC%" > "%TMP_PIDS%" 2>nul

set "WASRUNNING=0"
for /f "usebackq delims=" %%P in ("%TMP_PIDS%") do (
    set "WASRUNNING=1"
    taskkill /PID %%P /F /T >nul 2>&1
)
del /q "%TMP_PIDS%" >nul 2>&1

if "%WASRUNNING%"=="1" (
    echo Closed ungoogled-chromium so it can be updated...
    timeout /t 2 /nobreak >nul
)

echo Installing to %INSTALL_DIR% ...
robocopy "%TMP_EXTRACT%\%SUBFOLDER%" "%INSTALL_DIR%" /MIR /NFL /NDL /NJH /NJS /NC /NS /NP >nul
if %errorlevel% GEQ 8 (
    echo Copy to install folder failed. Aborting.
    goto :eof
)

>"%INSTALL_DIR%\version.txt" echo %VER%

rmdir /s /q "%TMP_EXTRACT%" >nul 2>&1
del /q "%TMP_ZIP%" >nul 2>&1

echo Done. ungoogled-chromium %VER% is installed at %INSTALL_DIR%

if "%WASRUNNING%"=="1" (
    echo Reopening ungoogled-chromium...
    start "" "%INSTALL_DIR%\chrome.exe" --restore-last-session
)

goto :eof


:end
echo.
pause
endlocal