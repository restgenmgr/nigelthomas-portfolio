# ================================================================
# SCRIPT: Move NT INFOMATICS section to the bottom of each page
# ================================================================

# ---- CONFIGURATION ----
# List of files to process (adjust as needed)
$targetFiles = @(
    "about.html",
    "blog.html",
    "cruise-ship-crew-rotations-guide.html",
    "culinary__menu-planning-engineering.html",
    "f&b-service-interview-q&a.html",
    "fifo-vs-fefo-stock-rotation-guide.html",
    "not-all-cruise-lines-are-created-equal.html",
    "profit-loss-10-day-cycle.html",
    "resort-co-working-future-office.html",
    "restaurant-financial-kpis.html",
    "restaurant-kpis-every-manager-should-track.html",
    "restaurant-supervisor-interview.html"
)

# Backup folder
$backupFolder = ".\backup_poster_move"
if (-not (Test-Path $backupFolder)) { New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null }

Write-Host "📁 Backups will be saved in: $backupFolder" -ForegroundColor Cyan
Write-Host "🎯 Processing $($targetFiles.Count) files..." -ForegroundColor Yellow
Write-Host ""

$processed = 0
$moved = 0
$skipped = 0

foreach ($fileName in $targetFiles) {
    $filePath = Join-Path -Path (Get-Location) -ChildPath $fileName

    if (-not (Test-Path $filePath)) {
        Write-Warning "⚠️  File not found: $fileName – skipping"
        $skipped++
        continue
    }

    Write-Host "Processing: $fileName" -ForegroundColor White
    $content = Get-Content -Path $filePath -Raw -Encoding UTF8

    # ---- 1. Find the NT INFOMATICS block ----
    # Use the opening div with class "nt-infomatics-section"
    $startMarker = '<div class="nt-infomatics-section"'
    $endMarker = '</div>'

    $startIndex = $content.IndexOf($startMarker)
    if ($startIndex -eq -1) {
        Write-Host "  ⚠️  No NT INFOMATICS section found – skipping" -ForegroundColor Yellow
        $skipped++
        continue
    }

    # Find the matching closing </div> for this specific block.
    # We'll search from the start, counting nested divs.
    $searchPos = $startIndex + $startMarker.Length
    $openDivs = 1
    $endIndex = -1
    while ($searchPos -lt $content.Length -and $openDivs -gt 0) {
        $nextOpen = $content.IndexOf('<div', $searchPos)
        $nextClose = $content.IndexOf('</div>', $searchPos)
        if ($nextClose -eq -1) { break }
        if ($nextOpen -ne -1 -and $nextOpen -lt $nextClose) {
            $openDivs++
            $searchPos = $nextOpen + 4
        } else {
            $openDivs--
            $endIndex = $nextClose + 6   # length of '</div>'
            $searchPos = $endIndex
        }
    }

    if ($endIndex -eq -1 -or $openDivs -ne 0) {
        Write-Warning "  ❌ Could not find matching closing div for the infomatics section – skipping"
        $skipped++
        continue
    }

    $blockLength = $endIndex - $startIndex
    $posterBlock = $content.Substring($startIndex, $blockLength)

    # ---- 2. Remove the block from its original position ----
    $contentWithoutBlock = $content.Remove($startIndex, $blockLength)

    # ---- 3. Insert the block just before </body> ----
    $bodyEnd = $contentWithoutBlock.LastIndexOf('</body>')
    if ($bodyEnd -eq -1) {
        # No </body> tag – append at the end
        $updatedContent = $contentWithoutBlock + "`n$posterBlock"
    } else {
        $updatedContent = $contentWithoutBlock.Insert($bodyEnd, "`n$posterBlock`n")
    }

    # ---- 4. Backup and save ----
    $backupPath = Join-Path -Path $backupFolder -ChildPath "$fileName.bak"
    Copy-Item -Path $filePath -Destination $backupPath -Force

    Set-Content -Path $filePath -Value $updatedContent -Encoding UTF8 -NoNewline

    Write-Host "  ✅ Moved NT INFOMATICS section to bottom." -ForegroundColor Green
    $moved++
    $processed++
}

Write-Host ""
Write-Host "========== SUMMARY ==========" -ForegroundColor Cyan
Write-Host "Files processed : $($targetFiles.Count)"
Write-Host "Moved successfully: $moved"
Write-Host "Skipped (not found or error): $skipped"
Write-Host "Backups saved in: $backupFolder" -ForegroundColor Yellow
Write-Host ""
Write-Host "✨ Done! Open any page and scroll to the bottom – the poster should be there." -ForegroundColor Green
Write-Host "To undo, copy the .bak files back to their original names." -ForegroundColor Yellow
