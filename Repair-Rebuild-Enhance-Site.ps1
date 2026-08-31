<#
.SYNOPSIS
    Master repair / rebuild / enhancement script for the nigelthomas.live HTML site.

.DESCRIPTION
    Walks every .html file under -RootPath and, in this order:
      1. Backs up the entire tree (unless -SkipBackup).
      2. Repairs common mojibake / double-encoding corruption
         (UTF-8 bytes that were mis-decoded as Windows-1252 and re-saved).
      3. Best-effort structural repair: missing <!DOCTYPE>, <html>, <head>,
         <body>, and unbalanced container tags. Anything it is not confident
         fixing automatically is only LOGGED, never guessed at blindly.
      4. Finds "poster" blocks (see -PosterSelectorHint) and moves them to
         the bottom of <body>, hidden behind an "Infomatics" toggle button,
         so visitors must click to reveal the poster/emblem/photo.
      5. Writes a full CSV log of every action taken, per file.

    SAFE BY DEFAULT:
      - Always makes a timestamped backup copy of the whole tree first
        (unless you pass -SkipBackup).
      - Supports -DryRun: reports exactly what it WOULD do, changes nothing.
      - Skips files that already carry the "INFOMATICS-PANEL" marker, so the
        script is safe to re-run without double-wrapping posters.

.PARAMETER RootPath
    Root folder containing your HTML site (defaults to current directory).
    The script recurses into all subfolders (academy, accounting, blog,
    career, culinary, food-safety, hospitality-management, etc.)

.PARAMETER PosterSelectorHint
    Regex fragment used to identify "poster" elements. Matches against
    class="", id="", src="", and alt="" attributes on candidate tags.
    Default: 'poster'. Change to e.g. 'poster|emblem' if you use both terms.

.PARAMETER DryRun
    Preview mode. No files are modified. A CSV log is still written showing
    what WOULD have happened to each file.

.PARAMETER SkipBackup
    Skip the pre-flight backup step. NOT recommended on a live site.

.PARAMETER SkipMojibakeRepair
    Skip step 2 (encoding repair).

.PARAMETER SkipStructureRepair
    Skip step 3 (structural / tag-balance repair).

.PARAMETER SkipPosterMove
    Skip step 4 (poster relocation + Infomatics button).

.EXAMPLE
    # Preview only — see what would happen, nothing is changed
    .\Repair-Rebuild-Enhance-Site.ps1 -RootPath "C:\sites\nigelthomas" -DryRun

.EXAMPLE
    # Full run against a COPY of the site first (recommended)
    .\Repair-Rebuild-Enhance-Site.ps1 -RootPath "C:\staging\nigelthomas"

.EXAMPLE
    # Only fix encoding, don't touch posters or structure
    .\Repair-Rebuild-Enhance-Site.ps1 -RootPath "C:\sites\nigelthomas" -SkipStructureRepair -SkipPosterMove

.NOTES
    Run this against a STAGING COPY first, review the CSV log and a sample
    of changed files, then run against the live folder. This is a heuristic,
    regex-based repair tool, not a full HTML parser — it is well suited to
    the reasonably consistent markup this site already uses, but always
    spot-check output before publishing.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$RootPath = (Get-Location).Path,
    [string]$PosterSelectorHint = 'poster',
    [switch]$DryRun,
    [switch]$SkipBackup,
    [switch]$SkipMojibakeRepair,
    [switch]$SkipStructureRepair,
    [switch]$SkipPosterMove
)

$ErrorActionPreference = 'Stop'
$stamp    = (Get-Date).ToString('yyyyMMdd-HHmmss')
$logPath  = Join-Path $RootPath "repair-log-$stamp.csv"
$backupPath = Join-Path $RootPath "backup-html-$stamp"

if (-not (Test-Path $RootPath)) {
    throw "RootPath '$RootPath' does not exist."
}

$results = New-Object System.Collections.Generic.List[object]

function Add-Result {
    param(
        [string]$Path, [bool]$MojibakeRepaired, [string]$StructureNotes,
        [int]$PostersMoved, [string]$Status, [string]$Detail
    )
    $results.Add([pscustomobject]@{
        File              = $Path
        MojibakeRepaired  = $MojibakeRepaired
        StructureNotes    = $StructureNotes
        PostersMoved      = $PostersMoved
        Status            = $Status
        Detail            = $Detail
        Timestamp         = (Get-Date).ToString('s')
    }) | Out-Null
}

# ---------------------------------------------------------------------------
# STEP 1: Backup
# ---------------------------------------------------------------------------
if (-not $SkipBackup -and -not $DryRun) {
    Write-Host "== Backing up '$RootPath' -> '$backupPath' ==" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
    Get-ChildItem -Path $RootPath -Filter *.html -Recurse -File |
        Where-Object { $_.FullName -notmatch '\\backup-html-' -and $_.FullName -notmatch '\\_mojibake_backups\\' -and $_.FullName -notmatch '\\_metadata_backups\\' } |
        ForEach-Object {
            $rel  = $_.FullName.Substring($RootPath.Length).TrimStart('\','/')
            $dest = Join-Path $backupPath $rel
            New-Item -ItemType Directory -Path (Split-Path $dest -Parent) -Force | Out-Null
            Copy-Item $_.FullName $dest -Force
        }
    Write-Host "Backup complete." -ForegroundColor Green
} elseif ($DryRun) {
    Write-Host "== DryRun: skipping backup (no files will be changed anyway) ==" -ForegroundColor Yellow
} else {
    Write-Host "== -SkipBackup passed: no backup taken ==" -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# STEP 2: Mojibake / encoding repair
# ---------------------------------------------------------------------------

# Fallback direct replacements for the most common mangled sequences.
# Applied ONLY if the round-trip re-decode (below) does not already resolve them.
$mojibakeMap = [ordered]@{
    "â€™" = "'";  "â€˜" = "'";  "â€œ" = '"';  "â€\u009d" = '"'
    "â€"  = "-";  "â€"  = "-";  "â€¦" = "..."
    "Ã©" = "e"; "Ã¨" = "e"; "Ã¯" = "i"; "Ã¼" = "u"; "Ã±" = "n"
    "Ã " = "a"; "Ã¢" = "a"; "Ã´" = "o"; "Ã§" = "c"
    "Â "  = " "; "Â©"  = "(c)"; "Â®" = "(R)"; "Â " = " "
}

function Test-MojibakePattern {
    param([string]$Text)
    # Telltale byte-garbage sequences produced when UTF-8 is misread as cp1252
    return ($Text -cmatch 'Ã.|â€.|Â[^\x00-\x7F ]')
}

function Repair-MojibakeText {
    param([string]$Text)

    if (-not (Test-MojibakePattern $Text)) { return $Text, $false }

    # Attempt the standard round-trip fix: re-interpret the mis-decoded
    # characters as Windows-1252 bytes, then decode those bytes as UTF-8.
    try {
        $cp1252 = [System.Text.Encoding]::GetEncoding(1252)
        $utf8   = [System.Text.Encoding]::UTF8
        $bytes  = $cp1252.GetBytes($Text)
        $fixed  = $utf8.GetString($bytes)
    } catch {
        $fixed = $Text
    }

    # Only accept the round-trip result if it actually reduced the garbage,
    # never apply a "fix" that leaves things equally or more broken.
    $beforeCount = ([regex]::Matches($Text, 'Ã.|â€.|Â[^\x00-\x7F ]')).Count
    $afterCount  = ([regex]::Matches($fixed, 'Ã.|â€.|Â[^\x00-\x7F ]')).Count

    if ($afterCount -lt $beforeCount) {
        $Text = $fixed
    }

    # Sweep any remaining known sequences with the direct map.
    foreach ($key in $mojibakeMap.Keys) {
        if ($Text.Contains($key)) {
            $Text = $Text.Replace($key, $mojibakeMap[$key])
        }
    }

    $changed = Test-MojibakePattern $Text
    return $Text, (-not $changed) -or ($Text -ne $Text)
}

# ---------------------------------------------------------------------------
# STEP 3: Structural repair (best-effort, conservative)
# ---------------------------------------------------------------------------
function Repair-Structure {
    param([string]$Html)

    $notes = New-Object System.Collections.Generic.List[string]

    if ($Html -notmatch '(?i)<!DOCTYPE\s+html') {
        $Html = "<!DOCTYPE html>`r`n" + $Html
        $notes.Add("Added missing <!DOCTYPE html>")
    }

    if ($Html -notmatch '(?i)<html[\s>]') {
        $Html = $Html -replace '(?i)(<!DOCTYPE html>\s*)', "`$1<html lang=`"en`">`r`n"
        if ($Html -notmatch '(?i)</html>') { $Html += "`r`n</html>" }
        $notes.Add("Wrapped content in missing <html> tags")
    }

    if ($Html -notmatch '(?i)<head[\s>]') {
        $Html = $Html -replace '(?i)(<html[^>]*>\s*)', "`$1<head><meta charset=`"UTF-8`"></head>`r`n"
        $notes.Add("Added missing <head> with UTF-8 meta charset")
    } elseif ($Html -notmatch '(?i)<meta[^>]+charset') {
        $Html = $Html -replace '(?i)(<head[^>]*>)', "`$1`r`n<meta charset=`"UTF-8`">"
        $notes.Add("Added missing <meta charset=UTF-8> to existing <head>")
    }

    if ($Html -notmatch '(?i)<body[\s>]') {
        if ($Html -match '(?i)</head>') {
            $Html = $Html -replace '(?i)(</head>\s*)', "`$1<body>`r`n"
        } else {
            $Html += "`r`n<body>"
        }
        if ($Html -notmatch '(?i)</body>') {
            $Html = $Html -replace '(?i)(</html>)', "</body>`r`n`$1"
        }
        $notes.Add("Added missing <body> tags")
    }

    # Balance a conservative set of block containers. If opens > closes,
    # append the missing closers just before </body>. We never REMOVE a
    # closing tag automatically (too risky to guess which one is spurious) —
    # an excess of closing tags is only logged for manual review.
    $tags = 'div','section','article','ul','ol','table','figure'
    foreach ($tag in $tags) {
        $opens  = ([regex]::Matches($Html, "(?i)<$tag(\s[^>]*)?>")).Count
        $closes = ([regex]::Matches($Html, "(?i)</$tag>")).Count
        if ($opens -gt $closes) {
            $missing = $opens - $closes
            $closeTags = ("</{0}>" -f $tag) * $missing
            if ($Html -match '(?i)</body>') {
                $Html = $Html -replace '(?i)(</body>)', "$closeTags`r`n`$1"
            } else {
                $Html += $closeTags
            }
            $notes.Add("Appended $missing missing </$tag> before </body>")
        } elseif ($closes -gt $opens) {
            $notes.Add("WARNING: $($closes - $opens) extra </$tag> found — needs manual review, not auto-removed")
        }
    }

    return $Html, ($notes -join '; ')
}

# ---------------------------------------------------------------------------
# STEP 4: Poster relocation behind an "Infomatics" toggle
# ---------------------------------------------------------------------------
$PANEL_MARKER = '<!-- INFOMATICS-PANEL:v1 -->'

function Extract-Balanced {
    # Given html text and the start index of an opening tag <tagname ...>,
    # returns the full outer-HTML of that element (handles nested same-name tags).
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
        if (-not $nextClose.Success) { return $null } # unbalanced, bail out safely

        if ($nextOpen.Success -and $nextOpen.Index -lt $nextClose.Index) {
            $depth++
            $pos = $nextOpen.Index + $nextOpen.Length
        } else {
            $depth--
            $pos = $nextClose.Index + $nextClose.Length
        }
    }
    $length = $pos - $OpenTagStart
    return @{ Text = $Html.Substring($OpenTagStart, $length); Start = $OpenTagStart; Length = $length }
}

function Move-Posters {
    param([string]$Html, [string]$SelectorHint)

    if ($Html.Contains($PANEL_MARKER)) {
        return $Html, 0   # already processed, idempotent no-op
    }

    $extracted = New-Object System.Collections.Generic.List[string]
    $workingHtml = $Html

    # 1) Container elements (div/section/figure/aside) whose class or id
    #    mentions "poster" (or the custom hint).
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
            $searchStart = $block.Start   # re-scan from same point, content shifted
        }
    }

    # 2) Standalone <img> tags whose src/alt/class mentions "poster", not
    #    already captured above. Keep an enclosing <a> wrapper if present.
    $imgRe = [regex]"(?i)(<a[^>]*>\s*)?<img(?=[\s>])[^>]*(?:src|alt|class)\s*=\s*[""'][^""']*(?:$SelectorHint)[^""']*[""'][^>]*/?>(\s*</a>)?"
    $imgMatches = $imgRe.Matches($workingHtml)
    for ($i = $imgMatches.Count - 1; $i -ge 0; $i--) {
        $m = $imgMatches[$i]
        $extracted.Insert(0, $m.Value)   # preserve original top-to-bottom order
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
# MAIN LOOP
# ---------------------------------------------------------------------------
$files = Get-ChildItem -Path $RootPath -Filter *.html -Recurse -File |
    Where-Object {
        $_.FullName -notmatch '\\backup-html-' -and
        $_.FullName -notmatch '\\_mojibake_backups\\' -and
        $_.FullName -notmatch '\\_metadata_backups\\'
    }

Write-Host "== Processing $($files.Count) HTML files under '$RootPath' ==" -ForegroundColor Cyan
if ($DryRun) { Write-Host "(DryRun mode: no files will be written)" -ForegroundColor Yellow }

foreach ($file in $files) {
    try {
        $raw = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        $original = $raw
        $mojibakeFixed = $false
        $structureNotes = ""
        $postersMoved = 0

        if (-not $SkipMojibakeRepair) {
            $repaired, $mojibakeFixed = Repair-MojibakeText -Text $raw
            $raw = $repaired
        }

        if (-not $SkipStructureRepair) {
            $raw, $structureNotes = Repair-Structure -Html $raw
        }

        if (-not $SkipPosterMove) {
            $raw, $postersMoved = Move-Posters -Html $raw -SelectorHint $PosterSelectorHint
        }

        $changed = ($raw -ne $original)

        if ($changed -and -not $DryRun) {
            Set-Content -Path $file.FullName -Value $raw -Encoding UTF8 -NoNewline
        }

        $status = if (-not $changed) { 'NoChangeNeeded' } elseif ($DryRun) { 'WouldChange' } else { 'Updated' }
        Add-Result -Path $file.FullName -MojibakeRepaired $mojibakeFixed `
            -StructureNotes $structureNotes -PostersMoved $postersMoved `
            -Status $status -Detail ''
    }
    catch {
        Add-Result -Path $file.FullName -MojibakeRepaired $false -StructureNotes '' `
            -PostersMoved 0 -Status 'ERROR' -Detail $_.Exception.Message
        Write-Warning "Failed on $($file.FullName): $($_.Exception.Message)"
    }
}

$results | Export-Csv -Path $logPath -NoTypeInformation -Encoding UTF8

# ---------------------------------------------------------------------------
# SUMMARY
# ---------------------------------------------------------------------------
$updated   = ($results | Where-Object Status -in @('Updated','WouldChange')).Count
$errors    = ($results | Where-Object Status -eq 'ERROR').Count
$mojibake  = ($results | Where-Object MojibakeRepaired -eq $true).Count
$postersMv = ($results | Measure-Object -Property PostersMoved -Sum).Sum

Write-Host ""
Write-Host "== SUMMARY ==" -ForegroundColor Cyan
Write-Host "Files scanned:            $($files.Count)"
Write-Host "Files changed/would change: $updated"
Write-Host "Mojibake repairs applied: $mojibake"
Write-Host "Poster blocks relocated:  $postersMv"
Write-Host "Errors:                   $errors"
Write-Host "Log written to:           $logPath"
if (-not $SkipBackup -and -not $DryRun) { Write-Host "Backup folder:            $backupPath" }
