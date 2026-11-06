@echo off
setlocal
cd /d "%~dp0"
echo ========================================================
echo   CAI DAT APP HD2020 LED STUDIO PRO CHO XIAOMI (MIUI 14)
echo ========================================================
echo.
echo Dang kiem tra ket noi dien thoai Xiaomi...
tools\platform-tools\adb.exe devices
echo.
echo Dang tien hanh cai dat HD2020_LED_Studio.apk vao may...
tools\platform-tools\adb.exe install -r -d "HD2020_LED_Studio.apk"
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================================
    echo   THANH CONG! APP DA DUOC CAP NHAT XONG 100%!
    echo ========================================================
) else (
    echo.
    echo [LOI] Kiem tra lai ket noi USB hoac bat Go loi USB tren may.
)
echo.
pause
