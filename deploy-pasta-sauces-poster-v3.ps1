# deploy-pasta-sauces-poster-v2.ps1
# Embeds the on-brand pasta sauces poster into types-of-pasta-sauces.html
# Rewritten to avoid here-strings and non-ASCII chars (Windows PowerShell 5.1 safe)
# Run from: C:\Users\admin\Desktop\nigelthomas-portfolio

$file = ".\types-of-pasta-sauces.html"

if (-not (Test-Path $file)) {
    Write-Host "FILE NOT FOUND: $file -- run this from the repo root." -ForegroundColor Red
    exit 1
}

$content = Get-Content $file -Raw -Encoding UTF8

# ---------- 1. Replace the empty figure with the poster markup ----------

$oldLines = @(
'<figure class="article-figure">',
'<figcaption>Quick-reference infographic: the five classic pasta sauces, their core ingredients, allergens, and correct pasta pairings.</figcaption>',
'</figure>'
)
$oldFigure = $oldLines -join "`n"

$newLines = @(
'<figure class="article-figure">',
'<div id="nt-poster">',
'  <div class="poster-head">',
'    <div class="brand">Nigel<span style="color:var(--gold)">Thomas</span> - Culinary Reference</div>',
'    <h2>Top 5 Classic <span class="accent">Pasta Sauces</span></h2>',
'    <p>Composition, allergens and traditional pairing - at a glance</p>',
'  </div>',
'  <div class="poster-grid">',
'    <div class="p-row">',
'      <div class="p-num">1</div>',
'      <div>',
'        <div class="p-name">Bolognese</div>',
'        <div class="p-desc">Slow-braised minced meat and tomato, red wine, soffritto. Holds well on a steam table.</div>',
'        <div class="p-tags">',
'          <span class="p-tag pairing">Tagliatelle / Pappardelle</span>',
'          <span class="p-tag allergen">Gluten, Milk, Celery, Sulphites</span>',
'        </div>',
'      </div>',
'    </div>',
'    <div class="p-row">',
'      <div class="p-num">2</div>',
'      <div>',
'        <div class="p-name">Arrabbiata</div>',
'        <div class="p-desc">Fast tomato, garlic, olive oil, chilli. No dairy - most allergen-flexible of the five.</div>',
'        <div class="p-tags">',
'          <span class="p-tag pairing">Penne / Spaghetti</span>',
'          <span class="p-tag allergen">May contain traces of gluten</span>',
'        </div>',
'      </div>',
'    </div>',
'    <div class="p-row">',
'      <div class="p-num">3</div>',
'      <div>',
'        <div class="p-name">Alfredo</div>',
'        <div class="p-desc">Butter, cream, Parmesan emulsion. Fragile - breaks if held or reheated carelessly.</div>',
'        <div class="p-tags">',
'          <span class="p-tag pairing">Fettuccine</span>',
'          <span class="p-tag allergen">Gluten, Milk</span>',
'        </div>',
'      </div>',
'    </div>',
'    <div class="p-row">',
'      <div class="p-num">4</div>',
'      <div>',
'        <div class="p-name">Pesto Genovese</div>',
'        <div class="p-desc">Raw basil, pine nuts, Parmesan, olive oil, garlic. Never cooked - finished a la minute.</div>',
'        <div class="p-tags">',
'          <span class="p-tag pairing">Trofie / Linguine</span>',
'          <span class="p-tag allergen">Tree nuts (pine nuts), Milk</span>',
'        </div>',
'      </div>',
'    </div>',
'    <div class="p-row">',
'      <div class="p-num">5</div>',
'      <div>',
'        <div class="p-name">Carbonara</div>',
'        <div class="p-desc">Egg and Pecorino/Parmesan emulsion off direct heat, guanciale or pancetta. No cream in the authentic version.</div>',
'        <div class="p-tags">',
'          <span class="p-tag pairing">Spaghetti / Rigatoni</span>',
'          <span class="p-tag allergen">Gluten, Egg, Milk</span>',
'        </div>',
'      </div>',
'    </div>',
'  </div>',
'  <div class="poster-foot">',
'    <span>NigelThomas.live</span> - Culinary Reference / F&B Terminology Series',
'  </div>',
'</div>',
'<figcaption>Quick-reference infographic: the five classic pasta sauces, their core ingredients, allergens, and correct pasta pairings.</figcaption>',
'</figure>'
)
$newFigure = $newLines -join "`n"

if (-not $content.Contains($oldFigure)) {
    Write-Host "NO MATCH on the figure block -- nothing was changed." -ForegroundColor Yellow
    exit 1
}

$content = $content.Replace($oldFigure, $newFigure)
Write-Host "Figure block replaced." -ForegroundColor Green

# ---------- 2. Inject poster CSS just before the first closing style tag ----------

$cssLines = @(
'',
'/* NT Poster component (pasta sauces) */',
'#nt-poster{max-width:100%;background:var(--bg);border:1px solid var(--panel-line);border-radius:14px;padding:2.4rem 2.2rem 2rem;color:var(--cream);}',
'.poster-head{text-align:center;margin-bottom:1.8rem;}',
'.poster-head .brand{font-size:0.72rem;font-weight:800;letter-spacing:0.18em;text-transform:uppercase;color:var(--gold);margin-bottom:0.6rem;}',
'.poster-head h2{font-size:1.9rem;font-weight:900;letter-spacing:0.01em;}',
'.poster-head h2 .accent{color:var(--gold);}',
'.poster-head p{font-size:0.85rem;color:var(--muted);margin-top:0.5rem;}',
'.poster-grid{display:flex;flex-direction:column;gap:0.9rem;}',
'.p-row{display:grid;grid-template-columns:44px 1fr;gap:1rem;background:var(--panel);border:1px solid var(--panel-line);border-radius:10px;padding:1.05rem 1.2rem;align-items:flex-start;}',
'.p-num{width:44px;height:44px;background:var(--gold);color:var(--bg);border-radius:8px;display:flex;align-items:center;justify-content:center;font-weight:900;font-size:1.05rem;}',
'.p-name{font-size:1.05rem;font-weight:800;color:var(--gold-soft);margin-bottom:0.3rem;}',
'.p-desc{font-size:0.82rem;color:#ded9cd;line-height:1.55;margin-bottom:0.55rem;}',
'.p-tags{display:flex;flex-wrap:wrap;gap:0.5rem;}',
'.p-tag{font-size:0.7rem;font-weight:700;letter-spacing:0.03em;padding:0.25rem 0.65rem;border-radius:100px;}',
'.p-tag.pairing{background:var(--navy);border:1px solid var(--navy-line);color:#cfe0f5;}',
'.p-tag.allergen{background:var(--green);border:1px solid var(--green-line);color:var(--gold-soft);}',
'.poster-foot{margin-top:1.6rem;text-align:center;font-size:0.72rem;color:var(--muted);border-top:1px solid var(--panel-line);padding-top:1rem;}',
'.poster-foot span{color:var(--gold);font-weight:700;}',
'</style>'
)
$cssBlock = $cssLines -join "`n"

$idx = $content.IndexOf('</style>')
if ($idx -lt 0) {
    Write-Host "No closing style tag found -- CSS not injected. Add it manually." -ForegroundColor Yellow
} else {
    $content = $content.Remove($idx, 8).Insert($idx, $cssBlock)
    Write-Host "Poster CSS injected into main stylesheet." -ForegroundColor Green
}

# ---------- 3. Save and verify ----------

$before = (Get-Item $file).Length
Set-Content -Path $file -Value $content -NoNewline -Encoding UTF8
$after = (Get-Item $file).Length

Write-Host ""
Write-Host "Done. File size: $before bytes -> $after bytes." -ForegroundColor Cyan
Write-Host "Now review before committing: git diff types-of-pasta-sauces.html" -ForegroundColor Cyan
