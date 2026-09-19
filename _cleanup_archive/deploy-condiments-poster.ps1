# ============================================================
# Deploy: Condiments vs Sauces poster (jfif + html)
# ============================================================

# --- EDIT THESE IF YOUR PATHS DIFFER ---
$RepoPath    = "C:\Users\Nigel\nigelthomas-portfolio"     # local repo root
$DownloadsPath = "$env:USERPROFILE\Downloads"
$AssetsFolder  = Join-Path $RepoPath "assets\images"       # target folder for jfif
$SourceJfifPattern = "condiments-and-sauces*.jfif"         # matches (1)/(2) suffixed downloads
$FinalJfifName     = "condiments-and-sauces.jfif"
$PosterHtmlName    = "condiments-vs-sauces-poster.html"

Set-Location $RepoPath

# --- 1. Pull latest before touching anything ---
git pull --rebase

# --- 2. Find the most recently downloaded jfif (handles (1)/(2) suffixes) ---
$sourceFile = Get-ChildItem -Path $DownloadsPath -Filter $SourceJfifPattern |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $sourceFile) {
    Write-Host "ERROR: No file matching '$SourceJfifPattern' found in $DownloadsPath" -ForegroundColor Red
    exit 1
}

Write-Host "Found source file: $($sourceFile.FullName)"

# --- 3. Hash it before moving (sanity check / dedup log) ---
$hash = Get-FileHash -Path $sourceFile.FullName -Algorithm SHA256
Write-Host "SHA256: $($hash.Hash)"

# --- 4. Ensure assets folder exists ---
if (-not (Test-Path $AssetsFolder)) {
    New-Item -ItemType Directory -Path $AssetsFolder -Force | Out-Null
    Write-Host "Created folder: $AssetsFolder"
}

# --- 5. Move + rename jfif into assets folder ---
$destJfif = Join-Path $AssetsFolder $FinalJfifName
Move-Item -Path $sourceFile.FullName -Destination $destJfif -Force
Write-Host "Moved jfif -> $destJfif"

# --- 6. Move the poster HTML into repo root (flat URL structure) ---
$sourceHtml = Join-Path $DownloadsPath $PosterHtmlName
$destHtml   = Join-Path $RepoPath $PosterHtmlName

if (Test-Path $sourceHtml) {
    Move-Item -Path $sourceHtml -Destination $destHtml -Force
    Write-Host "Moved html -> $destHtml"
} else {
    Write-Host "NOTE: $PosterHtmlName not found in Downloads — skipping move. Confirm it's already in repo root." -ForegroundColor Yellow
}

# --- 7. Git add, commit, push ---
git add "assets/images/$FinalJfifName" $PosterHtmlName
git commit -m "Add condiments-and-sauces.jfif to assets and deploy poster page"
git pull --rebase
git push

# --- 8. Deploy to Vercel ---
vercel --prod --force

Write-Host "`nDone. Verify at: https://www.nigelthomas.live/$PosterHtmlName" -ForegroundColor Green
