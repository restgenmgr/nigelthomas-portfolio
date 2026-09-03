# ================================================================
# FIX BUTTONS ON INDIVIDUAL BLOG POST PAGES
# ================================================================

# ---- CONFIGURATION ----
# What should the "Read More" button link to?
$correctDestination = "blog.html"   # 👈 CHANGE THIS if needed

# The exact list of your individual blog post files
$targetFiles = @(
    "area-manager-vs-cluster-manager.html",
    "restaurant-manager-roles-and-responsibilities.html",
    "haccp-hazard-analysis-critical-control-points.html",
    "direct-vs-ota-booking-guest-occasion.html",
    "blog/fine-dining-silverware.html",
    "food-cost-basics.html",
    "types-of-cheese-used-in-hotels.html",
    "types-of-pasta-sauces.html",
    "history-of-wine-world-wine-regions.html",
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

Write-Host "🎯 Targeting $($targetFiles.Count) individual blog files." -ForegroundColor Cyan
Write-Host "🔗 Setting 'Read More' link to: $correctDestination" -ForegroundColor Yellow
Write-Host ""

$processed = 0
$fixedArrow = 0
$fixedLink = 0

foreach ($fileName in $targetFiles) {
    $filePath = Join-Path -Path (Get-Location) -ChildPath $fileName

    if (-not (Test-Path $filePath)) {
        Write-Warning "⚠️  File not found: $fileName – skipping"
        continue
    }

    Write-Host "Processing: $fileName" -ForegroundColor White
    $content = Get-Content -Path $filePath -Raw -Encoding UTF8
    $originalContent = $content

    $content = $content -replace '(Read\s*More)\s*\?', '$1 →'
    $content = $content -replace '(Read\s*More)\s*&nbsp;\?', '$1 →'

    $content = $content -replace '(href=")about\.html(".*?Read\s*More)', "`$1$correctDestination`$2"
    $content = $content -replace "(href=')about\.html('.*?Read\s*More)", "`$1$correctDestination`$2"
    $content = $content -replace 'href="about\.html"', "href=`"$correctDestination`""

    if ($content -ne $originalContent) {
        $backupFolder = ".\backup_buttons_fix"
        if (-not (Test-Path $backupFolder)) { New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null }
        Copy-Item -Path $filePath -Destination "$backupFolder\$fileName.bak" -Force
        Set-Content -Path $filePath -Value $content -Encoding UTF8 -NoNewline
        Write-Host "  ✅ Updated: arrow and link fixed." -ForegroundColor Green
        $processed++
    } else {
        Write-Host "  ⏭️  No changes needed (already fixed or pattern not found)." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "========== SUMMARY ==========" -ForegroundColor Cyan
Write-Host "Files processed : $($targetFiles.Count)"
Write-Host "Files updated   : $processed"
Write-Host "Backups saved in: .\backup_buttons_fix\" -ForegroundColor Yellow
Write-Host ""
