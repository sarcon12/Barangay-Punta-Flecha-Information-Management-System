$port = 8000
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Prefixes.Add("http://10.0.1.219:$port/")
try {
    $listener.Start()
} catch {
    Write-Host "Error starting listener: $_"
    Write-Host "If permission denied, try running PowerShell as Administrator."
    exit
}

Write-Host "Barangay IMS API Server started!"
Write-Host "Local: http://localhost:$port/"
Write-Host "Network: http://10.0.1.219:$port/"
Write-Host "Press Ctrl+C to stop."

function Send-Response($response, $content, $contentType = "text/plain", $statusCode = 200) {
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($content)
    $response.StatusCode = $statusCode
    $response.ContentType = $contentType
    $response.AppendHeader("Access-Control-Allow-Origin", "*")
    $response.AppendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
    $response.AppendHeader("Access-Control-Allow-Headers", "Content-Type")
    $response.ContentLength64 = $buffer.Length
    $response.OutputStream.Write($buffer, 0, $buffer.Length)
    $response.Close()
}

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response
    $path = $request.Url.LocalPath
    $method = $request.HttpMethod

    if ($method -eq "OPTIONS") {
        Send-Response $response ""
        continue
    }

    if ($path.StartsWith("/api/")) {
        $dbName = $path.Substring(5)
        $dbFile = Join-Path (Get-Location).Path "data/$dbName.json"

        if ($method -eq "GET") {
            if (Test-Path $dbFile) {
                $content = Get-Content $dbFile -Raw
                Send-Response $response $content "application/json"
            } else {
                Send-Response $response "[]" "application/json"
            }
        }
        elseif ($method -eq "POST") {
            $reader = New-Object System.IO.StreamReader($request.InputStream)
            $body = $reader.ReadToEnd()
            Set-Content -Path $dbFile -Value $body
            Send-Response $response '{"status":"success"}' "application/json"
        }
        continue
    }

    if ($path -eq "/") { $path = "/index.html" }
    $localPath = $path.TrimStart("/")
    $filePath = Join-Path (Get-Location).Path $localPath

    if (Test-Path $filePath -PathType Leaf) {
        $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
        $contentType = switch ($ext) {
            ".html" { "text/html" }
            ".css"  { "text/css" }
            ".js"   { "application/javascript" }
            ".jpg"  { "image/jpeg" }
            ".png"  { "image/png" }
            default { "application/octet-stream" }
        }
        $bytes = [System.IO.File]::ReadAllBytes($filePath)
        $response.ContentType = $contentType
        $response.ContentLength64 = $bytes.Length
        $response.OutputStream.Write($bytes, 0, $bytes.Length)
        $response.Close()
    } else {
        Send-Response $response "404 - Not Found" "text/plain" 404
    }
}
