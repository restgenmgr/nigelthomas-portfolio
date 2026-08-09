# deploy-haccp-post.ps1
# One-shot deploy for the HACCP blog post + poster image.
# Run this FROM PowerShell, anywhere - it cds into the repo for you.

$repo = "C:\Users\admin\Desktop\nigelthomas-portfolio"
$downloads = "$env:USERPROFILE\Downloads"

cd $repo

# 1. Pull latest so we don't diverge from any GitHub web-UI edits
git pull --rebase origin main

# 2. Locate the two downloaded files even if Chrome appended a (1)/(2) suffix,
#    grab the most recently modified match, then copy into the repo with the clean names.
$htmlSrc = Get-ChildItem -Path $downloads -Filter "haccp-hazard-analysis-critical-control-points*.html" |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
$jpgSrc  = Get-ChildItem -Path $downloads -Filter "haccp*.jpg" |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $htmlSrc -or -not $jpgSrc) {
    Write-Host "ERROR: Could not find both files in $downloads. Download them from Claude first." -ForegroundColor Red
    exit 1
}

# Article goes at repo root; image goes straight into assets/ (matching your current convention)
Copy-Item $htmlSrc.FullName -Destination (Join-Path $repo "haccp-hazard-analysis-critical-control-points.html") -Force
Copy-Item $jpgSrc.FullName  -Destination (Join-Path $repo "assets\haccp.jpg") -Force

Write-Host "Copied files into $repo (image in assets\)" -ForegroundColor Green

# 3. Fix the <img> src in the article to point at assets/haccp.jpg (script defaults to root-relative)
$path = Join-Path $repo "haccp-hazard-analysis-critical-control-points.html"
$content = [System.IO.File]::ReadAllText($path)
$content = $content -replace 'src="haccp\.jpg"', 'src="assets/haccp.jpg"'
[System.IO.File]::WriteAllText($path, $content, (New-Object System.Text.UTF8Encoding $false))
Write-Host "Updated image path to assets/haccp.jpg inside the article" -ForegroundColor Green

# 4. Reminder: add the blog.html card and sitemap.xml entry BEFORE committing.
Write-Host "NOTE: Make sure you've added the blog.html card and sitemap.xml <url> entry before continuing." -ForegroundColor Yellow
$confirm = Read-Host "Have you updated blog.html and sitemap.xml? (y/n)"
if ($confirm -ne "y") {
    Write-Host "Stopping. Update blog.html + sitemap.xml, then re-run this script." -ForegroundColor Yellow
    exit 0
}

# 5. Commit and push
git add haccp-hazard-analysis-critical-control-points.html assets/haccp.jpg blog.html sitemap.xml
git commit -m "Add HACCP blog post + poster image"
git push origin main

# 6. Deploy
vercel --prod --force

# 7. Verify
Start-Sleep -Seconds 15
Invoke-WebRequest -Uri "https://nigelthomas.live/haccp-hazard-analysis-critical-control-points.html" -UseBasicParsing | Select-Object StatusCode
Invoke-WebRequest -Uri "https://nigelthomas.live/assets/haccp.jpg" -UseBasicParsing | Select-Object StatusCode

Write-Host "Done. Verify the live page and image load correctly." -ForegroundColor Green
