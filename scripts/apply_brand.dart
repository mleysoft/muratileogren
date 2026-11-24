import 'dart:io';

// Works after `flutter create`; avoids shipping stale Gradle/Xcode templates.
void main() {
  final android=File('android/app/src/main/AndroidManifest.xml');
  if(android.existsSync()){
    var text=android.readAsStringSync();
    for (final oldName in ['murat_ile_ogren','Murat Ile Ogren','Murat İle Öğren']) {
      text=text.replaceAll('android:label="${oldName}"','android:label="MG İle Öğren"');
    }
    if(!text.contains('android.permission.INTERNET')){
      text=text.replaceFirst('<application', '<uses-permission android:name="android.permission.INTERNET"/>\n    <application');
    }
    android.writeAsStringSync(text);
    stdout.writeln('Android uygulama adi ve internet izni uygulandi.');
  }
  final ios=File('ios/Runner/Info.plist');
  if(ios.existsSync()){
    var text=ios.readAsStringSync();
    final pattern=RegExp(r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)');
    if(pattern.hasMatch(text)){
      text=text.replaceAllMapped(pattern,(m)=>'${m.group(1)}MG İle Öğren${m.group(2)}');
    }else{
      text=text.replaceFirst('<dict>', '<dict>\n\t<key>CFBundleDisplayName</key>\n\t<string>MG İle Öğren</string>');
    }
    ios.writeAsStringSync(text);
    stdout.writeln('iOS ana ekran uygulama adi uygulandi.');
  }
}
