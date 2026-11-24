# Murat İle Öğren · Android başlangıç düzeltmesi v1.2.4

## Sorun
AndroidManifest.xml eskiden `com.example.murat_ile_ogren.MainActivity` çağırıyor, ancak `applicationId` `com.muratileogren.academy` idi. Sonuç: `ClassNotFoundException` ve anında kapanma. Eski PowerShell betikleri `android:label` değerini de Windows Türkçe kodlamasında bozabiliyor.

## Kurulum
**Hızlı güncelleme ZIP** içindeki dosyaları `C:\Muratileogren` köküne kopyala (özellikle `scripts/` ve `ANDROID_ACIL_DUZELT.bat`).

Ardından `C:\Muratileogren\ANDROID_ACIL_DUZELT.bat` dosyasını çalıştır.

Alternatif CMD:
```
cd /d C:\Muratileogren
dart run scripts\repair_android_launch.dart
flutter clean
flutter pub get
flutter run -d emulator-5554
```

## Kodun yaptığı
- namespace ve applicationId: `com.muratileogren.academy`
- Manifest launcher: `com.muratileogren.academy.MainActivity`
- Java sınıfı: `android/app/src/main/java/com/muratileogren/academy/MainActivity.java`
- Eski Kotlin/Java MainActivity dosyaları `.disabled` yapılır.
- Android uygulama etiketi: `@string/app_name`, Unicode karakterleri güvenli `strings.xml` içinde `MG İle Öğren`.
- Eski manifest ve Gradle için `.pre-v124.bak` yedeği.

## Dikkat
`flutter create` veya önceki sürümün kurulum bat dosyasını tekrar çalıştırmak mevcut Android ayarlarını yeniden değiştirebilir. Bu paketteki güncel GUNCELLE_WINDOWS.bat her işlemin sonunda onarımı tekrar çalıştırır.

Eğer hala çökme varsa terminalde `adb logcat -d -s AndroidRuntime:E` komutunun `Caused by` satırlarını al. Emulatorun uygulamayı kaldırıp temiz kurması gerekirse `adb uninstall com.muratileogren.academy` kullanabilirsin; bu cihazdaki uygulama verilerini siler fakat sunucudaki üyeliği etkilemez.

**Test kapsamı:** Dosya yapısı ve statik eşleştirme denetlendi. Bu ortamda Flutter/Dart/Android SDK olmadığı için uygulamanın gerçek derlemesi yapılamadı.
