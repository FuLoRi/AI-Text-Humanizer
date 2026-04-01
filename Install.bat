@echo off
echo.
echo   Installing AI Text Humanizer...
echo.

set "SCRIPT_DIR=%~dp0"

where pwsh >nul 2>nul
if %ERRORLEVEL% equ 0 (
    pwsh -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Install.ps1"
) else (
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Install.ps1"
)
