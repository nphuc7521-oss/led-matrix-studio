$hdDir = 'C:\Program Files (x86)\HD2020'
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
    public static extern int Ad_PrepareScreenData(int nReserved);

    [DllImport("HDSDK.dll", CallingConvention = CallingConvention.Cdecl)]
    public static extern int Ad_GetScreenSendPack(int nPackIndex, IntPtr pBuffer, ref int pBufSize);

    [DllImport("HDSDK.dll", CallingConvention = CallingConvention.Cdecl)]
    public static extern int Hd_GetSDKLastError();
}
"@

[Kernel32]::SetDllDirectory($hdDir)
$hDll = [Kernel32]::LoadLibrary("$hdDir\HDSDK.dll")

$nScreen = [HDSdk]::Hd_CreateScreen(64, 32, 2, 1, 142, [IntPtr]::Zero, 0)
$nProgID = [HDSdk]::Hd_AddProgram([IntPtr]::Zero, 10, 1, [IntPtr]::Zero, 0)
$nAreaID = [HDSdk]::Hd_AddArea($nProgID, 0, 0, 64, 32, [IntPtr]::Zero, 0, 0, [IntPtr]::Zero, 0)
$colorRed = [HDSdk]::Hd_GetColor(255, 0, 0)
$nItem = [HDSdk]::Hd_AddSimpleTextAreaItem($nAreaID, "PHÚC", $colorRed, 0, 0, "Arial", 16, 0, 10, 0, 5, [IntPtr]::Zero, 0)

$prep = [HDSdk]::Ad_PrepareScreenData(0)
Write-Host "Ad_PrepareScreenData result: $prep (Err: $([HDSdk]::Hd_GetSDKLastError()))"

$bufSize = 0
$packCount = [HDSdk]::Ad_GetScreenSendPack(0, [IntPtr]::Zero, [ref]$bufSize)
Write-Host "Ad_GetScreenSendPack(0) bufSize: $bufSize, result: $packCount (Err: $([HDSdk]::Hd_GetSDKLastError()))"
