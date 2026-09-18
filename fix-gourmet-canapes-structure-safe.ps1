<#
fix-gourmet-canapes-structure-safe.ps1
Fixes BOTH structural gaps around the Gourmet Canapes card in one pass:
  1. Missing </div> + END NEW CARD comment closing the Canapes card
  2. Missing <div class="article-card"> opening the Fire Safety card
Reads and writes the file as EXPLICIT UTF-8 throughout (no system
codepage guessing), so no other character in the file is touched or
re-encoded. Run from inside the nigelthomas-portfolio repo folder.
#>

$path = [System.IO.Path]::GetFullPath("blog.html")

$utf8 = New-Object System.Text.UTF8Encoding $false
$raw = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

# Normalize to \n for processing, remember to restore \r\n on write
$hasCRLF = $raw.Contains("`r`n")
$lines = $raw -replace "`r`n", "`n" -split "`n"

# --- Fix 1: insert </div> + comment after the Canapes "Read More" </a>,
# only if the very next non-inserted line is the Fire Safety title div
# with no closing tag in between (i.e. the bug is still present).
$anchorHref = '<a class="read-more-btn" href="blog/gourmet-canapes-italian-starters.html">'
$closeTag   = '</a>'
$titleDiv   = '<div class="article-title">'
$cardDiv    = '<div class="article-card">'
$closeDiv   = '</div>'
$comment    = '<!-- END NEW CARD (gourmet canapes and italian starters) -->'

$fix1Index = -1
for ($i = 2; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim() -eq $closeTag -and
        $lines[$i-2].Trim() -eq $anchorHref -and
        $i + 1 -lt $lines.Count -and
        $lines[$i+1].Trim() -eq $titleDiv) {
        $fix1Index = $i
        break
    }
}

if ($fix1Index -eq -1) {
    Write-Host "Fix 1 pattern not found (already fixed, or file changed). Skipping fix 1." -ForegroundColor Yellow
} else {
    Write-Host "Fix 1: inserting closing div + comment after line $($fix1Index + 1)." -ForegroundColor Green
    $before = $lines[0..$fix1Index]
    $after  = $lines[($fix1Index + 1)..($lines.Count - 1)]
    $lines = $before + @($closeDiv, $comment, "") + $after
}

# --- Fix 2: insert <div class="article-card"> before the Fire Safety
# card's title div, identified uniquely by its title text, only if
# missing (i.e. the line before the title div is not already cardDiv).
$fireTitleText = 'Restaurant Fire Safety: Complete Training Guide'
$fireHref = '<a href="blog/restaurant-fire-safety-training-guide.html">'

$fix2Index = -1
for ($i = 1; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim() -eq $fireTitleText -and
        $lines[$i-1].Trim() -eq $fireHref) {
        $j = $i - 2
        if ($j -ge 0 -and $lines[$j].Trim() -eq $titleDiv) {
            if ($j - 1 -lt 0 -or $lines[$j-1].Trim() -ne $cardDiv) {
                $fix2Index = $j
                break
            }
        }
    }
}

if ($fix2Index -eq -1) {
    Write-Host "Fix 2 pattern not found (already fixed, or file changed). Skipping fix 2." -ForegroundColor Yellow
} else {
    Write-Host "Fix 2: inserting opening article-card div before line $($fix2Index + 1)." -ForegroundColor Green
    $before = if ($fix2Index -ge 1) { $lines[0..($fix2Index - 1)] } else { @() }
    $after  = $lines[$fix2Index..($lines.Count - 1)]
    $lines = $before + @($cardDiv) + $after
}

if ($fix1Index -eq -1 -and $fix2Index -eq -1) {
    Write-Host "Nothing to fix. File left untouched." -ForegroundColor Yellow
    exit 0
}

$newline = if ($hasCRLF) { "`r`n" } else { "`n" }
$outText = ($lines -join $newline)

[System.IO.File]::WriteAllText($path, $outText, $utf8)

Write-Host ""
Write-Host "Done. File saved as explicit UTF-8 (no BOM), no other bytes touched." -ForegroundColor Green
Write-Host "Verifying structure now..." -ForegroundColor Yellow
Select-String -Path $path -Pattern "Gourmet Canapes" -Context 3,20
