# ============================================================
# fix-encoding-sitewide.ps1  (v2)
#
# Finds and repairs UTF-8-interpreted-as-Windows-1252 mojibake,
# including MULTI-LAYER corruption (double/triple misencoding),
# by iterating the repair per file until it stabilizes.
#
# Also flags files that contain embedded leftover script text
# (e.g. a stray "# Create ..." comment or "Out-File" / "Write-Host"
# line saved directly into the HTML) as STRUCTURAL issues that need
# manual review - these are NOT auto-fixed, since they're a content
# problem, not an encoding problem.
#
# SAFE BY DEFAULT: running with no switches only SCANS and writes
# a report. Nothing is modified until you re-run with -Apply.
#
# Usage:
#   .\fix-encoding-sitewide.ps1                 # scan only, writes report
#   .\fix-encoding-sitewide.ps1 -Apply           # actually fixes files
#
# Excludes: .git, node_modules, any backup-html-* folder
# ============================================================

param(
    [switch]$Apply,
    [int]$MaxIterations = 5
)

$ErrorActionPreference = "Stop"
$repoRoot = Get-Location
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportPath = Join-Path $repoRoot "encoding-scan-report-$timestamp.txt"
$backupRoot = Join-Path $repoRoot "backup-html-$timestamp"

Write-Host "=== Encoding Corruption Scan (v2 - multi-layer aware) ===" -ForegroundColor Cyan
Write-Host "Mode: $(if ($Apply) { 'APPLY (files will be modified)' } else { 'SCAN ONLY (report will be written, nothing changed)' })" -ForegroundColor Yellow

$files = Get-ChildItem -Path $repoRoot -Recurse -Filter "*.html" -File |
    Where-Object {
        $_.FullName -notmatch "\\\.git\\" -and
        $_.FullName -notmatch "\\node_modules\\" -and
        $_.FullName -notmatch "\\backup-html-"
    }

Write-Host "Scanning $($files.Count) HTML files...`n"

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$win1252 = [System.Text.Encoding]::GetEncoding(1252)
$indicatorPattern = [regex]"[ÂÃâ]"

# Patterns that indicate leftover script text embedded in the HTML content
# (not an encoding problem - a content problem)
$scriptLeakPatterns = @(
    "Out-File\s+-FilePath",
    "Write-Host\s+[`"']",
    "^\s*#\s*Create\s+",
    "ForegroundColor\s+(Green|Red|Yellow|Cyan)"
)

$report = New-Object System.Collections.Generic.List[string]
$report.Add("Encoding Corruption Scan Report (v2) - $timestamp")
$report.Add("Repo: $repoRoot")
$report.Add("Mode: $(if ($Apply) { 'APPLY' } else { 'SCAN ONLY' })")
$report.Add("=" * 70)
$report.Add("")

$filesWithIssues = 0
$filesFixed = 0
$filesSkippedRisky = 0
$filesFlaggedStructural = 0

foreach ($file in $files) {

    $original = [System.IO.File]::ReadAllText($file.FullName)
    $relPath = $file.FullName.Substring($repoRoot.Path.Length).TrimStart('\')

    # --- Check for embedded script-leak content first (structural issue) ---
    $hasScriptLeak = $false
    foreach ($pattern in $scriptLeakPatterns) {
        if ($original -match $pattern) {
            $hasScriptLeak = $true
            break
        }
    }
    if ($hasScriptLeak) {
        $filesFlaggedStructural++
        $report.Add("STRUCTURAL ISSUE (needs manual review - NOT auto-fixed): $relPath")
        $report.Add("  This file appears to contain leftover script text embedded in its HTML content.")
        $report.Add("  Open it and check for stray lines like '# Create ...', 'Out-File -FilePath ...', or 'Write-Host ...'.")
        $report.Add("")
    }

    if (-not $indicatorPattern.IsMatch($original)) {
        continue
    }

    # --- Iteratively repair multi-layer mojibake ---
    $current = $original
    $iterations = 0
    $failed = $false
    $originalReplacementCount = ([regex]::Matches($original, [char]0xFFFD)).Count
    $previousReplacementCount = $originalReplacementCount

    while ($indicatorPattern.IsMatch($current) -and $iterations -lt $MaxIterations) {
        try {
            $bytes = $win1252.GetBytes($current)
            $next = [System.Text.Encoding]::UTF8.GetString($bytes)
        } catch {
            $failed = $true
            break
        }

        $nextReplacementCount = ([regex]::Matches($next, [char]0xFFFD)).Count
        if ($nextReplacementCount -gt $previousReplacementCount) {
            # This iteration introduced new corruption artifacts - stop, don't use this step
            $failed = $true
            break
        }

        if ($next -eq $current) {
            # No further change possible - converged
            break
        }

        $current = $next
        $previousReplacementCount = $nextReplacementCount
        $iterations++
    }

    if ($failed) {
        $filesSkippedRisky++
        $report.Add("SKIPPED (repair looked unsafe after $iterations pass(es) - needs manual review): $relPath")
        $report.Add("")
        continue
    }

    # Strip a stray leaked Byte Order Mark if repair converged onto one.
    # Your site standard is UTF-8 no-BOM, so this shouldn't be preserved
    # as literal text at the start of the file.
    if ($current.Length -ge 3 -and $current.Substring(0,3) -eq "ï»¿") {
        $current = $current.Substring(3)
    }
    if ($current.Length -ge 1 -and $current[0] -eq [char]0xFEFF) {
        $current = $current.Substring(1)
    }

    if ($current -eq $original) {
        continue
    }

    $filesWithIssues++
    $report.Add("FILE: $relPath  (repaired in $iterations pass(es))")

    $origLines = $original -split "`n"
    $repLines = $current -split "`n"
    $sampleCount = 0
    for ($i = 0; $i -lt $origLines.Count -and $sampleCount -lt 3; $i++) {
        if ($i -lt $repLines.Count -and $origLines[$i] -ne $repLines[$i]) {
            $report.Add("  Line $($i+1) before: $($origLines[$i].Trim())")
            $report.Add("  Line $($i+1) after:  $($repLines[$i].Trim())")
            $sampleCount++
        }
    }
    $report.Add("")

    if ($Apply) {
        $relDir = Split-Path $relPath -Parent
        $backupDir = if ($relDir) { Join-Path $backupRoot $relDir } else { $backupRoot }
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        Copy-Item -Path $file.FullName -Destination (Join-Path $backupRoot $relPath) -Force

        [System.IO.File]::WriteAllText($file.FullName, $current, $utf8NoBom)
        $filesFixed++
    }
}

$report.Add("=" * 70)
$report.Add("SUMMARY")
$report.Add("Files scanned: $($files.Count)")
$report.Add("Files with encoding corruption found: $filesWithIssues")
$report.Add("Files skipped as risky (needs manual review): $filesSkippedRisky")
$report.Add("Files flagged with structural/script-leak issues (needs manual review): $filesFlaggedStructural")
if ($Apply) {
    $report.Add("Files fixed: $filesFixed")
    $report.Add("Backups saved to: $backupRoot")
} else {
    $report.Add("No files modified (scan-only mode). Re-run with -Apply to fix.")
}

$report | Out-File -FilePath $reportPath -Encoding utf8

Write-Host "`n=== Scan complete ===" -ForegroundColor Cyan
Write-Host "Files scanned:                  $($files.Count)"
Write-Host "Files with corruption:          $filesWithIssues" -ForegroundColor $(if ($filesWithIssues -gt 0) { "Yellow" } else { "Green" })
Write-Host "Files flagged risky (skip):     $filesSkippedRisky" -ForegroundColor $(if ($filesSkippedRisky -gt 0) { "Red" } else { "Green" })
Write-Host "Files flagged structural:       $filesFlaggedStructural" -ForegroundColor $(if ($filesFlaggedStructural -gt 0) { "Red" } else { "Green" })
if ($Apply) {
    Write-Host "Files fixed:                    $filesFixed" -ForegroundColor Green
    Write-Host "Backups saved to:               $backupRoot"
}
Write-Host "`nFull report written to: $reportPath" -ForegroundColor Cyan

if (-not $Apply -and $filesWithIssues -gt 0) {
    Write-Host "`nThis was a SCAN ONLY. Review $reportPath, then re-run with:" -ForegroundColor Yellow
    Write-Host "  .\fix-encoding-sitewide.ps1 -Apply" -ForegroundColor Yellow
}
if ($filesSkippedRisky -gt 0) {
    Write-Host "`n$filesSkippedRisky file(s) skipped - repair looked unsafe (possible deeper/different corruption). Needs manual review." -ForegroundColor Red
}
if ($filesFlaggedStructural -gt 0) {
    Write-Host "$filesFlaggedStructural file(s) contain leftover script text embedded in the HTML - NOT auto-fixed, needs manual cleanup." -ForegroundColor Red
}
