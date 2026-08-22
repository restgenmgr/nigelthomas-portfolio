# Removes 6 self-contained links to the deleted "7 Types of Coffee" article.
# Each of these is a full, standalone line (a <li> or <a>+<br/>), so removing
# the whole line is safe and won't break surrounding HTML structure.
# Skips _mojibake_backups (not part of the live site).

$repo = "C:\Users\admin\Desktop\nigelthomas-portfolio"
Set-Location $repo
git pull --rebase

$targets = @(
    @{ File = "coffee-types-poster.html";               Match = '→ 7 Types of Coffee' },
    @{ File = "history-of-wine-world-wine-regions-guide.html"; Match = '→ 7 Types of Coffee' },
    @{ File = "medicinal-properties-of-teas.html";       Match = '7-types-of-coffee-and-how-theyre-made.html">7 Types of Coffee' },
    @{ File = "types-of-alcohol-complete-guide.html";    Match = '→ 7 Types of Coffee' },
    @{ File = "types-of-cheese-used-in-hotels.html";     Match = '7-types-of-coffee-and-how-theyre-made.html">7 Types of Coffee' },
    @{ File = "types-of-water-used-in-restaurant.html";  Match = '7 Types of Coffee' }
)

foreach ($t in $targets) {
    $path = Join-Path $repo $t.File
    if (-not (Test-Path $path)) {
        Write-Host "SKIP (not found): $($t.File)" -ForegroundColor DarkYellow
        continue
    }
    $lines = [System.IO.File]::ReadAllLines($path)
    $before = $lines.Length
    $filtered = $lines | Where-Object { $_ -notmatch [regex]::Escape($t.Match) }
    $after = $filtered.Length

    if ($before -eq $after) {
        Write-Host "NOT FOUND in $($t.File) — check manually" -ForegroundColor Red
    } else {
        $newContent = [string]::Join("`r`n", $filtered)
        [System.IO.File]::WriteAllText($path, $newContent, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host "Removed $($before - $after) line(s) from $($t.File)" -ForegroundColor Green
    }
}

Write-Host "`nDone. Review 'git diff' before committing." -ForegroundColor Cyan
