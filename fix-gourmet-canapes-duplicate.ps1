<#
fix-gourmet-canapes-duplicate.ps1
Removes the duplicate/orphaned tail after the Gourmet Canapes card
in blog.html, matched by exact comment text (not line numbers).
Run this from inside the nigelthomas-portfolio repo folder.
#>

$path = "blog.html"
$marker = "<!-- END NEW CARD (gourmet canapes and italian starters) -->"

$lines = Get-Content -Path $path

$matchIndexes = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim() -eq $marker) {
        $matchIndexes += $i
    }
}

if ($matchIndexes.Count -ne 2) {
    Write-Host "Expected exactly 2 occurrences of the marker, found $($matchIndexes.Count). Stopping without changes." -ForegroundColor Red
    Write-Host "Marker line indexes found: $($matchIndexes -join ', ')"
    exit 1
}

$first  = $matchIndexes[0]
$second = $matchIndexes[1]

Write-Host "First marker at line $($first + 1), second (duplicate) marker at line $($second + 1)." -ForegroundColor Yellow
Write-Host "Lines to be removed (the orphaned tail):" -ForegroundColor Yellow
for ($i = $first + 1; $i -le $second; $i++) {
    Write-Host "  [$($i+1)] $($lines[$i])"
}

# Keep everything up to and including the first marker,
# then skip the duplicate tail (first+1 .. second inclusive),
# then keep everything after.
$newLines = @()
$newLines += $lines[0..$first]
if ($second + 1 -le $lines.Count - 1) {
    $newLines += $lines[($second + 1)..($lines.Count - 1)]
}

$outText = ($newLines -join "`r`n")

# Save as UTF-8 without BOM (site's established requirement)
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText((Join-Path (Get-Location) $path), $outText, $utf8NoBom)

Write-Host ""
Write-Host "Done. File rewritten without the duplicate tail, saved as UTF-8 (no BOM)." -ForegroundColor Green
Write-Host "Now verifying..." -ForegroundColor Yellow

$check = Select-String -Path $path -Pattern "gourmet-canapes-italian-starters"
Write-Host ($check | Out-String)
Write-Host "Match count: $($check.Count) (should be exactly 2)" -ForegroundColor Yellow
