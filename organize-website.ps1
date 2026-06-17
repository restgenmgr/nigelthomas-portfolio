# ============================================
# Website Organization Script
# For: nigelthomas.live
# Author: Nigel Anthony Thomas
# Date: June 17, 2026
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
    $folder = $_ -replace " ", "-"
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
    $folder = $_.Key -replace " ", "-"
    $files = $_.Value.files
    $display = $_.Value.display
    $files | ForEach-Object {
        $file = $_
        if (Test-Path $file) {
            $dest = "$folder/$file"
            # Handle special characters in filename
            $escapedFile = $file -replace '[#%&{}<>*?/|]', '_'
            $escapedDest = "$folder/$escapedFile"
            
            # If the file has special chars, rename it safely
            if ($file -ne $escapedFile) {
                Rename-Item -Path $file -NewName $escapedFile -ErrorAction SilentlyContinue
                Write-Host "  🔄 Renamed: $file → $escapedFile" -ForegroundColor Magenta
                $file = $escapedFile
                $dest = $escapedDest
            }
            
            Move-Item -Path $file -Destination $dest -ErrorAction SilentlyContinue
            Write-Host "  ✅ Moved: $file → $folder/" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️ File not found: $file" -ForegroundColor Red
        }
    }
}

# --- Handle special/standalone files ---
Write-Host "`n📂 Moving standalone files..." -ForegroundColor Yellow
$standalone = @(
    "Restaurant Cost Control Calculator.html",
    "about.html",
    "certifications.html",
    "contact.html",
    "blog.html",
    "index.html",
    "privacy-policy.html",
    "terms.html",
    "disclaimer.html",
    "article_backup.html",
    "profile.jpg",
    "assetsprofile.jpg",
    "street-food-stall.jpg",
    "robots.txt",
    "sitemap.xml"
)

$standalone | ForEach-Object {
    if (Test-Path $_) {
        Write-Host "  ✅ Kept in root: $_" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ Not found: $_" -ForegroundColor Red
    }
}

# --- Create updated sitemap.xml ---
Write-Host "`n🌐 Generating sitemap.xml..." -ForegroundColor Yellow

$today = Get-Date -Format "yyyy-MM-dd"
$sitemap = @'
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    
    <!-- Main Pages -->
    <url>
        <loc>https://www.nigelthomas.live/</loc>
        <lastmod>'$today'</lastmod>
        <changefreq>weekly</changefreq>
        <priority>1.0</priority>
    </url>
    <url>
        <loc>https://www.nigelthomas.live/index.html</loc>
        <lastmod>'$today'</lastmod>
        <changefreq>weekly</changefreq>
        <priority>1.0</priority>
    </url>
    <url>
        <loc>https://www.nigelthomas.live/about.html</loc>
        <lastmod>'$today'</lastmod>
        <changefreq>monthly</changefreq>
        <priority>0.8</priority>
    </url>
    <url>
        <loc>https://www.nigelthomas.live/blog.html</loc>
        <lastmod>'$today'</lastmod>
        <changefreq>weekly</changefreq>
        <priority>0.9</priority>
    </url>
    <url>
        <loc>https://www.nigelthomas.live/contact.html</loc>
        <lastmod>'$today'</lastmod>
        <changefreq>monthly</changefreq>
        <priority>0.7</priority>
    </url>
    <url>
        <loc>https://www.nigelthomas.live/certifications.html</loc>
        <lastmod>'$today'</lastmod>
        <changefreq>monthly</changefreq>
        <priority>0.6</priority>
    </url>

    <!-- Legal Pages -->
    <url>
        <loc>https://www.nigelthomas.live/privacy-policy.html</loc>
        <lastmod>'$today'</lastmod>
        <changefreq>yearly</changefreq>
        <priority>0.4</priority>
    </url>
    <url>
        <loc>https://www.nigelthomas.live/terms.html</loc>
        <lastmod>'$today'</lastmod>
        <changefreq>yearly</changefreq>
        <priority>0.4</priority>
    </url>
    <url>
        <loc>https://www.nigelthomas.live/disclaimer.html</loc>
        <lastmod>'$today'</lastmod>
        <changefreq>yearly</changefreq>
        <priority>0.3</priority>
    </url>

    <!-- Tools -->
    <url>
        <loc>https://www.nigelthomas.live/Restaurant%20Cost%20Control%20Calculator.html</loc>
        <lastmod>'$today'</lastmod>
        <changefreq>monthly</changefreq>
        <priority>0.8</priority>
    </url>

    <!-- Blog - Hospitality Management -->
'@

# Add blog posts to sitemap
$categories.GetEnumerator() | ForEach-Object {
    $folder = $_.Key
    $files = $_.Value.files
    $files | ForEach-Object {
        $file = $_ -replace '[#%&{}<>*?/|]', '_'
        $sitemap += @"
    <url>
        <loc>https://www.nigelthomas.live/$folder/$file</loc>
        <lastmod>$today</lastmod>
        <changefreq>monthly</changefreq>
        <priority>0.6</priority>
    </url>
"@
    }
}

$sitemap += @'
</urlset>
'@

$sitemap | Out-File -FilePath "sitemap.xml" -Encoding UTF8
Write-Host "  ✅ sitemap.xml updated!" -ForegroundColor Green

# --- Generate blog.html with categories ---
Write-Host "`n📝 Generating blog.html..." -ForegroundColor Yellow

$blogHtml = @'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Blog | Nigel Thomas - Hospitality Insights</title>
    <meta name="description" content="Hospitality blog covering F&B operations, food safety, culinary arts, regional cuisine, and restaurant management." />
    <link rel="canonical" href="https://www.nigelthomas.live/blog.html" />
    
    <!-- Google tag -->
    <script async src="https://www.googletagmanager.com/gtag/js?id=G-CLRRV5DMXZ"></script>
    <script>
        window.dataLayer = window.dataLayer || [];
        function gtag(){dataLayer.push(arguments);}
        gtag('js', new Date());
        gtag('config', 'G-CLRRV5DMXZ');
    </script>
    
    <style>
        :root {
            --ink: #1a1a1a;
            --soft: #4a4a4a;
            --muted: #888;
            --rule: #e2e2e2;
            --bg: #ffffff;
            --surface: #f7f5f2;
            --foh: #1b4f72;
            --boh: #7b3f00;
            --accent: #c0392b;
            --radius: 6px;
            --max: 1100px;
            --serif: 'Georgia', 'Times New Roman', serif;
            --sans: 'Segoe UI', system-ui, sans-serif;
        }
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: var(--sans);
            background: var(--bg);
            color: var(--ink);
            line-height: 1.75;
            font-size: 1.0625rem;
        }
        header {
            background: var(--ink);
            color: #fff;
            padding: 14px 24px;
            display: flex;
            align-items: center;
            gap: 12px;
            flex-wrap: wrap;
        }
        header .site-name {
            font-family: var(--serif);
            font-size: 1.1rem;
            letter-spacing: .03em;
            color: #fff;
            text-decoration: none;
        }
        header .badge {
            margin-left: auto;
            font-size: .72rem;
            text-transform: uppercase;
            letter-spacing: .12em;
            color: #aaa;
        }
        header .home-btn {
            background: var(--accent);
            color: #fff;
            padding: 6px 16px;
            border-radius: var(--radius);
            text-decoration: none;
            font-size: .8rem;
            font-weight: 600;
        }
        header .home-btn:hover { background: #a93226; }
        
        .breadcrumb {
            background: var(--surface);
            padding: 10px 24px;
            border-bottom: 1px solid var(--rule);
            font-size: .82rem;
        }
        .breadcrumb a { color: var(--foh); text-decoration: none; }
        .breadcrumb span { color: var(--muted); }
        
        .hero {
            background: linear-gradient(135deg, var(--foh) 0%, #0d2d47 55%, var(--boh) 100%);
            color: #fff;
            padding: 56px 24px 48px;
            text-align: center;
        }
        .hero h1 {
            font-family: var(--serif);
            font-size: clamp(2rem, 5vw, 3rem);
            margin-bottom: 12px;
        }
        .hero p {
            max-width: 600px;
            margin: 0 auto;
            color: rgba(255,255,255,.75);
        }
        
        main {
            max-width: var(--max);
            margin: 0 auto;
            padding: 40px 24px 60px;
        }
        
        .category-nav {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            margin-bottom: 40px;
            padding: 16px;
            background: var(--surface);
            border-radius: var(--radius);
            border: 1px solid var(--rule);
        }
        .category-nav a {
            padding: 6px 16px;
            border-radius: var(--radius);
            text-decoration: none;
            font-size: .85rem;
            font-weight: 600;
            background: #fff;
            border: 1px solid var(--rule);
            color: var(--soft);
            transition: all 0.2s;
        }
        .category-nav a:hover {
            background: var(--foh);
            color: #fff;
            border-color: var(--foh);
        }
        
        .section-divider {
            display: flex;
            align-items: center;
            gap: 14px;
            margin: 44px 0 24px;
        }
        .section-divider span {
            font-size: .72rem;
            text-transform: uppercase;
            letter-spacing: .16em;
            color: var(--muted);
            white-space: nowrap;
            font-weight: 700;
        }
        .section-divider::before,
        .section-divider::after {
            content: '';
            flex: 1;
            height: 1px;
            background: var(--rule);
        }
        
        .blog-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 20px;
            margin: 16px 0 32px;
        }
        .blog-card {
            background: var(--surface);
            border-radius: var(--radius);
            border: 1px solid var(--rule);
            padding: 20px 22px 24px;
            transition: box-shadow 0.2s;
        }
        .blog-card:hover {
            box-shadow: 0 4px 16px rgba(0,0,0,0.08);
        }
        .blog-card .badge {
            display: inline-block;
            padding: 2px 12px;
            border-radius: 20px;
            font-size: .65rem;
            text-transform: uppercase;
            letter-spacing: .08em;
            font-weight: 700;
            margin-bottom: 8px;
        }
        .badge-management { background: #1b4f72; color: #fff; }
        .badge-safety { background: #c0392b; color: #fff; }
        .badge-culinary { background: #7b3f00; color: #fff; }
        .badge-regional { background: #f39c12; color: #fff; }
        .badge-business { background: #27ae60; color: #fff; }
        .badge-tools { background: #8e44ad; color: #fff; }
        
        .blog-card h3 {
            font-family: var(--serif);
            font-size: 1.05rem;
            margin: 4px 0 6px;
        }
        .blog-card h3 a {
            color: var(--ink);
            text-decoration: none;
        }
        .blog-card h3 a:hover { color: var(--foh); }
        .blog-card .meta {
            font-size: .78rem;
            color: var(--muted);
            margin-bottom: 8px;
        }
        .blog-card p {
            font-size: .9rem;
            color: var(--soft);
            margin-bottom: 10px;
        }
        .blog-card .read-more {
            font-weight: 600;
            color: var(--foh);
            text-decoration: none;
            font-size: .85rem;
        }
        .blog-card .read-more:hover { text-decoration: underline; }
        
        footer {
            background: var(--ink);
            color: rgba(255,255,255,.55);
            text-align: center;
            padding: 32px 24px;
            font-size: .8rem;
        }
        footer a { color: rgba(255,255,255,.7); text-decoration: none; }
        footer a:hover { text-decoration: underline; }
        
        @media (max-width: 600px) {
            .blog-grid { grid-template-columns: 1fr; }
            .category-nav { flex-direction: column; }
        }
    </style>
</head>
<body>

<header>
    <a class="site-name" href="https://www.nigelthomas.live">Nigel Thomas</a>
    <span class="badge">Hospitality Insights</span>
    <a class="home-btn" href="https://www.nigelthomas.live">🏠 Home</a>
</header>

<div class="breadcrumb">
    <a href="https://www.nigelthomas.live">Home</a>
    <span>›</span>
    <span>Blog</span>
</div>

<div class="hero">
    <h1>Hospitality Blog</h1>
    <p>Insights on F&B operations, food safety, culinary arts, regional cuisine, and restaurant management</p>
</div>

<main>

    <!-- Category Navigation -->
    <div class="category-nav">
'@

# Add category navigation
$categories.GetEnumerator() | ForEach-Object {
    $key = $_.Key
    $display = $_.Value.display
    $blogHtml += @"
        <a href="#$key">$display</a>
"@
}
$blogHtml += @'
        <a href="#tools">🧮 Tools</a>
    </div>

'@

# Generate category sections
$categories.GetEnumerator() | ForEach-Object {
    $key = $_.Key
    $display = $_.Value.display
    $files = $_.Value.files
    
    $blogHtml += @"
    <div class="section-divider"><span id="$key">$display</span></div>
    <div class="blog-grid">
"@
    
    $files | ForEach-Object {
        $file = $_ -replace '[#%&{}<>*?/|]', '_'
        $title = $file -replace '\.html$', '' -replace '-', ' ' -replace '_', ' '
        $title = (Get-Culture).TextInfo.ToTitleCase($title)
        
        # Get badge class
        $badgeClass = "badge-" + $key
        $badgeDisplay = $display
        
        $blogHtml += @"
        <div class="blog-card">
            <span class="badge $badgeClass">$badgeDisplay</span>
            <h3><a href="/$key/$file">$title</a></h3>
            <p class="meta">June 2026</p>
            <p>Read the full article on $title.</p>
            <a href="/$key/$file" class="read-more">Read More →</a>
        </div>
"@
    }
    
    $blogHtml += @"
    </div>
"@
}

# Tools section
$blogHtml += @'
    <div class="section-divider"><span id="tools">🧮 Tools</span></div>
    <div class="blog-grid">
        <div class="blog-card">
            <span class="badge badge-tools">🧮 Tools</span>
            <h3><a href="/Restaurant%20Cost%20Control%20Calculator.html">Restaurant Cost Control Calculator</a></h3>
            <p class="meta">June 2026</p>
            <p>Free restaurant cost control calculator with live food cost, beverage cost, gross profit, labor cost, menu engineering, recipe costing and break-even analysis tools.</p>
            <a href="/Restaurant%20Cost%20Control%20Calculator.html" class="read-more">Launch Tool →</a>
        </div>
    </div>

</main>

<footer>
    <p>&copy; 2026 Nigel Anthony Thomas &nbsp;|&nbsp; <a href="https://www.nigelthomas.live">nigelthomas.live</a></p>
</footer>

</body>
</html>
'@

# Save blog.html
$blogHtml | Out-File -FilePath "blog.html" -Encoding UTF8
Write-Host "  ✅ blog.html generated with all categories!" -ForegroundColor Green

# --- Final Summary ---
Write-Host "`n" + "="*50 -ForegroundColor Cyan
Write-Host "✅ ORGANIZATION COMPLETE!" -ForegroundColor Green
Write-Host "="*50 -ForegroundColor Cyan
Write-Host ""
Write-Host "📁 Category Folders Created:" -ForegroundColor Yellow
$categories.Keys | ForEach-Object { Write-Host "  📂 $_" -ForegroundColor Green }
Write-Host ""
Write-Host "📄 Files Updated:" -ForegroundColor Yellow
Write-Host "  ✅ sitemap.xml" -ForegroundColor Green
Write-Host "  ✅ blog.html" -ForegroundColor Green
Write-Host ""
Write-Host "📌 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Review the new folder structure" -ForegroundColor Gray
Write-Host "  2. Check blog.html in your browser" -ForegroundColor Gray
Write-Host "  3. Commit changes to GitHub" -ForegroundColor Gray
Write-Host "  4. Submit sitemap to Google Search Console" -ForegroundColor Gray
Write-Host ""
Write-Host "🚀 Done!" -ForegroundColor Cyan
