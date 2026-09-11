$ErrorActionPreference = "Stop"

$repo = "C:\Users\admin\Desktop\nigelthomas-portfolio"
$file = Join-Path $repo "blog\cross-contamination-prevention.html"

Set-Location $repo

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " CROSS-CONTAMINATION MOJIBAKE REPAIR - SAFE VERSION" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

if (-not (Test-Path $file)) {
    Write-Host "FAIL - HTML file not found." -ForegroundColor Red
    exit 1
}

Write-Host "PASS - HTML file found" -ForegroundColor Green

$utf8 = New-Object System.Text.UTF8Encoding($false)
$cp1252 = [System.Text.Encoding]::GetEncoding(1252)

$html = [System.IO.File]::ReadAllText(
    (Resolve-Path $file),
    $utf8
)

Write-Host "Original HTML length: $($html.Length)"

# ------------------------------------------------------------
# BACKUP
# ------------------------------------------------------------

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = "$file.backup-mojibake-$stamp"

[System.IO.File]::Copy(
    (Resolve-Path $file),
    $backup,
    $false
)

Write-Host "PASS - Backup created:" -ForegroundColor Green
Write-Host $backup

# ------------------------------------------------------------
# MOJIBAKE SCORE
# Uses ASCII-only regular expressions.
# ------------------------------------------------------------

function Get-MojibakeScore {
    param(
        [string]$Text
    )

    $patterns = @(
        'Ã',
        'Â',
        'â',
        'ð',
        'ƒ',
        '‚',
        '€™',
        '€œ',
        'â€',
        'Ãƒ',
        'Ã‚',
        'Ã¢'
    )

    $score = 0

    foreach ($p in $patterns) {
        $score += ([regex]::Matches(
            $Text,
            [regex]::Escape($p)
        )).Count
    }

    return $score
}

$initialScore = Get-MojibakeScore $html

Write-Host ""
Write-Host "Initial mojibake score: $initialScore"

# ------------------------------------------------------------
# CONTROLLED REPAIR
# ------------------------------------------------------------

$current = $html
$currentScore = $initialScore

for ($pass = 1; $pass -le 5; $pass++) {

    Write-Host ""
    Write-Host "------------------------------------------------------------"
    Write-Host "REPAIR PASS $pass"
    Write-Host "------------------------------------------------------------"

    try {
        $bytes = $cp1252.GetBytes($current)
        $candidate = $utf8.GetString($bytes)
        $candidateScore = Get-MojibakeScore $candidate
    }
    catch {
        Write-Host "PASS $pass failed during conversion." -ForegroundColor Yellow
        continue
    }

    Write-Host "Before score: $currentScore"
    Write-Host "After score : $candidateScore"

    if ($candidateScore -lt $currentScore) {

        $current = $candidate
        $currentScore = $candidateScore

        Write-Host "PASS - Repair pass accepted." -ForegroundColor Green

    }
    else {

        Write-Host "PASS - No further improvement; stopping." -ForegroundColor Yellow
        break
    }
}

$html = $current

# ------------------------------------------------------------
# SAFE HTML ENTITY CLEANUP
# ASCII ONLY
# ------------------------------------------------------------

$html = $html.Replace(
    [char]0x00C2 + [char]0x00B7,
    "&bull;"
)

$html = $html.Replace(
    [char]0x00E2 + [char]0x20AC + [char]0x00A2 + [char]0x00E2 + [char]0x20AC + [char]0x00A2,
    "&bull;"
)

# Common smart punctuation entities
$html = $html.Replace(
    [char]0x00E2 + [char]0x20AC + [char]0x2122,
    "&#8217;"
)

# ------------------------------------------------------------
# SAVE UTF-8 WITHOUT BOM
# ------------------------------------------------------------

[System.IO.File]::WriteAllText(
    (Resolve-Path $file),
    $html,
    $utf8
)

Write-Host ""
Write-Host "PASS - HTML saved as UTF-8 without BOM" -ForegroundColor Green

# ------------------------------------------------------------
# RELOAD AND VERIFY
# ------------------------------------------------------------

$check = [System.IO.File]::ReadAllText(
    (Resolve-Path $file),
    $utf8
)

$finalScore = Get-MojibakeScore $check

Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " ENCODING VERIFICATION" -ForegroundColor Yellow
Write-Host "============================================================"

Write-Host "Original score: $initialScore"
Write-Host "Final score   : $finalScore"

if ($finalScore -lt $initialScore) {
    Write-Host "PASS - Mojibake reduced." -ForegroundColor Green
}
elseif ($initialScore -eq 0) {
    Write-Host "PASS - No mojibake detected." -ForegroundColor Green
}
else {
    Write-Host "WARNING - Mojibake may still remain." -ForegroundColor Yellow
}

# ------------------------------------------------------------
# POSTER STRUCTURE
# ------------------------------------------------------------

$buttonCount = (
    [regex]::Matches(
        $check,
        '(?is)<button[^>]*>.*?FREE POSTER DOWNLOAD.*?</button>'
    )
).Count

$sectionCount = (
    [regex]::Matches(
        $check,
        '(?is)<section[^>]*id=["'']free-poster-download["'']'
    )
).Count

$imageCount = (
    [regex]::Matches(
        $check,
        '(?is)<img[^>]*cross-contamination-poster\.jpg[^>]*>'
    )
).Count

$downloadCount = (
    [regex]::Matches(
        $check,
        '(?is)<a[^>]*href=["'']assets/cross-contamination-poster\.jpg["''][^>]*download[^>]*>'
    )
).Count

Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " POSTER VERIFICATION" -ForegroundColor Yellow
Write-Host "============================================================"

Write-Host "FREE POSTER button : $buttonCount"
Write-Host "Infomatic sections  : $sectionCount"
Write-Host "Poster image tags   : $imageCount"
Write-Host "Download links      : $downloadCount"

if ($buttonCount -eq 1) {
    Write-Host "PASS - One poster button" -ForegroundColor Green
}

if ($sectionCount -eq 1) {
    Write-Host "PASS - One infomatic section" -ForegroundColor Green
}

if ($imageCount -eq 1) {
    Write-Host "PASS - One poster image" -ForegroundColor Green
}

if ($downloadCount -eq 1) {
    Write-Host "PASS - One download link" -ForegroundColor Green
}

# ------------------------------------------------------------
# POSITION CHECK
# ------------------------------------------------------------

$bodyPos = $check.LastIndexOf(
    "</body>",
    [System.StringComparison]::OrdinalIgnoreCase
)

$posterPos = $check.LastIndexOf(
    "FREE POSTER DOWNLOAD",
    [System.StringComparison]::OrdinalIgnoreCase
)

Write-Host ""

if ($bodyPos -gt 0 -and $posterPos -gt 0 -and $posterPos -lt $bodyPos) {

    $distance = $bodyPos - $posterPos

    Write-Host "PASS - Poster control is before </body>" -ForegroundColor Green
    Write-Host "Distance from </body>: $distance characters"

}
else {

    Write-Host "WARNING - Poster position could not be confirmed." -ForegroundColor Yellow
}

# ------------------------------------------------------------
# GIT STATUS
# ------------------------------------------------------------

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " GIT STATUS - NO COMMIT / NO PUSH" -ForegroundColor Cyan
Write-Host "============================================================"

git status --short

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " SAFE MOJIBAKE REPAIR FINISHED" -ForegroundColor Green
Write-Host "============================================================"

Write-Host ""
Write-Host "NO GIT COMMIT WAS PERFORMED."
Write-Host "NO GIT PUSH WAS PERFORMED."
Write-Host ""
Write-Host "Paste the COMPLETE output into ChatGPT."