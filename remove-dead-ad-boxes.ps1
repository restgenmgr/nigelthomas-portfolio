# remove-dead-ad-boxes.ps1 - removes placeholder ad boxes (fake slot IDs), keeps the AdSense loader (Auto ads), verifies, commits, pushes
$repo='C:\Users\admin\Desktop\nigelthomas-portfolio'
Set-Location $repo
git pull --rebase --autostash
if($LASTEXITCODE -ne 0){Write-Host 'ERROR: git pull failed. NOTHING CHANGED.' -ForegroundColor Red; exit 1}
$u=New-Object System.Text.UTF8Encoding($false)
$fake='(?:0000000000|auto|xxxxxxxxxx|YOUR_AD_SLOT|REPLACE_WITH_AD_UNIT_ID_\d+)'
$rx=[regex]('(?is)[ \t]*<div[^>]*>\s*<ins class="adsbygoogle"[^>]*data-ad-slot="'+$fake+'"[^>]*>\s*</ins>\s*<script>\s*\(adsbygoogle\s*=\s*window\.adsbygoogle\s*\|\|\s*\[\]\)\.push\(\{\}\);?\s*</script>\s*</div>[ \t]*(?:\r?\n)?')
$files=Get-ChildItem -Path $repo -Recurse -Include *.html -File | Where-Object { $_.FullName -notmatch '\\(node_modules|\.git)\\' }
$changed=0; $removed=0; $bad=@()
foreach($f in $files){
  $t=[IO.File]::ReadAllText($f.FullName,$u)
  if($t -notmatch '<ins class="adsbygoogle"'){continue}
  $ms=$rx.Matches($t)
  if($ms.Count -eq 0){continue}
  $n=$rx.Replace($t,'')
  $d0=([regex]::Matches($t,'<div')).Count-([regex]::Matches($t,'</div>')).Count
  $d1=([regex]::Matches($n,'<div')).Count-([regex]::Matches($n,'</div>')).Count
  $l0=([regex]::Matches($t,'adsbygoogle\.js')).Count
  $l1=([regex]::Matches($n,'adsbygoogle\.js')).Count
  if($d0 -ne $d1 -or $l0 -ne $l1){$bad+=$f.Name; continue}
  [IO.File]::WriteAllText($f.FullName,$n,$u)
  $changed++; $removed+=$ms.Count
}
Write-Host "--- VERIFY ---" -ForegroundColor Cyan
Write-Host "Pages changed: $changed   Ad boxes removed: $removed"
if($bad.Count -gt 0){Write-Host ("FAIL  div balance or loader check failed on: "+($bad -join ', ')) -ForegroundColor Red; Write-Host 'Nothing committed. Run git restore . to undo.' -ForegroundColor Red; exit 1}
if($changed -eq 0){Write-Host 'Nothing to remove. NOTHING COMMITTED.' -ForegroundColor Yellow; exit 0}
Write-Host 'PASS  div balance and AdSense loader intact on every changed page' -ForegroundColor Green
$left=Select-String -Path $files.FullName -Pattern '<ins class="adsbygoogle"' -List
if($left){Write-Host ("WARN  ad tags still present (different markup) on: "+(($left | ForEach-Object {$_.Filename}) -join ', ')) -ForegroundColor Yellow}else{Write-Host 'PASS  no ad tags left on any page' -ForegroundColor Green}
$ld=(Select-String -Path $files.FullName -Pattern 'pagead2\.googlesyndication\.com/pagead/js/adsbygoogle\.js\?client=ca-pub-8127243414384620' -List | Measure-Object).Count
Write-Host "Pages with the AdSense loader (correct ID): $ld"
Write-Host '--- GIT ---' -ForegroundColor Cyan
git diff --stat
git add -u
git commit -m "Remove placeholder ad boxes with fake slot IDs; keep AdSense loader for Auto ads"
if($LASTEXITCODE -ne 0){Write-Host 'ERROR: commit failed.' -ForegroundColor Red; exit 1}
git pull --rebase
git push
git status
git log -1 --oneline
Write-Host 'DONE. Check Auto ads is on in AdSense (Ads > By site > nigelthomas.live > Edit).' -ForegroundColor Green
