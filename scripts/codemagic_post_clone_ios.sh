#!/usr/bin/env bash
# MG Ile Ogren - Codemagic Workflow Editor POST-CLONE script.
# Must run before iOS signing and the default iOS build.
set -euo pipefail
cd "${CM_BUILD_DIR:-$(pwd)}"
echo '=== MG Ile Ogren iOS v1.1.6: create iOS project ==='
flutter create --platforms=ios --org com.muratileogren --project-name murat_ile_ogren .

python3 - <<'PYIOS'
from pathlib import Path
import re, plistlib
pbx = Path('ios/Runner.xcodeproj/project.pbxproj')
if not pbx.is_file():
    raise SystemExit('ERROR: ios/Runner.xcodeproj project file missing')
s = pbx.read_text(encoding='utf-8')

def fix_bundle(m):
    previous=m.group(2).strip().strip('"')
    if 'RunnerTests' in previous:
        ident='com.muratileogren.academy.RunnerTests'
    else:
        ident='com.muratileogren.academy'
    return m.group(1)+ident+m.group(3)

s, n=re.subn(r'(PRODUCT_BUNDLE_IDENTIFIER\s*=\s*)([^;]+)(;)',fix_bundle,s)
if n<1:
    raise SystemExit('ERROR: Could not find PRODUCT_BUNDLE_IDENTIFIER')
pbx.write_text(s,encoding='utf-8')

plist=Path('ios/Runner/Info.plist')
with plist.open('rb') as f: data=plistlib.load(f)
data['CFBundleDisplayName']='MG İle Öğren'
data['CFBundleName']='MG İle Öğren'
with plist.open('wb') as f: plistlib.dump(data,f,fmt=plistlib.FMT_XML,sort_keys=False)
print('Bundle ID: com.muratileogren.academy')
print('App display name: MG İle Öğren')
PYIOS

echo '=== Configure Firebase/APNs native support ==='
bash scripts/prepare_firebase_ios.sh

echo '=== Install Flutter packages ==='
flutter pub get

echo '=== Generate original MG iOS app icons ==='
# The image config must point to a non-transparent 1024x1024 original MG image.
dart run flutter_launcher_icons -f flutter_launcher_icons_ios.yaml

echo '=== Validate generated iOS icons ==='
ICON_DIR='ios/Runner/Assets.xcassets/AppIcon.appiconset'
if [ ! -d "$ICON_DIR" ]; then
  echo 'ERROR: AppIcon.appiconset was not generated'
  exit 1
fi
python3 - <<'PYVERIFY'
from pathlib import Path
import json
p=Path('ios/Runner/Assets.xcassets/AppIcon.appiconset')
files=[x for x in p.glob('*.png')]
if not files:
    raise SystemExit('ERROR: no iOS icons found')
print('iOS icon image count:',len(files))
print('Sample icon:',files[0])
PYVERIFY

echo '=== MG iOS files and custom app icon prepared ==='
