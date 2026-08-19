# Coffee Batch — 3 New Pages Deploy Guide

## What's in this package
1. `coffee-types-poster.html` — quick-glance poster (7 coffee drinks)
2. `7-types-of-coffee-and-how-theyre-made.html` — full guide article
3. `coffee-shop-vocabulary.html` — new vocabulary poster article
4. `assets/coffee-shop-vocabulary.jpg` — converted image for #3 (736x1103, proper JPEG, no plain rename)

## ⚠️ Missing asset — action needed
`coffee-types-poster.html` and `7-types-of-coffee-and-how-theyre-made.html` both
reference `/assets/7-types-of-coffee-and-how-theyre-made.jpg`. That image was
**not** part of anything uploaded to me, so it is **not included** in this package.

Before deploying, either:
- Confirm it already exists in your repo's `assets/` folder, **or**
- Upload/generate it and drop it into `assets/` before running the script below

The deploy script checks for it and will warn (not fail) if it's missing, so the
pages will go live with a broken poster image until you add it.

## Step 1 — Unzip into your repo
Unzip `coffee-batch.zip` directly into `C:\Users\admin\Desktop\nigelthomas-portfolio`
so the three `.html` files land at repo root and the image lands in `assets\`.

## Step 2 — Run the deploy script
```powershell
cd C:\Users\admin\Desktop\nigelthomas-portfolio
.\deploy-coffee-batch.ps1
```
This will:
- `git pull --rebase`
- Re-save all 3 HTML files as no-BOM UTF-8 (matches your standard, even though
  unzip already writes clean UTF-8 — this guarantees it)
- Check whether `assets\7-types-of-coffee-and-how-theyre-made.jpg` exists and warn if not
- `git add` the 3 HTML files + the vocabulary image
- Commit and push
- Run `vercel --prod --force`

## Step 3 — Blog cards (blog.html)
I don't have your current `blog.html`, so I can't confirm the next
`<!-- END NEW CARD N -->` number or check for existing "Newest" badge issues.
Paste these 3 cards just before the next available `END NEW CARD` anchor,
adjusting the anchor comment number to match:

```html
<div class="article-card">
  <div class="article-title">7 Types of Coffee Poster</div>
  <div class="article-meta">F&amp;B Training</div>
  <div class="article-excerpt">A quick-glance visual poster of the 7 essential coffee drinks — Espresso, Americano, Cappuccino, Café Latte, Mocha, Macchiato and Flat White.</div>
  <a href="/coffee-types-poster.html" class="read-more-btn">Read More</a>
</div>

<div class="article-card">
  <div class="article-title">7 Types of Coffee & How They're Made</div>
  <div class="article-meta">F&amp;B Training</div>
  <div class="article-excerpt">The complete barista guide — how each of the 7 essential coffee drinks is made, key differences, and professional service tips.</div>
  <a href="/7-types-of-coffee-and-how-theyre-made.html" class="read-more-btn">Read More</a>
</div>

<div class="article-card">
  <div class="article-title">Coffee Shop Vocabulary Poster</div>
  <div class="article-meta">F&amp;B Training</div>
  <div class="article-excerpt">Essential coffee shop vocabulary for hospitality trainees — Coffee Cup, Espresso, Barista, Menu Board and more, in one visual.</div>
  <a href="/coffee-shop-vocabulary.html" class="read-more-btn">Read More</a>
</div>
```

## Step 4 — Sitemap.xml
Paste these 3 entries just before `</urlset>`:

```xml
<url>
  <loc>https://www.nigelthomas.live/coffee-types-poster.html</loc>
  <lastmod>2026-08-19</lastmod>
  <changefreq>monthly</changefreq>
  <priority>0.7</priority>
</url>
<url>
  <loc>https://www.nigelthomas.live/7-types-of-coffee-and-how-theyre-made.html</loc>
  <lastmod>2026-08-19</lastmod>
  <changefreq>monthly</changefreq>
  <priority>0.7</priority>
</url>
<url>
  <loc>https://www.nigelthomas.live/coffee-shop-vocabulary.html</loc>
  <lastmod>2026-08-19</lastmod>
  <changefreq>monthly</changefreq>
  <priority>0.7</priority>
</url>
```

After adding these, commit and push `blog.html` and `sitemap.xml` separately
(or add them to Step 2's commit before running — see script comments), then
resubmit the sitemap in Google Search Console.
