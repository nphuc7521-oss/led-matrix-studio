param(
    [string]$Text = "phuc",
    [string]$Color = "red",
    [int]$FontSize = 16,
    [int]$ShowEffect = 0
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $scriptDir) { $scriptDir = "D:\LAMVIEC\MẠCH ĐÈN LED MA TRẬN" }

$sendRaw = Join-Path $scriptDir "Send-RawPackets.ps1"
$p1Path = Join-Path $scriptDir "profile_board1.xml"
$p2Path = Join-Path $scriptDir "profile_board2.xml"

Write-Host "=================================================="
Write-Host "  DONG BO 2 BANG LED MA TRAN: WF2_f412 & WF2_1051"
Write-Host "  Truyen goi tin 'phuc' chuan HD2020"
Write-Host "=================================================="

# 1. Cai profile WiFi vao Windows
if (Test-Path $p1Path) { netsh wlan add profile filename="$p1Path" user=current | Out-Null }
if (Test-Path $p2Path) { netsh wlan add profile filename="$p2Path" user=current | Out-Null }

function Test-BoardOnline {
    param([string]$IP = "192.168.4.1", [int]$Port = 6101, [int]$TimeoutMs = 1200)
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $ar = $tcp.BeginConnect($IP, $Port, $null, $null)
        $wait = $ar.AsyncWaitHandle.WaitOne($TimeoutMs, $false)
        if ($wait -and $tcp.Connected) {
            $tcp.EndConnect($ar)
            $tcp.Close()
            return $true
        }
        $tcp.Close()
    } catch {}
    return $false
}

function Sync-SingleBoard {
    param(
        [string]$Name,
        [string]$Ssid
    )

    Write-Host "`n>>> [BUOC 1] KET NOI SANG: $Name ($Ssid)..."
    netsh wlan connect name="$Ssid" | Out-Null

    # Cho ket noi WiFi va cong 6101
    $connected = $false
    for ($i = 1; $i -le 15; $i++) {
        Write-Host "  Dang cho ket noi cong 6101 ($i/15s)..."
        Start-Sleep -Seconds 1
        if (Test-BoardOnline -IP "192.168.4.1" -Port 6101) {
            $connected = $true
            # Cho microcontroller on dinh socket
            Start-Sleep -Milliseconds 800
            break
        }
    }

    if (-not $connected) {
        Write-Host "  [LOI] Chua the ket noi toi WiFi '$Ssid'!" -ForegroundColor Red
        return $false
    }

    Write-Host "  [OK] Da ket noi thong suot toi $Name!" -ForegroundColor Green
    Write-Host ">>> [BUOC 2] TRUYEN GOI TIN VA HIEN THI CHU..."
    
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File "$sendRaw" -BoardIP "192.168.4.1" -Port 6101
    Write-Host ($out -join "`n")
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ===> [THANH CONG] $Name DA HIEN THI CHU 'phuc'!" -ForegroundColor Green
        return $true
    } else {
        Write-Host "  ===> [THAT BAI] Khong the truyen toi $Name!" -ForegroundColor Red
        return $false
    }
}

# 1. Dong bo Bang 1
$r1 = Sync-SingleBoard -Name "BANG 1" -Ssid "WF2_f412fab2b75c"
Start-Sleep -Seconds 3

# 2. Dong bo Bang 2
$r2 = Sync-SingleBoard -Name "BANG 2" -Ssid "WF2_1051db45b870"

Write-Host "`n=================================================="
if ($r1 -eq $true -and $r2 -eq $true) {
    Write-Host "  HOAN TAT! CA 2 BANG DA SANG CHU VA DONG BO!" -ForegroundColor Green
} elseif ($r1 -eq $true) {
    Write-Host "  BANG 1 DA SANG! Bang 2 chua nhan duoc." -ForegroundColor Yellow
} elseif ($r2 -eq $true) {
    Write-Host "  BANG 2 DA SANG! Bang 1 chua nhan duoc." -ForegroundColor Yellow
} else {
    Write-Host "  CHUA BANG NAO SANG. Vui long kiem tra WiFi." -ForegroundColor Red
}
Write-Host "=================================================="
