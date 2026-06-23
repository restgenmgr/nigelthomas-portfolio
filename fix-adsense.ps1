# =====================================================================
#  fix-adsense.ps1
#  Ensures ONLY the correct AdSense script is on every page:
#     ca-pub-8127243414384620
#  Removes any copy of the WRONG id that may have been added earlier:
#     ca-pub-4282121192943910
#
#  Uses true UTF-8 (no BOM) read/write so emojis, em-dashes, and the
#  copyright symbol are NOT corrupted this time.
#
#  USAGE:
#    cd C:\Users\admin\Desktop\nigelthomas-portfolio
#    powershell -ExecutionPolicy Bypass -File fix-adsense.ps1
#
#  Then:
#    git diff --stat      (quick summary check)
#    git diff              (press q to exit pager)
#    git add .
#    git commit -m "Add correct AdSense verification script (UTF-8 safe)"
#    git push
# =====================================================================

$RepoPath      = Get-Location
$CorrectPubId  = "ca-pub-8127243414384620"
$WrongPubId    = "ca-pub-4282121192943910"
$CorrectTag    = '<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=' + $CorrectPubId + '" crossorigin="anonymous"></script>'

# UTF-8 encoding WITHOUT a byte-order-mark, to match how these files were originally saved
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

Write-Host "Scanning .html files in: $RepoPath" -ForegroundColor Cyan

$htmlFiles = Get-ChildItem -Path $RepoPath -Recurse -Include *.html -File |
    Where-Object { $_.FullName -notmatch '\\\.git\\' }

if (-not $htmlFiles) {
    Write-Host "No .html files found. Are you in the right folder?" -ForegroundColor Yellow
    return
}

$cleanedCount    = 0
$reinsertedCount = 0
$untouchedCount  = 0

foreach ($file in $htmlFiles) {

    # Read as TRUE UTF-8 explicitly (this is the critical fix)
    $content  = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
    $original = $content
    $changed  = $false

    # 1) Remove any script block carrying the WRONG pub id
    $wrongPattern = '<script[^>]*' + [regex]::Escape($WrongPubId) + '[^>]*>.*?</script>\s*'
    if ([regex]::IsMatch($content, $wrongPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)) {
        $content = [regex]::Replace($content, $wrongPattern, "", [System.Text.RegularExpressions.RegexOptions]::Singleline)
        $changed = $true
    }

    # 2) Remove duplicate copies of the CORRECT tag (keep none for now, we re-add exactly one below)
    $correctScriptPattern = '<script[^>]*' + [regex]::Escape($CorrectPubId) + '[^>]*>.*?</script>\s*'
    $correctMatches = [regex]::Matches($content, $correctScriptPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if ($correctMatches.Count -ge 1) {
        $content = [regex]::Replace($content, $correctScriptPattern, "", [System.Text.RegularExpressions.RegexOptions]::Singleline)
        $changed = $true
    }

    # 3) Insert exactly one correct tag, right before </head>
    if ($content -match '</head>') {
        $content = $content -replace '</head>', "    $CorrectTag`r`n</head>"
        $changed = $true
    }
    else {
        Write-Host "  [WARNING - no </head> found] $($file.Name)" -ForegroundColor Red
    }

    # Collapse triple+ blank lines left behind by removals
    $content = $content -replace '(\r?\n){3,}', "`r`n`r`n"

    if ($content -ne $original) {
        [System.IO.File]::WriteAllText($file.FullName, $content, $Utf8NoBom)
        Write-Host "  [fixed] $($file.Name)" -ForegroundColor Green
        $cleanedCount++
    }
    else {
        Write-Host "  [untouched] $($file.Name)" -ForegroundColor DarkGray
        $untouchedCount++
    }
}

Write-Host ""
Write-Host "Done." -ForegroundColor Cyan
Write-Host "  Fixed files:      $cleanedCount" -ForegroundColor Green
Write-Host "  Untouched files:  $untouchedCount" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Now run: git diff --stat   (then git diff to inspect, press q to exit)" -ForegroundColor Cyan
