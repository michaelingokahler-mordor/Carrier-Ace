param([int]$Port = 1942, [switch]$NoBrowser)
$ErrorActionPreference = 'Stop'
$webRoot = [System.IO.Path]::GetFullPath($PSScriptRoot)
if (-not (Test-Path -LiteralPath (Join-Path $webRoot 'index.html'))) {
    $webRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../builds/web'))
}
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
try { $listener.Start() } catch {
    Write-Host "Port $Port kann nicht geoeffnet werden. Bitte -Port 1943 versuchen."
    throw
}
Write-Host "Carrier Ace: http://localhost:$Port/  |  Beenden mit Strg+C"
if (-not $NoBrowser) { Start-Process "http://localhost:$Port/" }
$mime = @{'.html'='text/html; charset=utf-8';'.js'='text/javascript';'.wasm'='application/wasm';'.pck'='application/octet-stream';'.png'='image/png';'.svg'='image/svg+xml';'.ogg'='audio/ogg';'.ico'='image/x-icon'}
try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        try {
            $relative = [Uri]::UnescapeDataString($context.Request.Url.AbsolutePath).TrimStart('/')
            if ($relative -eq '') { $relative = 'index.html' }
            $target = [System.IO.Path]::GetFullPath((Join-Path $webRoot $relative))
            if (-not $target.StartsWith($webRoot + [System.IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or -not [System.IO.File]::Exists($target)) {
                $context.Response.StatusCode = 404
            } else {
                $extension = [System.IO.Path]::GetExtension($target)
                $context.Response.ContentType = if ($mime.ContainsKey($extension)) { $mime[$extension] } else { 'application/octet-stream' }
                $context.Response.Headers['Cache-Control'] = 'no-store'
                $stream = [System.IO.File]::OpenRead($target)
                try {
                    $context.Response.ContentLength64 = $stream.Length
                    if ($context.Request.HttpMethod -ne 'HEAD') { $stream.CopyTo($context.Response.OutputStream) }
                } finally { $stream.Dispose() }
            }
        } catch { $context.Response.StatusCode = 500 }
        finally { $context.Response.Close() }
    }
} finally { $listener.Stop(); $listener.Close() }
