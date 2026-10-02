# add-frozen-blog-card.ps1 - adds the frozen desserts card to blog.html, verifies, pulls, pushes
$repo='C:\Users\admin\Desktop\nigelthomas-portfolio'
$slug='frozen-desserts.html'
$u=New-Object System.Text.UTF8Encoding($false)
function Fail($m){Write-Host "ERROR: $m - NOTHING COMMITTED." -ForegroundColor Red; exit 1}
Set-Location $repo
git pull --rebase --autostash
if($LASTEXITCODE -ne 0){Fail 'git pull failed'}
if(-not(Test-Path (Join-Path $repo $slug))){Fail "$slug not found in repo"}
$bp=Join-Path $repo 'blog.html'
$b=[IO.File]::ReadAllText($bp,$u)
if($b.Contains($slug)){Write-Host 'blog.html already lists the page. Nothing to do.' -ForegroundColor Yellow; exit 0}
$b=[regex]::Replace($b,'\s*<span class="badge">Newest</span>','')
$mainEnd=$b.IndexOf('</main>')
$first=[regex]::Match($b,'<(div|article)\s+class="article-card[^"]*"[^>]*>')
if((-not $first.Success) -or ($first.Index -gt $mainEnd)){Fail 'no article cards found inside main in blog.html'}
if($b.Contains("`r`n")){$nl="`r`n"}else{$nl="`n"}
$card='<div class="article-card">'+$nl+'<div class="article-title"><a href="'+$slug+'">Frozen Desserts: The Complete Gelato, Ice Cream, Sherbet and Sorbet Guide</a></div>'+$nl+'<div class="article-meta">Pastry &amp; Dessert Series</div>'+$nl+'<div class="article-excerpt">Four frozen dessert styles explained: base, dairy, air, texture and service temperatures for hospitality professionals, with a free printable poster.</div>'+$nl+'<a class="read-more-btn" href="'+$slug+'">Read Article &rarr;</a>'+$nl+'<span class="badge">Newest</span>'+$nl+'</div>'+$nl
$b=$b.Insert($first.Index,$card)
[IO.File]::WriteAllText($bp,$b,$u)
Write-Host '--- VERIFY ---' -ForegroundColor Cyan
$b2=[IO.File]::ReadAllText($bp,$u)
$ok=$true
function Chk($name,$c){ if($c){Write-Host "PASS  $name" -ForegroundColor Green}else{Write-Host "FAIL  $name" -ForegroundColor Red; $script:ok=$false} }
Chk 'card present' ($b2.Contains('href="'+$slug+'"'))
Chk 'card sits inside main' ($b2.IndexOf('href="'+$slug+'"') -lt $b2.IndexOf('</main>'))
Chk 'exactly one Newest badge' (([regex]::Matches($b2,'<span class="badge">Newest</span>')).Count -eq 1)
Chk 'div tags balanced' (([regex]::Matches($b2,'<div')).Count -eq ([regex]::Matches($b2,'</div>')).Count)
if(-not $ok){Write-Host 'Verification failed - nothing committed. Run git restore blog.html to undo.' -ForegroundColor Red; exit 1}
git add blog.html
git diff --cached --stat
git commit -m "Add Frozen Desserts card to blog list"
if($LASTEXITCODE -ne 0){Fail 'git commit failed'}
git pull --rebase
git push
git status --short
git log -1 --oneline
Write-Host 'DONE. After Vercel deploys, open blog.html and check the new card at the top.' -ForegroundColor Green
