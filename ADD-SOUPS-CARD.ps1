# ==============================================================================
#  ADD-SOUPS-CARD.ps1  -  clones the LAST article-card in blog.html and turns it
#  into the International Soups card. Run from the repo root:
#    PS C:\Users\admin\Desktop\nigelthomas-portfolio> .\ADD-SOUPS-CARD.ps1
#  Add -NoPush to only edit blog.html locally. Pure ASCII, UTF-8 no BOM output.
# ==============================================================================
param([switch]$NoPush)
$ErrorActionPreference = 'Stop'

$enc = New-Object System.Text.UTF8Encoding $false
function Invoke-Git([string[]]$GitArgs) {
    $old = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { & git $GitArgs 2>&1 | ForEach-Object { Write-Host ("    " + [string]$_) -ForegroundColor Gray } }
    finally { $ErrorActionPreference = $old }
    return $LASTEXITCODE
}
function Set-CardText([string]$Html, [string]$ClassName, [string]$NewText) {
    $pat = '(?s)(class="[^"]*' + $ClassName + '[^"]*"[^>]*>)(.*?)(</\w+>)'
    $ev = [System.Text.RegularExpressions.MatchEvaluator]({
        param($m)
        $inner = $m.Groups[2].Value
        if ($inner -match '(?s)^(\s*<a\b[^>]*>)(.*)$') { $inner = $Matches[1] + $NewText } else { $inner = $NewText }
        return $m.Groups[1].Value + $inner + $m.Groups[3].Value
    }.GetNewClosure())
    $rx = New-Object System.Text.RegularExpressions.Regex($pat)
    return $rx.Replace($Html, $ev, 1)
}

$root     = (Get-Location).Path
$blogFile = Join-Path $root 'blog.html'
if (-not (Test-Path $blogFile)) { throw 'blog.html not found - run from the repo root.' }

$text = [System.IO.File]::ReadAllText($blogFile, $enc)
if ($text.Contains('international-soups.html')) { Write-Host 'blog.html already has the soups card - nothing to do.' -ForegroundColor Yellow; return }
$nl = "`n"
if ($text.Contains("`r`n")) { $nl = "`r`n" }

# ---- find the last card ------------------------------------------------------
$startPat = '<(\w+)\b[^>]*class="[^"]*(?<![\w-])article-card(?![\w-])[^"]*"[^>]*>'
$ms = [regex]::Matches($text, $startPat)
if ($ms.Count -eq 0) { throw 'No article-card found in blog.html.' }
$last  = $ms[$ms.Count - 1]
$tag   = $last.Groups[1].Value
$start = $last.Index
$startLine = ($text.Substring(0, $start).Split("`n")).Count
Write-Host ("Last card: <" + $tag + "> at line " + $startLine + "  (" + $ms.Count + " cards found)") -ForegroundColor Cyan

# ---- find where that card ends (tag depth counting) ---------------------------
$tagRx = New-Object System.Text.RegularExpressions.Regex('<(/?)' + $tag + '\b[^>]*>')
$depth = 0
$end = -1
foreach ($m in $tagRx.Matches($text.Substring($start))) {
    if ($m.Groups[1].Value -eq '/') { $depth-- }
    elseif (-not $m.Value.EndsWith('/>')) { $depth++ }
    if ($depth -eq 0) { $end = $start + $m.Index + $m.Length; break }
}
if ($end -lt 0) { throw 'Could not find the end of the last card.' }
$card = $text.Substring($start, $end - $start)

# indentation of the card's first line
$ls = $text.LastIndexOf("`n", $start)
$indent = ''
if ($ls -ge 0) { $pre = $text.Substring($ls + 1, $start - $ls - 1); if ($pre.Trim() -eq '') { $indent = $pre } }

# ---- turn the clone into the soups card ---------------------------------------
$c = $card
$c = [regex]::Replace($c, 'href="[^"]*"', 'href="international-soups.html"')
$c = [regex]::Replace($c, 'src="[^"]*"', 'src="assets/international-soups-poster.jpg"')
$c = [regex]::Replace($c, 'alt="[^"]*"', 'alt="International Soups - 12 Famous Soups From Around the World"')
$c = Set-CardText $c 'article-title'   'International Soups: 12 Famous Soups From Around the World'
$c = Set-CardText $c 'article-excerpt' 'French Onion, Minestrone, Miso, Tom Yum, Gazpacho, Borscht, Pho and more - 12 famous soups with service, allergen and food safety notes, plus a free downloadable poster.'
$c = Set-CardText $c 'article-meta'    'Food &amp; Beverage | September 2026'

if (-not $c.Contains('international-soups.html')) { throw 'Clone has no link to the soups page - card structure unexpected. Nothing written.' }

Write-Host ''
Write-Host '--- NEW CARD (check this looks like your other cards) ---' -ForegroundColor Yellow
Write-Host $c -ForegroundColor White
Write-Host '---------------------------------------------------------' -ForegroundColor Yellow

# ---- backup (outside the repo), insert, save ------------------------------------
$bak = Join-Path (Split-Path -Parent $root) 'blog.html.bak-soups'
Copy-Item $blogFile $bak -Force
Write-Host ("Backup: " + $bak) -ForegroundColor Gray
$text = $text.Insert($end, $nl + $nl + $indent + $c)
[System.IO.File]::WriteAllText($blogFile, $text, $enc)

$check = [System.IO.File]::ReadAllText($blogFile, $enc)
$count = ([regex]::Matches($check, 'international-soups\.html')).Count
Write-Host ("Local blog.html now has " + $count + " reference(s) to international-soups.html") -ForegroundColor Green
if ($count -lt 1) { throw 'Insert failed - restore from the backup.' }

if ($NoPush) { Write-Host 'Done (-NoPush). Review with: git diff blog.html' -ForegroundColor Yellow; return }

# ---- commit / push -----------------------------------------------------------
Write-Host 'Commit and push...' -ForegroundColor Cyan
$rc = Invoke-Git @('add', '--', 'blog.html')
$rc = Invoke-Git @('commit', '-m', 'Add International Soups card to blog')
if ($rc -ne 0) { throw 'git commit failed' }
$rc = Invoke-Git @('push')
if ($rc -ne 0) {
    Write-Host 'push rejected - pull --rebase --autostash then retry' -ForegroundColor Yellow
    $rc = Invoke-Git @('pull', '--rebase', '--autostash')
    if ($rc -eq 0) { $rc = Invoke-Git @('push') }
    if ($rc -ne 0) { throw 'git push failed - resolve manually.' }
}

# ---- verify live -----------------------------------------------------------
Write-Host 'Checking live blog.html (up to 3 minutes)...' -ForegroundColor Cyan
$ok = $false
for ($i = 1; $i -le 18; $i++) {
    try {
        $r = Invoke-WebRequest -Uri ('https://www.nigelthomas.live/blog.html?v=' + (Get-Date -Format 'yyyyMMddHHmmss')) -UseBasicParsing -TimeoutSec 30
        if ($r.StatusCode -eq 200 -and ([string]$r.Content).Contains('international-soups.html')) { $ok = $true; break }
    } catch { }
    Write-Host '    ...not live yet, retry in 10s' -ForegroundColor Gray
    Start-Sleep -Seconds 10
}
if ($ok) { Write-Host '[200 OK] blog.html is live with the International Soups card' -ForegroundColor Green }
else { Write-Host 'Not confirmed live yet - check the Vercel dashboard and re-run the live check.' -ForegroundColor Red }
