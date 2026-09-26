# ============================================================
# ONE-SHOT-TYPES-OF-COFFEE.ps1
# Move coffee poster to assets + streamline article + add
# NigelThomas.live INFOMATICS poster/download + related links.
# ============================================================

$ErrorActionPreference = "Stop"

$repoRoot   = "C:\Users\admin\Desktop\nigelthomas-portfolio"
$pageName   = "types-of-coffee-complete-guide.html"
$assetsDir  = Join-Path $repoRoot "assets"
$pagePath   = Join-Path $repoRoot $pageName
$posterName = "coffee-types-poster.png"
$posterDest = Join-Path $assetsDir $posterName

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " TYPES OF COFFEE - ONE SHOT DEPLOY PREPARATION" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""

# ------------------------------------------------------------
# 1. Validate repository and target page
# ------------------------------------------------------------
if (-not (Test-Path $repoRoot -PathType Container)) {
    throw "Repository not found: $repoRoot"
}

if (-not (Test-Path $pagePath -PathType Leaf)) {
    throw "HTML page not found: $pagePath"
}

if (-not (Test-Path $assetsDir -PathType Container)) {
    New-Item -ItemType Directory -Path $assetsDir | Out-Null
}

Set-Location $repoRoot

# ------------------------------------------------------------
# 2. Find the PNG poster in the repository root and move it
#    to /assets/coffee-types-poster.png
# ------------------------------------------------------------
$rootPoster = Join-Path $repoRoot $posterName

if (-not (Test-Path $rootPoster -PathType Leaf)) {
    $candidates = @(Get-ChildItem -Path $repoRoot -File -Filter "*.png" |
        Where-Object {
            $_.Name -match '(?i)coffee.*poster|poster.*coffee'
        })

    if ($candidates.Count -eq 1) {
        $rootPoster = $candidates[0].FullName
        Write-Host "Found poster: $($candidates[0].Name)" -ForegroundColor Cyan
    }
    elseif ($candidates.Count -gt 1) {
        throw "More than one coffee poster PNG was found in the repository root. Rename the correct one to '$posterName' and run again."
    }
    elseif (Test-Path $posterDest -PathType Leaf) {
        Write-Host "Poster already exists in assets: $posterName" -ForegroundColor Green
    }
    else {
        throw "Could not find a coffee poster PNG in the repository root."
    }
}

if (Test-Path $rootPoster -PathType Leaf) {

    if (Test-Path $posterDest -PathType Leaf) {
        $srcHash = (Get-FileHash $rootPoster -Algorithm SHA256).Hash
        $dstHash = (Get-FileHash $posterDest -Algorithm SHA256).Hash

        if ($srcHash -eq $dstHash) {
            Remove-Item $rootPoster -Force
            Write-Host "Removed duplicate root poster; assets copy is identical." -ForegroundColor Green
        }
        else {
            throw "Both root and assets poster exist but their SHA256 hashes differ. Stopping so no poster is overwritten."
        }
    }
    else {
        Move-Item -LiteralPath $rootPoster -Destination $posterDest
        Write-Host "Moved poster -> assets\$posterName" -ForegroundColor Green
    }
}

# ------------------------------------------------------------
# 3. Read HTML and create a timestamped safety backup
# ------------------------------------------------------------
$html = [IO.File]::ReadAllText($pagePath, [Text.Encoding]::UTF8)

if ($html -notmatch '(?i)</main\s*>') {
    throw "The HTML does not contain a closing </main> tag. No changes were made."
}

$stamp  = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = Join-Path $repoRoot "$pageName.backup-before-coffee-infomatics-$stamp"
[IO.File]::WriteAllText($backup, $html, $utf8NoBom)

Write-Host "Backup created: $(Split-Path $backup -Leaf)" -ForegroundColor DarkGray

# ------------------------------------------------------------
# 4. Use the PNG consistently in SEO/social/schema references
# ------------------------------------------------------------
$html = $html -replace 'coffee-types-poster\.jpg', 'coffee-types-poster.png'

# ------------------------------------------------------------
# 5. Remove the old poster shown near the top of the article.
#    The poster will appear once only inside INFOMATICS at bottom.
# ------------------------------------------------------------
$oldTopPoster = '(?s)\s*<div\s+class="poster-embed">\s*<img\s+src="/assets/coffee-types-poster\.png"[^>]*>\s*</div>\s*'
$html = [regex]::Replace($html, $oldTopPoster, "`r`n`r`n", 1)

# ------------------------------------------------------------
# 6. Remove an older marked NT INFOMATICS block if the page
#    already contains one. This makes the script safe to rerun.
# ------------------------------------------------------------
$html = [regex]::Replace(
    $html,
    '(?s)\s*<!-- NT INFOMATICS -->.*?<!-- END NT INFOMATICS -->\s*',
    "`r`n",
    1
)

# Remove an older marked coffee-related block if present.
$html = [regex]::Replace(
    $html,
    '(?s)\s*<!-- NT-COFFEE-RELATED -->.*?<!-- END NT-COFFEE-RELATED -->\s*',
    "`r`n",
    1
)

# ------------------------------------------------------------
# 7. Add the established NigelThomas.live Infomatics styling.
# ------------------------------------------------------------
$infomaticsCss = @'
/* NT COFFEE INFOMATICS */
.nt-infomatics-section{
    margin:50px 0 35px;
    text-align:center;
}
.nt-infomatics-button{
    display:inline-block;
    padding:14px 40px;
    background:#d4af37;
    color:#000;
    border:1px solid #b8962e;
    border-radius:6px;
    font-weight:700;
    font-size:1.05rem;
    letter-spacing:1px;
    cursor:pointer;
    font-family:inherit;
}
.nt-infomatics-button:hover{
    background:#e6c04a;
}
.nt-infomatics-panel{
    display:none;
    margin-top:20px;
}
.nt-infomatics-panel.show{
    display:block;
}
.nt-poster-wrap{
    text-align:center;
    max-width:900px;
    margin:0 auto;
}
.nt-poster-wrap img{
    max-width:100%;
    height:auto;
    border:2px solid #d4af37;
    border-radius:8px;
    display:block;
    margin:0 auto;
}
.nt-download-btn{
    display:inline-block;
    margin-top:18px;
    padding:12px 28px;
    background:#d4af37;
    color:#000;
    text-decoration:none;
    border-radius:6px;
    font-weight:700;
    border:1px solid #b8962e;
}
.nt-download-btn:hover{
    background:#e6c04a;
}
.nt-infomatics-note{
    font-size:.9rem;
    color:#a8a8a8;
    margin-top:10px;
    text-align:center;
}
.nt-coffee-related{
    margin:45px 0 25px;
}
.nt-coffee-related h2{
    color:#d4af37;
    border-bottom:2px solid #d4af37;
    padding-bottom:10px;
}
.nt-coffee-related ul{
    margin:15px 0 25px 30px;
}
.nt-coffee-related a{
    color:#d4af37;
    text-decoration:none;
}
.nt-coffee-related a:hover{
    text-decoration:underline;
}
.nt-read-more{
    text-align:center;
    margin:25px 0 10px;
    clear:both;
}
.nt-read-more a{
    display:inline-block;
    padding:14px 40px;
    background:#d4af37;
    color:#000;
    text-decoration:none;
    border-radius:6px;
    font-weight:700;
    font-size:1.1rem;
    border:1px solid #b8962e;
}
.nt-read-more a:hover{
    background:#e6c04a;
}
'@

if ($html -notmatch '\.nt-infomatics-button\s*\{') {
    if ($html -notmatch '(?i)</style>') {
        throw "No </style> tag found for Infomatics CSS insertion."
    }
    $html = $html -replace '(?i)</style>', "`r`n$infomaticsCss`r`n</style>"
    Write-Host "Added Infomatics CSS." -ForegroundColor Green
}
else {
    Write-Host "Infomatics CSS already present; skipped duplicate CSS." -ForegroundColor DarkGray
}

# ------------------------------------------------------------
# 8. Build the bottom Infomatics + related-reading section.
#    Links are existing coffee/beverage pages in the site repo.
# ------------------------------------------------------------
$bottomBlock = @'
<!-- NT INFOMATICS -->
<section class="nt-infomatics-section">

    <button type="button"
            class="nt-infomatics-button"
            data-panel="nt-infomatics-panel"
            aria-expanded="false">
        FREE POSTER DOWNLOAD
    </button>

    <div id="nt-infomatics-panel"
         class="nt-infomatics-panel"
         aria-hidden="true">

        <div class="nt-poster-wrap">
            <img src="/assets/coffee-types-poster.png"
                 alt="Types of Coffee - The Complete F&amp;B Professional's Guide poster by Nigel A. Thomas"
                 loading="lazy">
        </div>

        <a class="nt-download-btn"
           href="/assets/coffee-types-poster.png"
           download="coffee-types-poster.png">
            DOWNLOAD POSTER (FREE)
        </a>

        <p class="nt-infomatics-note">
            Free to download and share with credit to nigelthomas.live.
        </p>

    </div>
</section>
<!-- END NT INFOMATICS -->

<!-- NT-COFFEE-RELATED -->
<section class="nt-coffee-related">
    <h2>Other Coffee &amp; Beverage Links</h2>
    <ul>
        <li><a href="/coffee-types-poster.html">Coffee Guide Poster - 16 Types of Coffee at a Glance</a></li>
        <li><a href="/coffee-shop-vocabulary.html">Coffee Shop Vocabulary - Essential F&amp;B Terms</a></li>
        <li><a href="/beverage.html">Beverage Management - Coffee, Tea, Wine, Cocktails &amp; Service</a></li>
        <li><a href="/types-of-cheese-used-in-hotels.html">Types of Cheese Used in Hotels</a></li>
    </ul>
</section>
<!-- END NT-COFFEE-RELATED -->

<div class="nt-read-more">
    <a href="/blog.html">Read More Articles &rarr;</a>
</div>
'@

# ------------------------------------------------------------
# 9. Insert the bottom block immediately before </main>.
# ------------------------------------------------------------
$mainClosePattern = '(?i)\s*</main\s*>'
if ($html -notmatch $mainClosePattern) {
    throw "Closing </main> tag disappeared before insertion."
}

$html = [regex]::Replace(
    $html,
    $mainClosePattern,
    "`r`n`r`n$bottomBlock`r`n</main>",
    1
)

# ------------------------------------------------------------
# 10. Add the Infomatics JavaScript exactly once.
# ------------------------------------------------------------
$infomaticsJs = @'
<script id="nt-infomatics-js">
document.addEventListener("click", function(event) {
    var button = event.target.closest(".nt-infomatics-button");
    if (!button) return;

    var panelId = button.getAttribute("data-panel");
    var panel = document.getElementById(panelId);
    if (!panel) return;

    var opened = panel.classList.toggle("show");

    button.textContent = opened
        ? "HIDE INFOMATICS"
        : "FREE POSTER DOWNLOAD";

    button.setAttribute(
        "aria-expanded",
        opened ? "true" : "false"
    );

    panel.setAttribute(
        "aria-hidden",
        opened ? "false" : "true"
    );
});
</script>
'@

if ($html -notmatch 'id="nt-infomatics-js"') {
    if ($html -notmatch '(?i)</body\s*>') {
        throw "No closing </body> tag found for JavaScript insertion."
    }
    $html = [regex]::Replace(
        $html,
        '(?i)</body\s*>',
        "`r`n$infomaticsJs`r`n</body>",
        1
    )
    Write-Host "Added Infomatics JavaScript." -ForegroundColor Green
}
else {
    Write-Host "Infomatics JavaScript already present." -ForegroundColor DarkGray
}

# ------------------------------------------------------------
# 11. Clean up the old poster CSS if it is now unused.
# ------------------------------------------------------------
$html = [regex]::Replace(
    $html,
    '(?s)\s*\.poster-embed\{text-align:center;margin:30px 0;\}\s*\.poster-embed img\{max-width:100%;height:auto;border-radius:8px;border:2px solid #d4af37;\}\s*',
    "`r`n",
    1
)

# ------------------------------------------------------------
# 12. Final safety checks before writing.
# ------------------------------------------------------------
$checks = [ordered]@{
    "HTML closing main"          = ($html -match '(?i)</main\s*>')
    "HTML closing body"          = ($html -match '(?i)</body\s*>')
    "Infomatics button"          = ($html -match 'FREE POSTER DOWNLOAD')
    "Infomatics panel"           = ($html -match 'id="nt-infomatics-panel"')
    "PNG poster path"            = ($html -match '/assets/coffee-types-poster\.png')
    "Download link"              = ($html -match 'download="coffee-types-poster\.png"')
    "Infomatics JS"              = ($html -match 'id="nt-infomatics-js"')
    "Related links"              = ($html -match 'nt-coffee-related')
}

foreach ($check in $checks.GetEnumerator()) {
    Write-Host ("{0,-28} {1}" -f $check.Key, $(if($check.Value){"PASS"}else{"FAIL"})) `
        -ForegroundColor $(if($check.Value){"Green"}else{"Red"})
}

if ($checks.Values -contains $false) {
    throw "A final validation check failed. The original HTML backup remains untouched."
}

# Count key elements so reruns can be verified.
$buttonCount = ([regex]::Matches($html, 'class="nt-infomatics-button"')).Count
$panelCount  = ([regex]::Matches($html, 'id="nt-infomatics-panel"')).Count
$posterCount = ([regex]::Matches($html, '/assets/coffee-types-poster\.png')).Count

Write-Host ""
Write-Host "Element counts:" -ForegroundColor Cyan
Write-Host "  Infomatics buttons : $buttonCount"
Write-Host "  Infomatics panels  : $panelCount"
Write-Host "  PNG asset refs     : $posterCount"

if ($buttonCount -ne 1 -or $panelCount -ne 1) {
    throw "Duplicate Infomatics elements detected. Stopping before writing."
}

# ------------------------------------------------------------
# 13. Write final HTML as UTF-8 without BOM.
# ------------------------------------------------------------
[IO.File]::WriteAllText($pagePath, $html, $utf8NoBom)

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " COFFEE ARTICLE PREP COMPLETE" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host "HTML  : $pageName"
Write-Host "Poster: assets\$posterName"
Write-Host "Backup: $(Split-Path $backup -Leaf)"
Write-Host ""

# ------------------------------------------------------------
# 14. Git status/diff review - NO COMMIT OR PUSH.
# ------------------------------------------------------------
Write-Host "===== GIT STATUS =====" -ForegroundColor Yellow
git status --short

Write-Host ""
Write-Host "===== TARGETED DIFF CHECK =====" -ForegroundColor Yellow
git diff -- $pageName $posterName "assets/$posterName"

Write-Host ""
Write-Host "No commit or push was performed." -ForegroundColor Cyan
Write-Host "Review the diff first, then commit/push when satisfied." -ForegroundColor Cyan
