param(
    [string]$BoardIP = "192.168.4.1",
    [int]$Port = 6101
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $scriptDir) { $scriptDir = "D:\LAMVIEC\MẠCH ĐÈN LED MA TRẬN" }
$packetDir = Join-Path $scriptDir "packets"

Write-Host "Dang ket noi toi $BoardIP`:$Port qua TCP..." -ForegroundColor Cyan

try {
    $client = New-Object System.Net.Sockets.TcpClient
    $client.SendTimeout = 5000
    $client.ReceiveTimeout = 5000
    $client.Connect($BoardIP, $Port)
    $stream = $client.GetStream()
    Write-Host "[OK] Da ket noi thanh cong qua TCP!" -ForegroundColor Green

    $packets = @("cmd_30.bin", "cmd_19.bin", "cmd_2.bin", "cmd_4.bin")

    foreach ($pkt in $packets) {
        $path = Join-Path $packetDir $pkt
        if (Test-Path $path) {
            $bytes = [System.IO.File]::ReadAllBytes($path)
            Write-Host ("  Dang truyen {0} ({1} bytes)..." -f $pkt, $bytes.Length)
            $stream.Write($bytes, 0, $bytes.Length)
            $stream.Flush()
            Start-Sleep -Milliseconds 250

            # Doc phan hoi tu bo dieu khien
            if ($stream.DataAvailable) {
                $buf = New-Object byte[] 256
                $read = $stream.Read($buf, 0, $buf.Length)
                $hex = ($buf[0..([Math]::Min(15, $read - 1))] | ForEach-Object { '{0:X2}' -f $_ }) -join ' '
                Write-Host ("  -> Nhan {0} bytes: {1}" -f $read, $hex) -ForegroundColor Green
            }
        }
    }

    $stream.Close()
    $client.Close()
    Write-Host "`n[THANH CONG] Da truyen toan bo du lieu toi bang LED!" -ForegroundColor Green
    exit 0
} catch {
    Write-Host "[THAT BAI] Loi: $_" -ForegroundColor Red
    exit 1
}
