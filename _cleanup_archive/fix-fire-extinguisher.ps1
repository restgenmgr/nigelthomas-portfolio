# ===== FIX FIRE EXTINGUISHER PAGE =====
$file = "blog\types-of-fire-extinguishers.html"
Copy-Item $file "$file.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

$html = Get-Content $file -Raw
$html = [regex]::Replace($html, '(?is)<section[^>]*class="nt-poster-bottom".*?</section>', '')
$html = [regex]::Replace($html, '(?is)<div[^>]*text-align\s*:\s*center[^>]*>\s*<img[^>]*fire-extinguisher-types\.png[^>]*>\s*</div>', '')
$html = [regex]::Replace($html, '(?is)(?<!content=")<img[^>]*fire-extinguisher-types\.png[^>]*>', '')
$html = [regex]::Replace($html, '(?is)<a[^>]*href="/assets/fire-extinguisher-types\.png"[^>]*>.*?</a>', '')
$html = [regex]::Replace($html, '(\r?\n){4,}', "`r`n`r`n")

$poster = "`r`n<!-- SINGLE BOTTOM POSTER -->`r`n<section class='nt-poster-bottom' style='margin:50px auto; max-width:900px; text-align:center;'><h2 style='color:#d4af37; margin-bottom:20px;'>Download the Free Poster</h2><img src='/assets/fire-extinguisher-types.png' alt='Types of Fire Extinguishers infographic' loading='lazy' style='max-width:100%; height:auto; border-radius:10px; display:block; margin:0 auto;'><p style='margin-top:20px;'><a href='/assets/fire-extinguisher-types.png' download='fire-extinguisher-types.png' style='display:inline-block; background:#d4af37; color:#000; padding:12px 28px; border-radius:30px; font-weight:bold; text-decoration:none;'>DOWNLOAD FREE POSTER</a></p></section>`r`n<!-- END SINGLE BOTTOM POSTER -->`r`n"

$html = $html.Replace('<footer>', "$poster<footer>")
$html = $html.Replace('G-CLRRV5DMXZ', 'G-P839TWLQSJ')
$html = $html.Replace('ca-pub-4282121192943910', 'ca-pub-8127243414384620')

[System.IO.File]::WriteAllText($file, $html, [System.Text.UTF8Encoding]::new($false))

$check = [System.IO.File]::ReadAllText($file, [System.Text.UTF8Encoding]::new($false))
"Poster sections:  " + [regex]::Matches($check, '(?is)<section[^>]*class="nt-poster-bottom"').Count
"Download buttons: " + [regex]::Matches($check, '(?i)DOWNLOAD FREE POSTER').Count
"Fire ext images:  " + [regex]::Matches($check, '(?i)fire-extinguisher-types\.png').Count
