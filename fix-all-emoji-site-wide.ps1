# ============================================================
# Convert all emoji in every .html file to HTML numeric entities
# (e.g. the chef emoji becomes &#128104;&#8205;&#127859;)
# Entities are plain ASCII, so they survive PowerShell, Git,
# GitHub web upload, and Windows-1252 misreads without corrupting.
# ============================================================

$root = Get-Location
$backupDir = Join-Path $root ("emoji-fix-backup-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
New-Item -ItemType Directory -Path $backupDir | Out-Null

$utf8NoBom = New-Object System.Text.UTF8Encoding $false

# Matches: emoji surrogate pairs (astral plane, e.g. most emoji),
# plus common symbol-range emoji, variation selector, ZWJ, and arrows.
$pattern = [regex]'(?:[\uD800-\uDBFF][\uDC00-\uDFFF])|[\u2600-\u27BF\u2B00-\u2BFF\uFE0F\u200D\u2190-\u21FF]'

$evaluator = {
    param($match)
    $s = $match.Value
    if ($s.Length -eq 2 -and [char]::IsHighSurrogate($s[0]) -and [char]::IsLowSurrogate($s[1])) {
        $codepoint = [char]::ConvertToUtf32($s[0], $s[1])
    } else {
        $codepoint = [int]$s[0]
    }
    return "&#$codepoint;"
}

$htmlFiles = Get-ChildItem -Path $root -Filter *.html -File -Recurse |
    Where-Object { $_.FullName -notmatch "\\(\.git|node_modules|emoji-fix-backup)" }

$totalFilesChanged = 0
$totalEmojiReplaced = 0

foreach ($file in $htmlFiles) {
    $content = [System.IO.File]::ReadAllText($file.FullName, $utf8NoBom)
    $matches = $pattern.Matches($content)

    if ($matches.Count -gt 0) {
        # Backup original before touching it
        Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $backupDir $file.Name) -Force

        $newContent = $pattern.Replace($content, $evaluator)
        [System.IO.File]::WriteAllText($file.FullName, $newContent, $utf8NoBom)

        $totalFilesChanged++
        $totalEmojiReplaced += $matches.Count
        Write-Host "Fixed $($matches.Count) emoji in $($file.Name)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Done. $totalEmojiReplaced emoji converted across $totalFilesChanged files." -ForegroundColor Cyan
Write-Host "Originals backed up to: $backupDir" -ForegroundColor Cyan
Write-Host "Review a few changed files, then: git add . ; git commit -m 'Convert all emoji to HTML entities to prevent encoding corruption' ; git push origin main ; vercel --prod --force" -ForegroundColor Cyan
