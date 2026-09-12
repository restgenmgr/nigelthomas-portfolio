Set-Location "C:\Users\admin\Desktop\nigelthomas-portfolio"
$files=@("restaurant-fire-safety-training-guide.html","restaurant-hotel-napkin-folding.html","cross-contamination-prevention.html")
$enc=New-Object System.Text.UTF8Encoding($false)
foreach($file in $files){
 if(!(Test-Path $file)){Write-Host "MISSING: $file" -ForegroundColor Red;continue}
 $stamp=Get-Date -Format "yyyyMMdd-HHmmss"
 Copy-Item $file "$file.bak-posterfix-$stamp" -Force
 $path=(Resolve-Path $file).Path
 $h=[IO.File]::ReadAllText($path,$enc)
 $h=$h.Replace("G-CLRRV5DMXZ","G-P839TWLQSJ").Replace("ca-pub-4282121192943910","ca-pub-8127243414384620")
 $h=[regex]::Replace($h,'(?is)<section[^>]*class=["''][^"'']*nt-poster-bottom[^"'']*["''][^>]*>.*?</section>','')
 $h=[regex]::Replace($h,'(?is)<!--\s*(?:SINGLE BOTTOM POSTER|NT BOTTOM INFOGRAPHIC START).*?(?:END SINGLE BOTTOM POSTER\s*-->|</section>)','')
 if($file -eq "restaurant-fire-safety-training-guide.html"){
  $h=[regex]::Replace($h,'(?is)<div class="nt-infomatics-section".*?<div id="fire-poster-panel".*?</div>\s*</div>\s*</div>',
  '<div class="nt-infomatics-section" style="margin:40px 0;"><button type="button" class="nt-infomatics-button" data-panel="fire-poster-panel" aria-expanded="false" style="display:block;margin:0 auto;background:#d4af37;color:#000;border:0;border-radius:30px;padding:12px 28px;font-weight:700;cursor:pointer;">FREE POSTER DOWNLOAD</button><div id="fire-poster-panel" class="nt-infomatics-panel" aria-hidden="true" style="display:none;margin-top:25px;text-align:center;"><img src="assets/fire-extinguisher-types.png" alt="Types of Fire Extinguishers infographic" loading="lazy" style="max-width:100%;height:auto;border-radius:10px;display:block;margin:0 auto;"><p style="margin-top:18px;"><a href="assets/fire-extinguisher-types.png" download="fire-extinguisher-types.png" style="display:inline-block;background:#d4af37;color:#000;padding:12px 28px;border-radius:30px;font-weight:bold;text-decoration:none;">DOWNLOAD POSTER</a></p></div></div></div>',1)
 }
 if($file -eq "restaurant-hotel-napkin-folding.html"){
  $h=[regex]::Replace($h,'(?is)<div id="posterWrap">\s*<div class="download-row">\s*</div>\s*</div>',
  '<div id="posterWrap"><img src="/assets/restaurant-hotel-napkin-folding.png" alt="Restaurant and Hotel Napkin Folding infographic" loading="lazy" style="max-width:100%;height:auto;border-radius:10px;display:block;margin:20px auto;"><div class="download-row"><a href="/assets/restaurant-hotel-napkin-folding.png" download="restaurant-hotel-napkin-folding.png" style="display:inline-block;background:#d4af37;color:#000;padding:12px 28px;border-radius:30px;font-weight:bold;text-decoration:none;">DOWNLOAD POSTER</a></div></div>',1)
  $h=$h.Replace("View Infomatic","FREE POSTER DOWNLOAD").Replace("Hide Infomatic","HIDE POSTER")
 }
 if($file -eq "cross-contamination-prevention.html"){
  $h=$h.Replace("VIEW INFOMATICS","FREE POSTER DOWNLOAD").Replace("HIDE INFOMATICS","HIDE POSTER")
  $h=[regex]::Replace($h,'(?is)<p[^>]*>\s*(?:&#128161;|💡).*?</p>\s*','')
  $h=[regex]::Replace($h,'(?is)(<img\s+src="/assets/cross-contamination-poster\.jpg"[^>]*>)\s*(?:<p[^>]*>.*?</p>)?',
  '$1<p style="margin-top:18px;"><a href="/assets/cross-contamination-poster.jpg" download="cross-contamination-poster.jpg" style="display:inline-block;background:#d4af37;color:#000;padding:12px 28px;border-radius:30px;font-weight:bold;text-decoration:none;">DOWNLOAD POSTER</a></p>',1)
 }
 [IO.File]::WriteAllText($path,$h,$enc)
 $x=[IO.File]::ReadAllText($path,$enc)
 Write-Host "`n$file" -ForegroundColor Cyan
 Write-Host "Floating nt-poster-bottom: $([regex]::Matches($x,'(?i)nt-poster-bottom').Count)"
 Write-Host "FREE POSTER DOWNLOAD: $([regex]::Matches($x,'FREE POSTER DOWNLOAD').Count)"
 Write-Host "DOWNLOAD POSTER: $([regex]::Matches($x,'DOWNLOAD POSTER').Count)"
 Write-Host "Old GA4: $([regex]::Matches($x,'G-CLRRV5DMXZ').Count)"
 Write-Host "Old AdSense: $([regex]::Matches($x,'ca-pub-4282121192943910').Count)"
}
Write-Host "`n================================================" -ForegroundColor Green
Write-Host "POSTER REPAIR FINISHED - NOT COMMITTED OR PUSHED" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
