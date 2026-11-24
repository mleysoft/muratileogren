@echo off
setlocal
cd /d "%~dp0"
echo [1/5] Proje kontrol ediliyor...
if not exist "pubspec.yaml" (
 echo HATA: pubspec.yaml bulunamadi. ZIP dosyasini C:\Muratileogren icine cikarin.
 pause
 exit /b 1
)
if not exist "lib\notifications.dart" (
 echo HATA: lib\notifications.dart bulunamadi.
 pause
 exit /b 1
)
echo [2/5] Hatalı Flutter derleme onbellegi temizleniyor...
call flutter clean
if errorlevel 1 goto fail
if exist ".dart_tool" rmdir /s /q ".dart_tool"
if exist "pubspec.lock" del /q /f "pubspec.lock"
echo [3/5] Flutter paketleri kuruluyor...
call flutter pub get
if errorlevel 1 goto fail
echo [4/5] Eksik paket referansi kontrol ediliyor...
findstr /s /i /m "app_badge_plus" "lib\*.dart" "pubspec.yaml" >nul 2>&1
if not errorlevel 1 (
 echo HATA: app_badge_plus kodda hala var; ZIP dosyalari dogru konuma kopyalanmamis.
 pause
 exit /b 1
)
echo [5/5] Emulator baslatiliyor...
call flutter run -d emulator-5554
if errorlevel 1 goto fail
exit /b 0
:fail
echo Derleme islemi basarisiz. Yukaridaki ilk ERROR satirini kontrol edin.
pause
exit /b 1
