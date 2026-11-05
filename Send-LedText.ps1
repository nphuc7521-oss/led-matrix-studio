param(
    [string]$Text = "phúc",
    [string]$Color = "red",
    [int]$FontSize = 16,
    [int]$ShowEffect = 0, # 0 = Tĩnh, 1 = Chạy trái
    [int]$Speed = 10,
    [string]$BoardIP = "192.168.4.1"
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$hdDir = 'C:\Program Files (x86)\HD2020'
if (-not (Test-Path "$hdDir\HDSDK.dll")) {
    Write-Host "KHÔNG TÌM THẤY HDSDK.dll tại $hdDir" -ForegroundColor Red
    exit 1
}

[System.Environment]::SetEnvironmentVariable('PATH', "$hdDir;" + [System.Environment]::GetEnvironmentVariable('PATH'))
Set-Location $hdDir

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Kernel32 {
    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern bool SetDllDirectory(string lpPathName);
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr LoadLibrary(string lpFileName);
}

public class HDSdk {
    [DllImport("HDSDK.dll", CallingConvention = CallingConvention.Cdecl)]
    public static extern int Hd_CreateScreen(int nWidth, int nHeight, int nColor, int nGray, int nCardType, IntPtr pParams, int nReserved);

    [DllImport("HDSDK.dll", CallingConvention = CallingConvention.Cdecl)]
    public static extern int Hd_AddProgram(IntPtr pParams, int nPlayTime, int nPlayCount, IntPtr pWeek, int nWeekLen);

    [DllImport("HDSDK.dll", CallingConvention = CallingConvention.Cdecl)]
    public static extern int Hd_AddArea(int nProgramID, int nX, int nY, int nWidth, int nHeight, IntPtr pBorderImgPath, int nBorderEffect, int nBorderSpeed, IntPtr pExParamsBuf, int nBufSize);

    [DllImport("HDSDK.dll", CallingConvention = CallingConvention.Cdecl)]
    public static extern int Hd_AddSimpleTextAreaItem(int nAreaID, [MarshalAs(UnmanagedType.LPWStr)] string pText, int nTextColor, int nBackGroupColor, int nStyle, [MarshalAs(UnmanagedType.LPWStr)] string pFontName, int nFontHeight, int nShowEffect, int nShowSpeed, int nClearType, int nStayTime, IntPtr pExParamsBuf, int nBufSize);

    [DllImport("HDSDK.dll", CallingConvention = CallingConvention.Cdecl)]
    public static extern int Hd_GetColor(int r, int g, int b);

    [DllImport("HDSDK.dll", CallingConvention = CallingConvention.Cdecl)]
    public static extern int Hd_SendScreen(int nSendType, [MarshalAs(UnmanagedType.LPStr)] string pStrParams, [MarshalAs(UnmanagedType.LPStr)] string pDeviceGUID, IntPtr pExParamsBuf, int nBufSize);

    [DllImport("HDSDK.dll", CallingConvention = CallingConvention.Cdecl)]
    public static extern int Hd_GetSDKLastError();
}
"@

[Kernel32]::SetDllDirectory($hdDir)
$hDll = [Kernel32]::LoadLibrary("$hdDir\HDSDK.dll")

# Color mapping
$colorVal = switch ($Color.ToLower()) {
    "red"     { [HDSdk]::Hd_GetColor(255, 0, 0) }
    "green"   { [HDSdk]::Hd_GetColor(0, 255, 0) }
    "blue"    { [HDSdk]::Hd_GetColor(0, 0, 255) }
    "yellow"  { [HDSdk]::Hd_GetColor(255, 255, 0) }
    "cyan"    { [HDSdk]::Hd_GetColor(0, 255, 255) }
    "magenta" { [HDSdk]::Hd_GetColor(255, 0, 255) }
    "white"   { [HDSdk]::Hd_GetColor(255, 255, 255) }
    default   { [HDSdk]::Hd_GetColor(255, 0, 0) }
}

Write-Host "Đang tạo nội dung: '$Text' (Màu: $Color, Cỡ: $FontSize)..." -ForegroundColor Cyan

# 1. Create Screen: 64x32, color=2, gray=1, cardType=142 (HD-WF2)
$nScreen = [HDSdk]::Hd_CreateScreen(64, 32, 2, 1, 142, [IntPtr]::Zero, 0)
if ($nScreen -ne 0) {
    Write-Host "Lỗi tạo màn hình! Mã lỗi: $([HDSdk]::Hd_GetSDKLastError())" -ForegroundColor Red
    exit 1
}

# 2. Add Program
$nProgID = [HDSdk]::Hd_AddProgram([IntPtr]::Zero, 10, 1, [IntPtr]::Zero, 0)

# 3. Add Area: full screen 0,0,64,32
$nAreaID = [HDSdk]::Hd_AddArea($nProgID, 0, 0, 64, 32, [IntPtr]::Zero, 0, 0, [IntPtr]::Zero, 0)

# 4. Add Text Item (Tiếng Việt Unicode qua LPWStr)
$nItem = [HDSdk]::Hd_AddSimpleTextAreaItem($nAreaID, $Text, $colorVal, 0, 1, "Arial", $FontSize, $ShowEffect, $Speed, 0, 3, [IntPtr]::Zero, 0)

# 5. Send Screen to board IP
Write-Host "Đang truyền tới bảng LED tại $BoardIP..." -ForegroundColor Yellow
$res = [HDSdk]::Hd_SendScreen(0, $BoardIP, $null, [IntPtr]::Zero, 0)
$err = [HDSdk]::Hd_GetSDKLastError()

if ($res -eq 0) {
    Write-Host "THÀNH CÔNG! Bảng đã cập nhật chữ '$Text'!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Lỗi gửi tới $BoardIP! Mã lỗi: $err" -ForegroundColor Red
    exit $err
}
