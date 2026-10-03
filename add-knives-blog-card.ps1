# add-knives-blog-card.ps1 - checks in memory first, writes only if all checks pass, then commits, pulls, pushes
$repo='C:\Users\admin\Desktop\nigelthomas-portfolio'
$slug='essential-kitchen-knives-guide.html'
$u=New-Object System.Text.UTF8Encoding($false)
function Fail($m){Write-Host "ERROR: $m - NOTHING COMMITTED." -ForegroundColor Red; exit 1}
Set-Location $repo
if(git status --porcelain blog.html){ git restore blog.html; Write-Host 'Restored blog.html left modified by the earlier failed run' -ForegroundColor Yellow }
git pull --rebase --autostash
if($LASTEXITCODE -ne 0){Fail 'git pull failed'}
if(-not(Test-Path (Join-Path $repo $slug))){Fail "$slug not found in repo"}
$bp=Join-Path $repo 'blog.html'
$b=[IO.File]::ReadAllText($bp,$u)
if($b.Contains($slug)){Write-Host 'blog.html already lists the page. Nothing to do.' -ForegroundColor Yellow; exit 0}
function Bal($x){ ([regex]::Matches($x,'<div')).Count - ([regex]::Matches($x,'</div>')).Count }
$d0=Bal $b
$n=[regex]::Replace($b,'\s*<span class="badge">Newest</span>','')
$mainEnd=$n.IndexOf('</main>')
$first=[regex]::Match($n,'<(div|article)\s+class="article-card[^"]*"[^>]*>')
if((-not $first.Success) -or ($first.Index -gt $mainEnd)){Fail 'no article cards found inside main in blog.html'}
if($n.Contains("`r`n")){$nl="`r`n"}else{$nl="`n"}
$card='<div class="article-card">'+$nl+'<div class="article-title"><a href="'+$slug+'">9 Essential Kitchen Knives: The Right Knife for the Right Task</a></div>'+$nl+'<div class="article-meta">Kitchen &amp; Food Series</div>'+$nl+'<div class="article-excerpt">Nine essential kitchen knives explained for chefs and F&amp;B teams, with uses, technique, care and safety, plus a free printable poster.</div>'+$nl+'<a class="read-more-btn" href="'+$slug+'">Read Article &rarr;</a>'+$nl+'<span class="badge">Newest</span>'+$nl+'</div>'+$nl
$n=$n.Insert($first.Index,$card)
Write-Host '--- VERIFY (in memory, nothing written yet) ---' -ForegroundColor Cyan
$ok=$true
function Chk($name,$c){ if($c){Write-Host "PASS  $name" -ForegroundColor Green}else{Write-Host "FAIL  $name" -ForegroundColor Red; $script:ok=$false} }
Chk 'card present' ($n.Contains('href="'+$slug+'"'))
Chk 'card sits inside main' ($n.IndexOf('href="'+$slug+'"') -lt $n.IndexOf('</main>'))
Chk 'exactly one Newest badge' (([regex]::Matches($n,'<span class="badge">Newest</span>')).Count -eq 1)
Chk 'this edit does not change the div balance' ((Bal $n) -eq $d0)
if($d0 -ne 0){Write-Host ("INFO  blog.html already had a div imbalance of "+$d0+" before this edit (an extra closing tag). Not caused by this script.") -ForegroundColor Yellow}
if(-not $ok){Fail 'verification failed, blog.html left untouched'}
[IO.File]::WriteAllText($bp,$n,$u)
git add blog.html
git diff --cached --stat
git commit -m "Add Kitchen Knives card to blog list"
if($LASTEXITCODE -ne 0){Fail 'git commit failed'}
git pull --rebase
git push
git status --short
git log -1 --oneline
Write-Host 'DONE. After Vercel deploys, open blog.html and check the new card at the top.' -ForegroundColor Green
