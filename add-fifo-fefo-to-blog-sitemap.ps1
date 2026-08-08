# add-fifo-fefo-to-blog-sitemap.ps1
# Adds FIFO/FEFO article + poster cards to blog.html (Food Safety & Culinary section)
# Adds poster entry to sitemap.xml and bumps article's lastmod date.
# Run from repo root. Avoids here-strings; writes no-BOM UTF-8.

$blogPath = Join-Path (Get-Location) "blog.html"
$sitemapPath = Join-Path (Get-Location) "sitemap.xml"

if (-not (Test-Path $blogPath)) { Write-Error "blog.html not found"; exit 1 }
if (-not (Test-Path $sitemapPath)) { Write-Error "sitemap.xml not found"; exit 1 }

$utf8NoBom = New-Object System.Text.UTF8Encoding $false

# ---------- 1. BLOG.HTML: insert two new cards before end of Food Safety section ----------
$blogContent = [System.IO.File]::ReadAllText($blogPath)

if ($blogContent -match [regex]::Escape('/fifo-vs-fefo-stock-rotation-guide.html') -and $blogContent -match [regex]::Escape('/fifo-vs-fefo-poster.html')) {
    Write-Host "blog.html already contains both FIFO/FEFO links - skipping blog.html edit." -ForegroundColor Yellow
} else {
    $anchorMarker = "north-indian-cuisine-guide.html"
    $anchorIndex = $blogContent.IndexOf($anchorMarker)

    if ($anchorIndex -lt 0) {
        Write-Warning "Could not find anchor 'north-indian-cuisine-guide.html' in blog.html - no changes made."
    } else {
        # Find the next </section> after the anchor - that's the end of Food Safety & Culinary
        $sectionCloseIndex = $blogContent.IndexOf("</section>", $anchorIndex)

        if ($sectionCloseIndex -lt 0) {
            Write-Warning "Could not find closing </section> after anchor - no changes made."
        } else {
            $cardLines = @(
                '',
                '<div class="article-card">',
                '<div class="article-title">',
                '<a href="/fifo-vs-fefo-stock-rotation-guide.html">',
                'FIFO vs FEFO: Stock Rotation Rules Every Store Manager Must Know',
                '</a>',
                '</div>',
                '<div class="article-meta">',
                '<span class="badge">New</span>',
                'Food Safety &middot; Inventory Management',
                '</div>',
                '<p class="article-excerpt">',
                'The practical difference between FIFO and FEFO, plus stacking rules for frozen, dry goods, meat, dairy, and raw vs cooked foods that store managers enforce every shift.',
                '</p>',
                '<a href="/fifo-vs-fefo-stock-rotation-guide.html" class="read-more-btn">',
                'Read Article &rarr;',
                '</a>',
                '</div>',
                '',
                '<div class="article-card">',
                '<div class="article-title">',
                '<a href="/fifo-vs-fefo-poster.html">',
                'FIFO vs FEFO: Quick Visual Reference',
                '</a>',
                '</div>',
                '<div class="article-meta">',
                '<span class="badge">New</span>',
                'Food Safety &middot; Infographic',
                '</div>',
                '<p class="article-excerpt">',
                'A one-page visual breakdown of FIFO and FEFO stock rotation - the core rules, comparison table, common mistakes and best practices at a glance.',
                '</p>',
                '<a href="/fifo-vs-fefo-poster.html" class="read-more-btn">',
                'View Poster &rarr;',
                '</a>',
                '</div>',
                ''
            )
            $cardsHtml = [string]::Join("`n", $cardLines)

            $newBlogContent = $blogContent.Insert($sectionCloseIndex, $cardsHtml)
            [System.IO.File]::WriteAllText($blogPath, $newBlogContent, $utf8NoBom)
            Write-Host "blog.html updated: FIFO/FEFO article + poster cards added to Food Safety & Culinary section." -ForegroundColor Green
        }
    }
}

# ---------- 2. SITEMAP.XML: add poster entry, bump article lastmod ----------
$sitemapContent = [System.IO.File]::ReadAllText($sitemapPath)
$today = Get-Date -Format "yyyy-MM-dd"

# Bump the article's lastmod date
$articleLocPattern = [regex]::Escape('<loc>https://www.nigelthomas.live/fifo-vs-fefo-stock-rotation-guide.html</loc>')
if ($sitemapContent -match $articleLocPattern) {
    $sitemapContent = [regex]::Replace(
        $sitemapContent,
        "($articleLocPattern\s*<lastmod>)[\d-]+(</lastmod>)",
        "`${1}$today`${2}"
    )
    Write-Host "sitemap.xml: article lastmod bumped to $today." -ForegroundColor Green
} else {
    Write-Warning "Article URL not found in sitemap.xml - lastmod not updated."
}

# Add poster entry if not already present
if ($sitemapContent -notmatch [regex]::Escape('/fifo-vs-fefo-poster.html')) {
    $urlCloseTag = "</urlset>"
    $urlCloseIndex = $sitemapContent.LastIndexOf($urlCloseTag)

    if ($urlCloseIndex -lt 0) {
        Write-Warning "Could not find </urlset> closing tag - poster entry not added."
    } else {
        $posterLines = @(
            '    <url>',
            "        <loc>https://www.nigelthomas.live/fifo-vs-fefo-poster.html</loc>",
            "        <lastmod>$today</lastmod>",
            '        <changefreq>monthly</changefreq>',
            '        <priority>0.7</priority>',
            '    </url>',
            ''
        )
        $posterEntry = [string]::Join("`n", $posterLines)
        $sitemapContent = $sitemapContent.Insert($urlCloseIndex, $posterEntry)
        Write-Host "sitemap.xml: poster entry added." -ForegroundColor Green
    }
} else {
    Write-Host "sitemap.xml already contains poster entry - skipped." -ForegroundColor Yellow
}

[System.IO.File]::WriteAllText($sitemapPath, $sitemapContent, $utf8NoBom)

Write-Host ""
Write-Host "Done. Review both files, then deploy:" -ForegroundColor Cyan
Write-Host "  git add blog.html sitemap.xml"
Write-Host "  git commit -m 'Add FIFO/FEFO poster and article to blog.html and sitemap.xml'"
Write-Host "  git push origin main"
Write-Host "  vercel --prod --force"
