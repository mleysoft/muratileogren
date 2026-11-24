import 'dart:io';

// Avoid rewriting AndroidManifest.xml with a literal Turkish label.
// The actual Android label is managed by scripts/repair_android_launch.dart
void main() {
  final ios=File('ios/Runner/Info.plist');
  if(ios.existsSync()) {
    var text=ios.readAsStringSync();
    final pattern=RegExp(r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)');
    if(pattern.hasMatch(text)) {
      text=text.replaceAllMapped(pattern,(m)=>'${m.group(1)}MG İle Öğren${m.group(2)}');
    }
    ios.writeAsStringSync(text);
  }
  stdout.writeln('Android launcher name is handled by repair_android_launch.dart');
}
