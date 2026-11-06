@echo off
chcp 65001 >nul
echo ========================================================
echo   CÔNG CỤ CÀI ĐẶT APP CHO ĐIỆN THOẠI XIAOMI (MIUI 14)
echo ========================================================
echo.
echo 1. Hãy cắm cáp USB nối điện thoại Xiaomi với máy tính.
echo 2. Trên Xiaomi, đảm bảo đã BẬT:
echo    - "Gỡ lỗi USB" (USB debugging)
echo    - "Cài đặt qua USB" (Install via USB)
echo.
pause
echo.
echo Đang kiểm tra kết nối điện thoại...
"tools\platform-tools\adb.exe" devices
echo.
echo Đang tiến hành cài đặt ứng dụng HD2020_LED_Studio.apk vào máy Xiaomi...
"tools\platform-tools\adb.exe" install -r "HD2020_LED_Studio.apk"
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================================
    echo   CHÚC MỪNG! APP ĐÃ ĐƯỢC CÀI ĐẶT THÀNH CÔNG LÊN XIAOMI!
    echo ========================================================
) else (
    echo.
    echo [LƯU Ý] Nếu máy báo lỗi:
    echo - Nhìn vào màn hình điện thoại Xiaomi xem có hiện thông báo "Cho phép gỡ lỗi USB" hoặc "Cho phép cài đặt qua USB" không, bấm CHO PHÉP (OK).
    echo - Sau đó chạy lại file này!
)
echo.
pause
