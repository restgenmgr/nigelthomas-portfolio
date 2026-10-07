```powershell
$repo = "C:\Users\admin\Desktop\nigelthomas-portfolio"
$backup = "$env:USERPROFILE\Desktop\_LINK-REPAIR-BACKUP-SAFE-BATCH1"

Set-Location $repo

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " SAFE INTERNAL LINK REPAIR - BATCH 1" -ForegroundColor Cyan
Write-Host " BACKUP + TARGETED REPAIR" -ForegroundColor Yellow
Write-Host " NO GIT COMMANDS" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# CREATE EXTERNAL BACKUP
# ------------------------------------------------------------

if (Test-Path $backup) {
    Write-Host "Backup folder already exists:" -ForegroundColor Yellow
    Write-Host $backup
    Write-Host ""
    Write-Host "STOP - Existing backup will not be overwritten." -ForegroundColor Red
    exit
}

New-Item -ItemType Directory -Path $backup -Force | Out-Null

# Files that will be modified in this batch.
$files = @(
    "certifications.html",
    "cloud-kitchen-catering-operations-guide.html",
    "equal-opportunity-employer-india-usa-europe.html",
    "foh-boh-hierarchy-blog.html",
    "hotel-gm-competency-framework.html",
    "restaurant-cost-control-calculator.html",
    "which-hotel-chain-is-biggest.html",
    "quality-controllers-food-industry.html",
    "restaurant-general-manager-complete-guide.html",
    "types-of-sandwiches.html",
    "types-of-alcohol-complete-guide.html",
    "history-of-wine-world-wine-regions.html",
    "live.html",
    "about-academy.html",
    "academy-news.html",
    "commercial-kitchen-operations-academy.html",
    "commercial-kitchen-operations-fundamentals.html",
    "commercial-kitchen-food-safety-fssai.html",
    "commercial-kitchen-haccp-fundamentals.html",
    "commercial-kitchen-kitchen-safety.html",
    "commercial-kitchen-cost-control.html",
    "commercial-kitchen-sops-checklists.html",
    "commercial-kitchen-staff-training-leadership.html",
    "commercial-kitchen-inventory-waste-management.html",
    "blog\cross-contamination-prevention.html",
    "blog\gourmet-canapes-italian-starters.html",
    "blog\kitchen-structure.html",
    "blog\types-of-alcohol-guide.html",
    "blog\wine-service-etiquette.html",
    "culinary\chefs-tools-knives-cutting-boards.html",
    "culinary\mother-sauces-complete-guide.html",
    "food-safety\color-coding-kitchen-housekeeping.html",
    "food-safety\food-allergies-restaurant-awareness.html",
    "food-safety\food-temperatures-article.html",
    "hospitality-management\foh-boh-hierarchy-blog.html",
    "hospitality-management\homestay-vs-hotels.html",
    "hospitality-management\House_Manager_Estate_Manager_Hospitality_Manager_Guide.html",
    "hospitality-management\qsr-vs-fine-dining.html",
    "regional-food\chinese-culinary-styles-blog.html",
    "regional-food\indian-spices-herbs-health-benefits.html",
    "regional-food\south-indian-food-styles-udupi-chettinad-nati.html"
)

# ------------------------------------------------------------
# VERIFY ALL TARGET FILES EXIST BEFORE CHANGING ANYTHING
# ------------------------------------------------------------

foreach ($file in $files) {
    $path = Join-Path $repo $file

    if (-not (Test-Path -LiteralPath $path)) {
        Write-Host "MISSING TARGET FILE: $file" -ForegroundColor Red
        Write-Host ""
        Write-Host "STOP - No files have been changed." -ForegroundColor Red
        exit
    }
}

# ------------------------------------------------------------
# BACKUP
# ------------------------------------------------------------

Write-Host "Creating external backup..." -ForegroundColor Cyan

foreach ($file in $files) {

    $source = Join-Path $repo $file
    $destination = Join-Path $backup $file
    $destinationFolder = Split-Path $destination -Parent

    New-Item -ItemType Directory -Path $destinationFolder -Force | Out-Null
    Copy-Item -LiteralPath $source -Destination $destination -Force
}

Write-Host "BACKUP COMPLETE:" -ForegroundColor Green
Write-Host $backup
Write-Host ""

# ------------------------------------------------------------
# BYTE-PRESERVING REPLACEMENT FUNCTION
# ------------------------------------------------------------

function Replace-Bytes {
    param(
        [string]$Path,
        [string]$Old,
        [string]$New
    )

    $bytes = [System.IO.File]::ReadAllBytes($Path)

    $oldBytes = [System.Text.Encoding]::ASCII.GetBytes($Old)
    $newBytes = [System.Text.Encoding]::ASCII.GetBytes($New)

    $positions = New-Object System.Collections.Generic.List[int]

    for ($i = 0; $i -le $bytes.Length - $oldBytes.Length; $i++) {

        $match = $true

        for ($j = 0; $j -lt $oldBytes.Length; $j++) {

            if ($bytes[$i + $j] -ne $oldBytes[$j]) {
                $match = $false
                break
            }
        }

        if ($match) {
            $positions.Add($i)
            $i += $oldBytes.Length - 1
        }
    }

    if ($positions.Count -eq 0) {
        return 0
    }

    $result = New-Object System.Collections.Generic.List[byte]
    $last = 0

    foreach ($pos in $positions) {

        for ($k = $last; $k -lt $pos; $k++) {
            $result.Add($bytes[$k])
        }

        foreach ($b in $newBytes) {
            $result.Add($b)
        }

        $last = $pos + $oldBytes.Length
    }

    for ($k = $last; $k -lt $bytes.Length; $k++) {
        $result.Add($bytes[$k])
    }

    [System.IO.File]::WriteAllBytes($Path, $result.ToArray())

    return $positions.Count
}

$totalChanges = 0

function Apply-Replace {
    param(
        [string]$File,
        [string]$Old,
        [string]$New
    )

    $script:totalChanges += Replace-Bytes `
        -Path (Join-Path $repo $File) `
        -Old $Old `
        -New $New
}

# ------------------------------------------------------------
# ROOT LEGACY NAVIGATION
# ------------------------------------------------------------

foreach ($file in $files) {

    Apply-Replace $file 'href=" About-complete.html"' 'href="about.html"'
    Apply-Replace $file 'href="About-complete.html"' 'href="about.html"'

    Apply-Replace $file 'href="privacy.html"' 'href="privacy-policy.html"'
}

# ------------------------------------------------------------
# CONFIRMED ROOT ARTICLE RENAMES
# ------------------------------------------------------------

Apply-Replace `
    "types-of-alcohol-complete-guide.html" `
    'href="food-and-beverage-service.html"' `
    'href="types-of-food-and-beverage-service.html"'

Apply-Replace `
    "types-of-alcohol-complete-guide.html" `
    'href="history-of-wine-world-wine-regions-guide.html"' `
    'href="history-of-wine-world-wine-regions.html"'

Apply-Replace `
    "restaurant-general-manager-complete-guide.html" `
    'href="knife-colour-codes.html"' `
    'href="knife-color-codes.html"'

Apply-Replace `
    "types-of-sandwiches.html" `
    'href="knife-colour-codes.html"' `
    'href="knife-color-codes.html"'

# ------------------------------------------------------------
# CONFIRMED RESTAURANT SOP RENAME
# ------------------------------------------------------------

Apply-Replace `
    "quality-controllers-food-industry.html" `
    'href="blog/restaurant-sops.html"' `
    'href="restaurant-sops-complete-operations-handbook.html"'

# ------------------------------------------------------------
# CONFIRMED WINE ARTICLE RENAME
# ------------------------------------------------------------

Apply-Replace `
    "beers.html" `
    'href="history-of-wine-world-wine-regions-guide.html"' `
    'href="history-of-wine-world-wine-regions.html"'

Apply-Replace `
    "history-of-wine-world-wine-regions.html" `
    'href="history-of-wine-world-wine-regions-guide.html"' `
    'href="history-of-wine-world-wine-regions.html"'

# ------------------------------------------------------------
# COMMERCIAL KITCHEN ACADEMY:
# CONFIRMED TOOLS LINK
# ------------------------------------------------------------

$academyFiles = @(
    "commercial-kitchen-operations-academy.html",
    "commercial-kitchen-operations-fundamentals.html",
    "commercial-kitchen-food-safety-fssai.html",
    "commercial-kitchen-haccp-fundamentals.html",
    "commercial-kitchen-kitchen-safety.html",
    "commercial-kitchen-cost-control.html",
    "commercial-kitchen-sops-checklists.html",
    "commercial-kitchen-staff-training-leadership.html",
    "commercial-kitchen-inventory-waste-management.html"
)

foreach ($file in $academyFiles) {

    Apply-Replace `
        $file `
        'href="tools.html"' `
        'href="hospitality-management-tools.html"'
}

# ------------------------------------------------------------
# NESTED SAFETY & COMPLIANCE LINKS
# Existing root page = safety-compliance.html
# Nested pages need ../
# ------------------------------------------------------------

$nestedSafetyFiles = @(
    "blog\cross-contamination-prevention.html",
    "blog\gourmet-canapes-italian-starters.html",
    "blog\kitchen-structure.html",
    "blog\types-of-alcohol-guide.html",
    "blog\wine-service-etiquette.html",
    "culinary\chefs-tools-knives-cutting-boards.html",
    "culinary\mother-sauces-complete-guide.html",
    "food-safety\color-coding-kitchen-housekeeping.html",
    "food-safety\food-allergies-restaurant-awareness.html",
    "food-safety\food-temperatures-article.html",
    "hospitality-management\foh-boh-hierarchy-blog.html",
    "hospitality-management\homestay-vs-hotels.html",
    "hospitality-management\House_Manager_Estate_Manager_Hospitality_Manager_Guide.html",
    "hospitality-management\qsr-vs-fine-dining.html",
    "regional-food\chinese-culinary-styles-blog.html",
    "regional-food\indian-spices-herbs-health-benefits.html",
    "regional-food\south-indian-food-styles-udupi-chettinad-nati.html"
)

foreach ($file in $nestedSafetyFiles) {

    Apply-Replace `
        $file `
        'href="safety-compliance.html"' `
        'href="../safety-compliance.html"'
}

# ------------------------------------------------------------
# REPORT
# ------------------------------------------------------------

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " SAFE BATCH 1 COMPLETE" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "TOTAL LINK REPLACEMENTS: $totalChanges" -ForegroundColor Green
Write-Host ""
Write-Host "BACKUP LOCATION:" -ForegroundColor Yellow
Write-Host $backup
Write-Host ""
Write-Host "NO GIT COMMANDS WERE RUN." -ForegroundColor Cyan
Write-Host "NO COMMIT WAS CREATED." -ForegroundColor Cyan
Write-Host "NO PUSH WAS PERFORMED." -ForegroundColor Cyan
Write-Host ""
```
