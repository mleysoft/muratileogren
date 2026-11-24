#!/usr/bin/env python3
"""Patch the generated iOS AppDelegate.swift to serve the Flutter badge channel.
Idempotent; run on Codemagic immediately after `flutter create --platforms=ios`.
"""
from pathlib import Path
p = Path('ios/Runner/AppDelegate.swift')
if not p.exists():
    raise SystemExit('iOS Runner/AppDelegate.swift missing (generate the iOS project first)')
s = p.read_text(encoding='utf-8')
if 'muratileogren/notification_badge' in s:
    print('Native iOS badge channel already configured')
    raise SystemExit(0)
# Preserve original AppDelegate lifecycle and Firebase swizzling, while
# registering the method channel on Flutter's root view controller.
needle = 'GeneratedPluginRegistrant.register(with: self)'
if needle not in s:
    raise SystemExit('Could not locate Flutter plugin registration in AppDelegate.swift')
s = s.replace(needle, '''GeneratedPluginRegistrant.register(with: self)
    if let flutterVC = window?.rootViewController as? FlutterViewController {
      let badgeChannel = FlutterMethodChannel(
        name: "muratileogren/notification_badge",
        binaryMessenger: flutterVC.binaryMessenger
      )
      badgeChannel.setMethodCallHandler { call, result in
        guard call.method == "setBadge" else {
          result(FlutterMethodNotImplemented)
          return
        }
        let arguments = call.arguments as? [String: Any]
        let count = max(0, min(999, arguments?["count"] as? Int ?? 0))
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
    }''')
if 'import UserNotifications' not in s:
    s = 'import UserNotifications\n' + s
p.write_text(s, encoding='utf-8')
print('Native iOS badge channel installed')
