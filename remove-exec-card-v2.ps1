$path = "C:\Users\admin\Desktop\nigelthomas-portfolio\blog.html"
$content = Get-Content -Raw $path

$anchorText = 'href="executive-career-dashboard.html"'
$anchorIndex = $content.IndexOf($anchorText)

if ($anchorIndex -eq -1) {
    Write-Host "Anchor text not found at all." -ForegroundColor Red
} else {
    Write-Host "Anchor found at position $anchorIndex" -ForegroundColor Green

    $cardMarker = '<div class="article-card">'
    $cardStart = $content.LastIndexOf($cardMarker, $anchorIndex)
    Write-Host "Card block starts at position $cardStart"

    $nextCardStart = $content.IndexOf($cardMarker, $cardStart + $cardMarker.Length)
    if ($nextCardStart -eq -1) {
        Write-Host "No next card found - this might be the last card." -ForegroundColor Yellow
    } else {
        Write-Host "Next card starts at position $nextCardStart"
        $blockLength = $nextCardStart - $cardStart
        $blockToRemove = $content.Substring($cardStart, $blockLength)
        Write-Host ""
        Write-Host "--- Block that would be removed ($blockLength chars) ---"
        Write-Host $blockToRemove
    }
}