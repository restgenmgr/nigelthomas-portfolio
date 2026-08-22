
# Audit-only script — makes NO changes. Lists every file and line that
# references the "7 Types of Coffee" article, so we can review before removing.
 
$repo = "C:\Users\admin\Desktop\nigelthomas-portfolio"
Set-Location $repo
git pull --rebase
 
$patterns = @(
    "7-types-of-coffee-and-theyre-made",
    "7 Types of Coffee"
)
 
$targets = Get-ChildItem -Path $repo -Include *.html,*.xml -Recurse -File |
    Where-Object { $_.FullName -notmatch "\\node_modules\\" }
 
Write-Host "================ AUDIT RESULTS ================" -ForegroundColor Cyan
 
$hits = 0
foreach ($file in $targets) {
    $lines = [System.IO.File]::ReadAllLines($file.FullName)
    for ($i = 0; $i -lt $lines.Length; $i++) {
        foreach ($p in $patterns) {
            if ($lines[$i] -match [regex]::Escape($p)) {
                $hits++
                $rel = $file.FullName.Replace($repo, "")
                Write-Host "`nFILE: $rel  (line $($i+1))" -ForegroundColor Yellow
                Write-Host $lines[$i].Trim()
                break
            }
        }
    }
}
 
Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "Total matching lines found: $hits" -ForegroundColor Cyan
 



