# remove-dead-ad-boxes-2.ps1 - second pass for ad boxes with extra labels/comments/other wrapper classes
$repo='C:\Users\admin\Desktop\nigelthomas-portfolio'
Set-Location $repo
git pull --rebase --autostash
if($LASTEXITCODE -ne 0){Write-Host 'ERROR: git pull failed. NOTHING CHANGED.' -ForegroundColor Red; exit 1}
$u=New-Object System.Text.UTF8Encoding($false)
$fake='(?:0000000000|auto|xxxxxxxxxx|YOUR_AD_SLOT|REPLACE_WITH_AD_UNIT_ID_\d+)'
$push='\s*<script>\s*\(adsbygoogle\s*=\s*window\.adsbygoogle\s*\|\|\s*\[\]\)\.push\(\{\}\);?\s*</script>\s*'
$rx1=[regex]('(?is)[ \t]*<ins class="adsbygoogle"(?:(?!</ins>).)*?(?:data-ad-slot="'+$fake+'"|data-ad-client="[^"]*x{6,}[^"]*")(?:(?!</ins>).)*?</ins>'+$push)
$cm='<!--(?:(?!-->).)*-->\s*'
$rx2=[regex]('(?is)(?:<!--(?:(?!-->).)*?\bad\b(?:(?!-->).)*-->\s*)?<div class="(?:ad-slot|adsense-container|ad-unit)"[^>]*>\s*(?:'+$cm+')*(?:<div class="ad-label">[^<]*</div>\s*)?</div>[ \t]*(?:\r?\n)?')
$files=Get-ChildItem -Path $repo -Recurse -Include *.html -File | Where-Object { $_.FullName -notmatch '\\(node_modules|\.git)\\' }
$changed=0; $removed=0; $bad=@()
foreach($f in $files){
  $t=[IO.File]::ReadAllText($f.FullName,$u)
  if($t -notmatch '<ins class="adsbygoogle"'){continue}
  $c1=$rx1.Matches($t).Count
  if($c1 -eq 0){continue}
  $n=$rx1.Replace($t,'')
  $n=$rx2.Replace($n,'')
  $d0=([regex]::Matches($t,'<div')).Count-([regex]::Matches($t,'</div>')).Count
  $d1=([regex]::Matches($n,'<div')).Count-([regex]::Matches($n,'</div>')).Count
  $l0=([regex]::Matches($t,'adsbygoogle\.js')).Count
  $l1=([regex]::Matches($n,'adsbygoogle\.js')).Count
  if($d0 -ne $d1 -or $l0 -ne $l1){$bad+=$f.Name; continue}
  [IO.File]::WriteAllText($f.FullName,$n,$u)
  $changed++; $removed+=$c1
}
Write-Host '--- VERIFY ---' -ForegroundColor Cyan
Write-Host "Pages changed: $changed   Ad tags removed: $removed"
if($bad.Count -gt 0){Write-Host ('FAIL  div balance or loader check failed on: '+($bad -join ', ')) -ForegroundColor Red; Write-Host 'Nothing committed. Run git restore . to undo.' -ForegroundColor Red; exit 1}
if($changed -eq 0){Write-Host 'Nothing to remove. NOTHING COMMITTED.' -ForegroundColor Yellow; exit 0}
Write-Host 'PASS  div balance and AdSense loader intact on every changed page' -ForegroundColor Green
$left=Select-String -Path $files.FullName -Pattern '<ins class="adsbygoogle"' -List
if($left){Write-Host ('WARN  ad tags still present on: '+(($left | ForEach-Object {$_.Filename}) -join ', ')) -ForegroundColor Yellow}else{Write-Host 'PASS  no ad tags left on any page' -ForegroundColor Green}
$empty=Select-String -Path $files.FullName -Pattern 'class="(ad-slot|adsense-container|ad-unit)"' -List
if($empty){Write-Host ('INFO  ad wrapper divs still present on: '+(($empty | ForEach-Object {$_.Filename}) -join ', ')) -ForegroundColor Yellow}
$ph=Select-String -Path $files.FullName -Pattern 'ca-pub-x+' -List
if($ph){Write-Host ('WARN  placeholder publisher ID (ca-pub-xxxx) still on: '+(($ph | ForEach-Object {$_.Filename}) -join ', ')) -ForegroundColor Yellow}
Write-Host '--- GIT ---' -ForegroundColor Cyan
git diff --stat
git add -u
git commit -m "Remove remaining placeholder ad boxes (labelled wrappers, xxxx client IDs)"
if($LASTEXITCODE -ne 0){Write-Host 'ERROR: commit failed.' -ForegroundColor Red; exit 1}
git pull --rebase
git push
git status
git log -1 --oneline
Write-Host 'DONE.' -ForegroundColor Green
