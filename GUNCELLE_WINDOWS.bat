@echo off
setlocal EnableExtensions
chcp 65001 >nul
cd /d "%~dp0"

echo Murat Ile Ogren v1.2.0 - Windows / Android Firebase ve video guncellemesi
where flutter >nul 2>&1
if errorlevel 1 (
  echo HATA: Flutter PATH icinde bulunamadi.
  pause
  exit /b 1
)
where dart >nul 2>&1
if errorlevel 1 (
  echo HATA: Dart PATH icinde bulunamadi.
  pause
  exit /b 1
)
if not exist "pubspec.yaml" (
  echo HATA: pubspec.yaml bulunamadi. ZIP dosyasini proje kokune cikarin.
  pause
  exit /b 1
)

echo [1/6] Android projesi kontrol ediliyor...
if not exist "android\app\src\main\AndroidManifest.xml" (
  call flutter create --platforms=android --org com.muratileogren .
  if errorlevel 1 goto fail
)

echo [2/6] Derleme onbellegi temizleniyor...
call flutter clean
if errorlevel 1 goto fail

echo [3/6] pubspec.yaml ile bagimliliklar yukleniyor...
echo Not: Paketler zorla en yeni surumlere yukseltilemeyecek.
call flutter pub get
if errorlevel 1 goto fail

echo [4/7] Android Gradle Kotlin uyumlulugu kontrol ediliyor...
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\fix_gradle_kotlin.ps1"
if errorlevel 1 goto fail

echo [5/7] Firebase Android ayarlari kontrol ediliyor...
if exist "firebase\google-services.json" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\setup_firebase_android.ps1"
  if errorlevel 1 goto fail
) else (
  echo Firebase Android config eksik, push devre disi kalacak.
)
echo [5/7] Android adi ve INTERNET izni uygulaniyor...
call dart run scripts\apply_brand.dart
if errorlevel 1 goto fail

echo [6/7] YALNIZCA ANDROID uygulama ikonu uretiliyor...
call dart run flutter_launcher_icons
if errorlevel 1 goto fail

echo [7/7] Native splash uretiliyor...
call dart run flutter_native_splash:create
if errorlevel 1 goto fail

echo.
echo TAMAMLANDI. Android emulatorde baslatmak icin:
echo flutter run -d emulator-5554
pause
exit /b 0

:fail
echo.
echo HATA: Adim basarisiz. Yukaridaki ilk hata satirini kontrol edin.
pause
exit /b 1
