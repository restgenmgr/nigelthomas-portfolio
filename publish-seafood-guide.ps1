# publish-seafood-guide.ps1  -  page + blog + sitemap + verify + pull + push (aborts before commit on any problem)
$repo='C:\Users\admin\Desktop\nigelthomas-portfolio'
$slug='popular-seafood-varieties-guide.html'
$ref='6-types-of-fried-fish.html'
$site='https://www.nigelthomas.live'
$poster='assets/seafood-varieties-poster.jpg'
$today='2026-10-01'; $long='October 1, 2026'
$title='Popular Seafood Varieties: A Practical Guide for Chefs and F&B Teams'
$short='Popular Seafood Varieties: A Practical Guide'
$desc='A practical guide to 28 popular seafood varieties for chefs and F&B teams: finfish, crustaceans and molluscs, with buying, costing, allergen and menu tips plus a free downloadable infographic.'
$exc='28 popular seafood varieties explained for chefs and F&B teams, with buying, costing and allergen tips and a free downloadable infographic.'
$u=New-Object System.Text.UTF8Encoding($false)
function Fail($m){Write-Host "ERROR: $m - NOTHING COMMITTED." -ForegroundColor Red; exit 1}
function Enc($x){[Net.WebUtility]::HtmlEncode($x)}
Set-Location $repo
git pull --rebase --autostash
if($LASTEXITCODE -ne 0){Fail 'git pull failed'}
if(-not(Test-Path (Join-Path $repo 'assets\seafood-varieties-poster.jpg'))){Fail 'poster not found in assets folder'}

$fin=@'
Salmon|A rich, oily fish with pink to orange flesh and a buttery texture. It stays moist under high heat, which makes it forgiving for line cooks, and it takes well to curing, smoking and raw preparations when handled correctly.|Grilled fillets, sushi and sashimi, banquet mains, smoked platters.
Tuna|A firm, meaty fish with deep red flesh that is best served rare or raw. Overcooking turns it dry and chalky, so cooks should sear it quickly, and receivers must check colour and smell carefully.|Seared steaks, poke, sashimi, sandwiches and salads.
Cod|A mild white fish with large, tender flakes and a clean flavour. It absorbs seasoning and sauces well, holds up to roasting, poaching and frying, and is a staple of pub and family dining.|Fish and chips, baked dishes, chowders, casual restaurants.
Halibut|A flatfish with thick, white, lean flesh and a sweet, delicate taste. It dries out quickly when overcooked, so gentle pan roasting or poaching works best, and its premium price demands careful portioning.|Fine dining mains, pan roasted fillets, upscale hotel menus.
Mackerel|A strongly flavoured oily fish with silvery skin and rich, dark flesh. It is highly perishable and must be very fresh, but its bold taste stands up to grilling, curing and pickling.|Grilled whole fish, smoked dishes, tapas and Japanese cuisine.
Swordfish|A dense, meaty fish cut into steaks, with a mild flavour and few bones. It can dry out on the grill, so brushing with oil and watching the clock is essential for consistent results.|Grilled steaks, skewers, kebabs and Mediterranean menus.
Haddock|A close cousin of cod with a slightly sweeter taste and finer flake. It is popular smoked, and it performs well in batter, which makes it a reliable choice for high volume frying.|Battered fish, smoked fillets, kedgeree and chowders.
Snapper|A lean fish with firm white flesh and a sweet, nutty flavour, often recognised by its pink or red skin. It suits whole preparations, and its crisp skin when pan seared delights guests.|Whole roasted or grilled fish, curries, tropical and coastal menus.
Grouper|A large reef fish with thick, firm, mild flesh that holds together in soups and stews. Its size makes it ideal for portion cutting, though availability and sourcing should always be confirmed.|Pan seared fillets, fish stews, sandwiches and resort dining.
Tilapia|A freshwater fish with mild, lean, slightly sweet flesh that is widely farmed and affordable. It is easy to cook and consistent in size, which supports tight food cost control.|Budget friendly mains, staff meals, institutional and cafeteria menus.
Sea Bass|A premium fish with moist, white, delicate flesh and a clean taste. Crisp skin and gentle seasoning let the fish speak for itself, and a whole bass makes a striking tableside presentation.|Whole baked fish, fillets with light sauces, fine dining.
Sardines|Small, oily, silver fish packed with flavour and affordable at any scale. They are best cooked very fresh over a hot grill, and they also shine canned, marinated or served on toast.|Grilled platters, appetisers, tapas and rustic menus.
Barramundi|A prized fish from Asian and Australian waters with moist, buttery white flesh and a mild flavour. It is also farmed in many regions and gives chefs a dependable, versatile fillet.|Pan roasted fillets, curries, steamed dishes and hotel restaurants.
Anchovy|A tiny, intensely savoury fish that works as a seasoning as much as an ingredient. Salted or oil cured, it adds depth to sauces, dressings and pizzas, and a little goes a long way.|Caesar dressing, pizza, pasta sauces and antipasti.
Eel|A long, rich fish with fatty, tender flesh that is usually grilled or braised with a sweet glaze. It needs skilled preparation and must always be cooked thoroughly, never served raw.|Japanese grilled eel, smoked platters, stews and specialty restaurants.
Monkfish|A firm, boneless tail with a texture often compared to lobster. It is mostly sold as the tail only, holds together in roasts and stews, and rewards chefs with excellent plate value.|Roasted medallions, curries, bouillabaisse and fine dining.
'@
$cru=@'
Lobster|The luxury centrepiece of the shellfish world, with sweet, dense meat in the tail and claws. Cook it just until opaque, because overcooking toughens it, and make sure live stock is lively when received.|Thermidor, grilled tails, bisques, banquets and celebration menus.
Crab|Sweet, delicate meat from the body and claws, available fresh, cooked or picked. Check origin and handling carefully, and use the rich brown meat for sauces and bisques.|Crab cakes, salads, curries, soups and cold seafood platters.
Shrimp|A small, fast cooking crustacean in countless sizes, sold fresh, frozen, peeled or shell on. Size grading drives price and plating, and overcooked shrimp curl tight and turn rubbery.|Cocktails, stir fries, pasta, tempura, buffets and bar snacks.
Prawn|Often larger than shrimp, with a firmer, meatier bite and a sweet taste. The two names are used loosely in different regions, so confirm species and size with suppliers rather than relying on the label.|Grilled king prawns, curries, skewers and tasting menus.
'@
$mol=@'
Scallop|A bivalve with a sweet, tender adductor muscle and sometimes the coral roe. Pat it dry and sear hard and fast for a golden crust, because wet scallops steam instead of browning.|Seared starters, crudo, risotto and tasting menus.
Mussel|A dark shelled bivalve that is affordable, farmed sustainably in many regions and quick to cook. Discard any that stay open before cooking or remain closed afterwards.|Steamed pots in wine broth, pasta, paella and bistro menus.
Clam|A bivalve with a sweet, briny flavour, sold live in a range of sizes. Purge them in cold salted water to remove grit and cook only until the shells open.|Chowder, linguine, steamed platters and Asian stir fries.
Oyster|A bivalve prized for its mineral, ocean flavour and often eaten raw. Strict cold chain control, tags and supplier documentation are essential, and shucking skill is a real service asset.|Raw bars, champagne pairings, grilled specials and luxury events.
Squid|A cephalopod with tender, mild flesh that turns tough when cooked a little too long. Flash fry or grill it in seconds, or braise it slowly until tender.|Fried calamari, grilled rings, stuffed squid and appetisers.
Octopus|A cephalopod with a chewy texture that softens through long, gentle cooking. Simmering or braising first, then charring, gives tender meat with a smoky edge.|Grilled octopus, salads, tapas and Mediterranean menus.
Cuttlefish|A cephalopod similar to squid but thicker and sweeter, with ink prized in sauces. It tolerates longer cooking than squid and makes a dramatic plate when the ink is used.|Black ink risotto, stews, grills and regional specials.
Sea Urchin|An echinoderm whose bright orange roe, called uni, tastes sweet, creamy and briny. It is extremely delicate and perishable, so serve it fresh and in small portions.|Sushi, pasta toppings, tasting menus and luxury plates.
'@
$qr=@'
Rich, forgiving fish for volume service|Salmon
Delicate premium white fish|Halibut or Sea Bass
Budget friendly mains|Tilapia or Haddock
Raw bar and sashimi programmes|Tuna, Salmon or Oyster
Luxury centrepiece dishes|Lobster or Scallop
Bold flavour on a small budget|Sardines or Mackerel
Seasoning and depth in sauces|Anchovy
'@
$n=0
function Cards($t){
  $h='<div class="two-col">'
  foreach($l in ($t -split "\r?\n")){ if(-not $l.Trim()){continue}
    $p=$l.Split('|'); $script:n++
    $h+='<div class="col-box"><h3><span class="num">'+$script:n+'</span>'+$p[0]+'</h3><p>'+$p[1]+'</p><div class="best-for"><strong>Best for:</strong> '+$p[2]+'</div></div>'
  }
  return $h+'</div>'
}
$cf=Cards $fin; $cc=Cards $cru; $cm=Cards $mol
$tbl='<table><tr><th>If your priority is...</th><th>Consider</th></tr>'
foreach($l in ($qr -split "\r?\n")){ if($l.Trim()){ $p=$l.Split('|'); $tbl+='<tr><td>'+$p[0]+'</td><td>'+$p[1]+'</td></tr>' } }
$tbl+='</table>'

$body=@'
<h1>Popular Seafood Varieties: A Practical Guide for Chefs and F&amp;B Teams</h1>
<p class="sf-meta">By Nigel A. Thomas &middot; Hospitality Executive and Corporate Trainer &middot; October 1, 2026</p>
<p>Walk into any well-run kitchen at six in the morning and you can tell within minutes how seriously the team takes seafood. The receiving table is clear, the ice is fresh, the thermometer is in hand, and someone is already checking gills, eyes and shells. Seafood is the most unforgiving category on the menu. It spoils faster than meat, it varies more from one delivery to the next, and a single mistake in storage or handling can turn a premium dish into a guest complaint or a food safety incident.</p>
<p>It is also one of the most profitable categories when handled well. Guests happily pay more for a perfectly seared scallop or a whole grilled snapper, and a server who can explain the difference between a prawn and a shrimp builds trust at the table. After three decades in luxury hotels, resorts and cruise operations across India, the Middle East and the USA, I have seen seafood make and break banquet menus, buffets and fine dining rooms alike.</p>
<p>This guide walks through 28 popular seafood varieties in the same order as the infographic at the bottom of the page, which you can download for your kitchen, your training room or your service briefing. For each variety you will find what it is, how it behaves in the kitchen, and where it fits best on a menu.</p>
<section class="breakdown"><h2>How the Seafood Family Is Organised</h2>
<p>Before memorising names, learn the families. Every variety in this guide belongs to one of four groups, and the group tells you most of what you need to know about storage, cooking and service.</p>
<p><strong>Finfish</strong> are vertebrate fish with fins and scales or skin. Within this group, oily fish such as salmon, mackerel and sardines carry more natural fat, cook quickly and spoil faster, while lean white fish such as cod, haddock and halibut are delicate, flake easily and need gentler heat.</p>
<p><strong>Crustaceans</strong> include lobster, crab, shrimp and prawn. They have a hard outer shell, cook in minutes, and turn rubbery when overcooked.</p>
<p><strong>Molluscs</strong> divide into bivalves such as scallops, mussels, clams and oysters, and cephalopods such as squid, octopus and cuttlefish. Bivalves are often served live or very lightly cooked, so sourcing and temperature control matter enormously. Cephalopods go one of two ways: cooked for seconds or cooked for an hour, never in between.</p>
<p>The last group has just one member here, the sea urchin, an echinoderm prized for its sweet, briny roe.</p></section>
<section class="breakdown"><h2>Finfish: Sixteen Varieties You Will Meet Most Often</h2>
<p>Finfish dominate most seafood menus, so this is where your team needs the strongest product knowledge.</p>{{FIN}}</section>
<section class="breakdown"><h2>Crustaceans: Shell, Sweetness and Speed</h2>
<p>Crustaceans are quick to cook and quick to ruin. Train your team to time them carefully and to store them cold and clean.</p>{{CRU}}</section>
<section class="breakdown"><h2>Molluscs and Echinoderms: Live Product, Live Responsibility</h2>
<p>Bivalves and cephalopods need the most careful sourcing on the list, and many are served raw or lightly cooked. Use only reputable, documented suppliers.</p>{{MOL}}</section>
<section class="breakdown"><h2>Quick Reference: Matching Seafood to the Menu</h2>{{TBL}}</section>
<section class="breakdown"><h2>Buying and Receiving: Where Quality Is Won or Lost</h2>
<p>Great seafood cookery begins at the back door. Train every receiver to use their senses and a thermometer before signing the invoice.</p>
<ul><li>Whole fish should have clear, bright eyes, red gills, firm elastic flesh and a clean smell of the sea, never a sharp or ammonia odour.</li>
<li>Fillets should look moist and translucent, with no gaping, browning or sticky film.</li>
<li>Live shellfish must be alive: shells tightly closed or closing when tapped, and lobsters and crabs actively moving.</li>
<li>Check temperature on arrival. Fresh fish should be received at 41&deg;F (5&deg;C) or below, packed in ice or under refrigeration.</li>
<li>Check tags, labels and origin documents, especially for oysters, clams and mussels, and keep records for traceability.</li></ul>
<p>Reject anything that fails these checks, and document the rejection. A firm receiving standard protects guests, margins and your reputation.</p></section>
<section class="breakdown"><h2>Costing, Yield and Portion Control</h2>
<p>Seafood is purchased in many forms, so the purchase price never tells the whole story. A whole fish may cost less per kilogram than fillets, but after heads, bones, skin and trim the edible yield can be as low as forty to fifty percent. Always run a yield test, record the results, and cost each dish on the usable weight, not the invoice weight.</p>
<p>Standardise portion sizes by weight or count, and train cooks to portion consistently. Use trim creatively in fish cakes, stocks, chowders and staff meals so that nothing of value goes to waste. For shellfish, size grading such as count per kilogram controls both plate appearance and cost. Review seafood prices weekly, because market swings are larger here than in almost any other category, and adjust specials accordingly. For a refresher on controlling cost across the whole operation, read <a href="food-cost-basics.html">Food Cost Basics</a>.</p></section>
<section class="breakdown"><h2>Food Safety and Allergen Awareness</h2>
<p>Cook fish to an internal temperature of 145&deg;F (63&deg;C) unless a compliant raw or undercooked preparation has been properly sourced and approved. Store raw seafood below cooked and ready to eat food, and use separate boards, knives and utensils. Keep live shellfish refrigerated in breathable containers, never sealed in airtight bags or submerged in fresh water.</p>
<p>Fish and crustaceans are recognised major food allergens, and in many jurisdictions molluscs are regulated as allergens too. Train servers to ask about allergies at every table, to know which dishes contain which species, and to alert the kitchen early. Shared fryers, grills and marinades are common sources of cross contact, so build clear protocols for them. Always follow your local regulations and your company food safety plan.</p></section>
<section class="breakdown"><h2>Seafood on the Menu: Planning and Service Tips</h2>
<p>Seafood suits almost every format. A seasonal menu can follow the catch calendar, and a du jour special lets you buy opportunistically and sell what is freshest that morning. An &agrave; la carte menu benefits from two or three signature seafood dishes with a clear price ladder, from an affordable fried fish to a premium lobster or scallop plate. To explore frying styles for casual menus, see <a href="6-types-of-fried-fish.html">6 Types of Fried Fish</a>, and for the formats themselves read <a href="types-of-menus-fb-service.html">Types of Menus in F&amp;B Service</a>.</p>
<p>Service staff are your best selling tool. Give them tasting notes, cooking times and pairing suggestions so they can describe each dish with confidence. Always tell guests when an item is subject to market availability, and never substitute species without clear communication.</p></section>
<section class="breakdown"><h2>Team Training Checklist</h2>
<ul><li>Can every cook identify all 28 varieties by sight and by name?</li>
<li>Can receivers perform freshness and temperature checks without prompting?</li>
<li>Do servers know which dishes contain fish, crustaceans and molluscs?</li>
<li>Does the kitchen run weekly yield tests on high cost items?</li>
<li>Are storage, labelling and first in, first out rules visible and enforced?</li></ul>
<p>Use the infographic below as a daily briefing tool, and quiz the team in pre-shift meetings until the names and families become second nature.</p></section>
<section class="sf-info" id="infographic"><h2>Download the Seafood Varieties Infographic</h2>
<p>All 28 varieties in one clean poster, grouped by family and ready to print for your kitchen, training room or pass. Save it, share it with your team, and pin it where people can see it.</p>
<img src="assets/seafood-varieties-poster.jpg" alt="Popular Seafood Varieties infographic showing 28 fish, crustaceans and molluscs" width="1200" height="1600" loading="lazy">
<p><a class="sf-dl" href="assets/seafood-varieties-poster.jpg" download="Nigel-Thomas-Popular-Seafood-Varieties-Poster.jpg">Download the Infographic (JPG)</a></p></section>
<section class="breakdown"><h2>Final Thought</h2>
<p>Seafood rewards the teams who respect it. Knowing the variety, understanding how it behaves, buying it with discipline and cooking it with care is what separates a forgettable plate from one that guests describe to their friends. Start with the 28 varieties in this guide, build product knowledge one family at a time, and turn that knowledge into consistent service on the floor. Great seafood is never an accident. It is the result of habits, training and attention to detail, repeated every single day.</p></section>
<section class="related"><h2>More from the F&amp;B Leadership Series</h2><ul>
<li><a href="types-of-menus-fb-service.html">Types of Menus in F&amp;B Service</a></li>
<li><a href="6-types-of-fried-fish.html">6 Types of Fried Fish</a></li>
<li><a href="food-cost-basics.html">Food Cost Basics: Control Cost, Improve Profit, Grow Business</a></li>
<li><a href="restaurant-kpis-every-manager-should-track.html">Restaurant KPIs Every Manager Should Track</a></li>
<li><a href="blog.html">All Articles</a></li></ul></section>
<div class="tags"><span>#Seafood</span><span>#FBLeadership</span><span>#Hospitality</span><span>#MenuEngineering</span><span>#FoodSafety</span></div>
'@
$body=$body.Replace('{{FIN}}',$cf).Replace('{{CRU}}',$cc).Replace('{{MOL}}',$cm).Replace('{{TBL}}',$tbl)
$txt=[Net.WebUtility]::HtmlDecode([regex]::Replace($body,'<[^>]+>',' '))
$wc=($txt -split '\s+' | Where-Object {$_}).Count
Write-Host "Article word count: $wc"
if($wc -lt 2500){Fail "word count $wc is under 2500"}

# ---- build page from the Menu Types page template (head, header, author box, footer) ----
$t=[IO.File]::ReadAllText((Join-Path $repo 'types-of-menus-fb-service.html'),$u)
$m=[regex]::Match($t,'(?is)^.*?<main[^>]*>'); $a=$t.IndexOf('<div class="author-box">')
if(-not $m.Success -or $a -lt 0){Fail 'template anchors not found in menu page'}
$pre=$m.Value; $suf=$t.Substring($a)
$art=[regex]::Match($t,'<article[^>]*>').Value; if(-not $art){$art='<article>'}
$pre=[regex]::Replace($pre,'(?is)<script type="application/ld\+json">.*?</script>','')
$pre=[regex]::Replace($pre,'(?i)<link[^>]+rel="canonical"[^>]*>','')
$pre=[regex]::Replace($pre,'(?i)<meta[^>]+(name="description"|property="og:(title|description|url|image)"|name="twitter:(title|description|image)")[^>]*>','')
$pre=[regex]::Replace($pre,'(?is)<title>.*?</title>','')
$url="$site/$slug"; $img="$site/$poster"
$ld='{"@context":"https://schema.org","@type":"Article","headline":"'+$title+'","datePublished":"'+$today+'","dateModified":"'+$today+'","author":{"@type":"Person","name":"Nigel A. Thomas"},"image":"'+$img+'","mainEntityOfPage":"'+$url+'"}'
$css='<style>.sf-meta{font-size:.95rem;opacity:.8}.sf-info{margin:48px 0;padding:32px 24px;background:#0a0a0a;border:2px solid #d4af37;border-radius:18px;text-align:center}.sf-info h2{color:#f3d98b;margin:0 0 8px}.sf-info p{color:#e8e8e8}.sf-info img{max-width:100%;height:auto;border:3px solid #d4af37;border-radius:12px;margin:20px 0}.sf-dl{display:inline-block;background:linear-gradient(180deg,#f3d98b,#b8860b);color:#0a0a0a!important;font-weight:700;padding:14px 34px;border-radius:999px;text-decoration:none}.sf-dl:hover{filter:brightness(1.1)}</style>'
$inj='<title>'+(Enc $title)+' | Nigel Thomas</title><meta name="description" content="'+(Enc $desc)+'"><link rel="canonical" href="'+$url+'"><meta property="og:title" content="'+(Enc $title)+'"><meta property="og:description" content="'+(Enc $desc)+'"><meta property="og:url" content="'+$url+'"><meta property="og:image" content="'+$img+'"><meta name="twitter:title" content="'+(Enc $title)+'"><meta name="twitter:description" content="'+(Enc $desc)+'"><meta name="twitter:image" content="'+$img+'">'+$css+'<script type="application/ld+json">'+$ld+'</script>'
$pre=$pre.Replace('</head>',$inj+'</head>')
$pagePath=Join-Path $repo $slug
[IO.File]::WriteAllText($pagePath,($pre+"`n"+$art+"`n"+$body+"`n</article>`n</main>`n`n"+$suf),$u)
Write-Host "Page written: $slug" -ForegroundColor Green

# ---- blog.html: clone the fried fish entry ----
$bp=Join-Path $repo 'blog.html'
$b=[IO.File]::ReadAllText($bp,$u)
if($b.Contains($slug)){Write-Host 'blog.html already lists the page.' -ForegroundColor Yellow}else{
  $i=$b.IndexOf($ref); if($i -lt 0){Fail 'blog.html has no fried fish entry to clone'}
  $r=$null
  foreach($tg in 'article','li','a'){
    $s=$b.LastIndexOf("<$tg",$i); $e=$b.IndexOf("</$tg>",$i)
    if($s -lt 0 -or $e -lt 0 -or $b.Substring($s,$i-$s).Contains("</$tg>")){continue}
    $cand=@($s,($e+$tg.Length+3))
    if($tg -eq 'a' -and ($b.Substring($s,3) -ne '<a ' -or $b.Substring($s,$i-$s).Contains('>') -or ($cand[1]-$cand[0]) -lt 200)){continue}
    $r=$cand; break
  }
  if(-not $r){Select-String -Path $bp -Pattern $ref -Context 6,6; Fail 'could not find a clonable blog entry (send the lines above to Claude)'}
  $nl=if($b.Contains("`r`n")){"`r`n"}else{"`n"}
  $new=$b.Substring($r[0],$r[1]-$r[0]).Replace($ref,$slug)
  $tn=[regex]'(?<=^|>)\s*[^<>\s][^<>]*(?=<|$)'
  $new=([regex]'(?is)(<h[1-6][^>]*>)(.*?)(</h[1-6]>)').Replace($new,{param($x) $x.Groups[1].Value+$tn.Replace($x.Groups[2].Value,(Enc $short),1)+$x.Groups[3].Value},1)
  $new=([regex]'(?is)(<p[^>]*>)(.*?)(</p>)').Replace($new,{param($x) $x.Groups[1].Value+$tn.Replace($x.Groups[2].Value,(Enc $exc),1)+$x.Groups[3].Value},1)
  $new=[regex]::Replace($new,'(?i)(<img[^>]*?\ssrc=")[^"]*(")',('${1}'+$poster+'${2}'))
  $new=[regex]::Replace($new,'(?i)(<img[^>]*?\salt=")[^"]*(")',('${1}'+(Enc $short)+'${2}'))
  $new=[regex]::Replace($new,'(January|February|March|April|May|June|July|August|September|October|November|December) \d{1,2}, \d{4}',$long)
  $new=[regex]::Replace($new,'\d{4}-\d{2}-\d{2}',$today)
  $b=$b.Insert($r[0],$new+$nl)
  [IO.File]::WriteAllText($bp,$b,$u)
  Write-Host 'blog.html entry added.' -ForegroundColor Green
}

# ---- sitemap.xml: clone the fried fish url block ----
$sp=Join-Path $repo 'sitemap.xml'
$s=[IO.File]::ReadAllText($sp,$u)
if($s.Contains($slug)){Write-Host 'sitemap already lists the page.' -ForegroundColor Yellow}else{
  $mm=[regex]::Match($s,'(?s)<url>(?:(?!</url>).)*?6-types-of-fried-fish\.html(?:(?!</url>).)*?</url>')
  if(-not $mm.Success){Fail 'fried fish url block not found in sitemap.xml'}
  $nu=$mm.Value.Replace($ref,$slug)
  $nu=[regex]::Replace($nu,'<lastmod>[^<]*</lastmod>',('<lastmod>'+$today+'</lastmod>'))
  $nls=if($s.Contains("`r`n")){"`r`n"}else{"`n"}
  $ls=$s.LastIndexOf("`n",$mm.Index); $ind=''
  if($ls -ge 0){$pad=$s.Substring($ls+1,$mm.Index-$ls-1); if($pad.Trim() -eq ''){$ind=$pad}}
  $s=$s.Insert($mm.Index+$mm.Length,$nls+$ind+$nu)
  [IO.File]::WriteAllText($sp,$s,$u)
  Write-Host 'sitemap.xml entry added.' -ForegroundColor Green
}

# ---- verify ----
Write-Host '--- VERIFY ---' -ForegroundColor Cyan
$ok=$true
function Chk($name,$c){ if($c){Write-Host "PASS  $name" -ForegroundColor Green}else{Write-Host "FAIL  $name" -ForegroundColor Red; $script:ok=$false} }
$pg=[IO.File]::ReadAllText($pagePath,$u)
Chk 'page file exists' (Test-Path $pagePath)
Chk "word count >= 2500 ($wc)" ($wc -ge 2500)
Chk 'poster file in assets' (Test-Path (Join-Path $repo 'assets\seafood-varieties-poster.jpg'))
Chk 'poster embedded' ($pg.Contains('<img src="'+$poster+'"'))
Chk 'download button' ($pg -match '<a class="sf-dl"[^>]*download=')
Chk 'canonical correct' ($pg.Contains('rel="canonical" href="'+$url+'"'))
Chk 'og:url correct' ($pg.Contains('property="og:url" content="'+$url+'"'))
Chk 'AdSense present' ($pg.Contains('ca-pub-8127243414384620'))
Chk 'author box kept' ($pg.Contains('class="author-box"'))
Chk 'blog.html lists page' ([IO.File]::ReadAllText($bp,$u).Contains($slug))
Chk 'sitemap.xml lists page' ([IO.File]::ReadAllText($sp,$u).Contains($slug))
$bad=@(); foreach($mt in [regex]::Matches($body,'href="([^"#?:/]+\.html)"')){ if(-not(Test-Path (Join-Path $repo $mt.Groups[1].Value))){$bad+=$mt.Groups[1].Value} }
Chk ('internal links resolve '+($bad -join ',')) ($bad.Count -eq 0)
Chk 'section tags balanced' (([regex]::Matches($body,'<section')).Count -eq ([regex]::Matches($body,'</section>')).Count)
if(-not $ok){Fail 'verification failed'}

# ---- git ----
Write-Host '--- GIT ---' -ForegroundColor Cyan
git add $slug blog.html sitemap.xml assets/seafood-varieties-poster.jpg
git add -u -- seafood-varieties-poster.jpg 2>$null
git status --short
git commit -m "Add Popular Seafood Varieties guide with downloadable infographic"
if($LASTEXITCODE -ne 0){Fail 'git commit failed'}
git pull --rebase
if($LASTEXITCODE -ne 0){Write-Host 'ERROR: pull --rebase failed, resolve before pushing.' -ForegroundColor Red; exit 1}
git push
git status
git log -1 --oneline
Write-Host "DONE. After Vercel deploys, open $url and test the download button." -ForegroundColor Green
