<#
diagnose-gourmet-canapes.ps1
Prints the raw text (as truly decoded UTF-8) around the second
occurrence of "gourmet-canapes-italian-starters.html", with no
assumptions about line endings or arrow characters.
#>

$path = [System.IO.Path]::GetFullPath("blog.html")
$raw = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

$needle = "gourmet-canapes-italian-starters.html"
$idx = $raw.IndexOf($needle)
$idx = $raw.IndexOf($needle, $idx + 1)  # second occurrence

if ($idx -lt 0) {
    Write-Host "Second occurrence not found." -ForegroundColor Red
    exit 1
}

$start = [Math]::Max(0, $idx - 50)
$len = [Math]::Min(400, $raw.Length - $start)
$snippet = $raw.Substring($start, $len)

Write-Host "Raw text snippet (with visible markers for CR/LF):" -ForegroundColor Yellow
$visible = $snippet -replace "`r", "[CR]" -replace "`n", "[LF]`n"
Write-Host $visible
