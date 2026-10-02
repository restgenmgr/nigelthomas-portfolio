# publish-bread-guide.ps1 - builds the burger page from YOUR classic-cocktails-guide.html design, adds blog + sitemap, verifies, pulls, pushes
$repo='C:\Users\admin\Desktop\nigelthomas-portfolio'
$slug='classic-bread-recipes-guide.html'
$pname='classic-bread-recipes-poster.jpg'
$site='https://www.nigelthomas.live'
$today='2026-10-02'
$title='16 Classic Bread Recipes: The Complete Baking Guide for F&B Teams'
$short='16 Classic Bread Recipes: The Complete Baking Guide for F&B Teams'
$desc='16 classic bread recipes with exact ingredient weights and yields: loaves, rolls, flatbreads, bagels, sourdough and more, with methods, oven temperatures and a free poster for bakers and hospitality teams.'
$kw='bread recipes, classic breads, white loaf, sourdough, baguette, focaccia, brioche, bagels, naan, baking guide, F&B recipes, bakery training'
$u=New-Object System.Text.UTF8Encoding($false)
function Fail($m){Write-Host "ERROR: $m - NOTHING COMMITTED." -ForegroundColor Red; exit 1}
function Enc($x){[Net.WebUtility]::HtmlEncode($x)}
Set-Location $repo
git pull --rebase --autostash
if($LASTEXITCODE -ne 0){Fail 'git pull failed'}

# ---- poster into assets ----
$dst=Join-Path $repo ('assets\'+$pname)
$src=Join-Path $env:USERPROFILE ('Downloads\'+$pname)
$rootcopy=Join-Path $repo $pname
if(Test-Path $rootcopy){ Move-Item $rootcopy $dst -Force; Write-Host "Moved poster from repo root into assets" -ForegroundColor Yellow }
if(-not(Test-Path $dst)){ if(Test-Path $src){Copy-Item $src $dst}else{Fail "poster $pname not found in Downloads or assets"} }

# ---- template = your sample design ----
$tp=Join-Path $repo 'classic-cocktails-guide.html'
if(-not(Test-Path $tp)){Fail 'template classic-cocktails-guide.html not found in repo'}
$t=[IO.File]::ReadAllText($tp,$u)
$ia=$t.IndexOf('<div class="author-box">'); $ie=$t.IndexOf('</article>')
if($ia -lt 0 -or $ie -lt $ia -or $t.IndexOf('<!-- NT INFOMATICS -->') -lt 0 -or $t.IndexOf('<style>') -lt 0 -or $t.IndexOf('<article class="article-body">') -lt 0 -or $t.IndexOf('<section class="hero">') -lt 0){Fail 'template anchors not found'}
$author=$t.Substring($ia,$ie-$ia)

# ---- content ----
$data=@'
01|Classic White Loaf|Bread flour=500 g;Water=300 ml;Instant yeast=7 g;Sugar=20 g;Softened butter=30 g;Salt=10 g|Makes 1 loaf. Knead until smooth, prove until doubled, shape, prove again and bake at 200&#176;C (400&#176;F) for 30 to 35 minutes.
02|Whole Wheat Loaf|Whole wheat flour=300 g;Bread flour=200 g;Water=340 ml;Instant yeast=7 g;Honey=25 g;Olive oil=25 ml;Salt=10 g|Makes 1 loaf. Knead to a smooth, slightly tacky dough, prove until doubled, shape and bake at 200&#176;C (400&#176;F) until it sounds hollow when tapped.
03|Classic French Baguettes|Bread flour=500 g;Water=350 ml;Instant yeast=5 g;Salt=10 g|Makes 2 baguettes. Mix a wet dough, fold it during a long rise, shape into baguettes, score and bake with steam at 230&#176;C (450&#176;F) until deep golden.
04|Rosemary Focaccia|Bread flour=500 g;Water=375 ml;Instant yeast=7 g;Olive oil, dough=30 ml;Olive oil, tray &amp; topping=30 ml;Fine salt=10 g;Fresh rosemary=2 tsp;Flaky salt=&#189; tsp|Makes 1 tray &#8226; 23 &#215; 33 cm. Rest a wet dough in an oiled tray, dimple with oiled fingers, top with rosemary and flaky salt, and bake at 220&#176;C (425&#176;F) until golden.
05|Classic Brioche|Bread flour=500 g;Eggs, without shells=200 g;Milk=100 ml;Instant yeast=7 g;Sugar=60 g;Softened butter=180 g;Salt=10 g;Beaten egg, glaze=1|Makes 1 loaf. Knead the flour, eggs and milk, add the butter gradually until silky, prove, chill, shape, glaze and bake at 180&#176;C (350&#176;F).
06|Soft Dinner Rolls|Bread flour=500 g;Milk=280 ml;Egg, without shell=50 g;Instant yeast=7 g;Sugar=40 g;Softened butter=50 g;Salt=9 g;Beaten egg, glaze=1|Makes 12 rolls. Knead a soft dough, divide into 12 equal rolls, prove until puffy, glaze with beaten egg and bake at 190&#176;C (375&#176;F) until golden.
07|Irish Soda Bread|Plain flour=500 g;Buttermilk=400 ml;Baking soda=5 g;Salt=8 g|Makes 1 round loaf. Mix the dry ingredients with the buttermilk without overworking, shape a round, cut a deep cross and bake at 200&#176;C (400&#176;F) for about 35 minutes.
08|Classic Pita Bread|Bread flour=500 g;Water=320 ml;Instant yeast=7 g;Olive oil=20 ml;Sugar=10 g;Salt=10 g|Makes 8 pitas. Knead, rest, divide into 8 rounds, roll thin and bake on a very hot surface at 250&#176;C (480&#176;F) until the pitas puff.
09|Classic Ciabatta|Bread flour=500 g;Water=400 ml;Instant yeast=5 g;Olive oil=20 ml;Salt=10 g|Makes 2 small loaves. Mix a very wet dough, fold it during a long rise, divide gently without knocking out the air and bake with steam at 230&#176;C (450&#176;F).
10|Challah|Bread flour=500 g;Water=180 ml;Eggs, without shells=100 g;Instant yeast=7 g;Sugar=50 g;Neutral oil=50 ml;Salt=9 g;Beaten egg, glaze=1|Makes 1 braided loaf. Knead a rich dough, prove, braid, glaze with beaten egg and bake at 180&#176;C (350&#176;F) until deep golden.
11|Classic Bagels|Bread flour=500 g;Water=280 ml;Instant yeast=7 g;Sugar=20 g;Salt=10 g;Water, boiling bath=2 litres;Honey, boiling bath=30 g|Makes 8 bagels. Knead a stiff dough, shape into rings, prove, boil briefly in the honey bath, then bake at 220&#176;C (425&#176;F) until glossy and golden.
12|Garlic Naan|Plain flour=500 g;Plain yogurt=150 g;Water=180 ml;Instant yeast=7 g;Sugar=15 g;Neutral oil=25 ml;Salt=8 g;Melted butter, topping=40 g;Minced garlic, topping=3 cloves;Chopped coriander=1 tbsp|Makes 8 naans. Mix the yogurt dough, prove, roll out, cook on a very hot pan or grill, then brush with garlic butter and coriander.
13|Classic Sourdough|Bread flour=450 g;Whole wheat flour=50 g;Water=350 ml;Active starter, 100% hydration=100 g;Salt=10 g|Makes 1 round loaf. Mix flour, water and starter, rest, fold through a long fermentation, shape, proof and bake in a hot covered pot at 230&#176;C (450&#176;F).
14|English Muffins|Bread flour=500 g;Milk=300 ml;Instant yeast=7 g;Sugar=20 g;Softened butter=30 g;Salt=9 g;Cornmeal, dusting=30 g|Makes 10 muffins. Make a soft dough, prove, cut rounds and dust with cornmeal, then cook on a griddle over low heat until golden and cooked through.
15|Soft Pretzels|Bread flour=500 g;Water=300 ml;Instant yeast=7 g;Brown sugar=25 g;Melted butter=30 g;Fine salt=9 g;Water, dipping bath=2 litres;Baking soda, dipping bath=60 g;Coarse salt, topping=1 tsp|Makes 8 pretzels. Knead, shape into pretzels, dip briefly in the baking soda bath, add coarse salt and bake at 220&#176;C (425&#176;F) until deep brown.
16|Classic Cornbread|Fine cornmeal=200 g;Plain flour=150 g;Baking powder=10 g;Sugar=40 g;Salt=5 g;Milk=250 ml;Eggs, without shells=100 g;Melted butter=80 g|Makes 1 pan &#8226; 20 &#215; 20 cm. Mix the dry and wet ingredients just until combined, pour into a greased pan and bake at 200&#176;C (400&#176;F) until golden and set.
'@
$intro=@'
<p>Bread is the first thing a guest tastes and the last thing a kitchen gets time to perfect. Flour, water, yeast and salt look simple, yet the same recipe can give a dense loaf one day and a beautiful open crumb the next, depending on how it was weighed, mixed, proved and baked. Consistency is the whole craft.</p>
<p>This guide gives you 16 classic bread recipes with exact ingredient weights and the yield each one makes, so they scale cleanly from a small batch to a full service. Every recipe has a short method with oven temperatures in Celsius and Fahrenheit. The poster at the bottom of the page puts all 16 on one sheet you can print for the bakery section or the kitchen.</p>
<div class="pull-quote"><p>"Bread does not forgive guesswork. Weigh everything, watch the dough rather than the clock, and bake the same way every time."</p></div>
<h2><span class="num">01</span> Why Weigh Everything</h2>
<p>Professional bakers weigh every ingredient, including water, because volume measures vary too much from one scoop to the next. A 500 g flour base keeps recipes easy to compare, scale and cost, and it makes mistakes obvious. The same discipline supports menu costing, which we cover in <a href="https://www.nigelthomas.live/food-cost-basics.html">Food Cost Basics</a> and <a href="https://www.nigelthomas.live/types-of-menus-fb-service.html">Types of Menus in F&amp;B Service</a>.</p>
<p>Most of the 16 recipes share the same core of bread flour, water, yeast and salt, and differ in enrichment, shaping and bake. That overlap keeps purchasing simple while the bread basket stays varied.</p>
'@
$groups=@('Everyday Loaves|The four loaves every breakfast buffet, bakery counter and bread basket relies on.','Enriched and Quick Breads|Rich brioche and soft rolls, plus a no-yeast soda bread and the classic pocket pita.','Artisan and Festive Breads|Open-crumb ciabatta, braided challah, chewy bagels and garlic naan for showcase and banquet service.','Classic Specialities|Sourdough, English muffins, soft pretzels and cornbread for breakfast, bar and bistro menus.')
$sec=''
$lines=@($data -split "\r?\n" | Where-Object { $_.Trim() })
for($g=0;$g -lt 4;$g++){
  $gp=$groups[$g].Split('|')
  $sec+='<h2><span class="num">'+('{0:D2}' -f ($g+2))+'</span> Collection '+($g+1)+': '+$gp[0]+'</h2><p>'+$gp[1]+'</p>'
  for($k=0;$k -lt 4;$k++){
    $p=$lines[$g*4+$k].Split('|')
    $li=($p[2].Split(';') | ForEach-Object { $q=$_.Split('='); '<li>'+$q[0]+' - '+$q[1]+'</li>' }) -join ''
    $sec+='<h3>'+[int]$p[0]+'. '+$p[1]+'</h3><ul class="cklist">'+$li+'</ul><p><strong>Method:</strong> '+$p[3]+'</p>'
  }
}
$tail=@'
<h2><span class="num">06</span> Bakery Standards for Every Loaf</h2>
<ul class="cklist">
<li>Weigh every ingredient, including water, and keep a scale at the bake station</li>
<li>Check water and dough temperature, because warm dough proves faster and cold dough slower</li>
<li>Judge proofing by the dough, which should look puffy and spring back slowly, not only by the clock</li>
<li>Bake loaves until they sound hollow when tapped, at roughly 90&ndash;99&deg;C (195&ndash;210&deg;F) inside depending on the dough</li>
<li>Cool bread on a rack before slicing so the crumb can set</li>
<li>Treat raw flour and raw egg dough as raw ingredients: do not taste raw dough, and wash hands and surfaces after handling</li>
<li>Flag allergens at order: wheat (gluten), egg, milk and honey appear across these recipes</li>
</ul>
<h2><span class="num">07</span> Frequently Asked Questions</h2>
<h3>Why weigh flour and water instead of using cups?</h3>
<p>A cup of flour can vary by 20 percent or more depending on how it is scooped. Weighing gives the same dough every time, which is what makes bread consistent and costable.</p>
<h3>Can these recipes be scaled for service?</h3>
<p>Yes. Scale every ingredient by weight, including yeast and salt. Larger batches hold heat and proof differently, so test proof times on the first big batch before relying on them.</p>
<h3>Why did my bread come out dense?</h3>
<p>The usual causes are under-proofing, too little kneading, old yeast or the wrong flour. Check the yeast is fresh, let the dough finish its rise, and use bread flour where the recipe asks for it.</p>
<p>Sixteen breads, one standard way of making them. Print the poster, brief the team, and let the weights and temperatures do the work.</p>
<p style="font-style:italic;color:var(--muted);margin-top:2rem;">Nigel A. Thomas, F&amp;B and Hospitality Operations Professional | India &middot; Middle East &middot; USA</p>
<div class="related"><h3>Related Recipe &amp; F&amp;B Reading</h3><div class="related-grid">
<a class="related-card" href="https://www.nigelthomas.live/classic-burger-recipes-guide.html"><div class="rc-tag">Recipe Series</div><div class="rc-title">16 Classic Burger Recipes</div></a>
<a class="related-card" href="https://www.nigelthomas.live/types-of-sandwiches.html"><div class="rc-tag">Culinary Reference</div><div class="rc-title">Types of Sandwiches</div></a>
<a class="related-card" href="https://www.nigelthomas.live/food-cost-basics.html"><div class="rc-tag">Cost Control</div><div class="rc-title">Food Cost Basics</div></a>
<a class="related-card" href="https://www.nigelthomas.live/condiments-vs-sauces-fb-guide.html"><div class="rc-tag">F&amp;B Terminology Series</div><div class="rc-title">Condiments vs Sauces: The Complete Guide</div></a>
<a class="related-card" href="https://www.nigelthomas.live/blog.html"><div class="rc-tag">More Articles</div><div class="rc-title">View All Blog Posts</div></a>
</div></div>
'@
$body=$intro+$sec+$tail

# ---- assemble page on the sample design ----
$url="$site/$slug"; $img="$site/assets/$pname"
$pg=$t
$pg=[regex]::Replace($pg,'(?is)<title>.*?</title>','')
$pg=[regex]::Replace($pg,'(?is)<script type="application/ld\+json">.*?</script>','')
$pg=[regex]::Replace($pg,'(?i)<link[^>]+rel="canonical"[^>]*>','')
$pg=[regex]::Replace($pg,'(?i)<meta[^>]+(name="(description|keywords|twitter:card)"|property="og:[a-z:_]+")[^>]*>','')
$ld='{"@context":"https://schema.org","@type":"Article","headline":"'+$title+'","description":"'+$desc+'","image":"'+$img+'","author":{"@type":"Person","name":"Nigel A. Thomas","url":"'+$site+'"},"publisher":{"@type":"Organization","name":"Nigel Thomas","url":"'+$site+'"},"datePublished":"'+$today+'","dateModified":"'+$today+'","mainEntityOfPage":"'+$url+'","keywords":"'+$kw+'"}'
$inj='<title>'+(Enc $title)+' | Nigel A. Thomas</title><meta content="'+(Enc $desc)+'" name="description"/><meta content="'+(Enc $kw)+'" name="keywords"/><link href="'+$url+'" rel="canonical"/><meta content="'+(Enc $title)+'" property="og:title"/><meta content="'+(Enc $desc)+'" property="og:description"/><meta content="article" property="og:type"/><meta content="'+$url+'" property="og:url"/><meta content="'+$img+'" property="og:image"/><meta content="Nigel Thomas" property="og:site_name"/><meta content="summary_large_image" name="twitter:card"/><script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-8127243414384620" crossorigin="anonymous"></script><script type="application/ld+json">'+$ld+'</script>'
$k=$pg.IndexOf('<style>'); $pg=$pg.Insert($k,$inj)
$hero='<section class="hero"><span class="eyebrow">Recipe Series &middot; Bread Reference</span><h1>16 Classic Bread Recipes <span class="accent">The Complete Baking Guide for F&amp;B Teams</span></h1><p class="lead">Sixteen breads, exact weights with the yield for each, oven temperatures and a printable poster. A practical reference for bakers, chefs and F&amp;B managers.</p><div class="hero-pills"><span>By Nigel A. Thomas</span><span>October 2026</span><span>~8 min read</span><span>Recipe Reference</span></div></section>'
$h0=$pg.IndexOf('<section class="hero">'); $h1=$pg.IndexOf('</section>',$h0)+10
$pg=$pg.Substring(0,$h0)+$hero+$pg.Substring($h1)
$a0=$pg.IndexOf('<article class="article-body">'); $a1=$pg.IndexOf('</article>')
$pg=$pg.Substring(0,$a0)+'<article class="article-body">'+"`n"+$body+"`n"+$author+$pg.Substring($a1)
$alt=Enc 'Classic bread recipes infographic: 16 breads with ingredient weights'
$pg=[regex]::Replace($pg,'(<div class="poster-wrap">\s*<img src=")[^"]*(" alt=")[^"]*(")',('${1}/assets/'+$pname+'${2}'+$alt+'${3}'))
$pagePath=Join-Path $repo $slug
[IO.File]::WriteAllText($pagePath,$pg,$u)
Write-Host "Page written: $slug" -ForegroundColor Green

# ---- blog.html ----
$bp=Join-Path $repo 'blog.html'
$b=[IO.File]::ReadAllText($bp,$u)
if($b.Contains($slug)){Write-Host 'blog already lists the page' -ForegroundColor Yellow}else{
  $b=[regex]::Replace($b,'\s*<span class="badge">Newest</span>','')
  $mainEnd=$b.IndexOf('</main>')
  $first=[regex]::Match($b,'<(div|article)\s+class="article-card[^"]*"[^>]*>')
  if((-not $first.Success) -or ($first.Index -gt $mainEnd)){Fail 'no article cards found inside main in blog.html'}
  if($b.Contains("`r`n")){$nl="`r`n"}else{$nl="`n"}
  $card='<div class="article-card">'+$nl+'<div class="article-title"><a href="'+$slug+'">'+(Enc $short)+'</a></div>'+$nl+'<div class="article-meta">Recipes &bull; Bread Series</div>'+$nl+'<div class="article-excerpt">16 classic bread recipes with exact ingredient weights and yields, methods, oven temperatures and a free printable poster.</div>'+$nl+'<a class="read-more-btn" href="'+$slug+'">Read Article &rarr;</a>'+$nl+'<span class="badge">Newest</span>'+$nl+'</div>'+$nl
  $b=$b.Insert($first.Index,$card)
  [IO.File]::WriteAllText($bp,$b,$u)
  Write-Host 'blog.html updated' -ForegroundColor Green
}

# ---- sitemap.xml ----
$sp=Join-Path $repo 'sitemap.xml'
$s=[IO.File]::ReadAllText($sp,$u)
if($s.Contains($slug)){Write-Host 'sitemap already lists the page' -ForegroundColor Yellow}else{
  $mm=[regex]::Match($s,'(?s)<url>.*?</url>')
  if(-not $mm.Success){Fail 'no url block found in sitemap.xml'}
  $nu=[regex]::Replace($mm.Value,'<loc>[^<]*</loc>',('<loc>'+$url+'</loc>'))
  $nu=[regex]::Replace($nu,'<lastmod>[^<]*</lastmod>',('<lastmod>'+$today+'</lastmod>'))
  if($s.Contains("`r`n")){$nls="`r`n"}else{$nls="`n"}
  $ls=$s.LastIndexOf("`n",$mm.Index); $ind=''
  if($ls -ge 0){$pad=$s.Substring($ls+1,$mm.Index-$ls-1); if($pad.Trim() -eq ''){$ind=$pad}}
  $s=$s.Insert($mm.Index+$mm.Length,$nls+$ind+$nu)
  [IO.File]::WriteAllText($sp,$s,$u)
  Write-Host 'sitemap.xml updated' -ForegroundColor Green
}

# ---- verify ----
Write-Host '--- VERIFY ---' -ForegroundColor Cyan
$ok=$true
function Chk($name,$c){ if($c){Write-Host "PASS  $name" -ForegroundColor Green}else{Write-Host "FAIL  $name" -ForegroundColor Red; $script:ok=$false} }
$pg2=[IO.File]::ReadAllText($pagePath,$u)
Chk 'poster in assets' (Test-Path $dst)
Chk 'canonical correct' ($pg2.Contains('href="'+$url+'" rel="canonical"'))
Chk 'og:url correct' ($pg2.Contains('content="'+$url+'" property="og:url"'))
Chk 'no leftover cocktail references' (-not $pg2.Contains('classic-cocktails-guide'))
Chk 'sample design CSS kept' ($pg2.Contains('--gold:#d4af37') -and $pg2.Contains('.nt-infomatics-button'))
Chk 'hero present' ($pg2.Contains('16 Classic Bread Recipes'))
Chk 'all 16 breads present' (([regex]::Matches($pg2,'<h3>\d+\. ')).Count -eq 16)
Chk 'infographic block with poster' ($pg2.Contains('class="nt-infomatics-button"') -and $pg2.Contains('/assets/'+$pname))
Chk 'poster img wired to assets' ($pg2 -match ('<div class="poster-wrap">\s*<img src="/assets/'+[regex]::Escape($pname)+'"'))
Chk 'AdSense loader + account meta' ($pg2.Contains('adsbygoogle.js?client=ca-pub-8127243414384620') -and $pg2.Contains('google-adsense-account'))
Chk 'GA4 tag kept' ($pg2.Contains('G-CLRRV5DMXZ'))
Chk 'author box kept' ($pg2.Contains('class="author-box"'))
Chk 'div tags balanced' (([regex]::Matches($pg2,'<div')).Count -eq ([regex]::Matches($pg2,'</div>')).Count)
$bad=@(); foreach($mt in [regex]::Matches($body,'href="https://www\.nigelthomas\.live/([^"#?/]+\.html)"')){ if(-not(Test-Path (Join-Path $repo $mt.Groups[1].Value))){$bad+=$mt.Groups[1].Value} }
Chk ('internal links resolve '+($bad -join ',')) ($bad.Count -eq 0)
Chk 'blog.html lists page' ([IO.File]::ReadAllText($bp,$u).Contains($slug))
Chk 'sitemap.xml lists page' ([IO.File]::ReadAllText($sp,$u).Contains($slug))
if(-not $ok){Fail 'verification failed (run git restore . and delete the new page to undo)'}

# ---- git ----
Write-Host '--- GIT ---' -ForegroundColor Cyan
git add $slug blog.html sitemap.xml ('assets/'+$pname)
git add -u -- $pname 2>$null
git status --short
git commit -m "Add 16 Classic Bread Recipes guide with infographic"
if($LASTEXITCODE -ne 0){Fail 'git commit failed'}
git pull --rebase
git push
git status --short
git log -1 --oneline
$trk=git ls-files ('assets/'+$pname)
if($trk -and ((Get-Item $dst).Length -gt 200000)){Write-Host ("PASS  poster tracked in assets ("+(Get-Item $dst).Length+" bytes)") -ForegroundColor Green}else{Write-Host 'FAIL  poster not tracked in assets' -ForegroundColor Red}
Write-Host "DONE. After Vercel deploys, open $url and click VIEW INFOMATICS." -ForegroundColor Green
