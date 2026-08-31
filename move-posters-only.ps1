<#
.SYNOPSIS
    Moves all "poster" elements to the bottom of every HTML page,
    hidden behind an "Infomatics" toggle button.
#>

[CmdletBinding()]
param(
    [string]$RootPath = (Get-Location).Path,
    [string]$PosterSelectorHint = 'poster',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
$logPath = Join-Path $RootPath "poster-move-log-$stamp.csv"
$backupPath = Join-Path $RootPath "backup-posters-$stamp"

if (-not (Test-Path $RootPath)) {
    throw "RootPath '$RootPath' does not exist."
}

$results = New-Object System.Collections.Generic.List[object]

function Add-Result {
    param([string]$Path, [int]$PostersMoved, [string]$Status, [string]$Detail)
    $results.Add([pscustomobject]@{
        File         = $Path
        PostersMoved = $PostersMoved
        Status       = $Status
        Detail       = $Detail
        Timestamp    = (Get-Date).ToString('s')
    }) | Out-Null
}

# ---------------------------------------------------------------------------
# Backup
# ---------------------------------------------------------------------------
if (-not $DryRun) {
    Write-Host "== Backing up '$RootPath' -> '$backupPath' ==" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
    Get-ChildItem -Path $RootPath -Filter *.html -Recurse -File |
        Where-Object { $_.FullName -notmatch '\\backup-' -and $_.FullName -notmatch '\\_mojibake_backups\\' -and $_.FullName -notmatch '\\_metadata_backups\\' } |
        ForEach-Object {
            $rel = $_.FullName.Substring($RootPath.Length).TrimStart('\','/')
            $dest = Join-Path $backupPath $rel
            New-Item -ItemType Directory -Path (Split-Path $dest -Parent) -Force | Out-Null
            Copy-Item $_.FullName $dest -Force
        }
    Write-Host "Backup complete." -ForegroundColor Green
} else {
    Write-Host "== DryRun: skipping backup ==" -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# Poster relocation
# ---------------------------------------------------------------------------
$PANEL_MARKER = '<!-- INFOMATICS-PANEL:v1 -->'

function Extract-Balanced {
    param([string]$Html, [string]$TagName, [int]$OpenTagStart)

    $openRe  = [regex]"(?i)<$TagName(\s[^>]*)?>"
    $closeRe = [regex]"(?i)</$TagName>"

    $m = $openRe.Match($Html, $OpenTagStart)
    if (-not $m.Success -or $m.Index -ne $OpenTagStart) { return $null }

    $depth = 1
    $pos   = $m.Index + $m.Length
    while ($depth -gt 0) {
        $nextOpen  = $openRe.Match($Html, $pos)
        $nextClose = $closeRe.Match($Html, $pos)
        if (-not $nextClose.Success) { return $null }
        if ($nextOpen.Success -and $nextOpen.Index -lt $nextClose.Index) {
            $depth++; $pos = $nextOpen.Index + $nextOpen.Length
        } else {
            $depth--; $pos = $nextClose.Index + $nextClose.Length
        }
    }
    $length = $pos - $OpenTagStart
    return @{ Text = $Html.Substring($OpenTagStart, $length); Start = $OpenTagStart; Length = $length }
}

function Move-Posters {
    param([string]$Html, [string]$SelectorHint)

    if ($Html.Contains($PANEL_MARKER)) { return $Html, 0 }

    $extracted = New-Object System.Collections.Generic.List[string]
    $workingHtml = $Html

    # Container elements (div, section, figure, aside)
    $containerTags = 'div','section','figure','aside'
    foreach ($tag in $containerTags) {
        $openRe = [regex]"(?i)<$tag(?=[\s>])([^>]*(?:class|id)\s*=\s*[""'][^""']*(?:$SelectorHint)[^""']*[""'][^>]*)>"
        $searchStart = 0
        while ($true) {
            $m = $openRe.Match($workingHtml, $searchStart)
            if (-not $m.Success) { break }
            $block = Extract-Balanced -Html $workingHtml -TagName $tag -OpenTagStart $m.Index
            if ($null -eq $block) { $searchStart = $m.Index + $m.Length; continue }
            $extracted.Add($block.Text)
            $workingHtml = $workingHtml.Remove($block.Start, $block.Length)
            $searchStart = $block.Start
        }
    }

    # Standalone <img> tags
    $imgRe = [regex]"(?i)(<a[^>]*>\s*)?<img(?=[\s>])[^>]*(?:src|alt|class)\s*=\s*[""'][^""']*(?:$SelectorHint)[^""']*[""'][^>]*/?>(\s*</a>)?"
    $imgMatches = $imgRe.Matches($workingHtml)
    for ($i = $imgMatches.Count - 1; $i -ge 0; $i--) {
        $m = $imgMatches[$i]
        $extracted.Insert(0, $m.Value)
        $workingHtml = $workingHtml.Remove($m.Index, $m.Length)
    }

    if ($extracted.Count -eq 0) { return $Html, 0 }

    $panelHtml = @"
$PANEL_MARKER
<div class="infomatics-launcher">
  <button type="button" class="infomatics-btn" aria-expanded="false" aria-controls="infomatics-panel"
    onclick="var p=document.getElementById('infomatics-panel');var open=p.classList.toggle('active');this.setAttribute('aria-expanded', open?'true':'false');">
    Infomatics
  </button>
  <div id="infomatics-panel" class="infomatics-panel">
$($extracted -join "`r`n")
  </div>
</div>
<style>
.infomatics-launcher{margin:2rem 0;}
.infomatics-btn{padding:0.6em 1.4em;border:none;border-radius:6px;background:#1f2937;color:#fff;font-weight:600;cursor:pointer;}
.infomatics-btn:hover{background:#374151;}
.infomatics-panel{display:none;margin-top:1rem;}
.infomatics-panel.active{display:block;}
</style>
"@

    if ($workingHtml -match '(?i)</body>') {
        $workingHtml = $workingHtml -replace '(?i)(</body>)', ($panelHtml -replace '\$', '$$') + "`r`n`$1"
    } else {
        $workingHtml += "`r`n$panelHtml"
    }

    return $workingHtml, $extracted.Count
}

# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------
$files = Get-ChildItem -Path $RootPath -Filter *.html -Recurse -File |
    Where-Object { $_.FullName -notmatch '\\backup-' -and $_.FullName -notmatch '\\_mojibake_backups\\' -and $_.FullName -notmatch '\\_metadata_backups\\' }

Write-Host "== Processing $($files.Count) HTML files under '$RootPath' ==" -ForegroundColor Cyan
if ($DryRun) { Write-Host "(DryRun mode: no files will be written)" -ForegroundColor Yellow }

foreach ($file in $files) {
    try {
        $raw = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        $original = $raw
        $postersMoved = 0

        $raw, $postersMoved = Move-Posters -Html $raw -SelectorHint $PosterSelectorHint

        $changed = ($raw -ne $original)

        if ($changed -and -not $DryRun) {
            Set-Content -Path $file.FullName -Value $raw -Encoding UTF8 -NoNewline
        }

        $status = if (-not $changed) { 'NoChangeNeeded' } elseif ($DryRun) { 'WouldChange' } else { 'Updated' }
        Add-Result -Path $file.FullName -PostersMoved $postersMoved -Status $status -Detail ''
    }
    catch {
        Add-Result -Path $file.FullName -PostersMoved 0 -Status 'ERROR' -Detail $_.Exception.Message
        Write-Warning "Failed on $($file.FullName): $($_.Exception.Message)"
    }
}

$results | Export-Csv -Path $logPath -NoTypeInformation -Encoding UTF8

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
$updated = ($results | Where-Object Status -in @('Updated','WouldChange')).Count
$errors = ($results | Where-Object Status -eq 'ERROR').Count
$postersMv = ($results | Measure-Object -Property PostersMoved -Sum).Sum

Write-Host ""
Write-Host "== SUMMARY ==" -ForegroundColor Cyan
Write-Host "Files scanned:            $($files.Count)"
Write-Host "Files changed/would change: $updated"
Write-Host "Poster blocks relocated:  $postersMv"
Write-Host "Errors:                   $errors"
Write-Host "Log written to:           $logPath"
if (-not $DryRun) { Write-Host "Backup folder:            $backupPath" }
