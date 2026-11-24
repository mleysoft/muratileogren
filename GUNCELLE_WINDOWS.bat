@echo off
setlocal EnableExtensions
chcp 65001 >nul
cd /d "%~dp0"

echo MG Ile Ogren v1.1.2 - Windows / Android derleme duzeltmesi
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

echo [4/6] Android adi ve INTERNET izni uygulaniyor...
call dart run scripts\apply_brand.dart
if errorlevel 1 goto fail

echo [5/6] YALNIZCA ANDROID uygulama ikonu uretiliyor...
call dart run flutter_launcher_icons
if errorlevel 1 goto fail

echo [6/6] Native splash uretiliyor...
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
