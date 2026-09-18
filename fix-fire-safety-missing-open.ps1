<#
fix-fire-safety-missing-open.ps1
Inserts the missing <div class="article-card"> immediately before the
Fire Safety card's <div class="article-title">, identified uniquely by
its title text "Restaurant Fire Safety: Complete Training Guide".
Run this from inside the nigelthomas-portfolio repo folder.
#>

$path = "blog.html"

$titleLine = 'Restaurant Fire Safety: Complete Training Guide'
$titleDivLine = '<div class="article-title">'
$cardDivLine = '<div class="article-card">'

$lines = Get-Content -Path $path

$targetIndex = -1
for ($i = 1; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim() -eq $titleLine -and
        $lines[$i-1].Trim() -like '<a href="blog/restaurant-fire-safety-training-guide.html">') {
        # walk back to find the <div class="article-title"> that opens this block
        $j = $i - 2
        if ($j -ge 0 -and $lines[$j].Trim() -eq $titleDivLine) {
            # check the line before THAT is NOT already an article-card open
            if ($j - 1 -ge 0 -and $lines[$j-1].Trim() -ne $cardDivLine) {
                $targetIndex = $j
                break
            }
        }
    }
}

if ($targetIndex -eq -1) {
    Write-Host "Could not find the expected broken pattern (or it's already fixed). Stopping without changes." -ForegroundColor Red
    exit 1
}

Write-Host "Found missing wrapper before line $($targetIndex + 1):" -ForegroundColor Yellow
Write-Host "  $($lines[$targetIndex])"
Write-Host "Will insert '<div class=""article-card"">' immediately before this line." -ForegroundColor Yellow

$newLines = @()
if ($targetIndex -ge 1) {
    $newLines += $lines[0..($targetIndex - 1)]
}
$newLines += $cardDivLine
$newLines += $lines[$targetIndex..($lines.Count - 1)]

$outText = ($newLines -join "`r`n")
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText((Join-Path (Get-Location) $path), $outText, $utf8NoBom)

Write-Host ""
Write-Host "Done. Verifying structure now..." -ForegroundColor Green
Select-String -Path $path -Pattern "Gourmet Canapes" -Context 3,20
