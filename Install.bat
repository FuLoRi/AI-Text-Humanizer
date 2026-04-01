@echo off
echo.
echo   Installing AI Text Humanizer...
echo.

set "SCRIPT_DIR=%~dp0"
powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Install.ps1"
