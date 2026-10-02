# update-frozen-desserts-page.ps1 - poster into the Infomatics panel with download button, interesting-blogs block below it, link/canonical fixes, verify, pull, push
$repo='C:\Users\admin\Desktop\nigelthomas-portfolio'
$slug='frozen-desserts.html'
$pname='frozen-desserts-poster.jpg'
$site='https://www.nigelthomas.live'
$u=New-Object System.Text.UTF8Encoding($false)
function Fail($m){Write-Host "ERROR: $m - NOTHING COMMITTED." -ForegroundColor Red; exit 1}
Set-Location $repo
git pull --rebase --autostash
if($LASTEXITCODE -ne 0){Fail 'git pull failed'}

# ---- poster into assets (also rescues a copy uploaded to the repo root) ----
$dst=Join-Path $repo ('assets\'+$pname)
$src=Join-Path $env:USERPROFILE ('Downloads\'+$pname)
$rootcopy=Join-Path $repo $pname
if(Test-Path $rootcopy){ Move-Item $rootcopy $dst -Force; Write-Host 'Moved poster from repo root into assets' -ForegroundColor Yellow }
if(-not(Test-Path $dst)){ if(Test-Path $src){Copy-Item $src $dst}else{Fail "poster $pname not found in Downloads or assets"} }

# ---- page ----
$pp=Join-Path $repo $slug
if(-not(Test-Path $pp)){Fail "$slug not found in repo"}
$t=[IO.File]::ReadAllText($pp,$u)
foreach($a in '<!-- NT INFOMATICS -->','<!-- END NT INFOMATICS -->','class="poster-wrap"','<style>'){ if($t.IndexOf($a) -lt 0){Fail "anchor not found in page: $a"} }

# 1. canonical, og:url, schema and in-body links: guide URL -> real file URL
$t=$t.Replace('<a href="https://www.nigelthomas.live/frozen-desserts-guide.html">','<a href="#infographic">')
$t=$t.Replace('https://www.nigelthomas.live/frozen-desserts-guide.html',"$site/$slug")
# 2. poster path (img, og:image, schema image)
$t=$t.Replace('/assets/frozen-desserts.jpg','/assets/'+$pname)
# 3. anchor id on the infomatics section
if(-not $t.Contains('id="infographic"')){ $t=$t.Replace('<div class="nt-infomatics-section">','<div class="nt-infomatics-section" id="infographic">') }
# 4. AdSense loader (Auto ads) if missing
if(-not $t.Contains('adsbygoogle.js?client=ca-pub-8127243414384620')){
  $k=$t.IndexOf('<style>'); $t=$t.Insert($k,'<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-8127243414384620" crossorigin="anonymous"></script>')
}
# 5. download button inside the panel, right after the poster
if(-not $t.Contains('download="Nigel-Thomas-Frozen-Desserts-Poster.jpg"')){
  $btn='<p style="text-align:center;margin:16px 0 0;"><a href="/assets/'+$pname+'" download="Nigel-Thomas-Frozen-Desserts-Poster.jpg" style="display:inline-block;background:#000;color:#d4af37;border:1px solid #d4af37;border-radius:4px;padding:12px 26px;font-family:Arial,sans-serif;font-size:14px;font-weight:700;letter-spacing:1.5px;text-decoration:none;">DOWNLOAD THE POSTER (JPG)</a></p>'
  $i=$t.IndexOf('class="poster-wrap"'); $j=$t.IndexOf('</div>',$i)+6; $t=$t.Insert($j,$btn)
}
# 6. related cards: drop cards pointing at pages that do not exist (404) and duplicates
$rx=[regex]'(?s)<a class="related-card" href="https://www\.nigelthomas\.live/([^"#?/]+\.html)">.*?</a>\s*'
$ms=$rx.Matches($t); $seen=@{}; $rm=@(); $removed=@()
foreach($m in $ms){ $f=$m.Groups[1].Value
  if(-not(Test-Path (Join-Path $repo $f))){$rm+=$m; $removed+=("missing: "+$f)}
  elseif($seen.ContainsKey($f)){$rm+=$m; $removed+=("duplicate: "+$f)}
  else{$seen[$f]=1} }
for($n=$rm.Count-1;$n -ge 0;$n--){ $t=$t.Remove($rm[$n].Index,$rm[$n].Length) }
if($removed.Count -gt 0){Write-Host ('Removed related cards: '+($removed -join ', ')) -ForegroundColor Yellow}
# 7. interesting blogs block below the infomatics button
$cand=@(@('sugar-free-dessert-menu.html','Dessert Series'),@('top-worldwide-famous-desserts.html','Dessert Series'),@('types-of-milk.html','Dairy Reference'),@('types-of-coffee-complete-guide.html','Bar &amp; Beverage Series'),@('classic-cocktails-guide.html','Bar &amp; Beverage Series'),@('classic-bread-recipes-guide.html','Recipe Series'),@('classic-burger-recipes-guide.html','Recipe Series'),@('healthy-daily-recipes.html','Recipe Series'),@('condiments-vs-sauces-fb-guide.html','F&amp;B Terminology Series'))
$cards=''; $count=0
foreach($c in $cand){
  if($count -ge 8){break}
  $f=Join-Path $repo $c[0]
  if(-not(Test-Path $f)){Write-Host ("skipped (not published yet): "+$c[0]) -ForegroundColor Yellow; continue}
  $ti=[regex]::Match([IO.File]::ReadAllText($f,$u),'(?is)<title>(.*?)</title>').Groups[1].Value
  $ti=(($ti -split '\s*\|\s*')[0]).Trim(); if(-not $ti){$ti=$c[0]}
  $cards+='<a class="related-card" href="'+$site+'/'+$c[0]+'"><div class="rc-tag">'+$c[1]+'</div><div class="rc-title">'+$ti+'</div></a>'
  $count++
}
$cards+='<a class="related-card" href="'+$site+'/blog.html"><div class="rc-tag">More Articles</div><div class="rc-title">View All Blog Posts</div></a>'
if($t.Contains('id="more-blogs"')){
  Write-Host 'more-blogs block already present, left as is' -ForegroundColor Yellow
}else{
  $blogs='<section id="more-blogs" style="max-width:820px;margin:34px auto 10px;padding:0 1.6rem;"><div class="related" style="margin-top:0"><h3>Interesting Blogs to Read Next</h3><div class="related-grid">'+$cards+'</div></div></section>'
  $e=$t.IndexOf('<!-- END NT INFOMATICS -->')+'<!-- END NT INFOMATICS -->'.Length; $t=$t.Insert($e,"`n"+$blogs)
}
[IO.File]::WriteAllText($pp,$t,$u)
Write-Host "Page updated: $slug" -ForegroundColor Green

# ---- verify ----
Write-Host '--- VERIFY ---' -ForegroundColor Cyan
$ok=$true
function Chk($name,$c){ if($c){Write-Host "PASS  $name" -ForegroundColor Green}else{Write-Host "FAIL  $name" -ForegroundColor Red; $script:ok=$false} }
$pg=[IO.File]::ReadAllText($pp,$u)
Chk 'poster in assets (over 200 KB)' ((Test-Path $dst) -and ((Get-Item $dst).Length -gt 200000))
Chk 'canonical points at the real file' ($pg.Contains('href="'+$site+'/'+$slug+'" rel="canonical"'))
Chk 'og:url points at the real file' ($pg.Contains('content="'+$site+'/'+$slug+'" property="og:url"'))
Chk 'no frozen-desserts-guide.html left' (-not $pg.Contains('frozen-desserts-guide.html'))
Chk 'no old frozen-desserts.jpg left' (-not $pg.Contains('/assets/frozen-desserts.jpg'))
Chk 'poster wired into infomatics panel' ($pg -match ('<div class="poster-wrap">\s*<img src="/assets/'+[regex]::Escape($pname)+'"'))
Chk 'download button present' ($pg.Contains('download="Nigel-Thomas-Frozen-Desserts-Poster.jpg"'))
Chk 'interesting blogs block present (3+ cards)' ($pg.Contains('id="more-blogs"') -and (([regex]::Matches($pg,'class="related-card"')).Count -ge 3))
Chk 'AdSense loader + account meta' ($pg.Contains('adsbygoogle.js?client=ca-pub-8127243414384620') -and $pg.Contains('google-adsense-account'))
Chk 'GA4 tag kept' ($pg.Contains('G-CLRRV5DMXZ'))
Chk 'infomatics toggle script kept' ($pg.Contains('nt-infomatics-button') -and $pg.Contains('classList.toggle("show")'))
Chk 'div tags balanced' (([regex]::Matches($pg,'<div')).Count -eq ([regex]::Matches($pg,'</div>')).Count)
$bad=@(); foreach($mt in [regex]::Matches($pg,'href="https://www\.nigelthomas\.live/([^"#?/]+\.html)"')){ if(-not(Test-Path (Join-Path $repo $mt.Groups[1].Value))){$bad+=$mt.Groups[1].Value} }
Chk ('every internal link resolves '+(($bad | Select-Object -Unique) -join ',')) ($bad.Count -eq 0)
$bl=[IO.File]::ReadAllText((Join-Path $repo 'blog.html'),$u)
Write-Host ("INFO  blog.html lists this page: "+$bl.Contains($slug)) -ForegroundColor Yellow
if(-not $ok){Fail 'verification failed (run git restore . to undo)'}

# ---- git ----
Write-Host '--- GIT ---' -ForegroundColor Cyan
git add $slug ('assets/'+$pname)
git add -u -- $pname 2>$null
git diff --cached --stat
git commit -m "Frozen desserts: poster in Infomatics with download, interesting blogs block, canonical and link fixes"
if($LASTEXITCODE -ne 0){Fail 'git commit failed'}
git pull --rebase
git push
git status --short
git log -1 --oneline
$trk=git ls-files ('assets/'+$pname)
if($trk){Write-Host ("PASS  poster tracked in assets ("+(Get-Item $dst).Length+" bytes)") -ForegroundColor Green}else{Write-Host 'FAIL  poster not tracked in assets' -ForegroundColor Red}
Write-Host "DONE. After Vercel deploys, open $site/$slug, hard-refresh (Ctrl+F5) and click VIEW INFOMATICS." -ForegroundColor Green
