using System;
using System.IO;
using System.Text;

class MakeBat {
    static void Main() {
        string dir = @"d:\LAMVIEC\MẠCH ĐÈN LED MA TRẬN";

        string bat = "@echo off\r\n" +
                     "title MAY CHU WEB DIEU KHIEN DONG BO BANG LED HD-WF2 (V3)\r\n" +
                     "color 0A\r\n\r\n" +
                     "echo ==============================================================\r\n" +
                     "echo     HE THONG DIEU KHIEN DONG BO CAC BANG LED MA TRAN (V3)\r\n" +
                     "echo ==============================================================\r\n" +
                     "echo.\r\n" +
                     "if not exist \"C:\\Program Files (x86)\\HD2020\\HDSDK.dll\" goto NoSDK\r\n\r\n" +
                     "echo [1] Kiem tra thu vien HDSDK.dll: SAN SANG!\r\n" +
                     "echo.\r\n" +
                     "echo [2] Dang dong cac phien cu (neu co)...\r\n" +
                     "taskkill /F /IM WebLedServer.exe >nul 2>&1\r\n" +
                     "taskkill /F /IM WebLedSync.exe >nul 2>&1\r\n" +
                     "taskkill /F /IM WebLedSyncV2.exe >nul 2>&1\r\n" +
                     "taskkill /F /IM WebLedSyncV3.exe >nul 2>&1\r\n" +
                     "echo.\r\n" +
                     "echo [3] Dang khoi dong Web Server V3 tai: http://localhost:8080 ...\r\n" +
                     "echo ==============================================================\r\n" +
                     "echo   DIA CHI TRANG WEB:   http://localhost:8080\r\n" +
                     "echo ==============================================================\r\n" +
                     "echo (Giu cua so nay mo trong suot qua trinh dieu khien bang LED)\r\n" +
                     "echo.\r\n" +
                     "cd /d \"%~dp0web_control\"\r\n" +
                     "start \"\" http://localhost:8080\r\n" +
                     "WebLedSyncV3.exe\r\n" +
                     "goto End\r\n\r\n" +
                     ":NoSDK\r\n" +
                     "color 0C\r\n" +
                     "echo [LOI] Khong tim thay C:\\Program Files (x86)\\HD2020\\HDSDK.dll\r\n" +
                     "pause\r\n" +
                     "exit /b\r\n\r\n" +
                     ":End\r\n" +
                     "pause\r\n";

        File.WriteAllText(Path.Combine(dir, "CHAY_WEB_DIEU_KHIEN.bat"), bat, Encoding.ASCII);
        Console.WriteLine("SUCCESS UPDATE CHAY_WEB_DIEU_KHIEN.bat to V3!");
    }
}
