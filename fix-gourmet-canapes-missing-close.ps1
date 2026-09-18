<#
fix-gourmet-canapes-missing-close.ps1
Inserts the missing </div> and END NEW CARD comment after the
Gourmet Canapes card's "Read More" link, before the next card begins.
Matched by exact anchor text, not line numbers.
Run this from inside the nigelthomas-portfolio repo folder.
#>

$path = "blog.html"

$anchorLine1 = '<a class="read-more-btn" href="blog/gourmet-canapes-italian-starters.html">'
$anchorLine2 = 'Read More' # matched loosely below, since the arrow char may vary
$anchorLine3 = '</a>'
$nextCardLine = '<div class="article-title">'

$lines = Get-Content -Path $path

# Find the index of the "</a>" that immediately follows the
# gourmet-canapes read-more-btn anchor, then check the very next
# line is the next card's title div with NO closing </div> before it.
$targetIndex = -1
for ($i = 0; $i -lt $lines.Count - 1; $i++) {
    if ($lines[$i].Trim() -eq $anchorLine3 -and
        $i -ge 2 -and
        $lines[$i-2].Trim() -eq $anchorLine1 -and
        $lines[$i+1].Trim() -eq $nextCardLine) {
        $targetIndex = $i
        break
    }
}

if ($targetIndex -eq -1) {
    Write-Host "Could not find the expected broken pattern. Stopping without changes." -ForegroundColor Red
    Write-Host "This likely means the file has already changed since this script was written." -ForegroundColor Red
    exit 1
}

Write-Host "Found the gap at line $($targetIndex + 1) (the closing </a>)." -ForegroundColor Yellow
Write-Host "Line $($targetIndex + 1): $($lines[$targetIndex])"
Write-Host "Line $($targetIndex + 2) (next, currently): $($lines[$targetIndex + 1])"
Write-Host ""
Write-Host "Will insert after line $($targetIndex + 1):" -ForegroundColor Yellow
Write-Host "  </div>"
Write-Host "  <!-- END NEW CARD (gourmet canapes and italian starters) -->"
Write-Host "  (blank line)"

$newLines = @()
$newLines += $lines[0..$targetIndex]
$newLines += "</div>"
$newLines += "<!-- END NEW CARD (gourmet canapes and italian starters) -->"
$newLines += ""
if ($targetIndex + 1 -le $lines.Count - 1) {
    $newLines += $lines[($targetIndex + 1)..($lines.Count - 1)]
}

$outText = ($newLines -join "`r`n")

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText((Join-Path (Get-Location) $path), $outText, $utf8NoBom)

Write-Host ""
Write-Host "Done. Verifying structure now..." -ForegroundColor Green
Select-String -Path $path -Pattern "Gourmet Canapes" -Context 3,15
