# MG İle Öğren — v1.1.4 (Android hata düzeltme)

## Neler değişti?
- **Eğitimler sayfasında beyaz/boş ekran**: `CourseCard` içinde dikey `ListView` ile uyumsuz `Expanded` kaldırıldı. Kartın yüksekliği içeriğe göre belirleniyor ve ana sayfa ızgarasında da kullanılabiliyor.
- **Profil çıkış yap**: Başarılı bir oturum kapatma işleminde kullanıcı bilgileri ekrandan anında kaldırılıyor. Sunucudaki oturum iptali internet nedeniyle takılırsa arayüz beklemiyor.
- **Giriş/çıkış sonrası arayüz güncellemesi**: `IndexedStack` altındaki sekme widget'ları her store değişiminde yeni konfigürasyonla oluşturuluyor; Stateful sekme durumu anahtarlarla korunuyor.
- **Eski API isteğinin kullanıcıyı geri getirmesi**: Oturum sürümü kontrolü eklendi. Gecikmiş bootstrap yanıtları yeni oturum durumunu ezemiyor.
- **Splash**: Android'in mecburi sistem splash ekranı düz beyaz; uygulama içi MG açılışı **1,8 saniye** kalıyor. Android 12+ sistem ekranının gerçek görünme süresi 0'a zorlanamaz.
- Yeni widget ve oturum testleri eklendi.

## Windows'ta kurulum
1. Mevcut `C:\\Muratileogren` klasörünün yedeğini alın.
2. `MG_Ile_Ogren_v1.1.4_Guncelleme.zip` içeriğini **doğrudan bu klasöre** çıkarın; `lib` ve `assets` klasörleri aynı dizinde olmalı.
3. CMD: `cd /d C:\\Muratileogren`
4. CMD: `GUNCELLE_WINDOWS.bat`
5. CMD: `flutter run -d emulator-5554`

İsteğe bağlı: `KONTROL_ET_WINDOWS.bat` ile `flutter analyze` ve `flutter test` çalıştırılabilir. Bu kontrollerin yerel Flutter SDK üzerinde çalıştırılması gerekir.

**Test sınırlaması:** Paket burada kaynak kontrolüyle doğrulandı. Flutter SDK/Android emülatörü olmadığı için gerçek bir Android derlemesi ve canlı oturum testi yapılmadı.
