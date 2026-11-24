$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
& dart run scripts/repair_android_launch.dart
if ($LASTEXITCODE -ne 0) { throw 'Dart Android repair failed' }
