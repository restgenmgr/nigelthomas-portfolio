# ============================================
# Website Organization Script
# ============================================

Write-Host "🚀 Starting Website Organization..." -ForegroundColor Cyan

# --- Define Categories ---
$categories = @{
    "hospitality-management" = @{
        display = "🏨 Hospitality Management"
        files = @(
            "House_Manager_Estate_Manager_Hospitality_Manager_Guide.html",
            "foh-boh-hierarchy-blog.html",
            "homestay-vs-hotels.html",
            "qsr-vs-fine-dining.html",
            "equal-opportunity-employer-india-usa-europe.html"
        )
    }
    "food-safety" = @{
        display = "🧊 Food Safety & Kitchen Ops"
        files = @(
            "food-temperatures-article.html",
            "Food Safety Temperatures, Cold Chain Control & Kitchen Storage Standards.html",
            "fire-safety-training-blog.html",
            "restaurant-sop-haccp-fire-safety-compliance-india.html",
            "color-coding-kitchen-housekeeping.html",
            "food-allergies-restaurant-awareness.html"
        )
    }
    "culinary" = @{
        display = "🍳 Culinary & Cooking"
        files = @(
            "mother-sauces-complete-guide.html",
            "chefs-tools-knives-cutting-boards.html",
            "menu-planning-engineering.html"
        )
    }
    "regional-food" = @{
        display = "🌏 Regional & Street Food"
        files = @(
            "street-food-india.html",
            "south-indian-food-styles-udupi-chettinad-nati.html",
            "indian-spices-herbs-health-benefits.html",
            "chinese-culinary-styles-blog.html"
        )
    }
    "operations-business" = @{
        display = "📊 Operations & Business"
        files = @(
            "cloud-kitchen-catering-operations-guide.html"
        )
    }
}

# --- Create category folders ---
Write-Host "`n📁 Creating category folders..." -ForegroundColor Yellow
$categories.Keys | ForEach-Object {
    $folder = $_
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        Write-Host "  ✅ Created: $folder" -ForegroundColor Green
    } else {
        Write-Host "  ⏭️ Already exists: $folder" -ForegroundColor Gray
    }
}

# --- Move files into category folders ---
Write-Host "`n📂 Moving files to categories..." -ForegroundColor Yellow
$categories.GetEnumerator() | ForEach-Object {
    $folder = $_.Key
    $files = $_.Value.files
    $files | ForEach-Object {
        $file = $_
        if (Test-Path $file) {
            Move-Item -Path $file -Destination "$folder\" -Force -ErrorAction SilentlyContinue
            Write-Host "  ✅ Moved: $file → $folder/" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️ File not found: $file" -ForegroundColor Red
        }
    }
}

Write-Host "`n✅ Organization Complete!" -ForegroundColor Green
Write-Host "📁 Created folders: $($categories.Keys -join ', ')" -ForegroundColor Yellow
