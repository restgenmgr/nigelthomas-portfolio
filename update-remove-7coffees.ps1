# One-shot: pull -> remove broken links to deleted 7 Types of Coffee article -> diff -> commit -> push -> verify
# Run this by filename: .\update-remove-7coffees.ps1

$ErrorActionPreference = "Stop"
$repo = "C:\Users\admin\Desktop\nigelthomas-portfolio"
Set-Location $repo

Write-Host "== Step 1: Pull latest (rebase) ==" -ForegroundColor Cyan
git pull --rebase

Write-Host "`n== Step 2: Remove broken links ==" -ForegroundColor Cyan

$targets = @(
    @{ File = "coffee-types-poster.html";                       Match = 'More Beverage Management Guides' ; Skip = $true },
    @{ File = "coffee-types-poster.html";                       Match = '→ 7 Types of Coffee' },
    @{ File = "history-of-wine-world-wine-regions-guide.html";  Match = '→ 7 Types of Coffee' },
    @{ File = "medicinal-properties-of-teas.html";               Match = '7-types-of-coffee-and-how-theyre-made.html">7 Types of Coffee' },
    @{ File = "types-of-alcohol-complete-guide.html";            Match = '→ 7 Types of Coffee' },
    @{ File = "types-of-cheese-used-in-hotels.html";             Match = '7-types-of-coffee-and-how-theyre-made.html">7 Types of Coffee' },
    @{ File = "types-of-water-used-in-restaurant.html";          Match = '7 Types of Coffee' }
) | Where-Object { -not $_.Skip }

$changedFiles = @()

foreach ($t in $targets) {
    $path = Join-Path $repo $t.File
    if (-not (Test-Path $path)) {
        Write-Host "SKIP (file not found): $($t.File)" -ForegroundColor DarkYellow
        continue
    }
    $lines = [System.IO.File]::ReadAllLines($path)
    $before = $lines.Length
    $filtered = $lines | Where-Object { $_ -notmatch [regex]::Escape($t.Match) }
    $after = $filtered.Length

    if ($before -eq $after) {
        Write-Host "NOT FOUND in $($t.File) — no change" -ForegroundColor Red
    } else {
        $newContent = [string]::Join("`r`n", $filtered)
        [System.IO.File]::WriteAllText($path, $newContent, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host "Removed $($before - $after) line(s) from $($t.File)" -ForegroundColor Green
        $changedFiles += $t.File
    }
}

$changedFiles = $changedFiles | Select-Object -Unique

if ($changedFiles.Count -eq 0) {
    Write-Host "`nNo files changed — nothing to commit. Exiting." -ForegroundColor Yellow
    exit 0
}

Write-Host "`n== Step 3: Show diff for review ==" -ForegroundColor Cyan
git diff -- $changedFiles

Write-Host "`n== Step 4: Commit and push ==" -ForegroundColor Cyan
git add -- $changedFiles
git commit -m "Remove broken links to deleted 7 Types of Coffee article"
git push

Write-Host "`n== Step 5: Verify live pages (waiting for Vercel) ==" -ForegroundColor Cyan
Start-Sleep -Seconds 30

foreach ($f in $changedFiles) {
    $url = "https://www.nigelthomas.live/$f"
    try {
        $resp = Invoke-WebRequest -Uri $url -UseBasicParsing
        $stillHasLink = $resp.Content -match '7-types-of-coffee-and-how-theyre-made\.html'
        Write-Host "$f -> Status: $($resp.StatusCode)  Still contains broken link: $stillHasLink"
    } catch {
        Write-Host "$f -> REQUEST FAILED: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n== Done ==" -ForegroundColor Cyan
