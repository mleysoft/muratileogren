import 'dart:io';

// Dart uses UTF-8 consistently on Windows; avoid PowerShell 5.1 ANSI decoding.
const packageId = 'com.muratileogren.academy';

Never _fail(String msg) => throw StateError('ANDROID CONFIG ERROR: $msg');

void main() {
  final root = Directory.current;
  final manifestFile = File('android/app/src/main/AndroidManifest.xml');
  final gradleFile = File('android/app/build.gradle.kts');
  if (!manifestFile.existsSync() || !gradleFile.existsSync()) {
    _fail('Flutter Android projesi bulunamadi. Once flutter create --platforms=android .');
  }

  var gradle = gradleFile.readAsStringSync();
  for (final entry in <String, String>{
    r'namespace\s*=\s*"[^"]+"': 'namespace = "$packageId"',
    r'applicationId\s*=\s*"[^"]+"': 'applicationId = "$packageId"',
  }.entries) {
    final regex = RegExp(entry.key);
    if (!regex.hasMatch(gradle)) _fail('build.gradle.kts: ${entry.key} bulunamadi');
    gradle = gradle.replaceFirst(regex, entry.value);
  }
  _backup(gradleFile);
  gradleFile.writeAsStringSync(gradle, flush: true);

  var manifest = manifestFile.readAsStringSync();
  final activityRegex = RegExp(r'(<activity\b[^>]*?android:name\s*=\s*")[^"]+("[^>]*>)', dotAll: true);
  if (!activityRegex.hasMatch(manifest)) {
    _fail('AndroidManifest.xml icinde launcher activity bulunamadi');
  }
  manifest = manifest.replaceFirstMapped(activityRegex,
      (m) => '${m.group(1)}$packageId.MainActivity${m.group(2)}');
  final applicationRegex = RegExp(r'(<application\b[^>]*?android:label\s*=\s*")[^"]*(")', dotAll: true);
  if (applicationRegex.hasMatch(manifest)) {
    manifest = manifest.replaceFirstMapped(applicationRegex,
        (m) => '${m.group(1)}@string/app_name${m.group(2)}');
  } else {
    manifest = manifest.replaceFirst('<application', '<application android:label="@string/app_name"');
  }
  _backup(manifestFile);
  manifestFile.writeAsStringSync(manifest, flush: true);

  // Named resource avoids console/PowerShell incorrectly decoding Turkish glyphs.
  final values = Directory('android/app/src/main/res/values');
  values.createSync(recursive: true);
  final strings = File('${values.path}/strings.xml');
  var resources = strings.existsSync()
      ? strings.readAsStringSync()
      : '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n</resources>\n';
  // XML numeric references are ASCII-safe and resolve to the real Turkish letters.
  const appName = '<string name="app_name">MG &#304;le &#214;&#287;ren</string>';
  final existing = RegExp(r'<string\s+name\s*=\s*["\x27]app_name["\x27][^>]*>.*?</string>', dotAll: true);
  if (existing.hasMatch(resources)) {
    resources = resources.replaceFirst(existing, appName);
  } else if (resources.contains('</resources>')) {
    resources = resources.replaceFirst('</resources>', '    $appName\n</resources>');
  } else {
    _fail('strings.xml icindeki resources elementi gecersiz');
  }
  _backup(strings);
  strings.writeAsStringSync(resources, flush: true);

  // Java Activity works with AGP 9 without depending on Kotlin plugin compilation.
  // Disable legacy MainActivity files so a duplicate class cannot be packaged.
  final java = File('android/app/src/main/java/com/muratileogren/academy/MainActivity.java');
  final sources = [
    Directory('android/app/src/main/kotlin'),
    Directory('android/app/src/main/java'),
  ];
  for (final dir in sources) {
    if (!dir.existsSync()) continue;
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final path = entity.path.replaceAll('\\', '/');
      final name = path.split('/').last;
      if ((name == 'MainActivity.kt' || name == 'MainActivity.java') &&
          path != java.path.replaceAll('\\', '/')) {
        final disabled = File('${entity.path}.disabled');
        if (!disabled.existsSync()) entity.renameSync(disabled.path);
        else entity.deleteSync();
        stdout.writeln('Devre disi: $path');
      }
    }
  }
  java.parent.createSync(recursive: true);
  java.writeAsStringSync("""package com.muratileogren.academy;

import android.app.NotificationManager;
import android.content.Context;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
  private static final String BADGE_CHANNEL = "muratileogren/notification_badge";

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    super.configureFlutterEngine(flutterEngine);
    new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), BADGE_CHANNEL)
      .setMethodCallHandler((call, result) -> {
        if (!"setBadge".equals(call.method)) {
          result.notImplemented();
          return;
        }
        Integer count = call.argument("count");
        // Android launcher badges are derived from active notifications.
        // Once every item is read, remove this app's old notifications so
        // launchers no longer display the stale red dot/count.
        if (count != null && count <= 0) {
          NotificationManager nm =
            (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
          if (nm != null) nm.cancelAll();
        }
        result.success(null);
      });
  }
}
""", flush: true);

  final checkManifest = manifestFile.readAsStringSync();
  final checkGradle = gradleFile.readAsStringSync();
  if (!checkManifest.contains('$packageId.MainActivity') ||
      !checkManifest.contains('@string/app_name') ||
      !checkGradle.contains('namespace = "$packageId"') ||
      !checkGradle.contains('applicationId = "$packageId"') ||
      !java.existsSync()) {
    _fail('Dogrulama basarisiz: Android kimlikleri eslesmiyor');
  }
  stdout.writeln('OK: Android start class: $packageId.MainActivity');
  stdout.writeln('OK: Android package: $packageId');
  stdout.writeln('OK: Launcher label: MG Ile Ogren (Turkish XML Unicode references)');
  stdout.writeln('Project: ${root.path}');
}

void _backup(File file) {
  if (!file.existsSync()) return;
  final backup = File('${file.path}.pre-v124.bak');
  if (!backup.existsSync()) file.copySync(backup.path);
}
