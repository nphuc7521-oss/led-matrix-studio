@echo off
chcp 65001 >nul 2>&1
title MAY CHU WEB DIEU KHIEN DONG BO BANG LED HD-WF2 (V18 PRO - HO TRO IPHONE / ANDROID / PC)
color 0A

echo ==============================================================
echo     HE THONG DIEU KHIEN DONG BO CAC BANG LED MA TRAN (V18 PRO)
echo     - HO TRO DIEU KHIEN TRUC TIEP TREN IPHONE VA ANDROID!
echo     - FIX DUT DIEM VIEN CHAY: Vien chay quanh 4 canh ngoai doc lap 100%!
echo     - KHONG CON BI CUON THEO CHU: Chu cuon/chay thoai mai ben trong!
echo     - FULL 7 MAU [AB], MAU DON SAC & FONT CHU NET CAN GIUA CHUAN 100%!
echo ==============================================================
echo.
if not exist "C:\Program Files (x86)\HD2020\HDSDK.dll" goto NoSDK

echo [1] Kiem tra thu vien HDSDK.dll: SAN SANG!
echo.
echo [2] Mo tuong lua Windows Firewall cho dien thoai ket noi...
netsh advfirewall firewall add rule name="HD2020 LED Studio Port 8080" dir=in action=allow protocol=TCP localport=8080 >nul 2>&1
echo.
echo [3] Dang dong cac phien cu (neu co)...
taskkill /F /IM WebLedServer.exe >nul 2>&1
taskkill /F /IM WebLedSync*.exe >nul 2>&1
echo.
echo [4] Dang khoi dong Web Server V18 tai: http://localhost:8080 ...
echo ==============================================================
echo   DIA CHI TRANG WEB (MAY TINH):   http://localhost:8080
echo   DIA CHI TRANG WEB (DIEN THOAI): http://192.168.0.104:8080
echo ==============================================================
echo (Giu cua so nay mo trong suot qua trinh dieu khien bang LED)
echo.
cd /d "%~dp0web_control"
start "" http://localhost:8080
WebLedSyncV18.exe
goto End

:NoSDK
color 0C
echo [LOI] Khong tim thay HDSDK.dll tai C:\Program Files (x86)\HD2020\
echo Hay cai dat phan mem HD2020 truoc!
pause
exit /b

:End
pause
