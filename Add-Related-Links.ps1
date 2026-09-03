# ================================================================
# SCRIPT: Append extra related links to existing "related-grid"
# ================================================================

# ---- CONFIGURATION ----
# Complete mapping for all your blog posts
$relatedLinksMapping = @{
    # Management & Leadership
    "restaurant-manager-roles-and-responsibilities.html" = @("area-manager-vs-cluster-manager.html", "restaurant-supervisor-interview.html", "general-manager-duties-and-responsibilities.html")
    "area-manager-vs-cluster-manager.html" = @("restaurant-manager-roles-and-responsibilities.html", "operations-manager-vs-restaurant-manager.html")
    "restaurant-supervisor-interview.html" = @("restaurant-manager-roles-and-responsibilities.html", "f&b-service-interview-q&a.html")
    "general-manager-duties-and-responsibilities.html" = @("hotel-gm-competency-framework.html", "many-hats-general-manager.html")
    "operations-manager-vs-restaurant-manager.html" = @("area-manager-vs-cluster-manager.html", "restaurant-manager-roles-and-responsibilities.html")
    
    # Food Safety & HACCP
    "haccp-hazard-analysis-critical-control-points.html" = @("food-safety-temperatures-cold-chain-control-kitchen-storage-standards.html", "haccp-kitchen-checklist.html", "kitchen-haccp-poster.html")
    "food-safety-temperatures-cold-chain-control-kitchen-storage-standards.html" = @("haccp-hazard-analysis-critical-control-points.html", "kitchen-temperature-log-sheet.html")
    "haccp-kitchen-checklist.html" = @("haccp-hazard-analysis-critical-control-points.html", "food-safety-temperatures-cold-chain-control-kitchen-storage-standards.html")
    
    # Kitchen Operations
    "kitchen-cleaning-schedule-template.html" = @("pest-control-in-kitchen.html", "colour-coding-knives-cutting-boards.html")
    "colour-coding-knives-cutting-boards.html" = @("knife-color-codes.html", "kitchen-cleaning-schedule-template.html")
    "pest-control-in-kitchen.html" = @("kitchen-cleaning-schedule-template.html", "safe-food-storage-guide.html")
    
    # Financial & Cost Control
    "food-cost-basics.html" = @("restaurant-financial-kpis.html", "profit-loss-10-day-cycle.html", "how-to-control-food-cost.html")
    "restaurant-financial-kpis.html" = @("food-cost-basics.html", "profit-loss-control-cycle.html", "hotel-p&l.html")
    "profit-loss-10-day-cycle.html" = @("food-cost-basics.html", "restaurant-financial-kpis.html", "hotel-p&l.html")
    "hotel-p&l.html" = @("restaurant-financial-kpis.html", "profit-loss-10-day-cycle.html")
    
    # F&B Service
    "f&b-service-interview-q&a.html" = @("restaurant-supervisor-interview.html", "food-and-beverage-question-and-answers.html")
    "fifo-vs-fefo-stock-rotation-guide.html" = @("inventory-management-guide.html", "food-cost-basics.html")
    "types-of-food-and-beverage-service.html" = @("right-vs-left-service-restaurants.html", "food-and-beverage-service-hierarchy.html")
    
    # Culinary & Recipes
    "types-of-cheese-used-in-hotels.html" = @("types-of-pasta-sauces.html", "6-pizza-recipes-hotel-restaurant-menu.html")
    "types-of-pasta-sauces.html" = @("types-of-cheese-used-in-hotels.html", "6-pizza-recipes-hotel-restaurant-menu.html")
    "6-pizza-recipes-hotel-restaurant-menu.html" = @("types-of-pasta-sauces.html", "types-of-cheese-used-in-hotels.html")
    
    # Beverages
    "history-of-wine-world-wine-regions-guide.html" = @("why-is-a-wine-bottle-750ml.html", "wine-pairing-guide.html")
    "why-is-a-wine-bottle-750ml.html" = @("history-of-wine-world-wine-regions-guide.html", "wine-pairing-guide.html")
    "7-types-of-coffee-and-how-theyre-made.html" = @("coffee-shop-vocabulary.html", "coffee-types-poster.html")
    
    # Career & Interviews
    "building-a-career-in-hospitality-guide.html" = @("hospitality-management-tools.html", "why-your-hospitality-cv-keeps-getting-rejected.html")
    "100-hospitality-interview-questions.html" = @("f&b-service-interview-q&a.html", "the-five-minute-restaurant-interview-test.html")
    
    # Hotel & Resort
    "cruise-ship-crew-rotations-guide.html" = @("not-all-cruise-lines-are-created-equal.html", "maritime-hospitality.html")
    "resort-co-working-future-office.html" = @("hospitality-trends.html", "hotel-vs-resort-expenditure-guide.html")
    
    # About page
    "about.html" = @("blog.html", "contact.html")
}

# List of files to process
$targetFiles = @(
    "about.html",
    "area-manager-vs-cluster-manager.html",
    "blog.html",
    "cruise-ship-crew-rotations-guide.html",
    "culinary__menu-planning-engineering.html",
    "f&b-service-interview-q&a.html",
    "fifo-vs-fefo-stock-rotation-guide.html",
    "food-cost-basics.html",
    "not-all-cruise-lines-are-created-equal.html",
    "profit-loss-10-day-cycle.html",
    "restaurant-financial-kpis.html",
    "restaurant-kpis-every-manager-should-track.html",
    "restaurant-manager-roles-and-responsibilities.html",
    "restaurant-supervisor-interview.html"
)

# Backup folder
$backupFolder = ".\backup_related_links"
if (-not (Test-Path $backupFolder)) { New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null }

Write-Host "📁 Backups saved in: $backupFolder" -ForegroundColor Cyan
Write-Host "🎯 Processing $($targetFiles.Count) files..." -ForegroundColor Yellow
Write-Host ""

$processed = 0
$added = 0
$skipped = 0

foreach ($fileName in $targetFiles) {
    $filePath = Join-Path -Path (Get-Location) -ChildPath $fileName
    
    if (-not (Test-Path $filePath)) {
        Write-Warning "⚠️  File not found: $fileName – skipping"
        $skipped++
        continue
    }

    $links = $relatedLinksMapping[$fileName]
    if (-not $links -or $links.Count -eq 0) {
        Write-Host "⏭️  No related links defined for $fileName – skipping" -ForegroundColor Yellow
        $skipped++
        continue
    }

    Write-Host "Processing: $fileName" -ForegroundColor White
    $content = Get-Content -Path $filePath -Raw -Encoding UTF8

    # Find the related-grid
    $gridStart = '<div class="related-grid">'
    $gridEnd = '</div>'
    $startIndex = $content.IndexOf($gridStart)
    if ($startIndex -eq -1) {
        Write-Host "  ⚠️  No related-grid found – skipping" -ForegroundColor Yellow
        $skipped++
        continue
    }

    $endIndex = $content.IndexOf($gridEnd, $startIndex + $gridStart.Length)
    if ($endIndex -eq -1) {
        Write-Host "  ❌ Could not find closing </div> for related-grid – skipping" -ForegroundColor Red
        $skipped++
        continue
    }

    # Build new links
    $newLinksHtml = ""
    foreach ($link in $links) {
        if ($link -match '^[^:]+\.html$') {
            $linkUrl = "https://www.nigelthomas.live/$link"
        } else {
            $linkUrl = $link
        }
        $linkName = [System.IO.Path]::GetFileNameWithoutExtension($link)
        $displayTitle = $linkName -replace '[-_]', ' ' -replace '\b\w', { $args[0].Value.ToUpper() }
        if ($displayTitle.Length -gt 50) { $displayTitle = $displayTitle.Substring(0, 47) + "..." }

        $newLinksHtml += @"
<a class="related-card" href="$linkUrl">
    <div class="rc-tag">Related</div>
    <div class="rc-title">$displayTitle</div>
</a>
"@
    }

    # Insert before closing </div>
    $insertPos = $endIndex
    $updatedContent = $content.Insert($insertPos, "`n$newLinksHtml")

    # Backup and save
    $backupPath = Join-Path -Path $backupFolder -ChildPath "$fileName.bak"
    Copy-Item -Path $filePath -Destination $backupPath -Force
    Set-Content -Path $filePath -Value $updatedContent -Encoding UTF8 -NoNewline

    Write-Host "  ✅ Added $($links.Count) related links to $fileName" -ForegroundColor Green
    $added++
    $processed++
}

Write-Host ""
Write-Host "========== SUMMARY ==========" -ForegroundColor Cyan
Write-Host "Files processed: $($targetFiles.Count)"
Write-Host "Files with links added: $added"
Write-Host "Skipped (no mapping or no grid): $skipped"
Write-Host "Backups saved in: $backupFolder" -ForegroundColor Yellow
