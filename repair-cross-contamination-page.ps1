# ============================================================
# REPAIR CROSS-CONTAMINATION PAGE
# ============================================================

$ErrorActionPreference = "Stop"

$repo = "C:\Users\admin\Desktop\nigelthomas-portfolio"
Set-Location $repo

$file = Join-Path $repo "blog\cross-contamination-prevention.html"
$poster = Join-Path $repo "assets\cross-contamination-poster.jpg"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " CROSS-CONTAMINATION PAGE REPAIR" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# ------------------------------------------------------------
# CHECK FILES
# ------------------------------------------------------------

if (-not (Test-Path $file)) {
    Write-Host "FAIL - HTML file not found:" -ForegroundColor Red
    Write-Host $file
    exit 1
}

if (-not (Test-Path $poster)) {
    Write-Host "FAIL - Poster image not found:" -ForegroundColor Red
    Write-Host $poster
    exit 1
}

Write-Host "PASS - HTML file found" -ForegroundColor Green
Write-Host "PASS - Poster image found" -ForegroundColor Green

# ------------------------------------------------------------
# READ UTF-8
# ------------------------------------------------------------

$utf8 = New-Object System.Text.UTF8Encoding($false)

$html = [System.IO.File]::ReadAllText(
    (Resolve-Path $file),
    $utf8
)

Write-Host "PASS - HTML loaded" -ForegroundColor Green

# ------------------------------------------------------------
# REMOVE EXISTING POSTER INFOMATIC BLOCKS
# ------------------------------------------------------------

$pattern1 = '(?is)<section[^>]*id\s*=\s*["'']free-poster-download["''][^>]*>.*?</section>'

$html = [regex]::Replace($html, $pattern1, "")

$pattern2 = '(?is)<div[^>]*id\s*=\s*["'']free-poster-download["''][^>]*>.*?</div>'

$html = [regex]::Replace($html, $pattern2, "")

# Remove old poster buttons / links that may remain.
$html = [regex]::Replace(
    $html,
    '(?is)<button[^>]*>[^<]*FREE POSTER DOWNLOAD[^<]*</button>',
    ""
)

$html = [regex]::Replace(
    $html,
    '(?is)<a[^>]*>\s*DOWNLOAD POSTER\s*</a>',
    ""
)

Write-Host "PASS - Existing poster controls removed" -ForegroundColor Green

# ------------------------------------------------------------
# REMOVE EXISTING CROSS-CONTAMINATION POSTER IMAGE TAGS
# ------------------------------------------------------------

$html = [regex]::Replace(
    $html,
    '(?is)<img[^>]*cross-contamination-poster[^>]*>',
    ""
)

Write-Host "PASS - Old poster image tags removed" -ForegroundColor Green

# ------------------------------------------------------------
# REMOVE OLD POSTER SCRIPT IF PRESENT
# ------------------------------------------------------------

$html = [regex]::Replace(
    $html,
    '(?is)<script[^>]*>.*?togglePosterInfomatic.*?</script>',
    ""
)

Write-Host "PASS - Old poster script removed" -ForegroundColor Green

# ------------------------------------------------------------
# NEW POSTER INFOMATIC
# IMPORTANT:
# This entire block is inserted immediately before </body>
# ------------------------------------------------------------

$infomatic = @'

<!-- =========================================================
     FREE POSTER DOWNLOAD
     CROSS-CONTAMINATION PREVENTION
     ========================================================= -->

<section id="free-poster-download"
style="margin:50px auto 20px;max-width:1000px;background:#0a0a0a;border:2px solid #d4af37;border-radius:12px;padding:22px;box-shadow:0 8px 30px rgba(0,0,0,.35);text-align:center;color:#ffffff;">

    <button
        type="button"
        onclick="togglePosterInfomatic()"
        aria-expanded="false"
        aria-controls="poster-infomatic-panel"
        style="display:inline-block;width:100%;max-width:600px;padding:16px 22px;background:#d4af37;color:#0a0a0a;border:0;border-radius:8px;font-size:18px;font-weight:800;letter-spacing:.5px;cursor:pointer;">
        FREE POSTER DOWNLOAD
    </button>

    <div
        id="poster-infomatic-panel"
        hidden
        style="margin-top:24px;">

        <h2 style="color:#d4af37;margin:0 0 15px;">
            Cross-Contamination Prevention
        </h2>

        <p style="margin:0 auto 20px;max-width:750px;line-height:1.7;">
            Download the quick-reference hospitality training poster by Nigel A Thomas.
        </p>

        <div style="background:#111111;border:1px solid #d4af37;border-radius:10px;padding:15px;">

            <img
                src="assets/cross-contamination-poster.jpg"
                alt="Cross-Contamination Prevention training poster by Nigel A Thomas"
                loading="lazy"
                style="display:block;width:100%;max-width:900px;height:auto;margin:0 auto 18px;border-radius:6px;">

            <a
                href="assets/cross-contamination-poster.jpg"
                download="Nigel-A-Thomas-Cross-Contamination-Prevention-Poster.jpg"
                style="display:inline-block;padding:13px 22px;background:#d4af37;color:#0a0a0a;text-decoration:none;border-radius:7px;font-weight:800;">
                DOWNLOAD POSTER
            </a>

            <p style="margin:16px 0 0;color:#d4af37;font-weight:700;">
                Nigel A Thomas
            </p>

        </div>

        <div
            class="related-management-links"
            style="margin-top:30px;padding-top:22px;border-top:1px solid #d4af37;">

            <h3 style="color:#d4af37;margin:0 0 15px;">
                Related Hospitality Management Resources
            </h3>

            <p style="line-height:1.9;margin:0;">

                <a
                    href="../haccp-hazard-analysis-critical-control-points.html"
                    style="color:#d4af37;font-weight:700;">
                    HACCP Hazard Analysis &amp; Critical Control Points
                </a>

                &nbsp;&bull;&nbsp;

                <a
                    href="../haccp-kitchen-checklist.html"
                    style="color:#d4af37;font-weight:700;">
                    HACCP Kitchen Checklist
                </a>

                &nbsp;&bull;&nbsp;

                <a
                    href="../receiving-food-safely.html"
                    style="color:#d4af37;font-weight:700;">
                    Receiving Food Safely
                </a>

                &nbsp;&bull;&nbsp;

                <a
                    href="../temperature-log-templates.html"
                    style="color:#d4af37;font-weight:700;">
                    Temperature Log Templates
                </a>

            </p>

        </div>

    </div>

</section>

<script>
function togglePosterInfomatic() {
    var panel = document.getElementById('poster-infomatic-panel');
    var button = document.querySelector('#free-poster-download button');

    if (!panel || !button) {
        return;
    }

    if (panel.hasAttribute('hidden')) {
        panel.removeAttribute('hidden');
        button.setAttribute('aria-expanded', 'true');
    } else {
        panel.setAttribute('hidden', '');
        button.setAttribute('aria-expanded', 'false');
    }
}
</script>

<!-- END FREE POSTER DOWNLOAD -->

'@

# ------------------------------------------------------------
# INSERT AT VERY BOTTOM OF BODY
# ------------------------------------------------------------

if ($html -match '(?i)</body>') {

    $html = [regex]::Replace(
        $html,
        '(?i)</body>',
        "$infomatic`r`n</body>",
        1
    )

    Write-Host "PASS - Infomatic inserted immediately before </body>" -ForegroundColor Green

} else {

    Write-Host "FAIL - </body> tag not found" -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------
# SAVE UTF-8 WITHOUT BOM
# ------------------------------------------------------------

[System.IO.File]::WriteAllText(
    (Resolve-Path $file),
    $html,
    $utf8
)

Write-Host "PASS - File saved as UTF-8 without BOM" -ForegroundColor Green

# ------------------------------------------------------------
# RE-READ FOR VERIFICATION
# ------------------------------------------------------------

$check = [System.IO.File]::ReadAllText(
    (Resolve-Path $file),
    $utf8
)

$posterRefs = (
    [regex]::Matches(
        $check,
        'assets/cross-contamination-poster\.jpg',
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )
).Count

$freeButtons = (
    [regex]::Matches(
        $check,
        'FREE POSTER DOWNLOAD',
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )
).Count

$downloadLinks = (
    [regex]::Matches(
        $check,
        'DOWNLOAD POSTER',
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )
).Count

$bodyPos = $check.LastIndexOf("</body>")
$posterPos = $check.LastIndexOf("FREE POSTER DOWNLOAD")

# ------------------------------------------------------------
# VERIFICATION
# ------------------------------------------------------------

Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " VERIFICATION" -ForegroundColor Yellow
Write-Host "============================================================"

Write-Host "Poster references : $posterRefs"
Write-Host "Poster button text: $freeButtons"
Write-Host "Download link text: $downloadLinks"

if ($posterRefs -ge 1) {
    Write-Host "PASS - Correct poster path exists" -ForegroundColor Green
} else {
    Write-Host "FAIL - Poster path missing" -ForegroundColor Red
}

if ($freeButtons -eq 1) {
    Write-Host "PASS - Exactly one FREE POSTER DOWNLOAD button" -ForegroundColor Green
} else {
    Write-Host "WARNING - FREE POSTER DOWNLOAD appears $freeButtons times" -ForegroundColor Yellow
}

if ($downloadLinks -ge 1) {
    Write-Host "PASS - DOWNLOAD POSTER link exists" -ForegroundColor Green
} else {
    Write-Host "FAIL - DOWNLOAD POSTER link missing" -ForegroundColor Red
}

if ($posterPos -lt $bodyPos) {
    Write-Host "PASS - Poster infomatic is before </body>" -ForegroundColor Green
} else {
    Write-Host "FAIL - Poster infomatic placement is wrong" -ForegroundColor Red
}

# ------------------------------------------------------------
# CHECK POSTER BLOCK IS NEAR THE END
# ------------------------------------------------------------

$distanceFromBody = $bodyPos - $posterPos

Write-Host "Distance from closing body tag: $distanceFromBody characters"

if ($distanceFromBody -lt 15000) {
    Write-Host "PASS - Poster block is positioned near page bottom" -ForegroundColor Green
} else {
    Write-Host "WARNING - Poster block may not be near the bottom" -ForegroundColor Yellow
}

# ------------------------------------------------------------
# GIT STATUS ONLY - NO PUSH
# ------------------------------------------------------------

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " GIT STATUS - NO PUSH PERFORMED" -ForegroundColor Cyan
Write-Host "============================================================"

git status --short

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " REPAIR SCRIPT FINISHED" -ForegroundColor Green
Write-Host "============================================================"
Write-Host ""
Write-Host "NO GIT PUSH WAS PERFORMED."
Write-Host "Paste the complete output into ChatGPT for verification."
Write-Host ""