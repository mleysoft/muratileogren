@echo off
chcp 65001 >nul
cd /d "%~dp0"
if not exist "lib\notifications.dart" (
 echo HATA: Betik Flutter proje ana klasorunde degil.
 pause
 exit /b 1
)
echo Flutter bagimliliklari yenileniyor...
call flutter pub get
if errorlevel 1 goto fail
echo Bildirim rozeti paketi dogrulaniyor...
call flutter pub deps --style=compact | findstr /i "app_badge_plus"
if errorlevel 1 goto fail
echo Basarili. Simdi flutter run -d emulator-5554 komutunu calistir.
pause
exit /b 0
:fail
echo Kurulum tamamlanamadi. Yukaridaki hatayi kontrol edin.
pause
exit /b 1
