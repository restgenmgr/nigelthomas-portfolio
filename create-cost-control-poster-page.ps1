# create-cost-control-poster-page.ps1
# ONE-SHOT SCRIPT: creates cost-control-protect-profit.html and updates sitemap.xml.
# Assumes assets/cost-control-nigel-a-thomas.jpg is already in place (confirmed).
# Run this from: C:\Users\admin\Desktop\nigelthomas-portfolio
# Usage: .\create-cost-control-poster-page.ps1

$ErrorActionPreference = "Stop"

# -----------------------------------------------------------------------
# STEP 1: Create the poster blog page (matches your confirmed design
# system: #0b0b0b background, #d4af37 gold, Segoe UI/Arial, GA4, AdSense)
# -----------------------------------------------------------------------
$outputPath = Join-Path (Get-Location) "cost-control-protect-profit.html"

$html = @'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Cost Control: Protect Profit Without Compromising Quality | Nigel A. Thomas</title>
<meta name="description" content="F&amp;B Leadership Series: how to protect profit without compromising quality &#8212; prime cost, waste and portions, purchasing and inventory, labour productivity, and menu profitability. By Nigel A. Thomas.">
<link rel="canonical" href="https://www.nigelthomas.live/cost-control-protect-profit.html">

<meta property="og:title" content="Cost Control: Protect Profit Without Compromising Quality">
<meta property="og:description" content="F&B Leadership Series: strong cost control starts with visibility, discipline, and daily action.">
<meta property="og:image" content="https://www.nigelthomas.live/assets/cost-control-nigel-a-thomas.jpg">
<meta property="og:type" content="article">
<meta property="og:url" content="https://www.nigelthomas.live/cost-control-protect-profit.html">

<!-- Google tag (gtag.js) -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-CLRRV5DMXZ"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-CLRRV5DMXZ');
</script>

<!-- Google AdSense -->
<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-4282121192943910" crossorigin="anonymous"></script>

<style>
  :root {
    --bg: #0b0b0b;
    --gold: #d4af37;
    --gold-bright: #f4d160;
    --text: #f4f4f4;
    --muted: #b8b8b8;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    background: var(--bg);
    color: var(--text);
    font-family: "Segoe UI", Arial, sans-serif;
    line-height: 1.6;
  }
  header.site-header {
    padding: 20px 24px;
    border-bottom: 1px solid #222;
  }
  header.site-header a {
    color: var(--gold);
    text-decoration: none;
    font-weight: 600;
    font-size: 1.1rem;
    letter-spacing: 0.5px;
  }
  main {
    max-width: 900px;
    margin: 0 auto;
    padding: 40px 20px 60px;
  }
  h1 {
    color: var(--gold-bright);
    font-size: clamp(1.6rem, 4vw, 2.4rem);
    margin-bottom: 12px;
    line-height: 1.25;
  }
  .byline {
    color: var(--muted);
    font-size: 0.95rem;
    margin-bottom: 28px;
  }
  .byline span {
    color: var(--gold);
    font-weight: 600;
  }
  .poster-wrap {
    text-align: center;
    margin: 20px 0 36px;
  }
  .poster-wrap img {
    max-width: 100%;
    height: auto;
    border-radius: 8px;
    border: 1px solid #262626;
    box-shadow: 0 8px 30px rgba(0,0,0,0.5);
  }
  .intro, .breakdown, .takeaway, .related {
    margin-bottom: 28px;
  }
  h2 {
    color: var(--gold);
    font-size: 1.3rem;
    margin-bottom: 10px;
    border-left: 3px solid var(--gold);
    padding-left: 10px;
  }
  p { color: var(--text); margin-bottom: 14px; }
  ul { margin: 0 0 14px 22px; color: var(--text); }
  li { margin-bottom: 8px; }
  .quote-block {
    background: #141414;
    border-left: 3px solid var(--gold);
    padding: 18px 20px;
    border-radius: 4px;
    color: var(--gold-bright);
    font-style: italic;
    margin: 28px 0;
  }
  .related-links {
    list-style: none;
    margin: 0;
  }
  .related-links li { margin-bottom: 10px; }
  .related-links a {
    color: var(--gold-bright);
    text-decoration: none;
    border-bottom: 1px dotted var(--gold);
  }
  .related-links a:hover { color: var(--gold); }
  .tags {
    margin-top: 30px;
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
  }
  .tags span {
    background: #1a1a1a;
    border: 1px solid #333;
    color: var(--gold);
    font-size: 0.8rem;
    padding: 5px 12px;
    border-radius: 20px;
  }
  .ad-slot {
    margin: 36px 0;
    text-align: center;
  }
  footer.site-footer {
    text-align: center;
    padding: 30px 20px;
    color: var(--muted);
    font-size: 0.85rem;
    border-top: 1px solid #222;
  }
  footer.site-footer a { color: var(--gold); text-decoration: none; }
</style>
</head>
<body>

<header class="site-header">
  <a href="/index.html">Nigel A. Thomas &#8212; Hospitality Leadership &amp; Training</a>
</header>

<main>
  <article>
    <h1>Cost Control: Protect Profit Without Compromising Quality</h1>
    <p class="byline">By <span>Nigel A. Thomas</span> &#8226; Hospitality Executive &amp; Corporate Trainer</p>

    <div class="poster-wrap">
      <img src="/assets/cost-control-nigel-a-thomas.jpg"
           alt="F&amp;B Leadership Series poster on cost control: prime cost, waste and portions, purchasing and inventory, labour productivity, and menu profitability, by Nigel A. Thomas"
           loading="lazy" width="750" height="1106">
    </div>

    <section class="intro">
      <h2>Control the Numbers. Protect the Experience.</h2>
      <p>Strong cost control starts with visibility, discipline, and daily action. It is not about cutting corners &#8212; it is about knowing exactly where every rupee goes, so the guest experience never has to pay the price for poor planning. Here are the five areas I focus on with every team I train.</p>
    </section>

    <section class="breakdown">
      <h2>1. Prime Cost</h2>
      <ul>
        <li>Track food cost and labour together</li>
      </ul>

      <h2>2. Waste &amp; Portions</h2>
      <ul>
        <li>Standardise portions and reduce avoidable loss</li>
      </ul>

      <h2>3. Purchasing &amp; Inventory</h2>
      <ul>
        <li>Buy accurately and maintain stock discipline</li>
      </ul>

      <h2>4. Labour Productivity</h2>
      <ul>
        <li>Schedule according to business demand</li>
      </ul>

      <h2>5. Menu Profitability</h2>
      <ul>
        <li>Use sales mix and margin data to improve results</li>
      </ul>
    </section>

    <div class="quote-block">
      Control the numbers. Protect the experience. Profitability improves when leaders turn reports into action.
    </div>

    <div class="ad-slot">
      <ins class="adsbygoogle"
           style="display:block"
           data-ad-client="ca-pub-4282121192943910"
           data-ad-slot="0000000000"
           data-ad-format="auto"
           data-full-width-responsive="true"></ins>
      <script>(adsbygoogle = window.adsbygoogle || []).push({});</script>
    </div>

    <section class="related">
      <h2>More from the F&amp;B Leadership Series</h2>
      <ul class="related-links">
        <li><a href="/restaurant-kpis-every-manager-should-track.html">Restaurant KPIs Every Manager Should Track</a></li>
        <li><a href="/operations-manager-vs-restaurant-manager.html">Operations Manager vs Restaurant Manager: What&#8217;s the Difference?</a></li>
        <li><a href="/hospitality-management-tools.html">Hospitality Management Tools Hub</a></li>
        <li><a href="/blog.html">All Articles</a></li>
      </ul>
    </section>

    <section class="takeaway">
      <h2>Discipline, Not Just Data</h2>
      <p>Reports only matter if they change behaviour on the floor. Pick one of these five areas, review it daily for the next two weeks, and let your team see the numbers move before you add the next one. That is how cost control becomes a habit instead of a monthly scramble.</p>
    </section>

    <div class="tags">
      <span>#CostControl</span>
      <span>#PrimeCost</span>
      <span>#FBLeadership</span>
      <span>#Hospitality</span>
      <span>#RestaurantOperations</span>
      <span>#Leadership</span>
    </div>
  </article>
</main>

<footer class="site-footer">
  <p>&copy; 2026 Nigel A. Thomas &#8226; <a href="/blog.html">Back to Blog</a></p>
</footer>

</body>
</html>
'@

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($outputPath, $html, $utf8NoBom)
Write-Host "Page written: $outputPath" -ForegroundColor Green

# -----------------------------------------------------------------------
# STEP 2: Add entry to sitemap.xml (inserted safely before </urlset>)
# -----------------------------------------------------------------------
$sitemapPath = Join-Path (Get-Location) "sitemap.xml"
if (Test-Path $sitemapPath) {
    $sitemapContent = [System.IO.File]::ReadAllText($sitemapPath)
    if ($sitemapContent -notmatch "cost-control-protect-profit\.html") {
        $today = Get-Date -Format "yyyy-MM-dd"
        $newEntry = @"
  <url>
    <loc>https://www.nigelthomas.live/cost-control-protect-profit.html</loc>
    <lastmod>$today</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.8</priority>
  </url>
</urlset>
"@
        $sitemapContent = $sitemapContent -replace "</urlset>", $newEntry
        [System.IO.File]::WriteAllText($sitemapPath, $sitemapContent, $utf8NoBom)
        Write-Host "sitemap.xml updated." -ForegroundColor Green
    } else {
        Write-Host "sitemap.xml already contains this page - skipped." -ForegroundColor Yellow
    }
} else {
    Write-Host "sitemap.xml not found in this folder - skipped (add manually)." -ForegroundColor Yellow
}

# -----------------------------------------------------------------------
# STEP 3: blog.html card snippet (NOT auto-inserted)
# -----------------------------------------------------------------------
$snippetPath = Join-Path (Get-Location) "cost-control-blog-card-snippet.html"
$snippet = @'
<!-- Paste this card into the F&B Leadership / Restaurant category section of blog.html -->
<a href="/cost-control-protect-profit.html" class="article-card">
  <img src="/assets/cost-control-nigel-a-thomas.jpg" alt="Cost Control: Protect Profit Without Compromising Quality" loading="lazy">
  <h3>Cost Control: Protect Profit Without Compromising Quality</h3>
  <p>Prime cost, waste and portions, purchasing, labour productivity, and menu profitability &#8212; the five levers of restaurant cost control.</p>
</a>
'@
[System.IO.File]::WriteAllText($snippetPath, $snippet, $utf8NoBom)
Write-Host "blog.html card snippet written: $snippetPath" -ForegroundColor Green
Write-Host "NOTE: blog.html was NOT auto-edited. Open blog.html, find the right category block, and paste the snippet in." -ForegroundColor Cyan

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  git pull --rebase origin main"
Write-Host "  git add assets/cost-control-nigel-a-thomas.jpg cost-control-protect-profit.html sitemap.xml"
Write-Host "  git commit -m 'Add Cost Control poster page'"
Write-Host "  git push origin main"
Write-Host "  vercel --prod --force"
