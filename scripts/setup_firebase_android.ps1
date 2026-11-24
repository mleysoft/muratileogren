# Run after flutter create in Windows. Requires real firebase/google-services.json.
$ErrorActionPreference='Stop'
Set-Location (Join-Path $PSScriptRoot '..')
$settings='android/settings.gradle.kts'
$app='android/app/build.gradle.kts'
if (!(Test-Path $settings) -or !(Test-Path $app)) { throw 'Android Gradle Kotlin files missing. Run flutter create --platforms=android . first.' }
$config='firebase/google-services.json'
if (!(Test-Path $config)) { throw 'Download Firebase Android app google-services.json to firebase/google-services.json first.' }
$s=Get-Content $settings -Raw
if ($s -notmatch 'com.google.gms.google-services') {
  $s=$s -replace '(plugins\s*\{)', ('$1' + "`r`n    id(`"com.google.gms.google-services`") version `"4.4.4`" apply false")
  Set-Content $settings $s -Encoding utf8
}
$a=Get-Content $app -Raw
if ($a -notmatch 'com.google.gms.google-services') {
  $a=$a -replace '(plugins\s*\{)', ('$1' + "`r`n    id(`"com.google.gms.google-services`")")
  Set-Content $app $a -Encoding utf8
}
Copy-Item $config 'android/app/google-services.json' -Force
$manifest='android/app/src/main/AndroidManifest.xml'
$m=Get-Content $manifest -Raw
if ($m -notmatch 'android.permission.POST_NOTIFICATIONS') {
  $m=$m -replace '<application', ("<uses-permission android:name=`"android.permission.POST_NOTIFICATIONS`"/>`r`n    <application")
  Set-Content $manifest $m -Encoding utf8
}
Write-Host 'Firebase Android configured. Run flutter clean; flutter pub get; flutter run'
