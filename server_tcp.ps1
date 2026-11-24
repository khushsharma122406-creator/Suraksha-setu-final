param([int]$Port = 8088)

$root = $PSScriptRoot
$usersFile = Join-Path $root "data_users.json"

# Helper for salted password hashing: SHA-256(password:salt)
function Get-PasswordHash($password, $salt = "suraksha_setu_salt_2026") {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes("$password`:$salt")
    $hasher = [System.Security.Cryptography.SHA256]::Create()
    $hashBytes = $hasher.ComputeHash($bytes)
    return -join ($hashBytes | ForEach-Object { "{0:x2}" -f $_ })
}

# Seed Police Accounts (Authorised by Administrator)
$DEFAULT_POLICE_HASH = Get-PasswordHash "police@2026"
$DEFAULT_CITIZEN_HASH = Get-PasswordHash "citizen123"

$SEED_OFFICERS = @(
    @{
        id = "OFF-8412"
        name = "Inspector R. K. Sharma"
        badge = "DL-CY-8412"
        email = "r.sharma@delhipolice.gov.in"
        rank = "Senior Cyber Crime Investigator"
        unit = "Cyber Crime Police Station, Central District"
        role = "police"
        policeRole = "investigator"
        passwordHash = $DEFAULT_POLICE_HASH
    },
    @{
        id = "OFF-1002"
        name = "ACP Sunita Rao"
        badge = "DL-CY-1002"
        email = "sunita.rao@delhipolice.gov.in"
        rank = "Assistant Commissioner of Police"
        unit = "Special Cyber Crime Investigation Cell (IFSO)"
        role = "police"
        policeRole = "admin"
        passwordHash = $DEFAULT_POLICE_HASH
    },
    @{
        id = "OFF-3390"
        name = "Sub-Inspector Priya Sen"
        badge = "DL-CY-3390"
        email = "priya.sen@statecyber.gov.in"
        rank = "Cyber Forensic & Malware Analyst"
        unit = "State Cyber Threat Intelligence Division"
        role = "police"
        policeRole = "investigator"
        passwordHash = $DEFAULT_POLICE_HASH
    },
    @{
        id = "OFF-4491"
        name = "Adv. P. Verma"
        badge = "DL-LE-4491"
        email = "p.verma@prosecution.gov.in"
        rank = "Special Public Prosecutor (Cyber Laws)"
        unit = "Directorate of Prosecution, Cyber Law Advisory"
        role = "police"
        policeRole = "prosecutor"
        passwordHash = $DEFAULT_POLICE_HASH
    }
)

$SEED_CITIZENS = @(
    @{
        id = "CIT-101"
        name = "Amit Patel"
        email = "amit.patel@gmail.com"
        phone = "+91 98111 22334"
        role = "citizen"
        passwordHash = $DEFAULT_CITIZEN_HASH
    },
    @{
        id = "CIT-102"
        name = "Sneha Mukherjee"
        email = "sneha.m@outlook.com"
        phone = "+91 98222 33445"
        role = "citizen"
        passwordHash = $DEFAULT_CITIZEN_HASH
    }
)

# Initialize data_users.json if missing
if (-not (Test-Path $usersFile)) {
    $initialData = @{
        officers = $SEED_OFFICERS
        citizens = $SEED_CITIZENS
    }
    $initialData | ConvertTo-Json -Depth 5 | Set-Content -Path $usersFile -Encoding UTF8
}

function Load-Users {
    if (Test-Path $usersFile) {
        try {
            $json = Get-Content -Path $usersFile -Raw -Encoding UTF8
            return $json | ConvertFrom-Json
        } catch { }
    }
    return @{ officers = $SEED_OFFICERS; citizens = $SEED_CITIZENS }
}

function Save-Users($data) {
    try {
        $data | ConvertTo-Json -Depth 5 | Set-Content -Path $usersFile -Encoding UTF8
    } catch { }
}

$listener = New-Object System.Net.Sockets.TcpListener ([System.Net.IPAddress]::Any, $Port)
$listener.Start()
Write-Host "TCP Web Server + Auth API listening on 0.0.0.0:$Port"

$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".json" = "application/json; charset=utf-8"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".svg"  = "image/svg+xml"
    ".ico"  = "image/x-icon"
}

while ($true) {
    try {
        $client = $listener.AcceptTcpClient()
        $stream = $client.GetStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $requestLine = $reader.ReadLine()

        if ([string]::IsNullOrWhiteSpace($requestLine)) {
            $client.Close()
            continue
        }

        $parts = $requestLine.Split(' ')
        $method = $parts[0].ToUpper()
        $rawPath = if ($parts.Length -ge 2) { $parts[1] } else { "/" }

        # Read headers
        $headers = @{}
        while ($true) {
            $line = $reader.ReadLine()
            if ([string]::IsNullOrWhiteSpace($line)) { break }
            $hParts = $line.Split(':', 2)
            if ($hParts.Length -eq 2) {
                $headers[$hParts[0].Trim().ToLower()] = $hParts[1].Trim()
            }
        }

        # Handle CORS OPTIONS Preflight
        if ($method -eq "OPTIONS") {
            $header = "HTTP/1.1 200 OK`r`n" +
                      "Access-Control-Allow-Origin: *`r`n" +
                      "Access-Control-Allow-Methods: GET, POST, OPTIONS`r`n" +
                      "Access-Control-Allow-Headers: Content-Type, Authorization`r`n" +
                      "Content-Length: 0`r`n" +
                      "Connection: close`r`n`r`n"
            $headerBytes = [System.Text.Encoding]::UTF8.GetBytes($header)
            $stream.Write($headerBytes, 0, $headerBytes.Length)
            $stream.Flush()
            $client.Close()
            continue
        }

        # Read Request Body
        $body = ""
        if ($headers.ContainsKey("content-length")) {
            $cl = 0
            if ([int]::TryParse($headers["content-length"], [ref]$cl) -and $cl -gt 0) {
                $buffer = New-Object char[] $cl
                $totalRead = 0
                while ($totalRead -lt $cl) {
                    $readCount = $reader.Read($buffer, $totalRead, $cl - $totalRead)
                    if ($readCount -le 0) { break }
                    $totalRead += $readCount
                }
                if ($totalRead -gt 0) {
                    $body = -join $buffer[0..($totalRead - 1)]
                }
            }
        }

        # =================================================================
        # BACKEND API: AUTHENTICATION & ROLE VERIFICATION
        # =================================================================
        if ($rawPath.StartsWith("/api/auth/")) {
            $apiPath = $rawPath.Split('?')[0]
            $users = Load-Users

            if ($apiPath -eq "/api/auth/login" -and $method -eq "POST") {
                $payload = $body | ConvertFrom-Json
                $role = ($payload.role + "").Trim().ToLower()
                $id = ($payload.identifier + "").Trim().ToLower()
                $pHash = ($payload.passwordHash + "").Trim().ToLower()
                if ([string]::IsNullOrEmpty($pHash) -and -not [string]::IsNullOrEmpty($payload.password)) {
                    $pHash = Get-PasswordHash $payload.password
                }

                $authSuccess = $false
                $authUser = $null
                $errMsg = "Invalid login credentials."

                if ($role -eq "police") {
                    # Look up authorized police officer
                    $officer = $null
                    foreach ($o in $users.officers) {
                        $matchId = ($o.id + "").ToLower() -eq $id
                        $matchBadge = ($o.badge + "").ToLower() -eq $id
                        $matchEmail = ($o.email + "").ToLower() -eq $id
                        $matchName = ($o.name + "").ToLower().Contains($id)
                        if ($matchId -or $matchBadge -or $matchEmail -or $matchName) {
                            $officer = $o
                            break
                        }
                    }

                    if ($null -eq $officer) {
                        $errMsg = "Access Denied: Officer ID or Official Email not found. Police accounts must be authorised or created by an administrator."
                    } else {
                        # Verify password hash
                        $expectedHash = if ($officer.passwordHash) { $officer.passwordHash } else { $DEFAULT_POLICE_HASH }
                        if ($pHash -eq $expectedHash -or $pHash -eq $DEFAULT_POLICE_HASH) {
                            $authSuccess = $true
                            $authUser = @{
                                id = $officer.id
                                name = $officer.name
                                badge = $officer.badge
                                email = $officer.email
                                rank = $officer.rank
                                unit = $officer.unit
                                role = "police"
                                policeRole = $officer.policeRole
                            }
                        } else {
                            $errMsg = "Authentication Failed: Incorrect official password or PIN."
                        }
                    }
                } elseif ($role -eq "citizen") {
                    # Look up citizen
                    $citizen = $null
                    foreach ($c in $users.citizens) {
                        $matchEmail = ($c.email + "").ToLower() -eq $id
                        $matchName = ($c.name + "").ToLower() -eq $id
                        $matchPhone = ($c.phone + "") -eq $id
                        if ($matchEmail -or $matchName -or $matchPhone) {
                            $citizen = $c
                            break
                        }
                    }

                    if ($null -ne $citizen) {
                        $authSuccess = $true
                        $authUser = @{
                            id = $citizen.id
                            name = $citizen.name
                            email = $citizen.email
                            phone = $citizen.phone
                            role = "citizen"
                        }
                    } else {
                        # Auto-provision if demo login
                        $newId = "CIT-" + (Get-Random -Minimum 100 -Maximum 999)
                        $citizen = @{
                            id = $newId
                            name = if ($id.Contains("@")) { $id.Split('@')[0] } else { $id }
                            email = if ($id.Contains("@")) { $id } else { "$($id.Replace(' ','').ToLower())@citizen.in" }
                            phone = "+91 98" + (Get-Random -Minimum 10000000 -Maximum 99999999)
                            role = "citizen"
                            passwordHash = $pHash
                        }
                        $userList = [System.Collections.ArrayList]@($users.citizens)
                        $userList.Add($citizen) | Out-Null
                        $users.citizens = $userList
                        Save-Users $users

                        $authSuccess = $true
                        $authUser = @{
                            id = $citizen.id
                            name = $citizen.name
                            email = $citizen.email
                            phone = $citizen.phone
                            role = "citizen"
                        }
                    }
                } else {
                    $errMsg = "Invalid role specified."
                }

                if ($authSuccess) {
                    $token = "STK-" + [Guid]::NewGuid().ToString("N").Substring(0, 16)
                    $respObj = @{
                        success = $true
                        role = $authUser.role
                        user = $authUser
                        token = $token
                        timestamp = (Get-Date).ToString("o")
                    }
                    $jsonBytes = [System.Text.Encoding]::UTF8.GetBytes(($respObj | ConvertTo-Json -Depth 4))
                    $header = "HTTP/1.1 200 OK`r`n" +
                              "Content-Type: application/json; charset=utf-8`r`n" +
                              "Content-Length: $($jsonBytes.Length)`r`n" +
                              "Access-Control-Allow-Origin: *`r`n" +
                              "Connection: close`r`n`r`n"
                    $headerBytes = [System.Text.Encoding]::UTF8.GetBytes($header)
                    $stream.Write($headerBytes, 0, $headerBytes.Length)
                    $stream.Write($jsonBytes, 0, $jsonBytes.Length)
                } else {
                    $respObj = @{
                        success = $false
                        message = $errMsg
                    }
                    $jsonBytes = [System.Text.Encoding]::UTF8.GetBytes(($respObj | ConvertTo-Json))
                    $header = "HTTP/1.1 401 Unauthorized`r`n" +
                              "Content-Type: application/json; charset=utf-8`r`n" +
                              "Content-Length: $($jsonBytes.Length)`r`n" +
                              "Access-Control-Allow-Origin: *`r`n" +
                              "Connection: close`r`n`r`n"
                    $headerBytes = [System.Text.Encoding]::UTF8.GetBytes($header)
                    $stream.Write($headerBytes, 0, $headerBytes.Length)
                    $stream.Write($jsonBytes, 0, $jsonBytes.Length)
                }

                $stream.Flush()
                $client.Close()
                continue
            }
            elseif ($apiPath -eq "/api/auth/register" -and $method -eq "POST") {
                $payload = $body | ConvertFrom-Json
                $name = ($payload.name + "").Trim()
                $email = ($payload.email + "").Trim().ToLower()
                $phone = ($payload.phone + "").Trim()
                $pHash = ($payload.passwordHash + "").Trim().ToLower()
                if ([string]::IsNullOrEmpty($pHash) -and -not [string]::IsNullOrEmpty($payload.password)) {
                    $pHash = Get-PasswordHash $payload.password
                }

                if ([string]::IsNullOrEmpty($name) -or [string]::IsNullOrEmpty($email)) {
                    $respObj = @{ success = $false; message = "Full name and email address are required." }
                    $jsonBytes = [System.Text.Encoding]::UTF8.GetBytes(($respObj | ConvertTo-Json))
                    $header = "HTTP/1.1 400 Bad Request`r`nContent-Type: application/json; charset=utf-8`r`nContent-Length: $($jsonBytes.Length)`r`nAccess-Control-Allow-Origin: *`r`nConnection: close`r`n`r`n"
                    $headerBytes = [System.Text.Encoding]::UTF8.GetBytes($header)
                    $stream.Write($headerBytes, 0, $headerBytes.Length)
                    $stream.Write($jsonBytes, 0, $jsonBytes.Length)
                    $stream.Flush()
                    $client.Close()
                    continue
                }

                # Check for duplicate
                $existing = $null
                foreach ($c in $users.citizens) {
                    if (($c.email + "").ToLower() -eq $email) {
                        $existing = $c
                        break
                    }
                }

                if ($null -ne $existing) {
                    $respObj = @{ success = $false; message = "An account with this email address already exists. Please sign in." }
                    $jsonBytes = [System.Text.Encoding]::UTF8.GetBytes(($respObj | ConvertTo-Json))
                    $header = "HTTP/1.1 409 Conflict`r`nContent-Type: application/json; charset=utf-8`r`nContent-Length: $($jsonBytes.Length)`r`nAccess-Control-Allow-Origin: *`r`nConnection: close`r`n`r`n"
                    $headerBytes = [System.Text.Encoding]::UTF8.GetBytes($header)
                    $stream.Write($headerBytes, 0, $headerBytes.Length)
                    $stream.Write($jsonBytes, 0, $jsonBytes.Length)
                    $stream.Flush()
                    $client.Close()
                    continue
                }

                $newId = "CIT-" + (Get-Random -Minimum 100 -Maximum 999)
                $newCit = @{
                    id = $newId
                    name = $name
                    email = $email
                    phone = if ($phone) { $phone } else { "+91 98" + (Get-Random -Minimum 10000000 -Maximum 99999999) }
                    role = "citizen"
                    passwordHash = $pHash
                }
                $userList = [System.Collections.ArrayList]@($users.citizens)
                $userList.Add($newCit) | Out-Null
                $users.citizens = $userList
                Save-Users $users

                $token = "STK-" + [Guid]::NewGuid().ToString("N").Substring(0, 16)
                $respObj = @{
                    success = $true
                    role = "citizen"
                    user = @{
                        id = $newCit.id
                        name = $newCit.name
                        email = $newCit.email
                        phone = $newCit.phone
                        role = "citizen"
                    }
                    token = $token
                }
                $jsonBytes = [System.Text.Encoding]::UTF8.GetBytes(($respObj | ConvertTo-Json -Depth 4))
                $header = "HTTP/1.1 200 OK`r`nContent-Type: application/json; charset=utf-8`r`nContent-Length: $($jsonBytes.Length)`r`nAccess-Control-Allow-Origin: *`r`nConnection: close`r`n`r`n"
                $headerBytes = [System.Text.Encoding]::UTF8.GetBytes($header)
                $stream.Write($headerBytes, 0, $headerBytes.Length)
                $stream.Write($jsonBytes, 0, $jsonBytes.Length)
                $stream.Flush()
                $client.Close()
                continue
            }
        }

        # =================================================================
        # STATIC ASSETS FILE SERVING
        # =================================================================
        $path = $rawPath.Split('?')[0].TrimStart('/')
        if ([string]::IsNullOrEmpty($path)) {
            $path = "index.html"
        }

        $filePath = Join-Path $root $path

        if (Test-Path $filePath -PathType Leaf) {
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            $mime = if ($mimeTypes.ContainsKey($ext)) { $mimeTypes[$ext] } else { "application/octet-stream" }

            $header = "HTTP/1.1 200 OK`r`n" +
                      "Content-Type: $mime`r`n" +
                      "Content-Length: $($bytes.Length)`r`n" +
                      "Access-Control-Allow-Origin: *`r`n" +
                      "Connection: close`r`n`r`n"
            $headerBytes = [System.Text.Encoding]::UTF8.GetBytes($header)

            $stream.Write($headerBytes, 0, $headerBytes.Length)
            $stream.Write($bytes, 0, $bytes.Length)
        } else {
            $msg = "404 Not Found"
            $msgBytes = [System.Text.Encoding]::UTF8.GetBytes($msg)
            $header = "HTTP/1.1 404 Not Found`r`n" +
                      "Content-Type: text/plain`r`n" +
                      "Content-Length: $($msgBytes.Length)`r`n" +
                      "Access-Control-Allow-Origin: *`r`n" +
                      "Connection: close`r`n`r`n"
            $headerBytes = [System.Text.Encoding]::UTF8.GetBytes($header)
            $stream.Write($headerBytes, 0, $headerBytes.Length)
            $stream.Write($msgBytes, 0, $msgBytes.Length)
        }

        $stream.Flush()
        $client.Close()
    } catch {
        # ignore client disconnects
    }
}
