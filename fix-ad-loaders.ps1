# fix-ad-loaders.ps1 - replaces placeholder publisher ID in AdSense loader scripts, verifies, pushes, shows tail of quality-controllers page
$repo='C:\Users\admin\Desktop\nigelthomas-portfolio'
Set-Location $repo
git pull --rebase --autostash
if($LASTEXITCODE -ne 0){Write-Host 'ERROR: git pull failed. NOTHING CHANGED.' -ForegroundColor Red; exit 1}
$u=New-Object System.Text.UTF8Encoding($false)
$real='ca-pub-8127243414384620'
$rx=[regex]'(?i)(adsbygoogle\.js\?client=)ca-pub-x{6,}'
$files=Get-ChildItem -Path $repo -Recurse -Include *.html -File | Where-Object { $_.FullName -notmatch '\\(node_modules|\.git)\\' }
$changed=@()
foreach($f in $files){
  $t=[IO.File]::ReadAllText($f.FullName,$u)
  if(-not $rx.IsMatch($t)){continue}
  $n=$rx.Replace($t,('${1}'+$real))
  [IO.File]::WriteAllText($f.FullName,$n,$u)
  $changed+=$f.Name
}
Write-Host '--- VERIFY ---' -ForegroundColor Cyan
Write-Host ('Loaders fixed on: '+($changed -join ', '))
foreach($name in 'color-coding-kitchen-housekeeping.html','general-manager-duties-and-responsibilities.html','quality-controllers-food-industry.html'){
  $p=(Get-ChildItem -Path $repo -Recurse -Include $name -File | Select-Object -First 1).FullName
  $t=[IO.File]::ReadAllText($p,$u)
  if($t.Contains('adsbygoogle.js?client='+$real)){Write-Host "PASS  correct loader on $name" -ForegroundColor Green}else{Write-Host "WARN  no correct loader on $name" -ForegroundColor Yellow}
  if($t -match '(?i)ca-pub-x{6,}'){Write-Host "WARN  placeholder ID still present on $name" -ForegroundColor Yellow}
}
if($changed.Count -gt 0){
  Write-Host '--- GIT ---' -ForegroundColor Cyan
  git diff --stat
  git add -u
  git commit -m "Fix placeholder publisher ID in AdSense loader scripts"
  if($LASTEXITCODE -ne 0){Write-Host 'ERROR: commit failed.' -ForegroundColor Red; exit 1}
  git pull --rebase
  git push
  git status
}else{Write-Host 'No loader placeholders found; nothing to commit.' -ForegroundColor Yellow}
Write-Host '--- TAIL OF quality-controllers-food-industry.html (send this to Claude) ---' -ForegroundColor Cyan
$qc=(Get-ChildItem -Path $repo -Recurse -Include quality-controllers-food-industry.html -File | Select-Object -First 1).FullName
$all=Get-Content -Path $qc
$i=0; for($k=0;$k -lt $all.Count;$k++){ if($all[$k] -match 'adsense-container'){$i=$k} }
for($k=[Math]::Max(0,$i-3);$k -lt $all.Count;$k++){ '{0,4}: {1}' -f ($k+1),$all[$k] }
