# MG İle Öğren v1.1.6 (7)

- Orijinal MG uygulama ikonundan 1024×1024 tam opak iOS ikon kaynağı (`assets/app_icon_ios.png`).
- iOS'a özel `flutter_launcher_icons_ios.yaml` dosyası.
- Codemagic Post-clone otomasyon betiği: iOS projesini oluşturur, Bundle ID ve görünen adı ayarlar, iOS simge setini üretir.
- Uygulama sürümü 1.1.6+7.
- Apple SDK uyarısı için Codemagic Xcode 27.x ayar yönergesi.

**Not:** Üretilen `.ipa` burada derlenmedi; imzalama ve yayınlama testleri yalnızca Codemagic'te gerçekleştirilebilir.
