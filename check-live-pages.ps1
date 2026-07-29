$files = @(
"100-hospitality-interview-questions.html",
"15-money-leaks-in-a-restaurant.html",
"about.html",
"ai-shaping-future-jobs-2026.html",
"area-manager-restaurant-visit-diagnostic-lenses.html",
"ats-friendly-hospitality-cv-guide.html",
"beers.html",
"blog.html",
"buffet-food-temperature-guide.html",
"building-a-career-in-hospitality-guide.html",
"certifications.html",
"chef-de-partie-complete-career-guide.html",
"cloud-kitchen-catering-operations-guide.html",
"cocktail-bar-service-guide.html",
"contact.html",
"cruise-ship-crew-rotations-guide.html",
"disclaimer.html",
"equal-opportunity-employer-india-usa-europe.html",
"executive-career-dashboard.html",
"executive-chef-duties-and-responsibilities.html",
"executive-chef-job-description-requirements.html",
"fb-cost-control-blueprint.html",
"fifo-vs-fefo-stock-rotation-guide.html",
"fire-safety-training-blog.html",
"foh-boh-equipment-guide.html",
"foh-boh-hierarchy-blog.html",
"food-and-beverage-service-hierarchy.html",
"food-cost-control-complete-guide.html",
"food-safety-temperatures-cold-chain-control-kitchen-storage-standards.html",
"general-manager-duties-and-responsibilities.html",
"general-manager-vs-hotel-manager.html",
"gm-leadership-playbook-interview-guide.html",
"haccp-kitchen-checklist.html",
"history-of-wine-world-wine-regions-guide.html",
"hospitality-franchising-complete-guide.html",
"hospitality-management-tools.html",
"hot-and-cold-kitchens-temperature-guide.html",
"hotel-gm-competency-framework.html",
"hotel-kpi-formula-cheat-sheet.html",
"hotel-sops-complete-guide.html",
"hotel-vs-resort-expenditure-guide.html",
"how-to-calculate-food-cost-per-portion.html",
"how-to-carry-a-service-tray.html",
"how-to-control-food-cost.html",
"index.html",
"key-hotel-kpis-every-hotelier-should-track.html",
"key-hotel-management-roles.html",
"kitchen-cleaning-schedule-template.html",
"kitchen-temperature-log-sheet.html",
"knife-color-codes.html",
"manager-on-duty-hotel-operations-complete-guide.html",
"many-hats-general-manager.html",
"nigel_apply_dashboard.html",
"nigel_job_dashboard.html",
"north-indian-cuisine-guide.html",
"not-all-cruise-lines-are-created-equal.html",
"partners.html",
"pl-management-guide.html",
"privacy-policy.html",
"quality-controllers-food-industry.html",
"register.html",
"resort-co-working-future-office.html",
"resort-manager-career-guide-2026.html",
"restaurant-cost-control-calculator.html",
"restaurant-fire-safety-training-guide.html",
"restaurant-general-operating-terms.html",
"restaurant-inventory-management-complete-guide.html",
"restaurant-leader-duties-responsibilities-guide.html",
"restaurant-service-excellence-guide.html",
"restaurant-supervisor-interview.html",
"restaurant-walkthrough-poster.html",
"resume.html",
"sales-marketing-hospitality-career-guide.html",
"service-get-the-job-done-hospitality-creates-the-memory.html",
"sous-chef-career-guide.html",
"staff-behavior-fb-service-guide.html",
"street-food-india-complete-guide.html",
"terms.html",
"the-five-minute-restaurant-interview-test.html",
"types-of-menus-fb-service.html",
"what-is-ebitda-fb-hospitality-guide.html",
"what-is-management-consulting.html",
"which-hotel-chain-is-biggest.html",
"why-your-hospitality-cv-keeps-getting-rejected.html"
)

$base = "https://www.nigelthomas.live/"
$results = foreach ($f in $files) {
    $url = "$base$f"
    try {
        $r = Invoke-WebRequest -Uri $url -UseBasicParsing -Method Head -TimeoutSec 15
        [PSCustomObject]@{File=$f; Status=$r.StatusCode}
    } catch {
        $code = $_.Exception.Response.StatusCode.value__
        if (-not $code) { $code = "ERROR: $($_.Exception.Message)" }
        [PSCustomObject]@{File=$f; Status=$code}
    }
}

Write-Host ""
Write-Host "=== PAGES NOT RETURNING 200 ===" -ForegroundColor Yellow
$results | Where-Object {$_.Status -ne 200} | Format-Table -AutoSize

Write-Host ""
Write-Host "Total checked: $($results.Count)"
Write-Host "OK (200):      $(($results | Where-Object {$_.Status -eq 200}).Count)"
Write-Host "Problems:      $(($results | Where-Object {$_.Status -ne 200}).Count)"

$results | Export-Csv "live-check-results.csv" -NoTypeInformation
Write-Host ""
Write-Host "Full results saved to live-check-results.csv"