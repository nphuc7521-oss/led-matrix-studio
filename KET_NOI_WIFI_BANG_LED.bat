@echo off
title KET NOI WIFI BANG LED
echo ==============================================================
echo        DANG KET NOI VAO WIFI BANG LED: WF2_1051db45b870
echo ==============================================================
echo.
echo [1] Dang nap profile WiFi...
netsh wlan add profile filename="%~dp0profile_board2.xml" user=current
echo.
echo [2] Dang ket noi toi WF2_1051db45b870...
netsh wlan connect name="WF2_1051db45b870"
echo.
echo [3] Dang cho 5 giay de nhan dia chi IP...
timeout /t 5 >nul
echo.
echo KET QUA IP HIEN TAI:
ipconfig | findstr /i "IPv4"
echo.
echo ==============================================================
echo XONG! Bay gio hay sang tab Web va bam 'GUI LEN BANG DEN LED'.
echo ==============================================================
pause
