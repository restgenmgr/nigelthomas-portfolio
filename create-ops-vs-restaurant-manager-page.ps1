# create-ops-vs-restaurant-manager-page.ps1
# Creates operations-manager-vs-restaurant-manager.html in the repo root
# Run this from: C:\Users\admin\Desktop\nigelthomas-portfolio
# Usage: .\create-ops-vs-restaurant-manager-page.ps1

$ErrorActionPreference = "Stop"

$outputPath = Join-Path (Get-Location) "operations-manager-vs-restaurant-manager.html"

$html = @'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Operations Manager vs Restaurant Manager: What&#8217;s the Difference? | Nigel A. Thomas</title>
<meta name="description" content="A clear breakdown of the Operations Manager vs Restaurant Manager roles in hospitality &#8212; scope, daily focus, and how each ensures outlet success. By Nigel A. Thomas.">
<link rel="canonical" href="https://www.nigelthomas.live/operations-manager-vs-restaurant-manager.html">

<meta property="og:title" content="Operations Manager vs Restaurant Manager: What's the Difference?">
<meta property="og:description" content="A clear breakdown of the Operations Manager vs Restaurant Manager roles in hospitality.">
<meta property="og:image" content="https://www.nigelthomas.live/assets/operations-manager-vs-restaurant-manager.jfif">
<meta property="og:type" content="article">
<meta property="og:url" content="https://www.nigelthomas.live/operations-manager-vs-restaurant-manager.html">

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
  .intro, .breakdown, .takeaway {
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
    <h1>Operations Manager vs Restaurant Manager: What&#8217;s the Difference?</h1>
    <p class="byline">By <span>Nigel A. Thomas</span> &#8226; Hospitality Executive &amp; Corporate Trainer</p>

    <div class="poster-wrap">
      <img src="/assets/operations-manager-vs-restaurant-manager.jfif"
           alt="Infographic comparing the roles of an Operations Manager and a Restaurant Manager in hospitality, by Nigel A. Thomas"
           loading="lazy" width="800" height="999">
    </div>

    <section class="intro">
      <h2>Two Roles, One Goal</h2>
      <p>In hospitality, the titles &#8220;Operations Manager&#8221; and &#8220;Restaurant Manager&#8221; often get used loosely &#8212; but the scope, focus, and pressure of each role are genuinely different. Knowing the distinction matters whether you&#8217;re mapping your own career path or building an org chart that actually works on the floor.</p>
    </section>

    <section class="breakdown">
      <h2>Restaurant Manager: One Outlet, Full Ownership</h2>
      <ul>
        <li>Focuses on daily operations and the smooth running of a single restaurant or outlet</li>
        <li>Handles guest satisfaction, feedback, and complaints directly</li>
        <li>Leads, trains, and motivates the restaurant team on the ground</li>
        <li>Maintains SOPs, hygiene, and service standards</li>
        <li>Controls daily sales, food cost, inventory, and staff scheduling</li>
        <li>Builds relationships with guests and the local community</li>
      </ul>

      <h2>Operations Manager: Every Outlet, Bigger Picture</h2>
      <ul>
        <li>Oversees multiple restaurants or outlets at once</li>
        <li>Develops business strategies and growth plans</li>
        <li>Monitors outlet performance through KPIs and reports</li>
        <li>Coaches and mentors Restaurant Managers</li>
        <li>Ensures brand consistency across all locations</li>
        <li>Focuses on expansion, new openings, and cost control</li>
      </ul>
    </section>

    <div class="quote-block">
      A Restaurant Manager ensures <strong>one outlet</strong> runs successfully. An Operations Manager ensures <strong>every outlet</strong> runs successfully.
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

    <section class="takeaway">
      <h2>Which Role Are You Building Toward?</h2>
      <p>Both roles serve the same end goal &#8212; excellence in hospitality &#8212; but they demand different muscles. A Restaurant Manager builds mastery on the floor. An Operations Manager builds systems that make many floors run the same way, well. Neither is a &#8220;bigger&#8221; job than the other; they&#8217;re different games.</p>
    </section>

    <div class="tags">
      <span>#OperationsManager</span>
      <span>#RestaurantManager</span>
      <span>#Hospitality</span>
      <span>#RestaurantOperations</span>
      <span>#Leadership</span>
      <span>#CareerGrowth</span>
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

Write-Host "Created: $outputPath" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  git pull --rebase origin main"
Write-Host "  git add operations-manager-vs-restaurant-manager.html"
Write-Host "  git commit -m 'Add Operations Manager vs Restaurant Manager poster page'"
Write-Host "  git push origin main"
Write-Host "  vercel --prod --force"
