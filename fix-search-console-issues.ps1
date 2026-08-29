# =========================================================
# Graveyard Workforce / nigelthomas.live
# Search Console cleanup: redirects + orphaned page links
# Run this from INSIDE your nigelthomas-portfolio repo folder
# =========================================================

Write-Host "Starting Search Console fixes..." -ForegroundColor Cyan

# -----------------------------------------------------------
# STEP 1: Create/update vercel.json with 301 redirects
# -----------------------------------------------------------
$vercelJsonPath = ".\vercel.json"

$redirectsBlock = @'
{
  "redirects": [
    {
      "source": "/mastering-food-cost-guide.html",
      "destination": "/food-cost-control-complete-guide.html",
      "permanent": true
    },
    {
      "source": "/blog/food-cost-control-complete-guide.html",
      "destination": "/food-cost-control-complete-guide.html",
      "permanent": true
    },
    {
      "source": "/Food Safety Temperatures, Cold Chain Control & Kitchen Storage Standards.html",
      "destination": "/food-safety-temperatures-cold-chain-control-kitchen-storage-standards.html",
      "permanent": true
    },
    {
      "source": "/hotel-department-heads-complete-guide.html",
      "destination": "/key-hotel-management-roles.html",
      "permanent": true
    },
    {
      "source": "/blog",
      "destination": "/blog.html",
      "permanent": true
    }
  ]
}
'@

if (Test-Path $vercelJsonPath) {
    Write-Host "vercel.json already exists - backing it up to vercel.json.bak" -ForegroundColor Yellow
    Copy-Item $vercelJsonPath "$vercelJsonPath.bak" -Force
    Write-Host "NOTE: vercel.json already existed. Review vercel.json.bak and merge manually if it had other config (headers, rewrites, etc)." -ForegroundColor Yellow
}

Set-Content -Path $vercelJsonPath -Value $redirectsBlock -Encoding UTF8
Write-Host "vercel.json written with 5 redirects." -ForegroundColor Green

# -----------------------------------------------------------
# STEP 2: Insert 5 new article cards into blog.html
# for orphaned pages (discovered but not indexed, no internal link)
# NOTE: partners.html excluded here - added to footer nav instead
# -----------------------------------------------------------
$blogPath = ".\blog.html"

if (-not (Test-Path $blogPath)) {
    Write-Host "ERROR: blog.html not found in current folder. Run this script from inside the repo root." -ForegroundColor Red
    exit 1
}

$blogContent = Get-Content -Path $blogPath -Raw -Encoding UTF8

$newCards = @'
<!-- NEW: Orphaned page fix - AI Shaping Future Jobs -->
<div class="article-card">
  <div class="article-title">
    <a href="ai-shaping-future-jobs-2026.html">How AI Is Shaping the Future of Hospitality Jobs in 2026</a>
  </div>
  <div class="article-meta">
    <span class="badge">New</span>
    Career Development &middot; AI &amp; Leadership
  </div>
  <p class="article-excerpt">
    What AI actually changes for hospitality roles in 2026 - which tasks shift, which skills matter more, and how to stay ahead of the curve.
  </p>
  <a href="ai-shaping-future-jobs-2026.html" class="read-more-btn">Read Article &rarr;</a>
</div>
<!-- END NEW CARD: ai-shaping-future-jobs-2026 -->

<!-- NEW: Orphaned page fix - FOH vs BOH Hierarchy -->
<div class="article-card">
  <div class="article-title">
    <a href="foh-boh-hierarchy-blog.html">Front of House vs Back of House Hierarchy Explained</a>
  </div>
  <div class="article-meta">
    Restaurant Operations &middot; Hierarchy
  </div>
  <p class="article-excerpt">
    A clear breakdown of FOH and BOH roles, reporting lines, and how the two sides of the operation work together during service.
  </p>
  <a href="foh-boh-hierarchy-blog.html" class="read-more-btn">Read Article &rarr;</a>
</div>
<!-- END NEW CARD: foh-boh-hierarchy-blog -->

<!-- NEW: Orphaned page fix - Hotel vs Resort Expenditure -->
<div class="article-card">
  <div class="article-title">
    <a href="hotel-vs-resort-expenditure-guide.html">Hotel vs Resort Expenditure: What's Actually Different</a>
  </div>
  <div class="article-meta">
    Hotel Finance &middot; Budgeting
  </div>
  <p class="article-excerpt">
    Where hotel and resort cost structures diverge - staffing ratios, amenities overhead, seasonal spend, and what that means for budgeting.
  </p>
  <a href="hotel-vs-resort-expenditure-guide.html" class="read-more-btn">Read Article &rarr;</a>
</div>
<!-- END NEW CARD: hotel-vs-resort-expenditure-guide -->

<!-- NEW: Orphaned page fix - Kitchen Cleaning Schedule -->
<div class="article-card">
  <div class="article-title">
    <a href="kitchen-cleaning-schedule-template.html">Kitchen Cleaning Schedule Template</a>
  </div>
  <div class="article-meta">
    <span class="badge">New</span>
    Kitchen Operations &middot; Template
  </div>
  <p class="article-excerpt">
    A ready-to-use daily, weekly and monthly cleaning schedule template for professional kitchens, built around hygiene compliance and shift handover.
  </p>
  <a href="kitchen-cleaning-schedule-template.html" class="read-more-btn">Read Article &rarr;</a>
</div>
<!-- END NEW CARD: kitchen-cleaning-schedule-template -->

<!-- NEW: Orphaned page fix - Not All Cruise Lines Are Created Equal -->
<div class="article-card">
  <div class="article-title">
    <a href="not-all-cruise-lines-are-created-equal.html">Not All Cruise Lines Are Created Equal</a>
  </div>
  <div class="article-meta">
    Maritime &middot; Career Guide
  </div>
  <p class="article-excerpt">
    What actually differs between cruise line employers - contracts, working conditions, career progression, and how to choose the right one.
  </p>
  <a href="not-all-cruise-lines-are-created-equal.html" class="read-more-btn">Read Article &rarr;</a>
</div>
<!-- END NEW CARD: not-all-cruise-lines-are-created-equal -->

</div>   <!-- Closes blog-grid -->
'@

# Anchor: insert new cards right before the FIRST "Closes blog-grid" comment
# (end of the Featured Articles section, after the AI Decision Matrix card)
$anchor = 'Read Article &rarr;
</a>
</div>

</div>   <!-- Closes blog-grid -->'

if ($blogContent -notmatch [regex]::Escape($anchor)) {
    Write-Host "WARNING: Could not find the expected anchor text in blog.html." -ForegroundColor Red
    Write-Host "No changes made to blog.html - insert the cards manually. See new-article-cards.html for the snippet." -ForegroundColor Yellow
    Set-Content -Path ".\new-article-cards.html" -Value $newCards -Encoding UTF8
} else {
    $replacement = 'Read Article &rarr;
</a>
</div>

' + $newCards
    $blogContent = $blogContent -replace [regex]::Escape($anchor), $replacement
    Set-Content -Path $blogPath -Value $blogContent -Encoding UTF8
    Write-Host "blog.html updated with 5 new article cards." -ForegroundColor Green
}

# -----------------------------------------------------------
# STEP 3: Add partners.html link to footer nav (not a blog article)
# -----------------------------------------------------------
$blogContent = Get-Content -Path $blogPath -Raw -Encoding UTF8
$footerAnchor = '<a href="disclaimer.html" style="margin:0 12px;">Disclaimer</a>'

if ($blogContent -match [regex]::Escape($footerAnchor)) {
    $footerReplacement = $footerAnchor + "`n`n<a href=""partners.html"" style=""margin:0 12px;"">Partners</a>"
    $blogContent = $blogContent -replace [regex]::Escape($footerAnchor), $footerReplacement
    Set-Content -Path $blogPath -Value $blogContent -Encoding UTF8
    Write-Host "partners.html link added to blog.html footer." -ForegroundColor Green
} else {
    Write-Host "WARNING: Could not find footer anchor for partners.html link. Add manually." -ForegroundColor Yellow
}

# -----------------------------------------------------------
# STEP 4: Git add, commit, push
# -----------------------------------------------------------
Write-Host "`nStaging and committing changes..." -ForegroundColor Cyan
git add vercel.json blog.html
git commit -m "SEO: add 301 redirects for moved/renamed pages, link orphaned articles"
git push

Write-Host "`nDone. Next steps:" -ForegroundColor Cyan
Write-Host "1. Confirm deploy succeeded on Vercel dashboard" -ForegroundColor White
Write-Host "2. Test a redirect: visit https://www.nigelthomas.live/mastering-food-cost-guide.html and confirm it forwards" -ForegroundColor White
Write-Host "3. In Search Console, run URL Inspection + Request Indexing on the 6 previously orphaned pages" -ForegroundColor White
