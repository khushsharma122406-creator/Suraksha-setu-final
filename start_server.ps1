# Suraksha Setu - Local Web Server Launcher
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "  SURAKSHA SETU - Police Cybercrime Intelligence Platform       " -ForegroundColor Yellow
Write-Host "  Starting local law-enforcement investigation server...         " -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Cyan

$port = 8088
$prefix = "http://localhost:$port/"
$root = $PSScriptRoot

try {
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add($prefix)
    $listener.Start()
    Write-Host "[+] Local Server successfully listening at: $prefix" -ForegroundColor Green
    Write-Host "[+] Opening default web browser..." -ForegroundColor Cyan
    Start-Process $prefix

    Write-Host "[i] Press Ctrl+C in this console window to terminate server.`n" -ForegroundColor DarkGray

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $path = $request.Url.LocalPath.TrimStart('/')
        if ([string]::IsNullOrEmpty($path)) {
            $path = "index.html"
        }

        $filePath = Join-Path $root $path

        if (Test-Path $filePath -PathType Leaf) {
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            
            # Determine content type
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            $mime = switch ($ext) {
                ".html" { "text/html; charset=utf-8" }
                ".css"  { "text/css; charset=utf-8" }
                ".js"   { "application/javascript; charset=utf-8" }
                ".json" { "application/json; charset=utf-8" }
                ".png"  { "image/png" }
                ".jpg"  { "image/jpeg" }
                ".svg"  { "image/svg+xml" }
                ".ico"  { "image/x-icon" }
                default { "application/octet-stream" }
            }

            $response.ContentType = $mime
            $response.Headers.Add("Access-Control-Allow-Origin", "*")
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
            $errBytes = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
            $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
        }
        $response.Close()
    }
} catch {
    Write-Host "Server stopped or encountered error: $_" -ForegroundColor Red
} finally {
    if ($listener -ne $null -and $listener.IsListening) {
        $listener.Stop()
    }
}
