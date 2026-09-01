<#
.SYNOPSIS
    Moves all "poster" containers (div, section, figure, aside)
    to the bottom of the page, behind an Infomatics toggle button.
#>

[CmdletBinding()]
param(
    [string]$RootPath = (Get-Location).Path,
    [string]$SelectorHint = 'poster',
    [switch]$DryRun
)

$ErrorActionPreference = 'Continue'
$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
$logPath = Join-Path $RootPath "poster-move-fixed-$stamp.csv"
$backupPath = Join-Path $RootPath "backup-fixed-$stamp"

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

# Helper: extract a balanced tag using a simple stack
function Get-BalancedTag {
    param([string]$html, [string]$tag, [int]$startIndex)
    $openTag = "<$tag"
    $closeTag = "</$tag>"
    $depth = 0
    $i = $startIndex
    $len = $html.Length
    while ($i -lt $len) {
        if ($html.Substring($i, $openTag.Length) -match "^<$tag(\s|>)") {
            $depth++
            $i += $openTag.Length
        } elseif ($html.Substring($i, $closeTag.Length) -eq $closeTag) {
            $depth--
            if ($depth -eq 0) {
                $i += $closeTag.Length
                return @{ Text = $html.Substring($startIndex, $i - $startIndex); Start = $startIndex; Length = $i - $startIndex }
            }
            $i += $closeTag.Length
        } else {
            $i++
        }
    }
    return $null
}

# Backup (only in real run)
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

$PANEL_MARKER = '<!-- INFOMATICS-PANEL:v1 -->'

# Main processing
$files = Get-ChildItem -Path $RootPath -Filter *.html -Recurse -File |
    Where-Object { $_.FullName -notmatch '\\backup-' -and $_.FullName -notmatch '\\_mojibake_backups\\' -and $_.FullName -notmatch '\\_metadata_backups\\' }

Write-Host "== Processing $($files.Count) HTML files under '$RootPath' ==" -ForegroundColor Cyan
if ($DryRun) { Write-Host "(DryRun mode: no files will be written)" -ForegroundColor Yellow }

foreach ($file in $files) {
    try {
        $html = Get-Content $file.FullName -Raw -Encoding UTF8
        $original = $html
        $postersMoved = 0

        # Skip if already processed
        if ($html.Contains($PANEL_MARKER)) {
            Add-Result -Path $file.FullName -PostersMoved 0 -Status 'Skipped (already has panel)' -Detail ''
            continue
        }

        # Find all container tags with class or id containing the hint
        $pattern = "(?i)<(div|section|figure|aside)(?=[\s>])[^>]*(?:class|id)\s*=\s*[""'][^""']*$SelectorHint[^""']*[""'][^>]*>"
        $matches = [regex]::Matches($html, $pattern)
        $extracted = @()
        $offset = 0

        foreach ($match in $matches) {
            $start = $match.Index - $offset
            $tagName = $match.Groups[1].Value
            $block = Get-BalancedTag -html $html -tag $tagName -startIndex $start
            if ($block) {
                $extracted += $block.Text
                $html = $html.Remove($block.Start, $block.Length)
                $offset += $block.Length
            }
        }

        if ($extracted.Count -eq 0) {
            Add-Result -Path $file.FullName -PostersMoved 0 -Status 'NoChangeNeeded' -Detail ''
            continue
        }

        $postersMoved = $extracted.Count

        # Build the panel
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

        # Insert panel before </body> using .Insert()
        $bodyPos = $html.IndexOf("</body>", [StringComparison]::OrdinalIgnoreCase)
        if ($bodyPos -ge 0) {
            $html = $html.Insert($bodyPos, "`r`n$panelHtml`r`n")
        } else {
            $html += "`r`n$panelHtml"
        }

        if (-not $DryRun) {
            Set-Content -Path $file.FullName -Value $html -Encoding UTF8 -NoNewline
            $status = 'Updated'
        } else {
            $status = 'WouldChange'
        }

        Add-Result -Path $file.FullName -PostersMoved $postersMoved -Status $status -Detail ''
    }
    catch {
        Add-Result -Path $file.FullName -PostersMoved 0 -Status 'ERROR' -Detail $_.Exception.Message
        Write-Warning "Failed on $($file.FullName): $($_.Exception.Message)"
    }
}

$results | Export-Csv -Path $logPath -NoTypeInformation -Encoding UTF8

# Summary
$updated = ($results | Where-Object { $_.Status -in @('Updated','WouldChange') }).Count
$errors = ($results | Where-Object { $_.Status -eq 'ERROR' }).Count
$postersMv = ($results | Measure-Object -Property PostersMoved -Sum).Sum

Write-Host ""
Write-Host "== SUMMARY ==" -ForegroundColor Cyan
Write-Host "Files scanned:            $($files.Count)"
Write-Host "Files changed/would change: $updated"
Write-Host "Poster blocks relocated:  $postersMv"
Write-Host "Errors:                   $errors"
Write-Host "Log written to:           $logPath"
if (-not $DryRun) { Write-Host "Backup folder:            $backupPath" }