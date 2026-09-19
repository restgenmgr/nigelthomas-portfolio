$path = "C:\Users\admin\Desktop\nigelthomas-portfolio\blog.html"
$content = Get-Content -Raw $path

$pattern = '(?s)<div class="article-card">\s*<div class="article-title">\s*<a href="executive-career-dashboard\.html">.*?</div>\s*</div>\s*</div>\s*'

$m = [regex]::Match($content, $pattern)
if ($m.Success) {
    Write-Host "Match found. Length: $($m.Length) characters" -ForegroundColor Green
    Write-Host "--- Preview ---"
    Write-Host $m.Value
} else {
    Write-Host "Still not found - need a different approach" -ForegroundColor Yellow
}
