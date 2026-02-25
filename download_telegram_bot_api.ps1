# Download pre-built telegram-bot-api for Windows
# Source: https://github.com/std-microblock/tg-botapi-build/releases

$BotDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$OutDir = Join-Path $BotDir "telegram-bot-api"
$ReleasesUrl = "https://api.github.com/repos/std-microblock/tg-botapi-build/releases/latest"

Write-Host "Fetching latest release..." -ForegroundColor Yellow
try {
    $release = Invoke-RestMethod -Uri $ReleasesUrl -Headers @{"Accept"="application/vnd.github.v3+json"}
} catch {
    Write-Host "ERROR: Could not fetch releases. Download manually from:" -ForegroundColor Red
    Write-Host "  https://github.com/std-microblock/tg-botapi-build/releases" -ForegroundColor Yellow
    Write-Host "  Look for Windows x64 asset, extract telegram-bot-api.exe to telegram-bot-api/" -ForegroundColor Yellow
    exit 1
}

$winAsset = $release.assets | Where-Object { $_.name -match "windows|x64|win|\.zip$" } | Select-Object -First 1
if (-not $winAsset) {
    $winAsset = $release.assets | Select-Object -First 1
}
if (-not $winAsset) {
    Write-Host "No assets found. Download manually from: $($release.html_url)" -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
$zipPath = Join-Path $OutDir $winAsset.name

Write-Host "Downloading $($winAsset.name)..." -ForegroundColor Green
Invoke-WebRequest -Uri $winAsset.browser_download_url -OutFile $zipPath -UseBasicParsing

Write-Host "Extracting..." -ForegroundColor Green
Expand-Archive -Path $zipPath -DestinationPath $OutDir -Force
Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

# Find exe
$exe = Get-ChildItem $OutDir -Filter "*.exe" -Recurse | Select-Object -First 1
if ($exe) {
    if ($exe.DirectoryName -ne $OutDir) {
        Move-Item $exe.FullName $OutDir -Force
    }
    Write-Host "Done! telegram-bot-api.exe is in: $OutDir" -ForegroundColor Green
} else {
    Write-Host "Extracted to $OutDir - check for telegram-bot-api.exe" -ForegroundColor Yellow
}
