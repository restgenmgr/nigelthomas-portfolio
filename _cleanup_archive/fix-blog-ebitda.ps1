$text = Get-Content blog.html -Raw
$pattern = '(?s)<section id="foodcost">.*?</section>'
$replacement = @'
<section id="foodcost">
            <h2 class="category-heading">&#128176; Food Cost &amp; Finance</h2>
            <div class="article-card">
                <div class="article-title"><a href="/how-to-calculate-food-cost-per-portion.html">How to Calculate Food Cost Per Portion</a></div>
                <div class="article-meta">Food Cost &amp; Finance &middot; July 2026</div>
                <p class="article-excerpt">A step-by-step framework for costing any recipe &mdash; from ingredient costing sheets to food cost percentage, target selling price, and gross profit per portion.</p>
                <a href="/how-to-calculate-food-cost-per-portion.html" class="read-more-btn">Read Article &rarr;</a>
            </div>
            <div class="article-card">
                <img src="what-is-ebitda-infographic.jpg" alt="What is EBITDA infographic for restaurant and F&B finance" loading="lazy">
                <div class="article-title"><a href="/what-is-ebitda-fb-hospitality-guide.html">What Is EBITDA? A Practical Guide for Restaurant &amp; F&amp;B Leaders</a></div>
                <div class="article-meta"><span class="badge badge-gold">Newest</span> Food Cost &amp; Finance &middot; July 2026</div>
                <p class="article-excerpt">EBITDA explained for hospitality operators &mdash; how to calculate it, where it's used, the KPIs built on it, and the five things it doesn't show you.</p>
                <a href="/what-is-ebitda-fb-hospitality-guide.html" class="read-more-btn">Read Article &rarr;</a>
            </div>
            <div class="article-card">
                <img src="pl-management-guide.jpg" alt="Profit and Loss P&L Management Guide infographic for F&B operations" loading="lazy">
                <div class="article-title"><a href="/pl-management-guide.html">Profit &amp; Loss (P&amp;L) Management Guide for F&amp;B Operations</a></div>
                <div class="article-meta">Food Cost &amp; Finance &middot; July 2026</div>
                <p class="article-excerpt">The financial compass for F&amp;B operations &mdash; cost of sales, gross profit, payroll cost, EBITDA, and the critical ratios every F&amp;B leader must monitor.</p>
                <a href="/pl-management-guide.html" class="read-more-btn">Read Article &rarr;</a>
            </div>
            <div class="article-card">
                <div class="article-title"><a href="/food-cost-control-complete-guide.html">Mastering Food Cost Control in Restaurants &amp; Hotels</a></div>
                <div class="article-meta"><span class="badge badge-gold">Editor's Choice</span> July 2026</div>
                <p class="article-excerpt">A comprehensive professional guide covering recipe costing, food cost percentage, inventory management, purchasing, supplier negotiations, menu engineering, portion control, waste reduction and practical methods used by profitable restaurants and hotels.</p>
                <a href="/food-cost-control-complete-guide.html" class="read-more-btn">Read Complete Guide &rarr;</a>
            </div>
            <div class="article-card">
                <div class="article-title"><a href="/15-money-leaks-in-a-restaurant.html">15 Money Leaks in a Restaurant</a></div>
                <div class="article-meta">Food Cost &middot; July 2026</div>
                <p class="article-excerpt">Fifteen silent profit killers hiding inside every restaurant operation &mdash; from unrecorded waste to oversized staffing &mdash; with the exact fix for each one.</p>
                <a href="/15-money-leaks-in-a-restaurant.html" class="read-more-btn">Read Article &rarr;</a>
            </div>
        </section>
'@
$newText = [regex]::Replace($text, $pattern, $replacement)
[System.IO.File]::WriteAllText("blog.html", $newText, [System.Text.Encoding]::UTF8)
Write-Host "Done. Match count:" ([regex]::Matches($text, $pattern)).Count
