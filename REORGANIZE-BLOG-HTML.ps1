$ErrorActionPreference = "Stop"
Set-Location "C:\Users\admin\Desktop\nigelthomas-portfolio"

$path = "blog.html"
$backup = "blog.html.before-category-reorg.html"
Copy-Item $path $backup -Force

$html = [IO.File]::ReadAllText($path, [Text.UTF8Encoding]::new($false))

$start = $html.IndexOf('<section id="featured">')
$end   = $html.IndexOf('</main>', $start)
if($start -lt 0 -or $end -lt 0){ throw "Could not find the blog article area." }

$area = $html.Substring($start, $end - $start)
$matches = [regex]::Matches($area, '<(?:div|article) class="article-card">')

$cards = New-Object System.Collections.Generic.List[string]
for($i=0; $i -lt $matches.Count; $i++){
    $p = $matches[$i].Index
    if($i -lt $matches.Count - 1){
        $next = $matches[$i+1].Index
        $block = $area.Substring($p, $next-$p).Trim()
    } else {
        $tail = $area.Substring($p)
        $cut = $tail.LastIndexOf('</section>')
        if($cut -lt 0){ throw "Could not find end of final article section." }
        $block = $tail.Substring(0,$cut).Trim()
        # Remove the closing blog-grid div from the last card slice if present.
        $close = $block.LastIndexOf('</div>')
        if($close -gt 0){
            $block = $block.Substring(0,$close+6).Trim()
        }
    }
    $cards.Add($block)
}

$seen = New-Object 'System.Collections.Generic.HashSet[string]'
$unique = New-Object System.Collections.Generic.List[string]

foreach($card in $cards){
    $hm = [regex]::Match($card,'href="([^"]+)"')
    if(-not $hm.Success){ throw "A blog card has no href." }
    $href = $hm.Groups[1].Value

    # Remove the About profile card; it is not a blog article.
    if($href -eq "/about.html"){ continue }

    if($seen.Add($href)){ $unique.Add($card) }
}

$M = @(
"operations-manager-vs-restaurant-manager.html",
"profit-loss-10-day-cycle.html",
"area-manager-vs-cluster-manager.html",
"restaurant-manager-roles-and-responsibilities.html",
"direct-vs-ota-booking-guest-occasion.html",
"food-cost-basics.html",
"restaurant-financial-kpis.html",
"restaurant-operational-challenges-solutions.html",
"restaurant-leader-duties-responsibilities-guide.html",
"blog/restaurant-fire-safety-training-guide.html",
"restaurant-service-excellence-guide.html",
"restaurant-pos-hotel-pms-complete-guide.html",
"restaurant-kpis-every-manager-should-track.html",
"cost-control-protect-profit.html",
"right-vs-left-service-restaurants.html",
"restaurant-hotel-napkin-folding.html",
"restaurant-mis-en-plas.html",
"blog/fine-dining-silverware.html"
)

$C = @(
"ai-readiness-self-assessment-hospitality.html",
"ai-decision-matrix.html",
"future-of-ai-guardrails.html",
"resume-making-tools-guide.html"
)

$F = @(
"haccp-hazard-analysis-critical-control-points.html",
"types-of-cheese-used-in-hotels.html",
"types-of-pasta-sauces.html",
"food-handling-guide-poster.html",
"6-pizza-recipes-hotel-restaurant-menu.html",
"waste-segregation-guide.html",
"condiments-vs-sauces-poster.html",
"condiments-vs-sauces-fb-guide.html",
"blog/stuffed-filled-foods-around-the-world.html",
"blog/gourmet-canapes-italian-starters.html",
"food-safety-temperatures-cold-chain-control-kitchen-storage-standards.html",
"knife-color-codes.html",
"blog/cross-contamination-prevention.html",
"types-of-sandwiches.html",
"international-soups.html"
)

$B = @(
"bartenders-quick-reference.html",
"types-of-water-used-in-restaurant.html",
"coffee-types-poster.html",
"history-of-wine-world-wine-regions.html",
"why-is-a-wine-bottle-750ml.html",
"vodka-brands-and-cocktails-guide.html",
"brandy-cognac-armagnac.html",
"blog/shake-vs-smoothie.html",
"blog/wine-service-etiquette.html",
"classic-cocktails-guide.html",
"draught-beers.html",
"whiskies-of-the-world.html"
)

function Get-Href($card){
    return ([regex]::Match($card,'href="([^"]+)"')).Groups[1].Value
}

$groups = @{
    M = New-Object System.Collections.Generic.List[string]
    C = New-Object System.Collections.Generic.List[string]
    F = New-Object System.Collections.Generic.List[string]
    B = New-Object System.Collections.Generic.List[string]
}

$classified = New-Object 'System.Collections.Generic.HashSet[string]'

foreach($card in $unique){
    $href = Get-Href $card
    if($M -contains $href){ $groups.M.Add($card); [void]$classified.Add($href); continue }
    if($C -contains $href){ $groups.C.Add($card); [void]$classified.Add($href); continue }
    if($F -contains $href){ $groups.F.Add($card); [void]$classified.Add($href); continue }
    if($B -contains $href){ $groups.B.Add($card); [void]$classified.Add($href); continue }
    throw "Unclassified blog card URL: $href"
}

function New-Section($id,$title,$items){
    $body = $items -join "`r`n`r`n"
    return "<section id=""$id"">`r`n<h2 class=""category-heading"">$title</h2>`r`n<div class=""blog-grid"">`r`n`r`n$body`r`n`r`n</div>`r`n</section>"
}

$newArea = @(
    (New-Section "management-operations" "Management &amp; Operations (M &amp; O)" $groups.M)
    (New-Section "career-general" "Career &amp; General" $groups.C)
    (New-Section "food" "Food" $groups.F)
    (New-Section "beverage" "Beverage" $groups.B)
) -join "`r`n`r`n"

$newHtml = $html.Substring(0,$start) + $newArea + "`r`n" + $html.Substring($end)

[IO.File]::WriteAllText($path,$newHtml,(New-Object System.Text.UTF8Encoding($false)))

# Verification
$verify = [IO.File]::ReadAllText($path,[Text.UTF8Encoding]::new($false))
$expected = @(
"Management &amp; Operations (M &amp; O)",
"Career &amp; General",
"Food",
"Beverage"
)
$positions = @($expected | ForEach-Object { $verify.IndexOf($_) })
if(($positions[0] -lt 0) -or ($positions[1] -lt $positions[0]) -or ($positions[2] -lt $positions[1]) -or ($positions[3] -lt $positions[2])){
    throw "Section order verification failed. Backup remains at $backup"
}

$finalMatches = [regex]::Matches($verify,'<(?:div|article) class="article-card">')
$finalHrefs = @([regex]::Matches($verify,'href="([^"]+)"') | ForEach-Object { $_.Groups[1].Value })
$dupHref = $finalHrefs | Group-Object | Where-Object { $_.Count -gt 1 }

Write-Host ""
Write-Host "===== BLOG REORGANIZATION COMPLETE =====" -ForegroundColor Green
Write-Host "Backup : $backup"
Write-Host "Cards before : $($cards.Count)"
Write-Host "Cards after  : $($finalMatches.Count)"
Write-Host "M & O        : $($groups.M.Count)"
Write-Host "Career       : $($groups.C.Count)"
Write-Host "Food         : $($groups.F.Count)"
Write-Host "Beverage     : $($groups.B.Count)"
if($dupHref){ throw "Duplicate hrefs remain: $($dupHref.Name -join ', ')" }
Write-Host "Duplicate href check : PASS" -ForegroundColor Green

Write-Host ""
Write-Host "===== GIT STATUS (ONLY INSPECT) =====" -ForegroundColor Yellow
git status -sb
Write-Host ""
Write-Host "===== DIFF STAT =====" -ForegroundColor Yellow
git diff --stat -- blog.html
Write-Host ""
Write-Host "===== PROTECTED FILES CHECK =====" -ForegroundColor Yellow
git status --short -- mise-en-place-vs-scene.jpg sitemap-entry-snippet.xml assets/brandy-cognac-armagnac.jpg blog-card-snippet.html live-version.html
