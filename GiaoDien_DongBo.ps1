$scriptDir = $PSScriptRoot
if (-not $scriptDir) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if (-not $scriptDir) {
    $scriptDir = "D:\LAMVIEC\MẠCH ĐÈN LED MA TRẬN"
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = "HUIDU HD-WF2 - DONG BO 2 BANG LED"
$form.Size = New-Object System.Drawing.Size(620, 720)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(24, 26, 32)
$form.ForeColor = [System.Drawing.Color]::White

# Title
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "DIEU KHIEN DONG BO BANG LED"
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(0, 210, 255)
$lblTitle.Location = New-Object System.Drawing.Point(30, 20)
$lblTitle.Size = New-Object System.Drawing.Size(540, 35)
$lblTitle.TextAlign = "MiddleCenter"
$form.Controls.Add($lblTitle)

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text = "Bang 1: WF2_f412fab2b75c  |  Bang 2: WF2_1051db45b870"
$lblSub.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblSub.ForeColor = [System.Drawing.Color]::LightGray
$lblSub.Location = New-Object System.Drawing.Point(30, 55)
$lblSub.Size = New-Object System.Drawing.Size(540, 20)
$lblSub.TextAlign = "MiddleCenter"
$form.Controls.Add($lblSub)

# Text Input Label
$lblText = New-Object System.Windows.Forms.Label
$lblText.Text = "Nhap noi dung chu hien thi:"
$lblText.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$lblText.Location = New-Object System.Drawing.Point(40, 95)
$lblText.Size = New-Object System.Drawing.Size(520, 25)
$form.Controls.Add($lblText)

# Text Box
$txtInput = New-Object System.Windows.Forms.TextBox
$txtInput.Text = "hoang phuc"
$txtInput.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$txtInput.Location = New-Object System.Drawing.Point(40, 125)
$txtInput.Size = New-Object System.Drawing.Size(520, 35)
$txtInput.BackColor = [System.Drawing.Color]::FromArgb(40, 44, 52)
$txtInput.ForeColor = [System.Drawing.Color]::Yellow
$form.Controls.Add($txtInput)

# Color Label
$lblColor = New-Object System.Windows.Forms.Label
$lblColor.Text = "Mau chu:"
$lblColor.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$lblColor.Location = New-Object System.Drawing.Point(40, 175)
$lblColor.Size = New-Object System.Drawing.Size(120, 25)
$form.Controls.Add($lblColor)

$cbColor = New-Object System.Windows.Forms.ComboBox
$cbColor.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$cbColor.DropDownStyle = "DropDownList"
[void]$cbColor.Items.Add("Do (Red)")
[void]$cbColor.Items.Add("Xanh la (Green)")
[void]$cbColor.Items.Add("Vang (Yellow)")
[void]$cbColor.Items.Add("Xanh duong (Blue)")
[void]$cbColor.Items.Add("Trang (White)")
$cbColor.SelectedIndex = 0
$cbColor.Location = New-Object System.Drawing.Point(40, 200)
$cbColor.Size = New-Object System.Drawing.Size(155, 30)
$form.Controls.Add($cbColor)

# Font Size Label
$lblFont = New-Object System.Windows.Forms.Label
$lblFont.Text = "Co chu:"
$lblFont.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$lblFont.Location = New-Object System.Drawing.Point(220, 175)
$lblFont.Size = New-Object System.Drawing.Size(120, 25)
$form.Controls.Add($lblFont)

$cbFont = New-Object System.Windows.Forms.ComboBox
$cbFont.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$cbFont.DropDownStyle = "DropDownList"
[void]$cbFont.Items.Add("16 (Vua khung)")
[void]$cbFont.Items.Add("20 (Lon)")
[void]$cbFont.Items.Add("24 (Rat lon)")
[void]$cbFont.Items.Add("32 (Toan man hinh)")
$cbFont.SelectedIndex = 0
$cbFont.Location = New-Object System.Drawing.Point(220, 200)
$cbFont.Size = New-Object System.Drawing.Size(155, 30)
$form.Controls.Add($cbFont)

# Effect Label
$lblEffect = New-Object System.Windows.Forms.Label
$lblEffect.Text = "Hieu ung:"
$lblEffect.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$lblEffect.Location = New-Object System.Drawing.Point(400, 175)
$lblEffect.Size = New-Object System.Drawing.Size(120, 25)
$form.Controls.Add($lblEffect)

$cbEffect = New-Object System.Windows.Forms.ComboBox
$cbEffect.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$cbEffect.DropDownStyle = "DropDownList"
[void]$cbEffect.Items.Add("Co dinh (Dung yen)")
[void]$cbEffect.Items.Add("Chay sang trai")
$cbEffect.SelectedIndex = 0
$cbEffect.Location = New-Object System.Drawing.Point(400, 200)
$cbEffect.Size = New-Object System.Drawing.Size(160, 30)
$form.Controls.Add($cbEffect)

# Big Send Button
$btnSend = New-Object System.Windows.Forms.Button
$btnSend.Text = "DONG BO 2 BANG CUNG LUC"
$btnSend.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$btnSend.BackColor = [System.Drawing.Color]::FromArgb(0, 180, 100)
$btnSend.ForeColor = [System.Drawing.Color]::White
$btnSend.FlatStyle = "Flat"
$btnSend.Location = New-Object System.Drawing.Point(40, 250)
$btnSend.Size = New-Object System.Drawing.Size(520, 50)
$btnSend.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnSend)

# Log Label
$lblLog = New-Object System.Windows.Forms.Label
$lblLog.Text = "Nhat ky truyen du lieu (Dang theo doi):"
$lblLog.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$lblLog.Location = New-Object System.Drawing.Point(40, 315)
$lblLog.Size = New-Object System.Drawing.Size(520, 20)
$lblLog.ForeColor = [System.Drawing.Color]::LightGray
$form.Controls.Add($lblLog)

# Log Box
$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Multiline = $true
$txtLog.ScrollBars = "Vertical"
$txtLog.ReadOnly = $true
$txtLog.Font = New-Object System.Drawing.Font("Consolas", 9)
$txtLog.BackColor = [System.Drawing.Color]::FromArgb(15, 17, 21)
$txtLog.ForeColor = [System.Drawing.Color]::LimeGreen
$txtLog.Location = New-Object System.Drawing.Point(40, 340)
$txtLog.Size = New-Object System.Drawing.Size(520, 310)
$form.Controls.Add($txtLog)

function LogMessage($msg) {
    $time = Get-Date -Format "HH:mm:ss"
    $txtLog.AppendText("[$time] $msg`r`n")
    $txtLog.SelectionStart = $txtLog.Text.Length
    $txtLog.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

$btnSend.Add_Click({
    $text = $txtInput.Text.Trim()
    if ([string]::IsNullOrEmpty($text)) {
        [System.Windows.Forms.MessageBox]::Show("Vui long nhap noi dung chu!", "Thong bao", "OK", "Warning")
        return
    }

    $btnSend.Enabled = $false
    $btnSend.Text = "DANG KET NOI VA DONG BO..."
    $btnSend.BackColor = [System.Drawing.Color]::Gray

    $colorMap = @{
        0 = "red"
        1 = "green"
        2 = "yellow"
        3 = "blue"
        4 = "white"
    }
    $colorVal = $colorMap[$cbColor.SelectedIndex]

    $fontSizes = @(16, 20, 24, 32)
    $fontSizeVal = $fontSizes[$cbFont.SelectedIndex]
    $effectVal = $cbEffect.SelectedIndex

    LogMessage("======================================")
    LogMessage("Bat dau dong bo chu: '$text'")
    LogMessage("Mau: $colorVal | Co: $fontSizeVal | Hieu ung: $effectVal")

    $dongboScript = Join-Path $scriptDir "DongBo_2Bang.ps1"

    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "powershell.exe"
    $pinfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$dongboScript`" -Text `"$text`" -Color `"$colorVal`" -FontSize $fontSizeVal -ShowEffect $effectVal"
    $pinfo.RedirectStandardOutput = $true
    $pinfo.RedirectStandardError = $true
    $pinfo.UseShellExecute = $false
    $pinfo.CreateNoWindow = $true

    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null

    # Doc song song output de cap nhat theo thoi gian thuc
    while (-not $p.HasExited) {
        while (-not $p.StandardOutput.EndOfStream) {
            $line = $p.StandardOutput.ReadLine()
            if ($line) { LogMessage($line) }
        }
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 100
    }

    while (-not $p.StandardOutput.EndOfStream) {
        $line = $p.StandardOutput.ReadLine()
        if ($line) { LogMessage($line) }
    }

    $btnSend.Enabled = $true
    $btnSend.Text = "DONG BO 2 BANG CUNG LUC"
    $btnSend.BackColor = [System.Drawing.Color]::FromArgb(0, 180, 100)
})

LogMessage("Ung dung san sang. Nhap chu va bam nut de dong bo!")
[void]$form.ShowDialog()
