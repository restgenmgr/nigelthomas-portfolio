<#
.SYNOPSIS
    Audits canonical tags across an HTML site for missing, mismatched, or duplicate canonicals.

.DESCRIPTION
    Scans all .html files under -Path, extracts <link rel="canonical" href="..."> if present,
    and reports:
      - Files with NO canonical tag
      - Files whose canonical href does not match their own expected site URL
      - Canonical targets that are claimed by more than one file (duplicates)

    Produces a timestamped CSV audit log. Read-only by default -- makes no changes to any file.

.PARAMETER Path
    Root directory of the site to scan. Defaults to current directory.

.PARAMETER SiteBaseUrl
    Base URL of the live site, used to compute each file's "expected" canonical
    (e.g. https://www.nigelthomas.live). Used only for the mismatch check.

.PARAMETER OutputCsv
    Path for the CSV report. Defaults to a timestamped file in the current directory.

.EXAMPLE
    .\Audit-CanonicalTags.ps1 -Path "C:\Users\admin\Desktop\nigelthomas-portfolio" -SiteBaseUrl "https://www.nigelthomas.live"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Path = ".",

    [Parameter(Mandatory = $false)]
    [string]$SiteBaseUrl = "https://www.nigelthomas.live",

    [Parameter(Mandatory = $false)]
    [string]$OutputCsv
)

$ErrorActionPreference = "Stop"

if (-not $OutputCsv) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $OutputCsv = Join-Path (Get-Location) "CanonicalAudit_$timestamp.csv"
}

$SiteBaseUrl = $SiteBaseUrl.TrimEnd('/')

Write-Host "Scanning HTML files under: $Path" -ForegroundColor Cyan
$htmlFiles = Get-ChildItem -Path $Path -Filter *.html -Recurse -File

if ($htmlFiles.Count -eq 0) {
    Write-Warning "No .html files found under $Path"
    return
}

Write-Host "Found $($htmlFiles.Count) HTML files. Analyzing canonical tags..." -ForegroundColor Cyan

$canonicalRegex = [regex]'(?is)<link[^>]+rel\s*=\s*["'']canonical["''][^>]*>'
$hrefRegex      = [regex]'(?is)href\s*=\s*["'']([^"'']+)["'']'

$results = New-Object System.Collections.Generic.List[Object]
$canonicalMap = @{}   # canonicalTargetUrl -> list of files claiming it

$fileCount = 0
foreach ($file in $htmlFiles) {
    $fileCount++
    if ($fileCount % 50 -eq 0) {
        Write-Host "  ...processed $fileCount / $($htmlFiles.Count)" -ForegroundColor DarkGray
    }

    try {
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
    }
    catch {
        $results.Add([PSCustomObject]@{
            FileName        = $file.Name
            RelativePath    = $file.FullName.Substring($Path.Length).TrimStart('\','/')
            HasCanonical    = "ERROR"
            CanonicalHref   = ""
            ExpectedUrl     = ""
            Mismatch        = ""
            Note            = "Could not read file: $($_.Exception.Message)"
        })
        continue
    }

    $relativePath = $file.FullName.Substring((Resolve-Path $Path).Path.Length).TrimStart('\','/')
    $relativeUrlPath = ($relativePath -replace '\\','/')
    $expectedUrl = "$SiteBaseUrl/$relativeUrlPath"

    $canonicalMatch = $canonicalRegex.Match($content)

    if (-not $canonicalMatch.Success) {
        $results.Add([PSCustomObject]@{
            FileName      = $file.Name
            RelativePath  = $relativePath
            HasCanonical  = "No"
            CanonicalHref = ""
            ExpectedUrl   = $expectedUrl
            Mismatch      = ""
            Note          = "Missing canonical tag"
        })
        continue
    }

    $hrefMatch = $hrefRegex.Match($canonicalMatch.Value)
    $hrefValue = if ($hrefMatch.Success) { $hrefMatch.Groups[1].Value } else { "" }

    $normalizedHref = $hrefValue.TrimEnd('/')
    $normalizedExpected = $expectedUrl.TrimEnd('/')
    $isMismatch = ($normalizedHref -ne "") -and ($normalizedHref -ne $normalizedExpected)

    $results.Add([PSCustomObject]@{
        FileName      = $file.Name
        RelativePath  = $relativePath
        HasCanonical  = "Yes"
        CanonicalHref = $hrefValue
        ExpectedUrl   = $expectedUrl
        Mismatch      = if ($isMismatch) { "Yes" } else { "No" }
        Note          = ""
    })

    if ($hrefValue -ne "") {
        if (-not $canonicalMap.ContainsKey($hrefValue)) {
            $canonicalMap[$hrefValue] = New-Object System.Collections.Generic.List[string]
        }
        $canonicalMap[$hrefValue].Add($relativePath)
    }
}

# Flag duplicates: same canonical target claimed by 2+ different files
$duplicateTargets = $canonicalMap.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }

foreach ($entry in $results) {
    if ($entry.CanonicalHref -ne "" -and $canonicalMap.ContainsKey($entry.CanonicalHref)) {
        if ($canonicalMap[$entry.CanonicalHref].Count -gt 1) {
            $entry.Note = "Duplicate canonical target (shared with $($canonicalMap[$entry.CanonicalHref].Count - 1) other file(s))"
        }
    }
}

$results | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8

# Summary
$missingCount   = ($results | Where-Object { $_.HasCanonical -eq "No" }).Count
$mismatchCount  = ($results | Where-Object { $_.Mismatch -eq "Yes" }).Count
$duplicateCount = ($duplicateTargets | Measure-Object).Count
$errorCount     = ($results | Where-Object { $_.HasCanonical -eq "ERROR" }).Count

Write-Host ""
Write-Host "=== Canonical Tag Audit Summary ===" -ForegroundColor Green
Write-Host "Total files scanned:         $($htmlFiles.Count)"
Write-Host "Missing canonical tag:       $missingCount"
Write-Host "Canonical href mismatch:     $mismatchCount"
Write-Host "Duplicate canonical targets: $duplicateCount (target URLs claimed by 2+ files)"
Write-Host "Files with read errors:      $errorCount"
Write-Host ""
Write-Host "Full report written to: $OutputCsv" -ForegroundColor Cyan

if ($duplicateTargets.Count -gt 0) {
    Write-Host ""
    Write-Host "--- Duplicate canonical targets (first 10) ---" -ForegroundColor Yellow
    $duplicateTargets | Select-Object -First 10 | ForEach-Object {
        Write-Host "  Target: $($_.Key)"
        $_.Value | ForEach-Object { Write-Host "    -> $_" }
    }
}
