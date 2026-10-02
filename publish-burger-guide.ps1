# publish-burger-guide.ps1 - builds the burger page from YOUR classic-cocktails-guide.html design, adds blog + sitemap, verifies, pulls, pushes
$repo='C:\Users\admin\Desktop\nigelthomas-portfolio'
$slug='classic-burger-recipes-guide.html'
$pname='classic-burger-recipes-poster.jpg'
$site='https://www.nigelthomas.live'
$today='2026-10-02'
$title='16 Classic Burger Recipes: The Complete Chef and F&B Guide'
$short='16 Classic Burger Recipes: The Complete Chef and F&B Guide'
$desc='16 classic burger recipes with exact ingredient quantities for one burger each: beef, cheese, chicken, fish, lamb, turkey and vegetarian, with method, safe cooking temperatures and a free poster for hospitality teams.'
$kw='burger recipes, classic burgers, beef burger, chicken burger, veggie burger, burger ingredients, F&B recipes, hotel kitchen, chef training, menu development'
$u=New-Object System.Text.UTF8Encoding($false)
function Fail($m){Write-Host "ERROR: $m - NOTHING COMMITTED." -ForegroundColor Red; exit 1}
function Enc($x){[Net.WebUtility]::HtmlEncode($x)}
Set-Location $repo
git pull --rebase --autostash
if($LASTEXITCODE -ne 0){Fail 'git pull failed'}

# ---- poster into assets ----
$dst=Join-Path $repo ('assets\'+$pname)
$src=Join-Path $env:USERPROFILE ('Downloads\'+$pname)
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
01|Classic Beef Burger|Ground beef=150 g;Burger bun=1;Lettuce=1 leaf;Tomato=2 slices;Onion=2 rings;Pickles=3 slices;Ketchup=1 tbsp;Mustard=1 tsp;Salt &amp; pepper=to taste|Season the patty and grill or pan-sear to 160&#176;F (71&#176;C), toast the bun, then stack with lettuce, tomato, onion and pickles.
02|Classic Cheeseburger|Ground beef=150 g;Burger bun=1;Cheddar=1 slice;Lettuce=1 leaf;Tomato=2 slices;Pickles=3 slices;Ketchup=1 tbsp;Mustard=1 tsp;Salt &amp; pepper=to taste|Cook as the classic burger, laying the cheddar on the patty for the last minute so it melts before assembly.
03|Crispy Chicken Burger|Chicken breast=150 g;Burger bun=1;Plain flour=40 g;Beaten egg=&#189;;Breadcrumbs=40 g;Lettuce=1 leaf;Mayonnaise=1 tbsp;Paprika=&#189; tsp;Salt &amp; pepper=to taste;Frying oil=as needed|Coat the chicken in flour, egg and seasoned breadcrumbs, fry until golden and 165&#176;F (74&#176;C), then dress with mayonnaise and lettuce.
04|Classic Veggie Burger|Cooked kidney beans=120 g;Breadcrumbs=25 g;Finely chopped onion=20 g;Ground cumin=&#188; tsp;Oil=1 tsp;Burger bun=1;Lettuce=1 leaf;Tomato=2 slices;Mayonnaise=1 tbsp;Salt &amp; pepper=to taste|Mash the beans with breadcrumbs, onion and cumin, shape, pan-fry in oil until crisp, then build with salad and mayonnaise.
05|Mushroom Swiss Burger|Ground beef=150 g;Burger bun=1;Swiss cheese=1 slice;Mushrooms=60 g;Butter=1 tsp;Mayonnaise=1 tbsp;Salt &amp; pepper=to taste|Saute the mushrooms in butter, cook the patty, melt the Swiss cheese on top and pile the mushrooms high.
06|BBQ Bacon Burger|Ground beef=150 g;Burger bun=1;Cheddar=1 slice;Cooked beef bacon=2 strips;BBQ sauce=1 tbsp;Onion=2 rings;Lettuce=1 leaf;Salt &amp; pepper=to taste|Cook the patty with cheddar, crisp the bacon, then layer with onion rings and BBQ sauce on a toasted bun.
07|Classic Fish Burger|White fish fillet=150 g;Burger bun=1;Plain flour=25 g;Beaten egg=&#189;;Breadcrumbs=30 g;Tartar sauce=1 tbsp;Lettuce=1 leaf;Salt &amp; pepper=to taste;Frying oil=as needed|Crumb the fish in flour, egg and breadcrumbs, fry until golden and 145&#176;F (63&#176;C), then top with tartar sauce and lettuce.
08|Grilled Chicken Burger|Chicken breast=150 g;Burger bun=1;Olive oil=1 tsp;Lemon juice=1 tsp;Garlic powder=&#188; tsp;Mayonnaise=1 tbsp;Lettuce=1 leaf;Tomato=2 slices;Salt &amp; pepper=to taste|Marinate the chicken in oil, lemon and garlic, grill to 165&#176;F (74&#176;C), and serve with mayonnaise, lettuce and tomato.
09|Classic Turkey Burger|Ground turkey=150 g;Burger bun=1;Breadcrumbs=10 g;Grated onion=15 g;Oil=1 tsp;Lettuce=1 leaf;Tomato=2 slices;Mayonnaise=1 tbsp;Salt &amp; pepper=to taste|Mix the turkey with breadcrumbs and onion, cook in oil to 165&#176;F (74&#176;C) without overworking, then dress with mayonnaise.
10|Double Smash Cheeseburger|Ground beef=160 g;Burger bun=1;Cheddar=2 slices;Pickles=4 slices;Finely chopped onion=15 g;Ketchup=1 tbsp;Mustard=1 tsp;Salt &amp; pepper=to taste|Smash two thin patties on a very hot surface, add cheddar to each, stack, and finish with pickles, onion, ketchup and mustard.
11|Portobello Mushroom Burger|Large portobello mushroom=1;Burger bun=1;Vegetarian mozzarella=1 slice;Olive oil=1 tsp;Balsamic vinegar=1 tsp;Lettuce=1 leaf;Tomato=2 slices;Mayonnaise=1 tbsp;Salt &amp; pepper=to taste|Marinate the portobello in oil and balsamic, grill until tender, melt the mozzarella on top and build with salad and mayonnaise.
12|Classic Lamb Burger|Ground lamb=150 g;Burger bun=1;Finely chopped onion=15 g;Ground cumin=&#188; tsp;Plain yogurt=1 tbsp;Chopped mint=1 tsp;Lettuce=1 leaf;Tomato=2 slices;Salt &amp; pepper=to taste|Mix the lamb with onion and cumin, cook to 160&#176;F (71&#176;C), then top with yogurt and mint, lettuce and tomato.
13|Hawaiian Beef Burger|Ground beef=150 g;Burger bun=1;Pineapple=1 ring;Cheddar=1 slice;Teriyaki sauce=1 tbsp;Lettuce=1 leaf;Oil=1 tsp;Salt &amp; pepper=to taste|Glaze the patty with teriyaki, grill a pineapple ring in oil, melt the cheddar and stack with lettuce.
14|Blue Cheese Burger|Ground beef=150 g;Burger bun=1;Blue cheese=25 g;Sliced onion=40 g;Butter=1 tsp;Mayonnaise=1 tbsp;Lettuce=1 leaf;Salt &amp; pepper=to taste|Caramelise the onion in butter, cook the patty, crumble blue cheese over it to melt, then add mayonnaise and lettuce.
15|Spicy Jalape&#241;o Burger|Ground beef=150 g;Burger bun=1;Cheddar=1 slice;Pickled jalape&#241;os=15 g;Mayonnaise=1 tbsp;Hot sauce=1 tsp;Lettuce=1 leaf;Tomato=2 slices;Salt &amp; pepper=to taste|Melt cheddar over the patty, top with pickled jalape&#241;os, and finish with a mayonnaise and hot sauce spread, lettuce and tomato.
16|Black Bean Burger|Cooked black beans=120 g;Breadcrumbs=25 g;Finely chopped onion=20 g;Ground cumin=&#188; tsp;Smoked paprika=&#188; tsp;Oil=1 tsp;Burger bun=1;Avocado=40 g;Lettuce=1 leaf;Tomato=2 slices;Salt &amp; pepper=to taste|Mash the beans with breadcrumbs, onion and spices, pan-fry in oil until firm, and top with avocado, lettuce and tomato.
'@
$intro=@'
<p>A burger looks like the simplest item on a menu, which is exactly why it exposes a kitchen so quickly. Patty weight drifts, buns arrive soggy, cheese goes on too early, and the same burger tastes different on every shift. Guests notice, and so does the food cost report.</p>
<p>This guide gives you 16 classic burger recipes with exact ingredient quantities for one burger each, so they scale cleanly from a single order to a full banquet. Every recipe has a short method and the safe cooking temperature that matters on a working line. The poster at the bottom of the page puts all 16 on one sheet you can print for the kitchen.</p>
<div class="pull-quote"><p>"A good burger is not a secret recipe. It is the same weights, the same temperatures and the same build, every single time."</p></div>
<h2><span class="num">01</span> Why Standard Recipes Matter</h2>
<p>Standardised quantities are the foundation of consistent quality and accurate costing. When every beef burger starts at 150 g, every cook plates the same product, and your costing sheet reflects what actually leaves the pass. The same discipline underpins good menu engineering, which we cover in <a href="https://www.nigelthomas.live/types-of-menus-fb-service.html">Types of Menus in F&amp;B Service</a> and <a href="https://www.nigelthomas.live/food-cost-basics.html">Food Cost Basics</a>.</p>
<p>The 16 burgers below share a small core of ingredients: bun, lettuce, tomato, mayonnaise and a handful of proteins. That overlap is deliberate. It lets a kitchen offer real variety on the menu while keeping purchasing and mise en place manageable.</p>
'@
$groups=@('Everyday Classics|The four foundations every menu needs: beef, cheese, chicken and a vegetarian option.','Grill, Fry and Flavour|Mushroom, barbecue, fish and grilled chicken burgers that widen the menu without widening the pantry.','Lean, Plant-Based and Smashed|Turkey, double smash, portobello and lamb, for lighter, vegetarian and premium options.','Bold and Signature|Hawaiian, blue cheese, jalape&ntilde;o and black bean burgers for specials and signature menu slots.')
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
<h2><span class="num">06</span> Kitchen Standards for Every Burger</h2>
<ul class="cklist">
<li>Cook ground beef and lamb patties to 160&deg;F (71&deg;C) and poultry patties to 165&deg;F (74&deg;C); cook fish to 145&deg;F (63&deg;C)</li>
<li>Check a sample patty with a probe thermometer each shift and record the result</li>
<li>Toast every bun so it holds up against sauces and juices</li>
<li>Melt cheese on the patty in the final minute, not earlier</li>
<li>Keep raw meat, poultry and fish apart from ready-to-eat toppings, with dedicated boards and utensils</li>
<li>Weigh patties before cooking, and keep frying oil fresh and at the right temperature for crumbed items</li>
<li>Flag allergens at order: wheat (buns, flour, breadcrumbs), egg, milk, fish and mustard appear across these recipes</li>
</ul>
<h2><span class="num">07</span> Frequently Asked Questions</h2>
<h3>How many burgers should a menu carry?</h3>
<p>Most venues do well with four to six: a beef burger, a cheeseburger, a chicken burger, a fish or premium special and a vegetarian option. Add specials from the remaining recipes when ingredients are in season or overstocked.</p>
<h3>Can these recipes be scaled for banquets?</h3>
<p>Yes. Every quantity is for one burger, so multiply by the cover count and add a small allowance for waste and testing. Always run a small trial batch before a large event.</p>
<h3>What is the biggest cause of a dry burger?</h3>
<p>Overcooking and overworking the meat. Handle the mix lightly, shape patties evenly, rest them briefly after cooking and rely on a thermometer rather than guesswork.</p>
<p>Sixteen burgers, one standard way of building them. Print the poster, brief the line team, and let the weights and temperatures do the work.</p>
<p style="font-style:italic;color:var(--muted);margin-top:2rem;">Nigel A. Thomas, F&amp;B and Hospitality Operations Professional | India &middot; Middle East &middot; USA</p>
<div class="related"><h3>Related Recipe &amp; F&amp;B Reading</h3><div class="related-grid">
<a class="related-card" href="https://www.nigelthomas.live/types-of-sandwiches.html"><div class="rc-tag">Culinary Reference</div><div class="rc-title">Types of Sandwiches</div></a>
<a class="related-card" href="https://www.nigelthomas.live/condiments-vs-sauces-fb-guide.html"><div class="rc-tag">F&amp;B Terminology Series</div><div class="rc-title">Condiments vs Sauces: The Complete Guide</div></a>
<a class="related-card" href="https://www.nigelthomas.live/food-cost-basics.html"><div class="rc-tag">Cost Control</div><div class="rc-title">Food Cost Basics</div></a>
<a class="related-card" href="https://www.nigelthomas.live/6-types-of-fried-fish.html"><div class="rc-tag">Recipes</div><div class="rc-title">6 Types of Fried Fish</div></a>
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
$hero='<section class="hero"><span class="eyebrow">Recipe Series &middot; Burger Reference</span><h1>16 Classic Burger Recipes <span class="accent">The Complete Chef &amp; F&amp;B Guide</span></h1><p class="lead">Sixteen burgers, exact quantities for one burger each, safe cooking temperatures and a printable poster. A practical reference for chefs, line cooks and F&amp;B managers.</p><div class="hero-pills"><span>By Nigel A. Thomas</span><span>October 2026</span><span>~8 min read</span><span>Recipe Reference</span></div></section>'
$h0=$pg.IndexOf('<section class="hero">'); $h1=$pg.IndexOf('</section>',$h0)+10
$pg=$pg.Substring(0,$h0)+$hero+$pg.Substring($h1)
$a0=$pg.IndexOf('<article class="article-body">'); $a1=$pg.IndexOf('</article>')
$pg=$pg.Substring(0,$a0)+'<article class="article-body">'+"`n"+$body+"`n"+$author+$pg.Substring($a1)
$alt=Enc 'Classic burger recipes infographic: 16 burgers with ingredient quantities'
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
  $card='<div class="article-card">'+$nl+'<div class="article-title"><a href="'+$slug+'">'+(Enc $short)+'</a></div>'+$nl+'<div class="article-meta">Recipes &bull; Burger Series</div>'+$nl+'<div class="article-excerpt">16 classic burger recipes with exact ingredient quantities for one burger each, method, safe cooking temperatures and a free printable poster.</div>'+$nl+'<a class="read-more-btn" href="'+$slug+'">Read Article &rarr;</a>'+$nl+'<span class="badge">Newest</span>'+$nl+'</div>'+$nl
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
Chk 'hero present' ($pg2.Contains('16 Classic Burger Recipes'))
Chk 'all 16 burgers present' (([regex]::Matches($pg2,'<h3>\d+\. ')).Count -eq 16)
Chk 'infographic block with poster' ($pg2.Contains('class="nt-infomatics-button"') -and $pg2.Contains('/assets/'+$pname))
Chk 'infographic toggle script kept' ($pg2.Contains('nt-infomatics-button'))
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
git status --short
git commit -m "Add 16 Classic Burger Recipes guide with infographic"
if($LASTEXITCODE -ne 0){Fail 'git commit failed'}
git pull --rebase
git push
git status
git log -1 --oneline
Write-Host "DONE. After Vercel deploys, open $url and click VIEW INFOMATICS." -ForegroundColor Green
