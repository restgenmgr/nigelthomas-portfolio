# PowerShell script to add snippets to blog.html
# Save this as Add-Snippets.ps1 and run in the same directory as blog.html

$filePath = "blog.html"

# Check if file exists
if (-not (Test-Path $filePath)) {
    Write-Host "Error: blog.html not found in current directory!" -ForegroundColor Red
    exit
}

# Read the file content
$content = Get-Content $filePath -Raw

# Define the snippets
$snippet1 = @'
<div class="article-card">

<h3 class="article-title">
<a href="/resort-manager-career-guide-2026.html">
Resort Manager: Complete Career Guide 2026
</a>
</h3>

<div class="article-meta">
Leadership • Resort Operations
</div>

<p>
A complete guide to running a luxury boutique resort — daily operations, F&B ownership, team leadership, guest experience, the stay-in reality and career progression from Resort Manager to General Manager.
</p>

<a class="read-more-btn"
href="/resort-manager-career-guide-2026.html">
Read Article →
</a>

</div>
'@

$snippet2 = @'
<div class="article-card">

<h3>
<a href="/resort-manager-career-guide-2026.html">
Resort Manager: Complete Career Guide 2026
</a>
</h3>

<p>
A complete guide to running a luxury boutique resort covering daily operations, F&B ownership, team leadership, the stay-in reality and career progression from Resort Manager to General Manager.
</p>

<a class="read-more-btn"
href="/resort-manager-career-guide-2026.html">
Read Guide →
</a>

</div>
'@

$snippet3 = @'
<div class="article-card">

<h3>
<a href="/resort-manager-career-guide-2026.html">
Resort Manager: Complete Career Guide 2026
</a>
</h3>

<p class="article-excerpt">
A complete guide covering daily resort operations, F&B ownership, team leadership, guest experience, the stay-in reality and career progression from Resort Manager to General Manager.
</p>

<a href="/resort-manager-career-guide-2026.html"
class="read-more-btn">
Read Article →
</a>

</div>
'@

$footerSnippet = '<p><a href="/resort-manager-career-guide-2026.html">Resort Manager Guide</a></p>'

# Function to insert snippet after a specific marker
function Insert-Snippet {
    param($content, $searchPattern, $snippet, $description)
    
    if ($content -match $searchPattern) {
        # Find the position after the match
        $matchEnd = $matches[0].Length + $matches[0].Index
        $before = $content.Substring(0, $matchEnd)
        $after = $content.Substring($matchEnd)
        
        # Insert the snippet
        $newContent = $before + "`n" + $snippet + "`n" + $after
        Write-Host "✓ Added snippet to: $description" -ForegroundColor Green
        return $newContent
    } else {
        Write-Host "✗ Pattern not found for: $description" -ForegroundColor Yellow
        return $content
    }
}

# Backup original file
$backupPath = "blog_backup.html"
Copy-Item $filePath $backupPath
Write-Host "✓ Created backup at $backupPath" -ForegroundColor Green

# Insert all snippets
$content = Insert-Snippet -content $content -searchPattern '(<div class="article-card">.*?Resort Co-Working.*?</div>)' -snippet $snippet1 -description "First section (plain style)"
$content = Insert-Snippet -content $content -searchPattern '(<div class="article-card">.*?Resort Co-Working.*?</div>)' -snippet $snippet2 -description "Second section (Leadership & Management)"
$content = Insert-Snippet -content $content -searchPattern '(<div class="article-card">.*?Key Hotel Management Roles.*?</div>)' -snippet $snippet3 -description "Third section (Hotel Leadership)"

# Add footer snippet
if ($content -match '(?s)(<div class="popular-guides">.*?)(</div>)') {
    $content = $content -replace '(?s)(<div class="popular-guides">.*?)(</div>)', "`$1`n$footerSnippet`n`$2"
    Write-Host "✓ Added footer snippet to Popular Guides" -ForegroundColor Green
} else {
    Write-Host "✗ Popular Guides section not found" -ForegroundColor Yellow
}

# Save the updated file
$content | Set-Content $filePath -NoNewline
Write-Host "`n✅ All snippets added successfully to $filePath!" -ForegroundColor Cyan
Write-Host "ℹ️  A backup was saved as blog_backup.html" -ForegroundColor Gray