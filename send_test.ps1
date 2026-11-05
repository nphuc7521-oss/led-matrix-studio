# Script to test sending binary command packets to HD-WF2 board
param(
    [string]$BoardIP = "192.168.4.1",
    [int]$Port = 6101
)

Write-Host "Connecting to Board at $BoardIP`:$Port..."
try {
    $client = New-Object System.Net.Sockets.TcpClient
    $client.SendTimeout = 5000
    $client.ReceiveTimeout = 5000
    $client.Connect($BoardIP, $Port)
    $stream = $client.GetStream()
    Write-Host "Connected successfully via TCP!" -ForegroundColor Green

    $packets = @("cmd_30.bin", "cmd_19.bin", "cmd_2.bin", "cmd_4.bin")
    $scratchDir = "C:\Users\PC\.gemini\antigravity\brain\f112592a-f67e-492f-909e-e814b5dd6a1d\scratch"

    foreach ($pkt in $packets) {
        $path = Join-Path $scratchDir $pkt
        if (Test-Path $path) {
            $bytes = [System.IO.File]::ReadAllBytes($path)
            Write-Host ("Sending {0} ({1} bytes)..." -f $pkt, $bytes.Length)
            $stream.Write($bytes, 0, $bytes.Length)
            $stream.Flush()
            Start-Sleep -Milliseconds 200

            # Check if board sent response
            if ($stream.DataAvailable) {
                $buf = New-Object byte[] 1024
                $read = $stream.Read($buf, 0, $buf.Length)
                Write-Host ("  Received {0} bytes response: {1}" -f $read, (($buf[0..([Math]::Min(15, $read-1))] | ForEach-Object { '{0:X2}' -f $_ }) -join ' '))
            }
        }
    }

    $stream.Close()
    $client.Close()
    Write-Host "All packets sent! Check the LED board display!" -ForegroundColor Green
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
