# Murat Ile Ogren - Android MainActivity launch package repair
# Repairs an existing generated Android project without deleting user files.
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
$manifestPath = 'android/app/src/main/AndroidManifest.xml'
$gradlePath = 'android/app/build.gradle.kts'
$activityPath = 'android/app/src/main/kotlin/com/muratileogren/academy/MainActivity.kt'
$packageId = 'com.muratileogren.academy'
if (!(Test-Path $manifestPath) -or !(Test-Path $gradlePath)) {
  throw 'Android project was not found. Run flutter create --platforms=android . first.'
}
# Save a timestamp-free backup once.
foreach ($p in @($manifestPath, $gradlePath)) {
  $backup = "$p.before-mainactivity-fix.bak"
  if (!(Test-Path $backup)) { Copy-Item $p $backup }
}
$gradle = Get-Content $gradlePath -Raw -Encoding UTF8
if ($gradle -match 'namespace\s*=\s*"[^"]+"') {
  $gradle = [regex]::Replace($gradle, 'namespace\s*=\s*"[^"]+"', 'namespace = "' + $packageId + '"', 1)
} else {
  throw 'No namespace declaration found in build.gradle.kts'
}
if ($gradle -match 'applicationId\s*=\s*"[^"]+"') {
  $gradle = [regex]::Replace($gradle, 'applicationId\s*=\s*"[^"]+"', 'applicationId = "' + $packageId + '"', 1)
} else { throw 'No applicationId declaration found in build.gradle.kts' }
Set-Content -Path $gradlePath -Value $gradle -Encoding UTF8

$manifest = Get-Content $manifestPath -Raw -Encoding UTF8
# Handle both Flutter templates: android:name=".MainActivity" and fully qualified legacy activity.
if ($manifest -notmatch '<activity\b[^>]*android:name\s*=') {
  throw 'Could not locate launcher <activity android:name="..."> in AndroidManifest.xml'
}
$manifest = [regex]::Replace($manifest, '(?s)(<activity\b[^>]*?android:name\s*=\s*")[^"]+("[^>]*>)', '${1}' + $packageId + '.MainActivity${2}', 1)
Set-Content -Path $manifestPath -Value $manifest -Encoding UTF8

$folder = Split-Path $activityPath
New-Item -Path $folder -ItemType Directory -Force | Out-Null
$kotlin = @'
package com.muratileogren.academy

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
'@
Set-Content -Path $activityPath -Value $kotlin -Encoding UTF8
if ((Get-Content $manifestPath -Raw) -notmatch 'com\.muratileogren\.academy\.MainActivity') { throw 'Manifest activity verification failed.' }
if ((Get-Content $activityPath -Raw) -notmatch 'package com\.muratileogren\.academy') { throw 'MainActivity verification failed.' }
Write-Host 'OK: namespace, applicationId, manifest activity and Kotlin MainActivity are aligned.' -ForegroundColor Green
