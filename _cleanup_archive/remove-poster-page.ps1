# ============================================
# remove-poster-page.ps1
# Removes operations-management-first-role-restaurant-manager.html
# from repo, blog.html, and sitemap.xml — then commits/pushes/verifies
# ============================================

cd C:\Users\admin\Desktop\nigelthomas-portfolio

$targetFile = "operations-management-first-role-restaurant-manager.html"
$blogPath = Join-Path (Get-Location) "blog.html"
$sitemapPath = Join-Path (Get-Location) "sitemap.xml"

# ---- Step 1: Remove the card block from blog.html ----
$blog = [System.IO.File]::ReadAllText($blogPath)

$searchAnchor = $targetFile
$anchorIndex = $blog.IndexOf($searchAnchor)

if ($anchorIndex -eq -1) {
    Write-Host "⚠️ Could not find reference to $targetFile in blog.html - skipping card removal" -ForegroundColor Yellow
} else {
    # Find the nearest '<div class="article-card"' before the anchor
    $cardMarker = '<div class="article-card"'
    $startIndex = $blog.LastIndexOf($cardMarker, $anchorIndex)

    if ($startIndex -eq -1) {
        Write-Host "⚠️ Could not find opening article-card div - skipping card removal" -ForegroundColor Yellow
    } else {
        # Walk forward from startIndex counting div depth to find the matching closing </div>
        $pos = $startIndex
        $depth = 0
        $endIndex = -1
        while ($pos -lt $blog.Length) {
            $nextOpen = $blog.IndexOf("<div", $pos)
            $nextClose = $blog.IndexOf("</div>", $pos)

            if ($nextClose -eq -1) { break }

            if ($nextOpen -ne -1 -and $nextOpen -lt $nextClose) {
                $depth++
                $pos = $nextOpen + 4
            } else {
                $depth--
                $pos = $nextClose + 6
                if ($depth -eq 0) {
                    $endIndex = $nextClose + 6
                    break
                }
            }
        }

        if ($endIndex -eq -1) {
            Write-Host "⚠️ Could not find matching closing div - skipping card removal" -ForegroundColor Yellow
        } else {
            $before = $blog.Substring(0, $startIndex)
            $after = $blog.Substring($endIndex)
            $blog = $before + $after
            [System.IO.File]::WriteAllText($blogPath, $blog, (New-Object System.Text.UTF8Encoding $false))
            Write-Host "✅ Removed card block from blog.html" -ForegroundColor Green
        }
    }
}

# ---- Step 2: Remove the <url> entry from sitemap.xml ----
$sitemap = [System.IO.File]::ReadAllText($sitemapPath)
$urlAnchorIndex = $sitemap.IndexOf($targetFile)

if ($urlAnchorIndex -eq -1) {
    Write-Host "⚠️ Could not find reference to $targetFile in sitemap.xml - skipping" -ForegroundColor Yellow
} else {
    $urlStart = $sitemap.LastIndexOf("<url>", $urlAnchorIndex)
    $urlEndTagIndex = $sitemap.IndexOf("</url>", $urlAnchorIndex)
    if ($urlStart -eq -1 -or $urlEndTagIndex -eq -1) {
        Write-Host "⚠️ Could not isolate <url> block - skipping sitemap removal" -ForegroundColor Yellow
    } else {
        $urlEnd = $urlEndTagIndex + 6
        $before = $sitemap.Substring(0, $urlStart)
        $after = $sitemap.Substring($urlEnd)
        $sitemap = $before + $after
        [System.IO.File]::WriteAllText($sitemapPath, $sitemap, (New-Object System.Text.UTF8Encoding $false))
        Write-Host "✅ Removed entry from sitemap.xml" -ForegroundColor Green
    }
}

# ---- Step 3: Delete the page file itself ----
if (Test-Path $targetFile) {
    git rm $targetFile
    Write-Host "✅ Deleted $targetFile from repo" -ForegroundColor Green
} else {
    Write-Host "⚠️ $targetFile not found in working directory" -ForegroundColor Yellow
}

# ---- Step 4: Commit and push ----
git add -A
git commit -m "Remove operations management poster page (photo issue)"
git pull --rebase origin main
git push origin main

# ---- Step 5: Verify it's down ----
Write-Host "Waiting 25s for Vercel deploy..." -ForegroundColor Cyan
Start-Sleep -Seconds 25

try {
    $check = Invoke-WebRequest -Uri "https://www.nigelthomas.live/$targetFile" -UseBasicParsing
    Write-Host "⚠️ Still live - status $($check.StatusCode)" -ForegroundColor Yellow
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "✅ Page removed - returns $statusCode" -ForegroundColor Green
}
