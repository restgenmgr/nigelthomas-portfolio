# add-poster-toggle.ps1
# Scans blog/*.html (and root *.html as fallback) for a poster image and wraps it
# in a click-to-reveal "Read More - View Full Infographic" toggle, matching the
# pattern used on fine-dining-silverware.html. Safe by default: dry-run unless
# -Apply is passed. Backs up every file it changes before writing.
#
# Usage:
#   .\add-poster-toggle.ps1                 # dry run, shows what WOULD change
#   .\add-poster-toggle.ps1 -Apply          # actually writes the changes
#   .\add-poster-toggle.ps1 -Apply -Path blog\fine-dining-silverware.html   # one file only

param(
    [switch]$Apply,
    [string]$Path = ""
)

$ErrorActionPreference = "Stop"
$repo = Get-Location
$backupDir = Join-Path $repo "_poster-toggle-backups"

if ($Path -ne "") {
    $files = Get-Item $Path
} else {
    $files = Get-ChildItem -Path (Join-Path $repo "blog") -Filter "*.html" -Recurse -ErrorAction SilentlyContinue
    if (-not $files) {
        # fallback: some older poster pages may still live at repo root
        $files = Get-ChildItem -Path $repo -Filter "*.html" -File
    }
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$changed = 0
$skippedAlready = 0
$skippedNoImage = 0

foreach ($f in $files) {
    $content = [System.IO.File]::ReadAllText($f.FullName)

    # Already has the toggle pattern? Skip (idempotent).
    if ($content -match 'id="poster-panel"' -or $content -match 'read-more-btn.*Infographic') {
        $skippedAlready++
        Write-Host "SKIP (already has toggle): $($f.Name)" -ForegroundColor DarkGray
        continue
    }

    # Find a poster-like image: base64 JPEG/PNG data URI, OR an <img> tag
    # pointing at any *.jpg|jpeg|png|webp that isn't clearly a small icon/logo.
    $imgMatch = [regex]::Match($content, '<img[^>]+src="(data:image/[^"]+;base64,[^"]+)"[^>]*>')

    if (-not $imgMatch.Success) {
        # gather every <img> tag with an image-file src, in order
        $allImgs = [regex]::Matches($content, '<img[^>]+src="([^"]+\.(?:jpg|jpeg|png|webp))"[^>]*>', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        $candidate = $allImgs | Where-Object { $_.Groups[1].Value -notmatch '(?i)(logo|icon|emblem|nav|favicon)' } | Select-Object -First 1
        if ($candidate) { $imgMatch = $candidate }
    }

    if (-not $imgMatch.Success) {
        $skippedNoImage++
        Write-Host "SKIP (no poster image found): $($f.Name)" -ForegroundColor Yellow
        $debugImgs = [regex]::Matches($content, '<img[^>]+src="([^"]+)"')
        if ($debugImgs.Count -gt 0) {
            Write-Host "   images present in this file:" -ForegroundColor DarkYellow
            foreach ($d in $debugImgs) { Write-Host "     - $($d.Groups[1].Value)" -ForegroundColor DarkYellow }
        } else {
            Write-Host "   (no <img> tags at all found in this file)" -ForegroundColor DarkYellow
        }
        continue
    }

    $fullImgTag = $imgMatch.Value

    # Build the replacement: button + hidden panel wrapping the same <img> tag
    $wrapped = @"
<div class="cta-wrap" style="text-align:center;margin:50px 0 10px;">
<button class="read-more-btn" style="background:#d4af37;color:#0b0b0b;border:none;font-weight:700;font-size:1rem;padding:14px 30px;border-radius:30px;cursor:pointer;" onclick="document.getElementById('poster-panel').classList.toggle('open'); this.textContent = document.getElementById('poster-panel').classList.contains('open') ? 'Hide Infographic' : 'Read More - View Full Infographic';">Read More - View Full Infographic</button>
<div id="poster-panel" style="display:none;margin-top:34px;text-align:center;">
$fullImgTag
</div>
</div>
"@

    $newContent = $content.Substring(0, $imgMatch.Index) + $wrapped + $content.Substring($imgMatch.Index + $imgMatch.Length)

    # add the .open{display:block} CSS rule once, right before </head>, if missing
    if ($newContent -notmatch '#poster-panel\.open') {
        $headIdx = $newContent.IndexOf("</head>")
        if ($headIdx -ge 0) {
            $cssRule = "<style>#poster-panel.open{display:block!important;}</style>`n</head>"
            $newContent = $newContent.Substring(0, $headIdx) + $cssRule + $newContent.Substring($headIdx + 7)
        }
    }

    if ($Apply) {
        if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
        Copy-Item $f.FullName (Join-Path $backupDir $f.Name) -Force
        [System.IO.File]::WriteAllText($f.FullName, $newContent, $utf8NoBom)
        Write-Host "APPLIED: $($f.Name)" -ForegroundColor Green
    } else {
        Write-Host "WOULD CHANGE: $($f.Name)" -ForegroundColor Cyan
    }
    $changed++
}

Write-Host ""
Write-Host "----------------------------------------"
Write-Host "Changed:            $changed"
Write-Host "Skipped (has it):   $skippedAlready"
Write-Host "Skipped (no image): $skippedNoImage"
if (-not $Apply) {
    Write-Host ""
    Write-Host "This was a DRY RUN. Review the list above, then re-run with -Apply to write changes." -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "Backups saved to: $backupDir" -ForegroundColor Yellow
    Write-Host "Review with: git diff" -ForegroundColor Yellow
}