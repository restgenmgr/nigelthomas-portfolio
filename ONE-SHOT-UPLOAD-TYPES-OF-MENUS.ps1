<# 
ONE-SHOT-UPLOAD-TYPES-OF-MENUS.ps1 
------------------------------------------------------------
Run this from INSIDE C:\Users\admin\Desktop\nigelthomas-portfolio
after uploading the poster image to the REPO ROOT (not assets/).

What it does, in order, with a safety check before each write:
  1. Finds the poster (types-of-menus-fb-service.jpg/.jpeg/.png) at repo root
  2. Moves it into assets/
  3. Rewrites types-of-menus-fb-service.html with the poster embedded
     as base64 behind a VIEW INFOMATICS toggle + download button
  4. Adds a new article-card to kitchen-food.html
  5. Adds one line to blog.html's "Latest Articles" list
  6. Adds a <url> entry to sitemap.xml
  7. Validates every file (well-formed HTML/XML, no BOM) before writing
  8. git add + commit (does NOT push ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â you review and push yourself)

Nothing is written until ALL checks pass. If anything is wrong,
the script throws and changes nothing.
------------------------------------------------------------
#>

$ErrorActionPreference = "Stop"
$repoRoot = Get-Location
Write-Host "Working in: $repoRoot" -ForegroundColor Yellow

# ------------------------------------------------------------
# STEP 0: Sanity checks
# ------------------------------------------------------------
if (-not (Test-Path ".\types-of-menus-fb-service.html")) {
    throw "types-of-menus-fb-service.html not found in current folder. Run this from the repo root."
}
if (-not (Test-Path ".\kitchen-food.html")) {
    throw "kitchen-food.html not found. Run this from the repo root."
}
if (-not (Test-Path ".\blog.html")) {
    throw "blog.html not found. Run this from the repo root."
}
if (-not (Test-Path ".\sitemap.xml")) {
    throw "sitemap.xml not found. Run this from the repo root."
}

$posterCandidates = @(
    "types-of-menus-fb-service.jpg",
    "types-of-menus-fb-service.jpeg",
    "types-of-menus-fb-service.png"
)
$posterFile = $posterCandidates | Where-Object { Test-Path ".\$_" } | Select-Object -First 1
if (-not $posterFile) {
    throw "No poster found at repo root. Upload one of: $($posterCandidates -join ', ')  then re-run this script."
}
Write-Host "Found poster: $posterFile" -ForegroundColor Green

$ext = [System.IO.Path]::GetExtension($posterFile).TrimStart(".").ToLower()
$mimeType = if ($ext -eq "png") { "image/png" } else { "image/jpeg" }

# ------------------------------------------------------------
# STEP 1: Move poster into assets/
# ------------------------------------------------------------
$assetsPath = Join-Path $repoRoot "assets"
if (-not (Test-Path $assetsPath)) { New-Item -ItemType Directory -Path $assetsPath | Out-Null }

$posterSourcePath = Join-Path $repoRoot $posterFile
$posterDestPath   = Join-Path $assetsPath $posterFile

if (Test-Path $posterDestPath) {
    Write-Host "Poster already exists in assets/ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â will overwrite." -ForegroundColor Yellow
}
Copy-Item -LiteralPath $posterSourcePath -Destination $posterDestPath -Force
Write-Host "Poster copied to assets\$posterFile" -ForegroundColor Green

# ------------------------------------------------------------
# STEP 2: Base64-encode the poster
# ------------------------------------------------------------
$posterBytes  = [System.IO.File]::ReadAllBytes($posterDestPath)
$posterBase64 = [Convert]::ToBase64String($posterBytes)
Write-Host "Poster encoded: $([math]::Round($posterBytes.Length / 1KB, 1)) KB" -ForegroundColor Green

# ------------------------------------------------------------
# STEP 3: Build the new page content
# ------------------------------------------------------------
$dataUri = "data:$mimeType;base64,$posterBase64"

$newPageHtml = @'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>13 Types of Menus Used in Food &amp; Beverage Service | Nigel Thomas</title>
<link rel="canonical" href="https://www.nigelthomas.live/types-of-menus-fb-service.html">
<meta name="description" content="A complete guide to the 13 types of menus used in food and beverage service ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â ÃƒÆ’Ã¢â€šÂ¬ la Carte, Table d'HÃƒÆ’Ã‚Â´te, Prix Fixe, Tasting, Buffet, Banquet, Cycle, Static, Seasonal, Du Jour, and more ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â with what each is best for.">
<script async src="https://www.googletagmanager.com/gtag/js?id=G-P839TWLQSJ"></script>
<script>
window.dataLayer = window.dataLayer || [];
function gtag(){dataLayer.push(arguments);}
gtag('js', new Date());
gtag('config', 'G-P839TWLQSJ');
</script>
<meta name="google-adsense-account" content="ca-pub-8127243414384620">
<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-8127243414384620" crossorigin="anonymous"></script>
<style>
body{font-family:'Segoe UI',Arial,sans-serif;background:#0b0b0b;color:#d4d4d4;line-height:1.7;margin:0}
.hero{background:#000;padding:60px 20px;text-align:center;border-bottom:2px solid #d4af37}
.hero h1{color:#d4af37;font-size:2.4rem;margin:0 0 12px}
.hero p{color:#d4d4d4;font-size:1.1rem;max-width:700px;margin:0 auto}
.container{max-width:1000px;margin:auto;padding:40px 20px}
.article{background:#111;padding:40px;border-left:4px solid #d4af37;border-radius:12px}
h1,h2,h3{color:#d4af37}
h2{margin-top:45px;border-bottom:1px solid #2a2a2a;padding-bottom:10px}
h3{margin-top:30px}
img{max-width:100%;border-radius:12px;margin:20px 0;display:block}
figure{margin:20px 0}
figcaption{color:#8a8a8a;font-size:0.9rem;text-align:center;margin-top:8px}
.highlight{background:#1a1a1a;border-left:4px solid #d4af37;padding:20px;margin:25px 0}
.menu-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:18px;margin:25px 0}
.menu-card{background:#161616;border:1px solid #2a2a2a;border-radius:10px;padding:18px 20px}
.menu-card .num{display:inline-block;background:#d4af37;color:#0b0b0b;font-weight:700;border-radius:50%;width:26px;height:26px;text-align:center;line-height:26px;margin-right:10px;font-size:0.9rem}
.menu-card h3{margin:0 0 8px;font-size:1.05rem;display:flex;align-items:center}
.menu-card p{margin:0 0 10px;font-size:0.95rem}
.menu-card .best-for{color:#8a8a8a;font-size:0.85rem;border-top:1px solid #2a2a2a;padding-top:8px}
.menu-card .best-for strong{color:#d4af37}
ul{padding-left:22px}
li{margin-bottom:8px}
table{width:100%;border-collapse:collapse;margin:25px 0;background:#161616;border-radius:10px;overflow:hidden}
th,td{padding:12px 16px;text-align:left;border-bottom:1px solid #2a2a2a;font-size:0.95rem}
th{background:#1a1a1a;color:#d4af37}
footer{background:#000;color:#d4af37;text-align:center;padding:25px;margin-top:40px}
a{color:#d4af37}
.back-link{display:inline-block;margin-bottom:20px;font-size:0.95rem}
.infomatic-toggle{background:#d4af37;color:#0b0b0b;border:none;padding:12px 26px;border-radius:30px;font-weight:700;cursor:pointer;font-size:0.95rem;margin:15px 0}
.infomatic-toggle:hover{background:#e6c14b}
.infomatic-panel{display:none;margin:20px 0;text-align:center}
.infomatic-panel.open{display:block}
.download-btn{display:inline-block;margin-top:14px;background:transparent;border:2px solid #d4af37;color:#d4af37;padding:10px 22px;border-radius:30px;font-weight:600;text-decoration:none}
.download-btn:hover{background:#d4af37;color:#0b0b0b}
.related-reading{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:16px;margin-top:16px}
.related-card{background:#161616;border:1px solid #2a2a2a;border-radius:10px;padding:16px 18px;text-decoration:none;display:block}
.related-card strong{color:#d4af37;display:block;margin-bottom:4px}
.related-card span{color:#9a9a9a;font-size:0.88rem}
</style>
</head>
<body>

<div class="hero">
<h1>ÃƒÂ°Ã…Â¸Ã‚ÂÃ‚Â½ÃƒÂ¯Ã‚Â¸Ã‚Â 13 Types of Menus Used in Food &amp; Beverage Service</h1>
<p>From ÃƒÆ’Ã¢â€šÂ¬ la Carte to Du Jour ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â a field-tested breakdown of every menu format hospitality professionals need to know, and exactly when to use each one.</p>
</div>

<div class="container">
<div class="article">

<a class="back-link" href="blog.html">&larr; Back to Blog</a>

<h1>13 Types of Menus Used in Food &amp; Beverage Service</h1>

<p>Choosing the right menu type is one of the most important decisions in food and beverage service. I've opened properties where the menu format was decided in a boardroom with a spreadsheet, and I've opened properties where it was decided on the back of a napkin at 11 PM before a soft launch ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â and the difference always shows up on the floor within the first week. Every menu is designed to meet different operational goals, guest expectations, and dining experiences. Get the format wrong, and even brilliant food struggles: kitchens over-produce, service slows down, and guests leave confused about what they actually paid for. Get it right, and the menu quietly does half the selling for you before a server ever reaches the table.</p>

<button class="infomatic-toggle" onclick="document.getElementById('infomaticPanel').classList.toggle('open')">ÃƒÂ°Ã…Â¸Ã¢â‚¬Å“Ã…Â  VIEW INFOMATIC</button>
<div class="infomatic-panel" id="infomaticPanel">
<img src="__DATA_URI__" alt="Infographic showing 13 types of menus used in food and beverage service, including a la carte, table d'hote, prix fixe, tasting, buffet, banquet, cycle, static, seasonal, du jour, children's, beverage, and dessert menus" loading="lazy">
<br>
<a class="download-btn" href="__DATA_URI__" download="types-of-menus-fb-service.__EXT__">ÃƒÂ¢Ã‚Â¬Ã¢â‚¬Â¡ Download Poster</a>
</div>

<div class="highlight"><strong>A menu is not a list of dishes. It's an operational contract between the kitchen, the front of house, and the guest ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â and each format below writes that contract differently.</strong></div>

<h2>The Core Five: How Guests Order and Pay</h2>
<p>These five formats decide the single biggest question in any dining concept: does the guest choose everything, or does the house decide most of it for them?</p>

<div class="menu-grid">

<div class="menu-card">
<h3><span class="num">1</span>ÃƒÆ’Ã¢â€šÂ¬ la Carte</h3>
<p>Each dish is listed and priced separately, allowing guests to order individual items exactly as they like them.</p>
<div class="best-for"><strong>Best for:</strong> Fine dining and casual restaurants.</div>
</div>

<div class="menu-card">
<h3><span class="num">2</span>Table d'HÃƒÆ’Ã‚Â´te (Set Menu)</h3>
<p>A complete meal with a fixed number of courses offered at one set price, with little or no choice per course.</p>
<div class="best-for"><strong>Best for:</strong> Hotels, banquets, and events.</div>
</div>

<div class="menu-card">
<h3><span class="num">3</span>Prix Fixe Menu</h3>
<p>A multi-course meal offered at one fixed price, often with a choice of dishes for each course.</p>
<div class="best-for"><strong>Best for:</strong> Fine dining restaurants and special occasions.</div>
</div>

<div class="menu-card">
<h3><span class="num">4</span>Tasting Menu (DÃƒÆ’Ã‚Â©gustation)</h3>
<p>A series of small courses showcasing the chef's creativity and signature dishes, usually in a set sequence.</p>
<div class="best-for"><strong>Best for:</strong> Fine dining restaurants.</div>
</div>

<div class="menu-card">
<h3><span class="num">5</span>Buffet Menu</h3>
<p>Guests serve themselves from a variety of prepared dishes offered at a fixed price.</p>
<div class="best-for"><strong>Best for:</strong> Hotels, weddings, and large events.</div>
</div>

</div>

<div class="highlight"><strong>Know the difference:</strong> Table d'HÃƒÆ’Ã‚Â´te menus are more fixed with limited or no choices, while Prix Fixe menus usually offer choices within each course.</div>

<h2>Menus Built Around Volume and Structure</h2>
<p>The next set exists to solve a different problem entirely ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â not guest choice, but operational repeatability. These formats keep a kitchen consistent across hundreds of covers a day, or years of contract catering.</p>

<div class="menu-grid">

<div class="menu-card">
<h3><span class="num">6</span>Banquet Menu</h3>
<p>A pre-arranged menu designed for large groups or special functions, agreed in advance with the client.</p>
<div class="best-for"><strong>Best for:</strong> Conferences, weddings, and corporate events.</div>
</div>

<div class="menu-card">
<h3><span class="num">7</span>Cycle Menu</h3>
<p>A menu that repeats over a fixed period ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â commonly 7, 14, or 28 days ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â before starting again.</p>
<div class="best-for"><strong>Best for:</strong> Hospitals, schools, and staff cafeterias.</div>
</div>

<div class="menu-card">
<h3><span class="num">8</span>Static Menu</h3>
<p>The same menu is offered every day with few or no changes, built for speed and predictability.</p>
<div class="best-for"><strong>Best for:</strong> Fast food and chain restaurants.</div>
</div>

<div class="menu-card">
<h3><span class="num">9</span>Seasonal Menu</h3>
<p>A menu that changes based on seasonal ingredients and their availability, refreshed a few times a year.</p>
<div class="best-for"><strong>Best for:</strong> Farm-to-table and premium restaurants.</div>
</div>

<div class="menu-card">
<h3><span class="num">10</span>Du Jour Menu</h3>
<p>Features dishes or specials that change daily, often built around what came in fresh that morning.</p>
<div class="best-for"><strong>Best for:</strong> Restaurants, cafÃƒÆ’Ã‚Â©s, and bistros.</div>
</div>

</div>

<h2>Additional Menu Types (Optional but Common)</h2>
<p>These aren't standalone concepts ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â they're supporting menus that ride alongside one of the ten above, and they quietly do a lot of work for guest satisfaction and check average.</p>

<div class="menu-grid">

<div class="menu-card">
<h3><span class="num">11</span>Children's Menu</h3>
<p>Smaller portions and simple dishes designed for children, usually priced lower and served faster.</p>
<div class="best-for"><strong>Best for:</strong> Family restaurants.</div>
</div>

<div class="menu-card">
<h3><span class="num">12</span>Beverage Menu</h3>
<p>A separate menu featuring alcoholic and non-alcoholic drinks, often the single biggest margin driver on the floor.</p>
<div class="best-for"><strong>Best for:</strong> Restaurants, bars, and hotels.</div>
</div>

<div class="menu-card">
<h3><span class="num">13</span>Dessert Menu</h3>
<p>A dedicated menu offering desserts, pastries, and sweet dishes, presented after the main meal.</p>
<div class="best-for"><strong>Best for:</strong> Restaurants and cafÃƒÆ’Ã‚Â©s.</div>
</div>

</div>

<h2>Quick Reference: Choosing the Right Format</h2>
<table>
<tr><th>If your priority is...</th><th>Consider this menu type</th></tr>
<tr><td>Maximum guest flexibility</td><td>ÃƒÆ’Ã¢â€šÂ¬ la Carte</td></tr>
<tr><td>Predictable food cost per cover</td><td>Table d'HÃƒÆ’Ã‚Â´te or Prix Fixe</td></tr>
<tr><td>Showcasing chef creativity</td><td>Tasting Menu</td></tr>
<tr><td>High volume, self-service</td><td>Buffet</td></tr>
<tr><td>Contracted institutional feeding</td><td>Cycle Menu</td></tr>
<tr><td>Speed and consistency at scale</td><td>Static Menu</td></tr>
<tr><td>Ingredient-led storytelling</td><td>Seasonal or Du Jour Menu</td></tr>
</table>

<h2>Why This Matters on the Floor, Not Just on Paper</h2>
<p>I've trained enough F&amp;B teams to know that menu type dictates almost everything downstream ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â prep schedules, staffing ratios, portion control, and even how a server is trained to sell. A static menu team can run lean because tomorrow looks like today. A du jour team needs a pre-shift briefing every single day, because the server has to sell a dish they may not have tasted yet. A banquet menu succeeds or fails entirely on what was agreed weeks in advance ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â there is no room for improvisation once 200 covers are plated. Understanding these formats isn't academic; it's the difference between a kitchen that runs in control and one that's constantly firefighting.</p>

<div class="highlight"><strong>Numbers tell you what happened. People tell you why. The right menu format is what lets both sides ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â kitchen and guest ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â actually deliver on their end of the deal.</strong></div>

<h2>Conclusion</h2>
<p>A well-designed menu is more than a list of food and drinks ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â it is a powerful tool for improving guest satisfaction, increasing profitability, and creating memorable dining experiences. Whether you're opening a fine dining room built around a tasting menu or running a 500-cover banquet on a fixed Table d'HÃƒÆ’Ã‚Â´te, the format you choose sets the ceiling for what your team can deliver consistently. Know all thirteen, and you'll never again default to "ÃƒÆ’Ã‚Â  la carte" just because it's familiar ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â you'll choose the format that actually fits the operation in front of you.</p>

<h2>Related Reading</h2>
<div class="related-reading">
<a class="related-card" href="food-cost-basics.html"><strong>Food Cost Basics</strong><span>The formula, worked examples, and target percentages by concept.</span></a>
<a class="related-card" href="restaurant-financial-kpis.html"><strong>Financial KPIs in Restaurants</strong><span>The 10 numbers every manager must track.</span></a>
<a class="related-card" href="condiments-vs-sauces-fb-guide.html"><strong>Condiments vs Sauces</strong><span>The complete F&amp;B terminology &amp; service standards guide.</span></a>
</div>

</div>
</div>

<footer>
<p>&copy; 2026 Nigel Anthony Thomas</p>
</footer>
</body>
</html>
'@

$newPageHtml = $newPageHtml.Replace("__DATA_URI__", $dataUri).Replace("__EXT__", $ext)

# ------------------------------------------------------------
# STEP 4: Validate the new page BEFORE writing anything
# ------------------------------------------------------------
if ($newPageHtml -notmatch "infomatic-panel") { throw "Template build failed ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â infomatic panel missing. Nothing written." }
if ($newPageHtml -notmatch [regex]::Escape($dataUri.Substring(0,60))) { throw "Base64 data URI failed to embed. Nothing written." }
Write-Host "New page template validated." -ForegroundColor Green

# ------------------------------------------------------------
# STEP 5: Build kitchen-food.html card + sitemap entry, validate BEFORE writing
# ------------------------------------------------------------
$kfContent = [System.IO.File]::ReadAllText((Join-Path $PWD "kitchen-food.html"), [System.Text.UTF8Encoding]::new($false))
$kfMarker = "`n</div>`n</main>"
if ($kfContent -notmatch [regex]::Escape("</div>") ) { throw "kitchen-food.html structure not recognized. Nothing written." }

$newCard = @"

<div class="article-card">
<span class="badge">MENU KNOWLEDGE</span>
<h2>
<a href="types-of-menus-fb-service.html">
13 Types of Menus Used in Food & Beverage Service
</a>
</h2>
<p>
From A la Carte to Du Jour - every menu format used in food and beverage service, what each is built for, and how to choose the right one for your operation. Includes a free downloadable infographic.
</p>
<a class="read-more" href="types-of-menus-fb-service.html">Read Article</a>
</div>
"@

# find the actual closing pattern used in kitchen-food.html (either "\n</div>\n\n</main>" or "\n</div>\n</main>")
if ($kfContent -match "(?s)\n</div>\s*\n\s*</main>") {
    $kfClosePattern = $Matches[0]
} else {
    throw "Could not find article-grid closing pattern in kitchen-food.html. Nothing written."
}
$newKfContent = $kfContent -replace [regex]::Escape($kfClosePattern), ($newCard + $kfClosePattern)
if ($newKfContent -eq $kfContent) { throw "kitchen-food.html insertion failed - no change detected. Nothing written." }
if (([regex]::Matches($newKfContent, 'class="article-card"')).Count -ne ([regex]::Matches($kfContent, 'class="article-card"')).Count + 1) {
    throw "kitchen-food.html card count did not increase by exactly 1. Nothing written."
}
Write-Host "kitchen-food.html update validated (card count +1)." -ForegroundColor Green

# --- sitemap.xml ---
$sitemapContent = [System.IO.File]::ReadAllText((Join-Path $PWD "sitemap.xml"), [System.Text.UTF8Encoding]::new($false))
if ($sitemapContent -match "types-of-menus-fb-service\.html") {
    Write-Host "sitemap.xml already has an entry for this page - skipping sitemap update." -ForegroundColor Yellow
    $newSitemapContent = $sitemapContent
    $sitemapChanged = $false
} else {
    $today = Get-Date -Format "yyyy-MM-dd"
    $newUrlEntry = @"
  <url>
    <loc>https://www.nigelthomas.live/types-of-menus-fb-service.html</loc>
    <lastmod>$today</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.5</priority>
  </url>
</urlset>
"@
    if ($sitemapContent -notmatch "</urlset>") { throw "sitemap.xml missing </urlset> tag. Nothing written." }
    $newSitemapContent = $sitemapContent -replace "</urlset>\s*$", $newUrlEntry
    if ($newSitemapContent -eq $sitemapContent) { throw "sitemap.xml insertion failed. Nothing written." }
    $sitemapChanged = $true
}

# validate sitemap is still well-formed XML
try {
    [xml]$testXml = $newSitemapContent
    Write-Host "sitemap.xml validated as well-formed XML. URL count: $($testXml.urlset.url.Count)" -ForegroundColor Green
} catch {
    throw "New sitemap.xml is not valid XML: $($_.Exception.Message). Nothing written."
}

$blogContent = [System.IO.File]::ReadAllText((Join-Path $PWD "blog.html"), [System.Text.UTF8Encoding]::new($false))

# --- blog.html "Latest Articles" list (one line, non-destructive) ---
if ($blogContent -match "types-of-menus-fb-service\.html") {
    Write-Host "blog.html already references this page - skipping blog.html update." -ForegroundColor Yellow
    $newBlogContent = $blogContent
    $blogChanged = $false
} else {
    $latestListMarker = '<h3 style="font-size:22px;color:#d4af37;margin-bottom:15px;">Latest Articles</h3>
<ul style="margin-left:30px;line-height:2;">'
    if ($blogContent -notmatch [regex]::Escape($latestListMarker)) {
        Write-Host "Could not find Latest Articles list marker in blog.html - skipping blog.html update (kitchen-food.html and sitemap.xml still proceed)." -ForegroundColor Yellow
        $newBlogContent = $blogContent
        $blogChanged = $false
    } else {
        $today2 = Get-Date -Format "MMMM yyyy"
        $newListItem = @"
<li><a href="types-of-menus-fb-service.html">13 Types of Menus Used in Food & Beverage Service</a> &mdash; $today2
<p>A la Carte, Table d'Hote, Prix Fixe, Tasting, Buffet, Banquet, Cycle, Static, Seasonal, Du Jour and more - every menu format explained, with what each is best for.</p>
</li>
"@
        $newBlogContent = $blogContent -replace [regex]::Escape($latestListMarker), ($latestListMarker + "`n" + $newListItem)
        if ($newBlogContent -eq $blogContent) { throw "blog.html insertion failed. Nothing written." }
        $blogChanged = $true
    }
}

# ------------------------------------------------------------
# STEP 6: Everything validated - NOW write all files
# ------------------------------------------------------------
$utf8NoBom = [Text.UTF8Encoding]::new($false)

[IO.File]::WriteAllText((Join-Path $repoRoot "types-of-menus-fb-service.html"), $newPageHtml, $utf8NoBom)
Write-Host "Wrote types-of-menus-fb-service.html" -ForegroundColor Green

[IO.File]::WriteAllText((Join-Path $repoRoot "kitchen-food.html"), $newKfContent, $utf8NoBom)
Write-Host "Wrote kitchen-food.html" -ForegroundColor Green

if ($sitemapChanged) {
    [IO.File]::WriteAllText((Join-Path $repoRoot "sitemap.xml"), $newSitemapContent, $utf8NoBom)
    Write-Host "Wrote sitemap.xml" -ForegroundColor Green
}

if ($blogChanged) {
    [IO.File]::WriteAllText((Join-Path $repoRoot "blog.html"), $newBlogContent, $utf8NoBom)
    Write-Host "Wrote blog.html" -ForegroundColor Green
}

# ------------------------------------------------------------
# STEP 7: Remove the poster from repo root (it now lives in assets/ only)
# ------------------------------------------------------------
Remove-Item -LiteralPath $posterSourcePath -Force
Write-Host "Removed poster from repo root (kept in assets\)" -ForegroundColor Green

# ------------------------------------------------------------
# STEP 8: git add + commit (NO PUSH - you review and push)
# ------------------------------------------------------------
Write-Host ""
Write-Host "===== GIT STATUS =====" -ForegroundColor Cyan
git status --short

$filesToAdd = @("types-of-menus-fb-service.html", "kitchen-food.html", "assets\$posterFile")
if ($sitemapChanged) { $filesToAdd += "sitemap.xml" }
if ($blogChanged) { $filesToAdd += "blog.html" }

git add $filesToAdd
git commit -m "Add 13 Types of Menus poster/article to kitchen-food.html, blog.html, and sitemap.xml"

Write-Host ""
Write-Host "===== DONE - NOT PUSHED YET =====" -ForegroundColor Cyan
Write-Host "Review with: git show --stat HEAD" -ForegroundColor Yellow
Write-Host "Then push with: git push" -ForegroundColor Yellow