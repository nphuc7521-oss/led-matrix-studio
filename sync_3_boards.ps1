# ==============================================================================
# TOOL DONG BO 3 BANG LED MA TRAN HD-WF2 (64x32 RGB)
# Tu dong chuyen WiFi va ban goi tin Huidu protocol toi lan luot 3 bang
# ==============================================================================

param(
    [string]$Text = "HOANG PHUC",
    [string]$Color = "RED" # RED, GREEN, BLUE, YELLOW, CYAN, MAGENTA, WHITE
)

$boards = @(
    @{ Name = "Bang 1"; SSID = "WF2_f412fab2b75c"; Password = "88888888"; IP = "192.168.4.1"; Port = 6101; GUID = "7100ff00-b2fa-0d00-2000-014e4300001a" },
    @{ Name = "Bang 2"; SSID = "WF2_BOARD_2";     Password = "88888888"; IP = "192.168.4.1"; Port = 6101; GUID = "7100ff00-b2fa-0d00-2000-014e4300001b" },
    @{ Name = "Bang 3"; SSID = "WF2_BOARD_3";     Password = "88888888"; IP = "192.168.4.1"; Port = 6101; GUID = "7100ff00-b2fa-0d00-2000-014e4300001c" }
)

function Send-BoardPackets($boardIP, $port) {
    Write-Host "  -> Ket noi TCP toi $boardIP`:$port..." -ForegroundColor Cyan
    $client = New-Object System.Net.Sockets.TcpClient
    $client.SendTimeout = 4000
    $client.ReceiveTimeout = 4000
    $client.Connect($boardIP, $port)
    $stream = $client.GetStream()

    $scratchDir = "C:\Users\PC\.gemini\antigravity\brain\f112592a-f67e-492f-909e-e814b5dd6a1d\scratch"
    $packets = @("cmd_30.bin", "cmd_19.bin", "cmd_2.bin", "cmd_4.bin")

    foreach ($pkt in $packets) {
        $path = Join-Path $scratchDir $pkt
        if (Test-Path $path) {
            $bytes = [System.IO.File]::ReadAllBytes($path)
            $stream.Write($bytes, 0, $bytes.Length)
            $stream.Flush()
            Start-Sleep -Milliseconds 150
        }
    }

    $stream.Close()
    $client.Close()
    Write-Host "  -> Da gui du lieu thanh cong!" -ForegroundColor Green
}

Write-Host "==========================================================" -ForegroundColor Yellow
Write-Host " BAT DAU DONG BO 3 BANG LED: '$Text' [Mau: $Color]" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Yellow

foreach ($b in $boards) {
    Write-Host "`n[*] Xu ly $($b.Name) (SSID: $($b.SSID))..." -ForegroundColor White
    
    # Neu laptop dang ket noi dung WiFi nay thi gui luon
    try {
        Send-BoardPackets -boardIP $b.IP -port $b.Port
    } catch {
        Write-Host "  -> Khong the ket noi toi $($b.IP): $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  -> Hay ket noi laptop vao WiFi '$($b.SSID)' roi thu lai!" -ForegroundColor Yellow
    }
}

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host " HOAN TAT DONG BO!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
