# Firebase Android setup for an existing Flutter project (Kotlin Gradle files).
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
$settings = 'android/settings.gradle.kts'
$app = 'android/app/build.gradle.kts'
$manifest = 'android/app/src/main/AndroidManifest.xml'
$config = 'firebase/google-services.json'
if (!(Test-Path $settings) -or !(Test-Path $app) -or !(Test-Path $manifest)) {
  throw 'Android Kotlin Gradle project missing. Run: flutter create --platforms=android .'
}
if (!(Test-Path $config)) {throw 'firebase/google-services.json missing.'}
$json = Get-Content $config -Raw | ConvertFrom-Json
$targetId = 'com.muratileogren.academy'
$matching = @($json.client | Where-Object {$_.client_info.android_client_info.package_name -eq $targetId})
if ($matching.Count -ne 1) {throw "Firebase Android package $targetId not found in JSON."}
$s = Get-Content $settings -Raw
if ($s -notmatch 'com\.google\.gms\.google-services') {
  $s = $s -replace '(plugins\s*\{)', ('$1' + "`r`n    id(`"com.google.gms.google-services`") version `"4.4.4`" apply false")
  Set-Content -Path $settings -Value $s -Encoding utf8
}
$a = Get-Content $app -Raw
if ($a -notmatch 'id\("com\.google\.gms\.google-services"\)') {
  $a = $a -replace '(plugins\s*\{)', ('$1' + "`r`n    id(`"com.google.gms.google-services`")")
}
# Firebase package must match applicationId, not namespace.
if ($a -match 'applicationId\s*=\s*"[^"]+"') {
  $a = [regex]::Replace($a, 'applicationId\s*=\s*"[^"]+"', 'applicationId = "com.muratileogren.academy"')
} else {
  throw 'applicationId not found in android/app/build.gradle.kts'
}

# Flutter's AGP 9 Android template does not expose a top-level kotlin { compilerOptions }
# in app/build.gradle.kts. Remove only that invalid, top-level block when present.
# Keep android { compileOptions { ... } } and the Flutter/Kotlin plugin declarations intact.
$lines = $a -split "`r?`n"
$fixedLines = New-Object 'System.Collections.Generic.List[string]'
$depth = 0
$skipping = $false
$skipDepth = 0
foreach ($line in $lines) {
  if (-not $skipping -and $depth -eq 0 -and $line -match '^\s*kotlin\s*\{\s*(?://.*)?$') {
    $skipping = $true
    $skipDepth = 0
  }
  if ($skipping) {
    $open = ([regex]::Matches(($line -replace '//.*$', ''), '\{')).Count
    $close = ([regex]::Matches(($line -replace '//.*$', ''), '\}')).Count
    $skipDepth += $open - $close
    if ($skipDepth -eq 0) { $skipping = $false }
    continue
  }
  $fixedLines.Add($line)
  $clean = $line -replace '//.*$', ''
  $depth += ([regex]::Matches($clean, '\{')).Count - ([regex]::Matches($clean, '\}')).Count
}
if ($skipping) { throw 'Unbalanced top-level kotlin block; no changes written.' }
$a = $fixedLines -join "`r`n"

Set-Content -Path $app -Value $a -Encoding utf8
Copy-Item $config 'android/app/google-services.json' -Force
$m=Get-Content $manifest -Raw
if ($m -notmatch 'android.permission.POST_NOTIFICATIONS') {
  $m=$m -replace '<application', ('<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>' + "`r`n    <application")
}
if ($m -notmatch 'android.permission.INTERNET') {
  $m=$m -replace '<application', ('<uses-permission android:name="android.permission.INTERNET"/>' + "`r`n    <application")
}
Set-Content -Path $manifest -Value $m -Encoding utf8
Write-Host 'Firebase Android client installed; package ID and notification permission configured.'
