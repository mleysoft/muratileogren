$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
$file = 'android/app/build.gradle.kts'
if (!(Test-Path $file)) { throw "Could not find $file" }
$s = Get-Content $file -Raw
$lines = $s -split "`r?`n"
$fixed = New-Object 'System.Collections.Generic.List[string]'
$depth = 0
$skipping = $false
$skipDepth = 0
$removed = 0
foreach ($line in $lines) {
  if (!$skipping -and $depth -eq 0 -and $line -match '^\s*kotlin\s*\{\s*(?://.*)?$') {
    $skipping = $true
    $skipDepth = 0
    $removed++
  }
  if ($skipping) {
    $clean = $line -replace '//.*$', ''
    $skipDepth += ([regex]::Matches($clean, '\{')).Count - ([regex]::Matches($clean, '\}')).Count
    if ($skipDepth -eq 0) { $skipping = $false }
    continue
  }
  $fixed.Add($line)
  $clean = $line -replace '//.*$', ''
  $depth += ([regex]::Matches($clean, '\{')).Count - ([regex]::Matches($clean, '\}')).Count
}
if ($skipping) { throw 'Unbalanced Kotlin block: unchanged.' }
if ($removed -gt 0) {
  Copy-Item $file "$file.bak" -Force
  Set-Content $file ($fixed -join "`r`n") -Encoding utf8
  Write-Host "Removed invalid top-level Kotlin DSL block. Backup: $file.bak"
} else { Write-Host 'No invalid top-level Kotlin DSL block found.' }
