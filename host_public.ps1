# Suraksha Setu - 1-Click Public Tunnel & Local Host Launcher
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "  SURAKSHA SETU - Hosting Live Public Law-Enforcement Platform  " -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Start local TCP server on port 8088 if not already running
$port = 8088
$conn = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
if (-not $conn) {
    Write-Host "[+] Starting local TCP server on port $port..." -ForegroundColor Green
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File .\server_tcp.ps1 -Port $port" -WindowStyle Hidden
    Start-Sleep -Seconds 1
} else {
    Write-Host "[i] Local server is already running on port $port." -ForegroundColor Cyan
}

# 2. Start SSH tunnel to localhost.run
Write-Host "[+] Establishing secure public HTTPS tunnel..." -ForegroundColor Yellow
Write-Host "[i] You will see your public HTTPS URL below once connected:`n" -ForegroundColor DarkGray

ssh.exe -o StrictHostKeyChecking=no -R 80:127.0.0.1:$port nokey@localhost.run
