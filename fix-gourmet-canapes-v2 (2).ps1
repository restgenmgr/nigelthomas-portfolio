<#
fix-gourmet-canapes-v2.ps1
Simple direct substring replacement (not line-index math) to close the
Gourmet Canapes card and open the Fire Safety card's wrapper div.
Reads/writes as explicit UTF-8 (no BOM). Does a dry-run check first and
refuses to write anything if the target text isn't found exactly once.
#>

$path = [System.IO.Path]::GetFullPath("blog.html")
$utf8 = New-Object System.Text.UTF8Encoding $false

$raw = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
$hasCRLF = $raw.Contains("`r`n")

# Normalize to \n only for the search/replace, restore line endings after.
$normalized = $raw -replace "`r`n", "`n"

$find = "Read More " + [char]0x2192 + "`n</a>`n<div class=`"article-title`">`n<a href=`"blog/restaurant-fire-safety-training-guide.html`">"

$replace = "Read More " + [char]0x2192 + "`n</a>`n</div>`n<!-- END NEW CARD (gourmet canapes and italian starters) -->`n`n<div class=`"article-card`">`n<div class=`"article-title`">`n<a href=`"blog/restaurant-fire-safety-training-guide.html`">"

$occurrences = ([regex]::Matches($normalized, [regex]::Escape($find))).Count

Write-Host "Occurrences of target text found: $occurrences" -ForegroundColor Yellow

if ($occurrences -ne 1) {
    Write-Host "Expected exactly 1 occurrence. Stopping WITHOUT writing anything." -ForegroundColor Red
    Write-Host "Showing the arrow-character bytes actually present near 'Read More' for diagnosis:" -ForegroundColor Yellow
    $idx = $normalized.IndexOf("Read More")
    while ($idx -ge 0) {
        $snippet = $normalized.Substring($idx, [Math]::Min(30, $normalized.Length - $idx))
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($snippet) | ForEach-Object { $_.ToString("X2") }
        Write-Host "At $idx : $snippet"
        Write-Host "  bytes: $($bytes -join ' ')"
        $idx = $normalized.IndexOf("Read More", $idx + 1)
    }
    exit 1
}

$updated = $normalized.Replace($find, $replace)

$newline = if ($hasCRLF) { "`r`n" } else { "`n" }
$outText = $updated -replace "`n", $newline

[System.IO.File]::WriteAllText($path, $outText, $utf8)

Write-Host ""
Write-Host "Done. Replacement made, file saved as explicit UTF-8 (no BOM)." -ForegroundColor Green
Write-Host "Verifying..." -ForegroundColor Yellow
Select-String -Path $path -Pattern "Gourmet Canapes" -Context 3,20
