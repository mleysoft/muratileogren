MG İLE ÖĞREN - MOBİL GÜNCELLEME v1.1

MEVCUT FLUTTER KLASÖRÜN: C:\Muratileogren

1. Mevcut proje klasörünü yedekle.
2. ZIP içerisindeki 02_FLUTTER_MOBIL klasörünün İÇERİĞİNİ C:\Muratileogren içine kopyala.
3. Mevcut android/ ve ios/ klasörlerini silme.
4. C:\Muratileogren\GUNCELLE_WINDOWS.bat çalıştır.
5. Emülatör açıkken C:\Muratileogren klasöründe: flutter run -d emulator-5554

SUNUCU: Önceki PHP mobil API'n zaten kuruluysa yeniden SQL veya web sitesi yüklemene gerek yok.

YAPILANLAR:
- Tam ekran 1080 x 1920 MG açılış tasarımı (Flutter splash).
- Android ve iOS uygulama adı MG İle Öğren.
- Kullanıcının verdiği orijinal MG logo uygulama simgesi.
- Gizlilik ve koşullar sayfası uygulama içi tarayıcıda açılır.
- Video dış bağlantıları mümkün olduğunda uygulama içi açılır.
- Giriş sonrasında kullanıcı durumu API yanıtından anında yenilenir; beklenmeyen bootstrap hataları mevcut oturumu silmez.
- Beyaz temalı yeni ana sayfa, eğitim kartları, kategori üst alanı ve ders bilgi paneli.

NOT: Android 12+ sistem açılış ekranı tam sayfa görseli desteklemez. Önce logo gösterilir, hemen ardından uygulamanın 1080x1920 özel splash ekranı görünür.

TEST: Dosyalar ve statik kod kontrolleri yapıldı. Flutter/Android derlemesi bu ortamda yapılmadı.
