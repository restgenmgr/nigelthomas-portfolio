# organize-root-images.ps1
#
# Finds .jpg/.jpeg/.png/.jfif files sitting loose at the repo ROOT (not in
# any subfolder) and moves them into assets/, keeping things organized.
# True duplicates (same filename AND identical content as a file already
# in assets/) are deleted instead of moved. Same-name-but-different-content
# files are NEVER auto-deleted — they're flagged for you to check by hand.
#
# SAFE BY DEFAULT: running with no switches only PRINTS what it would do.
# Nothing is moved or deleted until you re-run with -Apply.
#
# Usage:
#   .\organize-root-images.ps1            # dry run - just shows the plan
#   .\organize-root-images.ps1 -Apply     # actually moves/deletes, then
#                                          # pulls, commits, pushes, deploys
#
# Run from PowerShell as: .\organize-root-images.ps1
# (Do NOT paste this multi-line script directly into the PowerShell prompt.)

param(
    [switch]$Apply
)

$ErrorActionPreference = "Stop"
$repoPath = "C:\Users\admin\Desktop\nigelthomas-portfolio"
$assetsPath = "$repoPath\assets"
$extensions = @("*.jpg", "*.jpeg", "*.png", "*.jfif")

Write-Host "== Step 1: Navigate to repo ==" -ForegroundColor Cyan
Set-Location $repoPath

if ($Apply) {
    Write-Host "== Step 2: Pull latest with rebase ==" -ForegroundColor Cyan
    git pull --rebase origin main
} else {
    Write-Host "== DRY RUN MODE - nothing will be changed. Re-run with -Apply to execute. ==" -ForegroundColor Yellow
}

Write-Host "== Step 3: Scan repo root for image files ==" -ForegroundColor Cyan
$rootImages = Get-ChildItem -Path $repoPath -File -Include $extensions | Where-Object { $_.DirectoryName -eq $repoPath }

if ($rootImages.Count -eq 0) {
    Write-Host "No jpg/png/jfif files found loose at repo root. Nothing to do." -ForegroundColor Green
    exit 0
}

New-Item -ItemType Directory -Force -Path $assetsPath | Out-Null

$toMove = @()
$toDelete = @()
$conflicts = @()

foreach ($img in $rootImages) {
    $targetPath = Join-Path $assetsPath $img.Name

    if (Test-Path $targetPath) {
        $rootHash = (Get-FileHash $img.FullName -Algorithm SHA256).Hash
        $assetHash = (Get-FileHash $targetPath -Algorithm SHA256).Hash

        if ($rootHash -eq $assetHash) {
            # True duplicate - identical content already in assets/
            $toDelete += $img
        } else {
            # Same filename, different content - do NOT touch automatically
            $conflicts += $img
        }
    } else {
        $toMove += $img
    }
}

Write-Host "`n== Plan ==" -ForegroundColor Cyan

if ($toMove.Count -gt 0) {
    Write-Host "`nWill MOVE to assets/ ($($toMove.Count)):" -ForegroundColor Green
    $toMove | ForEach-Object { Write-Host "  $($_.Name)" }
}

if ($toDelete.Count -gt 0) {
    Write-Host "`nWill DELETE from root - identical copy already in assets/ ($($toDelete.Count)):" -ForegroundColor Yellow
    $toDelete | ForEach-Object { Write-Host "  $($_.Name)" }
}

if ($conflicts.Count -gt 0) {
    Write-Host "`nCONFLICTS - same filename in assets/ but DIFFERENT content. Skipping these, review manually ($($conflicts.Count)):" -ForegroundColor Red
    $conflicts | ForEach-Object { Write-Host "  $($_.Name)" }
}

if (-not $Apply) {
    Write-Host "`nThis was a dry run. Re-run with -Apply to actually move/delete these files." -ForegroundColor Yellow
    exit 0
}

Write-Host "`n== Step 4: Applying changes ==" -ForegroundColor Cyan

foreach ($img in $toMove) {
    Move-Item $img.FullName (Join-Path $assetsPath $img.Name) -Force
    Write-Host "Moved: $($img.Name)" -ForegroundColor Green
}

foreach ($img in $toDelete) {
    Remove-Item $img.FullName -Force
    Write-Host "Deleted duplicate: $($img.Name)" -ForegroundColor Yellow
}

Write-Host "== Step 5: Stage, commit, push ==" -ForegroundColor Cyan
git add -A
git commit -m "Organize root-level images into assets/, remove exact duplicates"
git push origin main

Write-Host "== Step 6: Deploy to production via Vercel ==" -ForegroundColor Cyan
vercel --prod --force

Write-Host "`nDone." -ForegroundColor Green
if ($conflicts.Count -gt 0) {
    Write-Host "Reminder: $($conflicts.Count) file(s) were skipped due to name conflicts with different content - check these by hand." -ForegroundColor Red
}
Write-Host "Reminder: if any moved image was referenced anywhere with a root-relative path (not /assets/...), that HTML will need updating." -ForegroundColor Yellow
