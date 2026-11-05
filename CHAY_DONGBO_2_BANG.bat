@echo off
chcp 65001 >nul
title DONG BO 2 BANG LED MA TRAN HD-WF2
cd /d "%~dp0"

echo ========================================================
echo   KHOI DONG GIAO DIEN DONG BO 2 BANG LED MA TRAN
echo ========================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "GiaoDien_DongBo.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [LOI] Co van de xay ra khi mo giao dien!
    pause
)
