@echo off
SETLOCAL ENABLEDELAYEDEXPANSION
title 🔐 DeepFaceLab Launch & Lock Environment (Multi-User Safe)

REM ============================================================================
REM 🔐 FILE: Launch_n_Lock_DFL_Env.bat
REM ----------------------------------------------------------------------------
REM AUTHOR      : @yourgithubusername
REM CREATED     : 2024
REM LICENSE     : MIT
REM PURPOSE     : System-integrated DeepFaceLab launcher with cleanup/reset
REM ----------------------------------------------------------------------------
REM 🔧 TECHNICAL OVERVIEW:
REM Isolates DFL to a locked shell, redirects TEMP, cleans leftover processes,
REM and performs full system cleanup & reboot after session ends.
REM ============================================================================

:: === AUTO-ELEVATE TO ADMIN ===
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo 🔐 Requesting administrator privileges...
    powershell -Command "Start-Process -Verb RunAs -FilePath '%~f0'"
    exit /b
)

:: === PATHS ===
SET "BASEDIR=%~dp0"
SET "BASEDIR=%BASEDIR:~0,-1%"
SET "SETENV=%BASEDIR%\setenv.bat"
SET "WORKDIR=%BASEDIR%"
SET "WORKSPACE=%BASEDIR%\..\workspace"
SET "LOGFILE=%USERPROFILE%\Desktop\DFL_Cleanup_Summary.txt"

IF NOT EXIST "%SETENV%" (
    echo ❌ ERROR: Required environment script not found:
    echo     %SETENV%
    pause
    exit /b
)

:: === LAUNCH LOCKED SHELL ===
echo 🚀 Launching DeepFaceLab Shell Environment...
echo 💡 Type 'exit' when you're done to unlock and start cleanup...
timeout /t 1 >nul

start /wait cmd /k "%SETENV% && cd /d %WORKDIR% && powershell -noexit -Command \"$host.UI.RawUI.WindowTitle='🔒 DeepFaceLab Shell — type ''exit'' to unlock'\""

:: === FORCE-KILL DFL PROCESSES ===
echo.
echo 🧹 Checking for orphaned DeepFaceLab processes...

for %%P in (python.exe ffmpeg.exe train.exe main.exe) do (
    tasklist /fi "imagename eq %%P" | find /i "%%P" >nul
    if !errorlevel! neq 1 (
        echo 🔪 Terminating: %%P
        taskkill /f /im %%P >nul 2>&1
    )
)
echo ✅ DFL background processes terminated.

:: === RELEASE TEMP FOLDER (_e\t) ===
echo 🔄 Releasing DeepFaceLab TEMP folder (_e\t)...
timeout /t 2 >nul
rd /s /q "%WORKDIR%\_e\t" >nul 2>&1
if exist "%WORKDIR%\_e\t" (
    echo ⚠️ TEMP folder could not be deleted — still in use.
    echo ❌ TEMP folder still locked: %WORKDIR%\_e\t >> "%LOGFILE%"
) else (
    echo ✅ TEMP folder _e\t released successfully.
    echo ✔ TEMP folder cleaned: %WORKDIR%\_e\t >> "%LOGFILE%"
)

echo.
echo 🔓 Session closed. Starting cleanup wizard...

:: === INIT LOG FLAGS ===
set "log_cleanWS=❌ Workspace cleanup skipped"
set "log_cleanTMP=❌ TEMP cleanup skipped"
set "log_cleanWin=❌ System cleanup skipped"
set "log_pagefile=❌ Pagefile not modified"
set "log_restore=❌ Restore point not created"

:: === STEP 1: Workspace cleanup
set /p cleanWS="🧹 Delete .log/.tmp/.bak files from workspace? (Y/N): "
if /i "%cleanWS%"=="Y" (
    for %%X in (log tmp bak) do (
        del /s /q "%WORKSPACE%\*.%%X" >nul 2>&1
    )
    set "log_cleanWS=✔ Workspace cleaned"
    echo ✅ Workspace cleaned.
)

:: === STEP 2: TEMP cleanup
set /p cleanTMP="🧺 Clean TEMP folder (%TEMP%)? (Y/N): "
if /i "%cleanTMP%"=="Y" (
    del /s /q "%TEMP%\*" >nul 2>&1
    set "log_cleanTMP=✔ TEMP folder cleaned"
    echo ✅ TEMP folder cleaned.
)

:: === STEP 3: Windows logs/cache cleanup
set /p cleanWin="🧼 Clean Windows logs/cache/update files? (Y/N): "
if /i "%cleanWin%"=="Y" (
    for %%F in (
        "%WINDIR%\Temp\*"
        "%WINDIR%\Prefetch\*"
        "%WINDIR%\Logs\*"
        "%WINDIR%\System32\LogFiles\*"
        "%WINDIR%\SoftwareDistribution\Download\*"
        "%LOCALAPPDATA%\Microsoft\Windows\INetCache\*"
    ) do (
        del /s /q %%F >nul 2>&1
    )
    set "log_cleanWin=✔ System logs/cache cleaned"
    echo ✅ System cleanup done.
)

:: === STEP 4: Pagefile
set /p pfmanage="💾 Reset pagefile to 4096–8192 MB? (Y/N): "
if /i "%pfmanage%"=="Y" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "try {
        Get-WmiObject Win32_PageFileSetting | ForEach-Object { $_.Delete() };
        [WMIClass]'Win32_PageFileSetting'::Create('C:\pagefile.sys', 4096, 8192) | Out-Null
    } catch { }"
    set "log_pagefile=✔ Pagefile set to 4096–8192 MB"
    echo ✅ Pagefile updated.
)

:: === STEP 5: System Restore
set /p mkrestore="🛡️ Create system restore point? (Y/N): "
if /i "%mkrestore%"=="Y" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "try {
        Checkpoint-Computer -Description 'DFL Cleanup Restore' -RestorePointType MODIFY_SETTINGS
    } catch { }"
    set "log_restore=✔ Restore point created"
    echo ✅ Restore point created.
)

:: === WRITE LOG FILE ===
(
    echo DeepFaceLab Cleanup Summary
    echo ============================
    echo Date: %DATE%
    echo Time: %TIME%
    echo.
    echo %log_cleanWS%
    echo %log_cleanTMP%
    echo %log_cleanWin%
    echo %log_pagefile%
    echo %log_restore%
    echo.
    echo 🔁 System reboot required to apply changes.
) >> "%LOGFILE%"

echo.
echo 📝 Summary saved to: %LOGFILE%
echo 🔄 Rebooting in 15 seconds...
timeout /t 15 >nul
shutdown /r /t 0
