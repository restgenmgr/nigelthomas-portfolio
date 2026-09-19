$ErrorActionPreference = "Stop"

$repo = "C:\Users\admin\Desktop\nigelthomas-portfolio"
$article = "ai-decision-matrix.html"
$imageName = "ai-decision-matrix.png"
$articleUrl = "https://www.nigelthomas.live/ai-decision-matrix.html"

Set-Location $repo
Write-Host "`n=== AI DECISION MATRIX: ONE-SHOT DEPLOY ===" -ForegroundColor Cyan

# 1. Make sure the working tree is clean before pulling.
$dirty = git status --porcelain
if ($dirty) {
    Write-Host "STOP: Working tree has uncommitted changes. Commit/stash them first." -ForegroundColor Red
    git status
    exit 1
}

# 2. Pull latest production branch before making the new changes.
git pull --rebase origin main
if ($LASTEXITCODE -ne 0) { throw "git pull --rebase failed." }

# 3. Locate the PNG. The script checks the repo and common Windows folders.
$imageCandidates = @(
    (Join-Path $repo $imageName),
    (Join-Path $HOME "Downloads\$imageName"),
    (Join-Path $HOME "Desktop\$imageName"),
    (Join-Path $HOME "Pictures\$imageName")
)
$imageSource = $imageCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $imageSource) {
    Write-Host "STOP: $imageName was not found in repo, Downloads, Desktop or Pictures." -ForegroundColor Red
    exit 1
}

if ((Resolve-Path $imageSource).Path -ne (Join-Path $repo $imageName)) {
    Copy-Item $imageSource (Join-Path $repo $imageName) -Force
}
Write-Host "PNG ready: $repo\$imageName" -ForegroundColor Green

# 4. Write the complete article HTML.
$articleHtml = @'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>AI Decision Matrix: How Leaders Can Make Better Data-Driven Decisions | Nigel A. Thomas</title>
<meta name="description" content="A practical AI leadership decision framework for making higher-quality, better data-driven decisions using Risk, Opportunity, Impact, Tradeoffs and Alignment.">
<meta name="author" content="Nigel A. Thomas">
<meta name="keywords" content="AI decision matrix, AI leadership, data-driven decisions, decision intelligence, hospitality AI, AI in hospitality, business decision making, leadership framework">
<meta name="robots" content="index, follow">
<link rel="canonical" href="https://www.nigelthomas.live/ai-decision-matrix.html">
<meta property="og:title" content="AI Decision Matrix: Better Data-Driven Decisions Today">
<meta property="og:description" content="How leaders can use AI, reliable data and a five-dimension decision matrix to improve decision quality, speed and accountability.">
<meta property="og:type" content="article">
<meta property="og:url" content="https://www.nigelthomas.live/ai-decision-matrix.html">
<meta property="og:image" content="https://www.nigelthomas.live/ai-decision-matrix.png">
<meta property="og:site_name" content="Nigel Thomas">
<script type="application/ld+json">
{
  "@context":"https://schema.org",
  "@type":"Article",
  "headline":"AI Decision Matrix: How Leaders Can Make Better Data-Driven Decisions",
  "description":"A practical AI leadership decision framework for making higher-quality, better data-driven decisions using Risk, Opportunity, Impact, Tradeoffs and Alignment.",
  "author":{"@type":"Person","name":"Nigel A. Thomas","url":"https://www.nigelthomas.live"},
  "publisher":{"@type":"Organization","name":"Nigel Thomas","url":"https://www.nigelthomas.live"},
  "datePublished":"2026-08-18",
  "dateModified":"2026-08-18",
  "mainEntityOfPage":"https://www.nigelthomas.live/ai-decision-matrix.html",
  "image":"https://www.nigelthomas.live/ai-decision-matrix.png"
}
</script>
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{--bg:#0b0b0b;--gold:#d4af37;--gold-soft:#e8cf7a;--panel:#141414;--line:#292929;--cream:#f4ede0;--muted:#aaa49a;--max:860px;--sans:'Segoe UI',Arial,sans-serif}
html{scroll-behavior:smooth}
body{background:var(--bg);color:var(--cream);font-family:var(--sans);line-height:1.75;font-size:1.02rem}
a{color:var(--gold)}
.site-header{background:#000;height:54px;display:flex;align-items:center;justify-content:space-between;padding:0 1.6rem;position:sticky;top:0;z-index:100;border-bottom:1px solid var(--line)}
.logo{color:#fff;font-weight:800;font-size:1.05rem;text-decoration:none;letter-spacing:.04em} .logo span{color:var(--gold)}
.site-header nav a{color:rgba(255,255,255,.68);font-size:.83rem;text-decoration:none;margin-left:1.4rem}
.hero{padding:3.4rem 1.5rem 2.6rem;text-align:center;border-bottom:1px solid var(--line)}
.eyebrow{display:inline-block;font-size:.7rem;font-weight:800;letter-spacing:.14em;text-transform:uppercase;color:var(--gold);background:rgba(212,175,55,.1);border:1px solid rgba(212,175,55,.35);padding:.3rem .9rem;border-radius:100px;margin-bottom:1.3rem}
.hero h1{font-size:clamp(2rem,5vw,3rem);font-weight:900;line-height:1.12;max-width:800px;margin:0 auto 1rem}
.hero h1 .accent{color:var(--gold)}
.hero .lead{max-width:680px;margin:0 auto 1.3rem;color:var(--muted)}
.hero-pills{display:flex;justify-content:center;flex-wrap:wrap;gap:.6rem}
.hero-pills span{background:var(--panel);border:1px solid var(--line);color:var(--muted);font-size:.76rem;padding:.25rem .75rem;border-radius:100px}
.article-wrap{max-width:var(--max);margin:0 auto;padding:2.8rem 1.5rem 4rem}
.article-body p{margin-bottom:1.35rem;color:#ded9cd}
.article-body h2{font-size:1.5rem;font-weight:900;color:var(--cream);margin:3rem 0 1rem;display:flex;align-items:center;gap:.6rem}
.article-body h2 .num{display:inline-flex;align-items:center;justify-content:center;width:34px;height:34px;min-width:34px;background:var(--gold);color:var(--bg);border-radius:6px;font-size:.95rem}
.article-body h3{font-size:1.08rem;font-weight:800;color:var(--gold-soft);margin:1.8rem 0 .7rem;border-left:3px solid var(--gold);padding-left:.75rem}
.article-body strong{color:var(--cream)}
.decision-image{margin:0 auto 2.6rem;text-align:center}
.decision-image img{width:100%;height:auto;border:1px solid var(--gold);border-radius:10px;display:block}
.caption{font-size:.78rem;color:var(--muted);margin-top:.6rem}
.pull-quote{border-left:4px solid var(--gold);background:var(--panel);padding:1.3rem 1.6rem;margin:2rem 0;border-radius:0 8px 8px 0}
.pull-quote p{font-style:italic;color:var(--gold-soft);margin:0}
.callout{background:var(--panel);border:1px solid rgba(212,175,55,.3);border-radius:10px;padding:1.5rem 1.7rem;margin:2rem 0}
.banner{background:linear-gradient(135deg,rgba(212,175,55,.15),rgba(212,175,55,.03));border:1px solid rgba(212,175,55,.35);border-radius:10px;padding:2rem;text-align:center;margin:2.5rem 0}
.banner h3{color:var(--gold-soft);font-size:1.25rem;margin-bottom:.5rem}
.author-box{border:1px solid var(--line);border-radius:10px;padding:1.6rem 1.8rem;margin-top:3rem;background:var(--panel)}
.author-box h4{color:var(--cream);margin-bottom:.25rem} .author-box .role{color:var(--gold);font-size:.8rem;font-weight:700}
.site-footer{background:#000;color:var(--muted);text-align:center;font-size:.82rem;padding:2rem 1rem;border-top:1px solid var(--line)}
.site-footer a{color:rgba(255,255,255,.75);text-decoration:none}
@media(max-width:640px){.site-header nav a{margin-left:.7rem}.article-body h2{font-size:1.25rem}}
</style>
</head>
<body>
<header class="site-header">
<a href="https://www.nigelthomas.live" class="logo">Nigel<span>Thomas</span></a>
<nav><a href="https://www.nigelthomas.live">Home</a><a href="https://www.nigelthomas.live/blog.html">Blog</a><a href="https://www.joblynk.live" target="_blank" rel="noopener">JobLynk</a></nav>
</header>
<section class="hero">
<span class="eyebrow">AI Leadership · Decision Intelligence</span>
<h1>AI Decision Matrix: <span class="accent">Make Better Data-Driven Decisions Today</span></h1>
<p class="lead">A practical leadership framework for using AI and reliable data to improve decision quality, reduce uncertainty and turn complex information into measurable action.</p>
<div class="hero-pills"><span>By Nigel A. Thomas</span><span>August 2026</span><span>~10 min read</span><span>AI · Leadership · Operations</span></div>
</section>
<main class="article-wrap">
<article class="article-body">
<div class="decision-image">
<img src="ai-decision-matrix.png" alt="Adaptive Leadership AI Decision Matrix for better data-driven decisions" loading="eager">
<div class="caption">The Adaptive Leadership AI Decision Matrix — Risk, Opportunity, Impact, Tradeoffs and Alignment.</div>
</div>
<div class="pull-quote"><p>“AI amplifies intelligence. Leadership gives it direction.”</p></div>
<p>The hardest business decisions are rarely difficult because leaders have no information. They are difficult because information arrives from different systems, at different speeds, with different levels of reliability — while the decision still has to be made.</p>
<p>Artificial Intelligence changes that equation. Used properly, AI can help leaders bring together operational data, financial information, customer behaviour, market signals, forecasts and performance indicators so that decisions are not based only on instinct, incomplete reports or yesterday's assumptions. AI does not remove the responsibility of leadership. It strengthens the quality, speed and depth of the thinking behind it.</p>
<p>For today's General Managers, Operations Leaders, F&B Directors, Revenue Leaders and business owners, the opportunity is not simply to <q>use AI.</q> The bigger opportunity is to build a better decision process around AI and data.</p>
<p>That is the purpose of the Adaptive Leadership AI Decision Matrix.</p>
<h2><span class="num">01</span>From More Data to Better Decisions</h2>
<p>Modern organisations do not suffer from a shortage of data. They often suffer from a shortage of usable insight.</p>
<p>A hotel can have occupancy figures, ADR, RevPAR, food cost, labour cost, guest satisfaction scores, online reviews, purchasing records, inventory movement, energy consumption and staffing information. A restaurant can have covers, average check, menu mix, table turns, food cost, beverage cost, wastage and labour productivity. Yet having all these numbers does not automatically create a good decision.</p>
<p>The first question should therefore be: What decision are we trying to improve?</p>
<p>AI can help transform raw information into patterns, comparisons, forecasts and questions that deserve management attention. It can identify unusual movements, compare actual performance with targets, summarise large datasets and help leaders test possible scenarios.</p>
<p>But AI should not be treated as an unquestioned answer machine. A confident-looking answer built on poor data is still a poor decision.</p>
<p>The goal is better questions, better evidence and better judgement.</p>
<h2><span class="num">02</span>The Five Decision Dimensions</h2>
<p>The matrix uses five dimensions to pressure-test important decisions: Risk, Opportunity, Impact, Tradeoffs and Alignment.</p>
<p>These dimensions work together. A decision that looks attractive from one perspective can become dangerous when the other four are considered.</p>
<h3>Risk — What could go wrong?</h3>
<p>AI can identify trends and anomalies that may be difficult to see manually. It can flag unusual cost movements, falling demand, changes in guest sentiment, productivity problems or deviations from established operating patterns.</p>
<p>Leaders should ask: What are we assuming? What information could be wrong? What happens if the forecast is incorrect? Who could be negatively affected? What operational, financial, technical or reputational risks are being introduced?</p>
<p>AI should make risk more visible, not make leaders less cautious.</p>
<h3>Opportunity — What could we unlock?</h3>
<p>Every decision also contains potential upside.</p>
<p>AI can help identify revenue opportunities, operational efficiencies, customer segments, purchasing improvements, staffing patterns and process bottlenecks. It can compare historical performance with current conditions and help leaders explore what might happen if a process, price, menu, staffing model or service approach changes.</p>
<p>The important question is not simply <q>Can AI do this?</q> It is <q>Where can AI and better data create measurable value?</q></p>
<h3>Impact — What will actually change?</h3>
<p>A decision can be technically impressive and still have little operational value.</p>
<p>Impact asks where the decision will change revenue, profitability, guest experience, employee productivity, compliance, workflow or customer behaviour. AI can help estimate relationships between variables, measure results after implementation and identify whether expected benefits are actually appearing.</p>
<p>Leaders should define the metrics before declaring success.</p>
<h3>Tradeoffs — What must we give up?</h3>
<p>Every meaningful decision has a cost.</p>
<p>A project may improve productivity but require training. Automation may reduce administrative work but change job responsibilities. A cheaper supplier may improve purchase price while creating quality or reliability risks. A new technology platform may improve reporting while creating implementation complexity.</p>
<p>AI can model scenarios and compare alternatives, but the final tradeoff remains a leadership decision.</p>
<h3>Alignment — Who needs to move together?</h3>
<p>Even a technically correct decision can fail if the organisation is not aligned.</p>
<p>Who owns the decision? Who executes it? Who is affected? Which departments depend on it? What KPIs must change? What communication is required?</p>
<p>AI can help map relationships, summarise stakeholder concerns and identify dependencies, but alignment ultimately requires people to understand the reason for the decision and commit to execution.</p>
<h2><span class="num">03</span>AI Should Improve the Question Before It Improves the Answer</h2>
<p>One of the most powerful uses of AI in management is not asking it for an immediate answer.</p>
<p>Instead, ask AI to challenge the question.</p>
<p>For example, <q>How can we reduce restaurant labour cost?</q> may produce a list of obvious suggestions. A better leadership prompt is: <q>Analyse labour cost, sales by hour, covers, average check, service periods, staffing levels, productivity and guest satisfaction. Identify where labour is structurally inefficient, where cutting hours could damage service, and what alternative scheduling scenarios should be tested.</q></p>
<p>The second question is better because it defines the evidence, the constraints and the possible downside.</p>
<p>The same principle applies to hotel occupancy, food cost, purchasing, marketing, maintenance, recruitment and capital investment.</p>
<p>Good AI decision-making starts with a well-framed management question.</p>
<h2><span class="num">04</span>Data Quality Comes Before AI Quality</h2>
<p>AI cannot compensate reliably for missing, inconsistent or misleading data.</p>
<p>If a restaurant records wastage differently across shifts, the resulting analysis may be misleading. If hotel revenue data is entered inconsistently, forecasts can become unreliable. If customer feedback is incomplete or biased, sentiment analysis may provide a distorted picture.</p>
<p>Before asking AI to optimise a process, leaders should examine the data itself.</p>
<p>Is the data complete? Is it current? Are definitions consistent? Are duplicate records present? Are manual entries being controlled? Are the KPIs calculated in the same way across departments?</p>
<p>Data governance may sound technical, but operational leaders are responsible for the business meaning of the numbers.</p>
<p>A useful principle is simple: garbage in does not become intelligence because AI is added.</p>
<h2><span class="num">05</span>From Dashboards to Decision Intelligence</h2>
<p>Traditional dashboards tell managers what happened.</p>
<p>A stronger AI-enabled decision process can help answer four additional questions:</p>
<p>What is happening now?</p>
<p>Why is it happening?</p>
<p>What is likely to happen next?</p>
<p>What should we consider doing about it?</p>
<p>This progression moves management from reporting toward decision intelligence.</p>
<p>For example, a food-cost dashboard may show that actual food cost has risen from target. AI-assisted analysis can examine purchasing prices, recipe yields, portion sizes, waste records, menu mix and sales volume to identify possible drivers. Management can then test corrective actions rather than simply recording the variance.</p>
<p>The same approach can be applied to occupancy, payroll, utilities, guest complaints, online reputation, inventory and maintenance.</p>
<h2><span class="num">06</span>AI and Hospitality Leadership</h2>
<p>Hospitality is particularly suited to data-driven decision-making because almost every operation generates measurable signals.</p>
<p>A General Manager can combine occupancy, ADR, RevPAR, guest satisfaction, labour productivity, departmental profitability and forecast demand to understand the health of the property.</p>
<p>An F&B leader can combine covers, menu engineering, contribution margin, food cost, beverage cost, labour hours and wastage to determine where attention is needed.</p>
<p>An operations manager can compare service standards, productivity, complaints, maintenance tickets and staffing patterns to locate recurring operational weaknesses.</p>
<p>AI can make this information easier to interpret, but it should remain a management support system rather than a replacement for human judgement.</p>
<p>Hospitality is a people business. A data point may indicate that a process is inefficient; it cannot automatically understand the human circumstances behind every result.</p>
<h2><span class="num">07</span>The Human Decision Still Matters</h2>
<p>There is a temptation to believe that a sufficiently advanced AI system will eventually make management decisions unnecessary.</p>
<p>That is the wrong objective.</p>
<p>Leadership involves accountability, ethics, context, experience, communication and responsibility. AI can calculate, compare, summarise, detect patterns and generate scenarios. Leaders decide what is acceptable, what is strategically important and what consequences the organisation is prepared to carry.</p>
<p>The best model is therefore human judgement amplified by AI — not human judgement replaced by AI.</p>
<p>AI should challenge assumptions, reveal blind spots and increase the quality of preparation before a decision is made.</p>
<h2><span class="num">08</span>A Practical AI Decision Workflow</h2>
<p>A useful management workflow can be built around seven steps.</p>
<p>First, define the decision clearly. What exactly must be decided?</p>
<p>Second, collect the relevant evidence. Bring together financial, operational, customer and market data where appropriate.</p>
<p>Third, validate the data. Check definitions, dates, missing information and anomalies.</p>
<p>Fourth, ask AI to analyse rather than merely recommend. Request patterns, causes, scenarios, risks and alternative interpretations.</p>
<p>Fifth, pressure-test the result through Risk, Opportunity, Impact, Tradeoffs and Alignment.</p>
<p>Sixth, make the decision and define ownership, deadlines and measurable KPIs.</p>
<p>Seventh, review the outcome. Compare actual results with the original expectation and feed the learning back into the next decision.</p>
<p>This creates a decision cycle rather than a one-time AI interaction.</p>
<h2><span class="num">09</span>Measuring Whether the Decision Was Good</h2>
<p>A decision should not be judged only by whether the result was favourable.</p>
<p>Sometimes a sound decision produces a poor outcome because external conditions changed. Conversely, a weak decision can produce a lucky result.</p>
<p>A better evaluation asks whether the organisation used appropriate evidence, identified the major risks, considered realistic alternatives, defined ownership and measured the outcome.</p>
<p>AI can help maintain a decision record: what data was available, what assumptions were made, what scenarios were considered, what action was selected and what actually happened.</p>
<p>Over time, this creates organisational learning.</p>
<p>The business becomes better not simply because AI becomes more powerful, but because management becomes more disciplined about learning from decisions.</p>
<h2><span class="num">10</span>Use the Matrix Before the Meeting, Not After It</h2>
<p>The greatest value of a decision framework is achieved before the leadership meeting.</p>
<p>Instead of arriving with a preferred answer and using the meeting to defend it, leaders can circulate the decision question together with the five dimensions. Each stakeholder can identify risks, opportunities, expected impacts, tradeoffs and alignment requirements before the discussion begins.</p>
<p>AI can assist by summarising the evidence, identifying conflicting assumptions and producing alternative scenarios. This gives the meeting a stronger starting point.</p>
<p>For example, if management is considering a new property-management system, the discussion should not begin with a demonstration of software features. It should begin with the operational problem. What is not working today? Which departments are affected? What measurable improvement is expected? What implementation risks exist? What will change for employees? What data must be migrated? What is the total cost of ownership? What happens if the project is delayed?</p>
<p>The technology is only one part of the decision.</p>
<p>The matrix keeps the leadership team focused on the business outcome rather than becoming distracted by the technology itself.</p>
<h2><span class="num">11</span>Warning Signs of Weak AI-Assisted Decisions</h2>
<p>There are several warning signs that a decision process needs improvement.</p>
<p>If nobody can clearly state the decision, the question is not ready.</p>
<p>If the analysis uses numbers without explaining their source, the evidence is not ready.</p>
<p>If AI produces a recommendation but nobody challenges its assumptions, the leadership process is incomplete.</p>
<p>If the expected benefit cannot be measured, the business case is weak.</p>
<p>If the person accountable for execution has not been identified, alignment is incomplete.</p>
<p>If the organisation cannot explain what would make it change course, the decision may be too rigid.</p>
<p>These checks are deliberately simple. They are designed to work in a hotel, restaurant, resort, corporate office or small business without requiring a complicated technology programme.</p>
<p>The objective is not to create another management ritual. It is to make the quality of important decisions more consistent.</p>
<h2><span class="num">12</span>Better Questions. Better Insights. Better Decisions.</h2>
<p>The Adaptive Leadership AI Decision Matrix is ultimately a framework for slowing down the thinking just enough to improve the action.</p>
<p>In a fast-moving environment, leaders will continue to face pressure to decide quickly. AI can help them move faster, but speed should not be confused with quality.</p>
<p>The strongest leaders will combine three capabilities: human judgement, reliable data and intelligent technology.</p>
<p>Use AI to see more clearly.</p>
<p>Use data to challenge assumptions.</p>
<p>Use the matrix to examine Risk, Opportunity, Impact, Tradeoffs and Alignment.</p>
<p>Then make the decision with accountability.</p>
<p>The future of leadership is not about choosing between people and technology. It is about building operating systems where people use technology intelligently, data is treated as a management asset, and decisions become measurable, explainable and continuously improvable.</p>
<p>AI amplifies intelligence. Leadership gives it direction.</p>
<p>Better questions create better insights. Better insights create better decisions. And better decisions create stronger, more resilient organisations.</p>
<div class="banner"><h3>Better Questions. Better Insights. Better Decisions.</h3><p>Use AI to see more clearly, use data to challenge assumptions, and use the matrix to make decisions with accountability.</p></div>
<div class="author-box"><h4>Nigel A. Thomas</h4><div class="role">Hospitality Professional · F&amp;B Operations · Corporate Trainer</div><p>Writing about hospitality operations, leadership, technology, food safety and the business of running better organisations.</p></div>
</article>
</main>
<footer class="site-footer"><p><a href="https://www.nigelthomas.live">nigelthomas.live</a> · <a href="https://www.nigelthomas.live/blog.html">All Articles</a></p><p>© 2026 Nigel A. Thomas. All rights reserved.</p></footer>
</body>
</html>

'@
[System.IO.File]::WriteAllText((Join-Path $repo $article), $articleHtml, (New-Object System.Text.UTF8Encoding($false)))

# 5. Update blog.html once only.
$blogPath = Join-Path $repo "blog.html"
$blog = Get-Content $blogPath -Raw -Encoding UTF8
if ($blog -notmatch "ai-decision-matrix\.html") {
    $blogCard = @'
<!-- AI DECISION MATRIX START -->
<section class="ai-decision-feature" style="max-width:1100px;margin:30px auto;padding:0 20px;">
  <a href="ai-decision-matrix.html" style="display:block;background:#141414;border:1px solid #d4af37;border-radius:12px;padding:22px;text-decoration:none;">
    <div style="font-size:.75rem;font-weight:800;letter-spacing:.12em;text-transform:uppercase;color:#d4af37;margin-bottom:8px;">AI · LEADERSHIP · DECISION INTELLIGENCE</div>
    <h2 style="color:#f4ede0;margin:0 0 8px;">AI Decision Matrix: Make Better Data-Driven Decisions Today</h2>
    <p style="color:#aaa49a;margin:0;">A practical framework using Risk, Opportunity, Impact, Tradeoffs and Alignment to help leaders pressure-test important decisions with AI and reliable data.</p>
  </a>
</section>
<!-- AI DECISION MATRIX END -->
'@
    if ($blog -match "(?i)</main>") {
        $blog = [regex]::Replace($blog, "(?i)</main>", "$blogCard`r`n</main>", 1)
    } elseif ($blog -match "(?i)</body>") {
        $blog = [regex]::Replace($blog, "(?i)</body>", "$blogCard`r`n</body>", 1)
    } else {
        $blog += "`r`n$blogCard`r`n"
    }
    [System.IO.File]::WriteAllText($blogPath, $blog, (New-Object System.Text.UTF8Encoding($false)))
} else {
    Write-Host "blog.html already contains the article link; no duplicate added." -ForegroundColor Yellow
}

# 6. Update sitemap.xml once only.
$sitemapPath = Join-Path $repo "sitemap.xml"
$sitemap = Get-Content $sitemapPath -Raw -Encoding UTF8
if ($sitemap -notmatch "ai-decision-matrix\.html") {
    $entry = @'
  <url>
    <loc>https://www.nigelthomas.live/ai-decision-matrix.html</loc>
    <lastmod>2026-08-18</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.8</priority>
  </url>
'@
    if ($sitemap -match "(?i)</urlset>") {
        $sitemap = [regex]::Replace($sitemap, "(?i)</urlset>", "$entry`r`n</urlset>", 1)
    } else {
        throw "sitemap.xml does not contain </urlset>."
    }
    [System.IO.File]::WriteAllText($sitemapPath, $sitemap, (New-Object System.Text.UTF8Encoding($false)))
} else {
    Write-Host "sitemap.xml already contains the article URL; no duplicate added." -ForegroundColor Yellow
}

# 7. Local verification before commit.
Write-Host "`n=== LOCAL VERIFY ===" -ForegroundColor Cyan
if (-not (Test-Path (Join-Path $repo $article))) { throw "Article HTML missing." }
if (-not (Test-Path (Join-Path $repo $imageName))) { throw "PNG missing." }
if ((Get-Item (Join-Path $repo $imageName)).Length -lt 100000) { throw "PNG file looks unexpectedly small." }

Select-String -Path (Join-Path $repo $article) -Pattern "ai-decision-matrix\.png","AI Decision Matrix","Risk","Opportunity","Tradeoffs","Alignment" | Select-Object -First 10
Select-String -Path $blogPath -Pattern "ai-decision-matrix\.html"
Select-String -Path $sitemapPath -Pattern "ai-decision-matrix\.html"

# 8. Commit and push.
git add $article $imageName blog.html sitemap.xml
git status
git commit -m "Add AI Decision Matrix leadership article and infographic"
if ($LASTEXITCODE -ne 0) { throw "git commit failed." }

git pull --rebase origin main
if ($LASTEXITCODE -ne 0) { throw "Second git pull --rebase failed." }

git push origin main
if ($LASTEXITCODE -ne 0) { throw "git push failed." }

# 9. Verify GitHub state and live production page.
Write-Host "`n=== GIT VERIFY ===" -ForegroundColor Cyan
git log -1 --oneline
git status --short
git remote -v

Write-Host "`n=== LIVE VERIFY ===" -ForegroundColor Cyan
try {
    $r = Invoke-WebRequest -Uri $articleUrl -UseBasicParsing -TimeoutSec 30
    Write-Host "LIVE: $($r.StatusCode) $articleUrl" -ForegroundColor Green
    if ($r.Content -match "AI Decision Matrix" -and $r.Content -match "ai-decision-matrix\.png") {
        Write-Host "LIVE CONTENT VERIFY: PASS" -ForegroundColor Green
    } else {
        Write-Host "LIVE CONTENT VERIFY: CHECK — page loaded but expected article/image text was not found." -ForegroundColor Yellow
    }
} catch {
    Write-Host "LIVE VERIFY FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== DONE ===" -ForegroundColor Green
Write-Host "GSC URL: $articleUrl" -ForegroundColor Cyan
Write-Host "Image: https://www.nigelthomas.live/ai-decision-matrix.png" -ForegroundColor Cyan
Write-Host "Blog: https://www.nigelthomas.live/blog.html" -ForegroundColor Cyan
Write-Host "Sitemap: https://www.nigelthomas.live/sitemap.xml" -ForegroundColor Cyan
