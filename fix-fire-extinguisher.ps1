# =============================================================
# FIX TYPES OF FIRE EXTINGUISHERS PAGE
# =============================================================

$file   = "blog\types-of-fire-extinguishers.html"
$backup = "$file.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# 1. Backup
Copy-Item $file $backup
Write-Host "Backup created: $backup" -ForegroundColor Cyan

# 2. Read the file
$html = Get-Content $file -Raw

# 3. Remove any existing floating poster <img> for fire-extinguisher-types.png
#    (only the visible ones, not the ones inside <script> or meta tags)
$html = [regex]::Replace(
    $html,
    '(?is)<div[^>]*style="[^"]*text-align:\s*center[^"]*"[^>]*>\s*<img[^>]*fire-extinguisher-types\.png[^>]*>\s*</div>',
    ''
)

$html = [regex]::Replace(
    $html,
    '(?is)<img[^>]*fire-extinguisher-types\.png[^>]*>',
    ''
)

# 4. Define the single clean poster block
$poster = @'

<!-- =========================================================
     SINGLE BOTTOM POSTER
     ========================================================= -->
<section class="nt-poster-bottom" style="margin:50px auto; max-width:900px; text-align:center;">
    <h2 style="color:#d4af37; margin-bottom:20px;">Download the Free Poster</h2>
    <img src="/assets/fire-extinguisher-types.png"
         alt="Types of Fire Extinguishers infographic"
         loading="lazy"
         style="max-width:100%; height:auto; border-radius:10px; display:block; margin:0 auto;">
    <p style="margin-top:20px;">
        <a href="/assets/fire-extinguisher-types.png"
           download="fire-extinguisher-types.png"
           class="download-btn"
           style="display:inline-block; background:#d4af37; color:#000; padding:12px 28px; border-radius:30px; font-weight:bold; text-decoration:none;">
            DOWNLOAD FREE POSTER
        </a>
    </p>
</section>
<!-- =========================================================
     END SINGLE BOTTOM POSTER
     ========================================================= -->

'@

# 5. Insert poster immediately before <footer>
$footerMarker = '<footer>'

if ($html -notmatch [regex]::Escape($footerMarker)) {
    throw "FOOTER MARKER NOT FOUND - file not modified."
}

$html = $html.Replace(
    $footerMarker,
    "$poster`r`n$footerMarker"
)

# 6. Update GA4
$html = $html.Replace('G-CLRRV5DMXZ', 'G-P839TWLQSJ')

# 7. Update AdSense
$html = $html.Replace('ca-pub-4282121192943910', 'ca-pub-8127243414384620')

# 8. Remove excessive blank lines
$html = [regex]::Replace($html, '(\r?\n){4,}', "`r`n`r`n")

# 9. Write UTF-8 without BOM
[System.IO.File]::WriteAllText($file, $html, [System.Text.UTF8Encoding]::new($false))
Write-Host "PASS - HTML written as UTF-8 without BOM." -ForegroundColor Green

# 10. Validation
$check = [System.IO.File]::ReadAllText($file, [System.Text.UTF8Encoding]::new($false))

$posterCount     = [regex]::Matches($check, '(?is)<section[^>]*class="nt-poster-bottom"').Count
$downloadCount   = [regex]::Matches($check, '(?i)DOWNLOAD FREE POSTER').Count
$imageCount      = [regex]::Matches($check, '(?i)fire-extinguisher-types\.png').Count
$badEncodingCount = [regex]::Matches($check, 'Aƒ|A¢|dY|A°').Count
$ga4Current      = $check.Contains('G-P839TWLQSJ')
$adsenseCurrent  = $check.Contains('ca-pub-8127243414384620')

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " VALIDATION RESULTS" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host "Poster sections       : $posterCount"
Write-Host "Download buttons      : $downloadCount"
Write-Host "Poster image refs     : $imageCount"
Write-Host "Bad encoding matches  : $badEncodingCount"
Write-Host "Current GA4           : $ga4Current"
Write-Host "Current AdSense       : $adsenseCurrent"
Write-Host ""

if ($posterCount -ne 1)     { Write-Host "FAIL - Poster section count is not exactly 1." -ForegroundColor Red; exit 1 }
if ($downloadCount -ne 1)   { Write-Host "FAIL - Download button count is not exactly 1." -ForegroundColor Red; exit 1 }
if (-not $ga4Current)       { Write-Host "FAIL - Current GA4 ID not found." -ForegroundColor Red; exit 1 }
if (-not $adsenseCurrent)   { Write-Host "FAIL - Current AdSense ID not found." -ForegroundColor Red; exit 1 }

if ($badEncodingCount -gt 0) {
    Write-Host "WARNING - Some mojibake remains elsewhere." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "PASS - TYPES OF FIRE EXTINGUISHERS CLEANUP COMPLETE" -ForegroundColor Green
Write-Host "Backup: $backup"
Write-Host "File  : $file"
Write-Host "============================================================" -ForegroundColor Green