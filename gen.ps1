# generator
$css = @"
:root { --bg: #0f172a; }
"@
Set-Content -Path "smart_retail/frontend/static/style.css" -Value $css -Encoding UTF8
Write-Host "Done"
