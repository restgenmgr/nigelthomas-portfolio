$path = "C:\Users\admin\Desktop\nigelthomas-portfolio"
Set-Location $path

$blogPath = Join-Path $path "blog.html"
$blogContent = Get-Content -Raw $blogPath
$blockStart = '<article class="article-card">'
$anchorText = 'operations-management-first-role-restaurant-manager.html" class="read-more-btn"'
$anchorIdx = $blogContent.IndexOf($anchorText)
if ($anchorIdx -eq -1) {
    Write-Host "blog.html: anchor not found - may already be removed" -ForegroundColor Yellow
} else {
    $cardStart = $blogContent.LastIndexOf($blockStart, $anchorIdx)
    $blockEnd = '</article>'
    $endIdx = $blogContent.IndexOf($blockEnd, $anchorIdx)
    if ($cardStart -eq -1 -or $endIdx -eq -1) {
        Write-Host "blog.html: could not find full block boundaries - skipping" -ForegroundColor Red
    } else {
        $realEnd = $endIdx + $blockEnd.Length
        $before = $blogContent.Substring(0, $cardStart)
        $after = $blogContent.Substring($realEnd)
        $newBlog = $before + $after
        Set-Content -Path $blogPath -Value $newBlog -NoNewline -Encoding UTF8
        Write-Host "blog.html: removed article-card block" -ForegroundColor Green
    }
}

$gmPath = Join-Path $path "general-manager-duties-and-responsibilities.html"
$gmContent = Get-Content -Raw $gmPath
$gmLine = '        <li><a href="https://www.nigelthomas.live/operations-management-first-role-restaurant-manager.html" target="_blank">First Role as a Restaurant Manager</a></li>' + "`r`n"
if ($gmContent -match [regex]::Escape($gmLine.Trim())) {
    $newGm = $gmContent -replace [regex]::Escape($gmLine), ""
    if ($newGm -eq $gmContent) {
        $gmLineNoCrlf = '        <li><a href="https://www.nigelthomas.live/operations-management-first-role-restaurant-manager.html" target="_blank">First Role as a Restaurant Manager</a></li>' + "`n"
        $newGm = $gmContent -replace [regex]::Escape($gmLineNoCrlf), ""
    }
    Set-Content -Path $gmPath -Value $newGm -NoNewline -Encoding UTF8
    Write-Host "general-manager-duties-and-responsibilities.html: removed li line" -ForegroundColor Green
} else {
    Write-Host "general-manager-duties-and-responsibilities.html: line not found - skipping" -ForegroundColor Yellow
}

$rocPath = Join-Path $path "restaurant-operational-challenges-solutions.html"
$rocContent = Get-Content -Raw $rocPath
$rocLine = '                <li><a href="https://www.nigelthomas.live/operations-management-first-role-restaurant-manager.html" target="_blank">First Role as a Restaurant Manager</a></li>' + "`r`n"
if ($rocContent -match [regex]::Escape($rocLine.Trim())) {
    $newRoc = $rocContent -replace [regex]::Escape($rocLine), ""
    if ($newRoc -eq $rocContent) {
        $rocLineNoCrlf = '                <li><a href="https://www.nigelthomas.live/operations-management-first-role-restaurant-manager.html" target="_blank">First Role as a Restaurant Manager</a></li>' + "`n"
        $newRoc = $rocContent -replace [regex]::Escape($rocLineNoCrlf), ""
    }
    Set-Content -Path $rocPath -Value $newRoc -NoNewline -Encoding UTF8
    Write-Host "restaurant-operational-challenges-solutions.html: removed li line" -ForegroundColor Green
} else {
    Write-Host "restaurant-operational-challenges-solutions.html: line not found - skipping" -ForegroundColor Yellow
}

$sitemapPath = Join-Path $path "sitemap.xml"
if (Test-Path $sitemapPath) {
    $sitemap = [System.IO.File]::ReadAllText($sitemapPath)
    $urlAnchorIdx = $sitemap.IndexOf("operations-management-first-role-restaurant-manager.html")
    if ($urlAnchorIdx -eq -1) {
        Write-Host "sitemap.xml: entry not found - skipping" -ForegroundColor Yellow
    } else {
        $urlStart = $sitemap.LastIndexOf("<url>", $urlAnchorIdx)
        $urlEndIdx = $sitemap.IndexOf("</url>", $urlAnchorIdx)
        if ($urlStart -eq -1 -or $urlEndIdx -eq -1) {
            Write-Host "sitemap.xml: could not isolate url block - skipping" -ForegroundColor Red
        } else {
            $urlEnd = $urlEndIdx + 6
            $before = $sitemap.Substring(0, $urlStart)
            $after = $sitemap.Substring($urlEnd)
            $newSitemap = $before + $after
            [System.IO.File]::WriteAllText($sitemapPath, $newSitemap, (New-Object System.Text.UTF8Encoding $false))
            Write-Host "sitemap.xml: removed entry" -ForegroundColor Green
        }
    }
}

if (Test-Path "operations-management-first-role-restaurant-manager.html") {
    git rm "operations-management-first-role-restaurant-manager.html"
    Write-Host "Deleted operations-management-first-role-restaurant-manager.html" -ForegroundColor Green
}
if (Test-Path "operations-management-first-role-restaurant-manager.pre-encoding-repair.html") {
    git rm "operations-management-first-role-restaurant-manager.pre-encoding-repair.html"
    Write-Host "Deleted stray backup file" -ForegroundColor Green
}

Write-Host ""
Write-Host "Done. Review with 'git status' before committing." -ForegroundColor Cyan