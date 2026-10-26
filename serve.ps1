param([int]$Port = 8090)

# Local dev server for Roadmapper. Serves only the app/ folder (exactly what Azure deploys), with the
# security headers from app/staticwebapp.config.json, so local testing matches production. Localhost only.
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'app'))
$rootPrefix = $root.TrimEnd('\') + '\'
$config = Get-Content -LiteralPath (Join-Path $root 'staticwebapp.config.json') -Raw | ConvertFrom-Json
$headers = $config.globalHeaders.PSObject.Properties

# Only these file types are served; anything else is a 404.
$mime = @{
    '.html' = 'text/html; charset=utf-8'; '.js' = 'application/javascript; charset=utf-8'
    '.css' = 'text/css; charset=utf-8'; '.svg' = 'image/svg+xml'; '.woff2' = 'font/woff2'
    '.txt' = 'text/plain; charset=utf-8'
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host "Roadmapper serving $root on http://localhost:$Port/"

try {
    while ($listener.IsListening) {
        $ctx = $listener.GetContext()
        $req = $ctx.Request
        $res = $ctx.Response
        try {
            foreach ($h in $headers) { $res.Headers[$h.Name] = $h.Value }
            $res.Headers['Cache-Control'] = 'no-store'
            if ($req.HttpMethod -ne 'GET' -and $req.HttpMethod -ne 'HEAD') {
                $res.StatusCode = 405
                continue
            }
            $rel = [Uri]::UnescapeDataString($req.Url.AbsolutePath).TrimStart('/')
            if ($rel -eq '' -or $rel.EndsWith('/')) { $rel += 'index.html' }
            $path = $null
            # Reject drive letters, alternate data streams and wildcards before touching the file system.
            if ($rel -notmatch '[:*?"<>|]') { $path = [IO.Path]::GetFullPath((Join-Path $root $rel)) }
            $ext = if ($path) { [IO.Path]::GetExtension($path).ToLower() } else { '' }
            $ok = $path -and
                $path.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase) -and
                $mime.ContainsKey($ext) -and
                (Test-Path -LiteralPath $path -PathType Leaf)
            if ($ok) {
                $bytes = [IO.File]::ReadAllBytes($path)
                $res.ContentType = $mime[$ext]
                $res.ContentLength64 = $bytes.Length
                if ($req.HttpMethod -eq 'GET') { $res.OutputStream.Write($bytes, 0, $bytes.Length) }
                Write-Host "200 /$rel"
            } else {
                $res.StatusCode = 404
                Write-Host "404 /$rel"
            }
        } catch {
            $res.StatusCode = 500
            Write-Host "500 $($_.Exception.Message)"
        } finally {
            $res.Close()
        }
    }
} finally {
    $listener.Stop()
}
