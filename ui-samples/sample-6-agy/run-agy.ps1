$ErrorActionPreference = "Continue"
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$brief = Join-Path $PSScriptRoot "agy-brief.md"
$log = Join-Path $PSScriptRoot "agy-run.log"
$prompt = Get-Content -LiteralPath $brief -Raw -Encoding UTF8
Set-Location $root
"AGY RUN START $(Get-Date -Format o)" | Out-File -LiteralPath $log -Encoding utf8
& "C:\Users\mijiu\AppData\Local\agy\bin\agy.exe" -p $prompt --model gemini-3.1-pro-high --dangerously-skip-permissions *>> $log
"AGY RUN END exit=$LASTEXITCODE $(Get-Date -Format o)" | Out-File -LiteralPath $log -Append -Encoding utf8
