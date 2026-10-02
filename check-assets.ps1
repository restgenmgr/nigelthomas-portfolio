$broken = Get-ChildItem -Recurse -File |
  Where-Object { $_.FullName -notmatch '\\\.git\\' -and $_.Extension -in '.html','.htm','.css','.js' } |
  Select-String -Pattern 'assets/[A-Za-z0-9_\-\./&%]+\.(jpg|jpeg|png|jfif|svg|gif|webp)' -AllMatches |
  ForEach-Object {
    foreach ($m in $_.Matches) {
      $ref = $m.Value -replace '&amp;', '&'
      if (-not (Test-Path $ref)) { $ref }
    }
  }
$broken | Group-Object | Sort-Object Count -Descending | Format-Table Count,Name -AutoSize