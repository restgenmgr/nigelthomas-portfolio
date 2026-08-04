# Fix double-layer UTF-8/Windows-1252 corruption in about.html
$path = Join-Path (Get-Location) "about.html"
$content = [System.IO.File]::ReadAllText($path)

$before = $content.Length

$content = $content.Replace([char]0x00C3 + [char]0x0192 + [char]0x00C2 + [char]0x00A9, '&eacute;')
$content = $content.Replace([char]0x00C3 + [char]0x201A + [char]0x00C2 + [char]0x00A9, '&copy;')

[System.IO.File]::WriteAllText($path, $content, (New-Object System.Text.UTF8Encoding $false))

Write-Host "Done. Original length: $before, New length: $($content.Length)"
