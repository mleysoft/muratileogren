@echo off
setlocal EnableExtensions
cd /d "%~dp0"
chcp 65001 >nul
echo [1/4] Android paket, MainActivity ve baslatma adi onariliyor...
call dart run scripts\repair_android_launch.dart
if errorlevel 1 goto fail
echo [2/4] Onceki Android derlemeleri temizleniyor...
call flutter clean
if errorlevel 1 goto fail
echo [3/4] Paketler hazirlaniyor...
call flutter pub get
if errorlevel 1 goto fail
echo [4/4] Emulatorde baslatiliyor...
call flutter run -d emulator-5554
if errorlevel 1 goto fail
echo Bitti.
pause
exit /b 0
:fail
echo HATA: Yukaridaki ilk hatayi inceleyin.
pause
exit /b 1
