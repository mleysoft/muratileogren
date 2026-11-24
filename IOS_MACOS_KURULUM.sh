#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
command -v flutter >/dev/null || { echo 'Flutter SDK gerekli: https://docs.flutter.dev/install'; exit 1; }
command -v xcodebuild >/dev/null || { echo 'iOS derleme icin macOS ve Xcode gerekir'; exit 1; }
flutter create --platforms android,ios --org com.muratileogren --project-name murat_ile_ogren .
dart run scripts/apply_brand.dart
flutter pub get
dart run flutter_launcher_icons -f flutter_launcher_icons_ios.yaml
dart run flutter_native_splash:create
flutter analyze
flutter test
flutter build ios --release --no-codesign
echo 'iOS kodu ve imzasiz derlemesi hazir. Gercek cihaz ve App Store icin Apple Developer imzasi gerekir.'
