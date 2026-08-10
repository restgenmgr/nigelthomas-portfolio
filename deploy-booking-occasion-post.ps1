# deploy-booking-occasion-post.ps1
# One-shot deploy for the Direct vs OTA "Booking the Guest Occasion" post,
# poster image, and standalone byline headshot.

$repo = "C:\Users\admin\Desktop\nigelthomas-portfolio"
$downloads = "$env:USERPROFILE\Downloads"

cd $repo

# 1. Pull latest so we don't diverge from any GitHub web-UI edits
git pull --rebase origin main

# 2. Locate the downloaded files even if Chrome appended a (1)/(2) suffix
$htmlSrc = Get-ChildItem -Path $downloads -Filter "direct-vs-ota-booking-guest-occasion*.html" |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
$posterSrc = Get-ChildItem -Path $downloads -Filter "booking-guest-occasion*.jpg" |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
$headshotSrc = Get-ChildItem -Path $downloads -Filter "nat-headshot*.jpg" |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $htmlSrc -or -not $posterSrc -or -not $headshotSrc) {
    Write-Host "ERROR: Could not find all three files in $downloads. Download them from Claude first." -ForegroundColor Red
    exit 1
}

# Article at repo root; both images go into assets/ (matching current site convention)
Copy-Item $htmlSrc.FullName -Destination (Join-Path $repo "direct-vs-ota-booking-guest-occasion.html") -Force
Copy-Item $posterSrc.FullName -Destination (Join-Path $repo "assets\booking-guest-occasion.jpg") -Force
Copy-Item $headshotSrc.FullName -Destination (Join-Path $repo "assets\nat-headshot.jpg") -Force

Write-Host "Copied files into $repo (images in assets\)" -ForegroundColor Green

# 3. Fix the poster <img> src in the article to point at assets/ (script defaults to root-relative)
$path = Join-Path $repo "direct-vs-ota-booking-guest-occasion.html"
$content = [System.IO.File]::ReadAllText($path)
$content = $content -replace 'src="booking-guest-occasion\.jpg"', 'src="assets/booking-guest-occasion.jpg"'
[System.IO.File]::WriteAllText($path, $content, (New-Object System.Text.UTF8Encoding $false))
Write-Host "Updated poster image path to assets/booking-guest-occasion.jpg inside the article" -ForegroundColor Green

# 4. Reminder: add the blog.html card and sitemap.xml entry BEFORE committing.
Write-Host "NOTE: Make sure you've added the blog.html card and sitemap.xml <url> entry before continuing." -ForegroundColor Yellow
$confirm = Read-Host "Have you updated blog.html and sitemap.xml? (y/n)"
if ($confirm -ne "y") {
    Write-Host "Stopping. Update blog.html + sitemap.xml, then re-run this script." -ForegroundColor Yellow
    exit 0
}

# 5. Commit and push
git add direct-vs-ota-booking-guest-occasion.html assets/booking-guest-occasion.jpg assets/nat-headshot.jpg blog.html sitemap.xml
git commit -m "Add Direct vs OTA booking guest occasion post + poster + byline headshot"
git push origin main

# 6. Deploy
vercel --prod --force

# 7. Verify
Start-Sleep -Seconds 15
Invoke-WebRequest -Uri "https://nigelthomas.live/direct-vs-ota-booking-guest-occasion.html" -UseBasicParsing | Select-Object StatusCode
Invoke-WebRequest -Uri "https://nigelthomas.live/assets/booking-guest-occasion.jpg" -UseBasicParsing | Select-Object StatusCode
Invoke-WebRequest -Uri "https://nigelthomas.live/assets/nat-headshot.jpg" -UseBasicParsing | Select-Object StatusCode

Write-Host "Done. Verify the live page and both images load correctly." -ForegroundColor Green
