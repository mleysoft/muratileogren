#!/usr/bin/env bash
# Run on Codemagic macOS after flutter create and before Xcode code signing.
set -euo pipefail
cd "${CM_BUILD_DIR:-$(pwd)}"
if [ ! -d ios/Runner.xcodeproj ]; then
  echo 'ERROR: ios/Runner.xcodeproj missing; run flutter create first.' >&2
  exit 1
fi
if [ -f firebase/GoogleService-Info.plist ]; then
cat > ios/Runner/Runner.entitlements <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>aps-environment</key><string>production</string>
</dict></plist>
PLIST
python3 - <<'PYIOS'
from pathlib import Path
import plistlib
p=Path('ios/Runner/Info.plist')
with p.open('rb') as f: data=plistlib.load(f)
data['UIBackgroundModes']=sorted(set(data.get('UIBackgroundModes',[])+['remote-notification']))
data['FirebaseAppDelegateProxyEnabled']=True
with p.open('wb') as f: plistlib.dump(data,f,sort_keys=False)
PYIOS
  cp firebase/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist
  ruby - <<'RUBY'
require 'xcodeproj'
proj=Xcodeproj::Project.open('ios/Runner.xcodeproj')
runner=proj.targets.find{|t|t.name=='Runner'}
raise 'Runner target not found' unless runner
# Xcode Push Notifications capability; Apple App ID must also enable this.
attributes=proj.root_object.attributes['TargetAttributes'] ||= {}
runner_attributes=attributes[runner.uuid] ||= {}
capabilities=runner_attributes['SystemCapabilities'] ||= {}
capabilities['com.apple.Push']={'enabled'=>1}
capabilities['com.apple.BackgroundModes']={'enabled'=>1}
runner.build_configurations.each do |cfg|
  cfg.build_settings['CODE_SIGN_ENTITLEMENTS']='Runner/Runner.entitlements'
end
file=proj.files.find{|f| f.path=='GoogleService-Info.plist'}
unless file
  group=proj.main_group.find_subpath('Runner',true)
  file=group.new_file('GoogleService-Info.plist')
end
unless runner.resources_build_phase.files_references.include?(file)
  runner.resources_build_phase.add_file_reference(file)
end
proj.save
RUBY
  echo 'Firebase iOS plist attached to Runner and push entitlements configured.'
else
  # Do not pretend push is enabled without a real Firebase project config.
  echo 'WARNING: firebase/GoogleService-Info.plist missing. iOS app builds, FCM push will not initialize.'

fi
