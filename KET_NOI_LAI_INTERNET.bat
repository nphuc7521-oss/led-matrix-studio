@echo off
title KET NOI LAI WIFI VAN PHONG
echo ==============================================================
echo        DANG KET NOI LAI WIFI VAN PHONG (Chi Nhanh)
echo ==============================================================
echo.
netsh wlan connect name="Chi Nhanh"
timeout /t 3 >nul
echo.
echo Da ket noi lai WiFi van phong!
pause
