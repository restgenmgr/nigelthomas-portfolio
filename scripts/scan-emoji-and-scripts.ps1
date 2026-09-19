<#
.SYNOPSIS
    Dry-run scan: finds all emoji characters and suspicious/duplicate <script> tags
    across every HTML file. Makes NO changes -- report only.

.DESCRIPTION
    Emoji detection covers the common emoji Unicode blocks (2600-27BF, 2B00-2BFF,
    variation selectors, ZWJ, and the D83C-D83E surrogate-pair range covering most
    pictographs/emoticons/transport/supplemental symbols). Arrows (like the "Read
    More ->" ones) are NOT touched -- only genuine emoji characters.

    Script-tag scan flags:
      - Files with more than one <script> tag pointing to the exact same src URL
      - Empty <script></script> tags
      - Any leftover raw PowerShell/JS-looking text sitting outside a real <script>
        block (the same bug pattern we found earlier in shake-vs-smoothie.html)
#>

$path = "C:\Users\admin\Desktop\nigelthomas-portfolio"
$excludeFolders = @("_mojibake_backups", "_metadata_backups", "encoding_backup", "encoding_fix2_backup")

$emojiPattern = '[\u2600-\u27BF\u2B00-\u2BFF\uFE0F\u200D]|[\uD83C-\uD83E][\uDC00-\uDFFF]'

$htmlFiles = Get-ChildItem -Path $path -Filter *.html -Recurse -File | Where-Object {
    $fp = $_.FullName
    -not ($excludeFolders | Where-Object { $fp -like "*\$_\*" })
}

Write-Host "Scanning $($htmlFiles.Count) HTML files..." -ForegroundColor Cyan
Write-Host ""

$emojiResults = @()
$duplicateScriptResults = @()
$emptyScriptResults = @()
$leakedScriptResults = @()

foreach ($f in $htmlFiles) {
    $content = Get-Content -Raw $f.FullName -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    $rel = $f.FullName.Substring($path.Length).TrimStart('\')

    # --- Emoji count ---
    $emojiMatches = [regex]::Matches($content, $emojiPattern)
    if ($emojiMatches.Count -gt 0) {
        $uniqueEmoji = ($emojiMatches | ForEach-Object { $_.Value } | Sort-Object -Unique) -join ' '
        $emojiResults += [PSCustomObject]@{
            RelativePath = $rel
            Count        = $emojiMatches.Count
            Sample       = $uniqueEmoji
        }
    }

    # --- Duplicate script src ---
    $srcMatches = [regex]::Matches($content, '<script[^>]+src=["'']([^"'']+)["'']')
    $srcs = $srcMatches | ForEach-Object { $_.Groups[1].Value }
    $dupes = $srcs | Group-Object | Where-Object { $_.Count -gt 1 }
    foreach ($d in $dupes) {
        $duplicateScriptResults += [PSCustomObject]@{
            RelativePath = $rel
            ScriptSrc    = $d.Name
            Occurrences  = $d.Count
        }
    }

    # --- Empty script tags ---
    if ($content -match '<script[^>]*>\s*</script>') {
        $emptyScriptResults += $rel
    }

    # --- Leaked script-looking text (heuristic: PowerShell/JS keywords outside a <script> block) ---
    if ($content -match '# Full script to overwrite' -or $content -match '\$htmlContent\s*=\s*@''') {
        $leakedScriptResults += $rel
    }
}

Write-Host "=== EMOJI RESULTS ===" -ForegroundColor Yellow
Write-Host "Files containing emoji: $($emojiResults.Count)" -ForegroundColor Cyan
$emojiResults | Sort-Object Count -Descending | Select-Object -First 20 | Format-Table -AutoSize
$totalEmoji = ($emojiResults | Measure-Object -Property Count -Sum).Sum
Write-Host "Total emoji characters found sitewide: $totalEmoji"

Write-Host ""
Write-Host "=== DUPLICATE SCRIPT SRC RESULTS ===" -ForegroundColor Yellow
Write-Host "Duplicate script tag instances: $($duplicateScriptResults.Count)" -ForegroundColor Cyan
$duplicateScriptResults | Select-Object -First 20 | Format-Table -AutoSize

Write-Host ""
Write-Host "=== EMPTY SCRIPT TAGS ===" -ForegroundColor Yellow
Write-Host "Files with empty <script></script>: $($emptyScriptResults.Count)" -ForegroundColor Cyan
$emptyScriptResults | Select-Object -First 20

Write-Host ""
Write-Host "=== LEAKED SCRIPT TEXT (same bug as shake-vs-smoothie) ===" -ForegroundColor Yellow
Write-Host "Files with leaked script text: $($leakedScriptResults.Count)" -ForegroundColor Cyan
$leakedScriptResults

# Export full results for review
$emojiResults | Export-Csv "$path\EmojiScan_$(Get-Date -Format yyyyMMdd_HHmmss).csv" -NoTypeInformation -Encoding UTF8
$duplicateScriptResults | Export-Csv "$path\DuplicateScriptScan_$(Get-Date -Format yyyyMMdd_HHmmss).csv" -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "Full CSV reports written to repo root." -ForegroundColor Green
