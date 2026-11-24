# MG İle Öğren — Mobil v1.1.5

## Güncelleme
- Giriş ve Hesap oluştur sayfaları yeniden tasarlandı: MG marka başlığı, koyu yeşil eğitim vitrini, beyaz form kartları, daha açık alan isimleri ve modern kayıt/giriş geçişi.
- Kayıt formunda sözleşmeler uygulama içi tarayıcıda açılmaya devam eder; pazarlama izni isteğe bağlıdır ve varsayılan olarak kapalıdır.
- Şifre göster/gizle, e-posta doğrulama, buton yükleme durumu ve tek seferde birden fazla gönderim yapılmasını önleme korunur.
- v1.1.4'teki Eğitimler beyaz ekran düzeltmesi, profil çıkışı sırasında anında arayüz yenileme ve önceki isteklerin eski oturumu geri getirmesini engelleme korunur.
- Ana sayfa eğitim kartı yüksekliği artırıldı; başlık ve istatistiklerin küçük ekranlarda kesilmesi riski azaltıldı.
- Açılışta Android sistem splash zorunludur: düz beyaz tutulur; MG tam ekran splash yaklaşık 1,8 saniye görünür.
- Giriş ve kayıt ekranlarına widget testleri eklendi.

## Windows kurulum
1. Mevcut `C:\Muratileogren` klasörünü yedekleyin.
2. Güncelleme ZIP'indeki dosyaları doğrudan proje köküne kopyalayın. ZIP içinde `lib`, `test`, `pubspec.yaml` bulunur.
3. `flutter pub get`
4. `flutter test`
5. `flutter run -d emulator-5554`

Güncelleme Android klasörünü değiştirmez. Önceden app adı, ikon ve splash oluşturulduysa GUNCELLE_WINDOWS.bat'i yeniden çalıştırmanız gerekmez. Uygulama içi splash görüntüsü `assets/splash_full.png` dosyasındadır.

## Test durumu
Dosya bütünlüğü, işlevsel kod bağlantıları ve parantez/string yapısı statik olarak kontrol edilmiştir. Bu ortamda Flutter SDK ve Android emülatörü bulunmadığından Flutter derleme/widget testleri burada çalıştırılamamıştır; testleri kendi geliştirme ortamınızda çalıştırın.
