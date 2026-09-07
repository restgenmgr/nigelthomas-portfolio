$path = "C:\Users\admin\Desktop\nigelthomas-portfolio\blog.html"
$content = Get-Content -Raw $path

$anchorText = 'href="executive-career-dashboard.html"'
$anchorIndex = $content.IndexOf($anchorText)

if ($anchorIndex -eq -1) {
    Write-Host "Anchor text not found - nothing to remove." -ForegroundColor Red
} else {
    $cardMarker = '<div class="article-card">'
    $cardStart = $content.LastIndexOf($cardMarker, $anchorIndex)
    $nextCardStart = $content.IndexOf($cardMarker, $cardStart + $cardMarker.Length)

    if ($nextCardStart -eq -1) {
        Write-Host "No next card found - aborting to be safe." -ForegroundColor Yellow
    } else {
        $blockLength = $nextCardStart - $cardStart
        $before = $content.Substring(0, $cardStart)
        $after = $content.Substring($nextCardStart)
        $newContent = $before + $after

        Set-Content -Path $path -Value $newContent -NoNewline -Encoding UTF8
        Write-Host "Removed $blockLength characters. File saved." -ForegroundColor Green
    }
}