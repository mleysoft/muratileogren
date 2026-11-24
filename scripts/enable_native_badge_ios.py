#!/usr/bin/env python3
"""Install the native iOS badge method channel after flutter create.
Supports the modern UIScene/FlutterImplicitEngineDelegate Flutter template and
older AppDelegate templates. Safe to run again on the same generated project.
"""
from pathlib import Path
import re

p = Path('ios/Runner/AppDelegate.swift')
if not p.exists():
    raise SystemExit('ERROR: ios/Runner/AppDelegate.swift missing. Create iOS project first.')
s = p.read_text(encoding='utf-8')
channel_id = 'muratileogren/notification_badge'
if channel_id in s:
    print('iOS badge channel already installed.')
    raise SystemExit(0)

channel_code = '''
    // Native badge count remains in sync when a notification is read or on logout.
    let badgeChannel = FlutterMethodChannel(
      name: "muratileogren/notification_badge",
      binaryMessenger: BADGE_MESSENGER
    )
    badgeChannel.setMethodCallHandler { call, result in
      guard call.method == "setBadge" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let args = call.arguments as? [String: Any]
      let count = max(0, min(999, args?["count"] as? Int ?? 0))
      if #available(iOS 16.0, *) {
        UNUserNotificationCenter.current().setBadgeCount(count) { error in
          DispatchQueue.main.async {
            if let error = error {
              result(FlutterError(code: "BADGE_ERROR", message: error.localizedDescription, details: nil))
            } else {
              result(nil)
            }
          }
        }
      } else {
        UIApplication.shared.applicationIconBadgeNumber = count
        result(nil)
      }
    }
'''

if 'import UserNotifications' not in s:
    s = 'import UserNotifications\n' + s

# Flutter 3.41+ UIScene: window?.rootViewController is nil during AppDelegate
# launch. Use the FlutterImplicitEngineBridge applicationRegistrar messenger.
if 'didInitializeImplicitFlutterEngine' in s:
    marker = re.search(r'GeneratedPluginRegistrant\s*\.\s*register\s*\(with:\s*engineBridge\.pluginRegistry\s*\)', s)
    if not marker:
        raise SystemExit('ERROR: UIScene AppDelegate found but implicit-engine plugin registration is missing; refusing unsafe patch.')
    block = channel_code.replace('BADGE_MESSENGER', 'engineBridge.applicationRegistrar.messenger()')
    s = s[:marker.end()] + '\n' + block + s[marker.end():]
    print('Configured iOS badge channel using UIScene / FlutterImplicitEngineDelegate.')
else:
    # Older Flutter template uses the FlutterViewController in application launch.
    marker = re.search(r'GeneratedPluginRegistrant\s*\.\s*register\s*\(with:\s*self\s*\)', s)
    if not marker:
        raise SystemExit('ERROR: Unsupported AppDelegate.swift template; no plugin registration found.')
    legacy = '''
    if let flutterVC = window?.rootViewController as? FlutterViewController {
''' + channel_code.replace('BADGE_MESSENGER', 'flutterVC.binaryMessenger') + '''
    }
'''
    s = s[:marker.end()] + '\n' + legacy + s[marker.end():]
    print('Configured iOS badge channel using legacy FlutterViewController.')

p.write_text(s, encoding='utf-8')
