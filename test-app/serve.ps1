#!/bin/sh
echo `# <#`
PORT="${1:-8081}"
cd "$(dirname "$0")/build/wasm"
echo "Serving Test application WASM build on http://localhost:$PORT"
python3 -m http.server "$PORT"
exit 0
#> > $null
param($Port=8081)
Set-Location "$PSScriptRoot\build\wasm"
Write-Host "Serving Test application WASM build on http://localhost:$Port"
python -m http.server $Port
