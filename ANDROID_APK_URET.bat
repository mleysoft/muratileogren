@echo off
chcp 65001 >nul
cd /d "%~dp0"
where flutter >nul 2>&1
if errorlevel 1 (echo Flutter SDK yok. & pause & exit /b 1)
if not exist android\app\build.gradle.kts (
 if not exist android\app\build.gradle (
  echo Android proje dosyalari bulunamadi. Once KURULUM_WINDOWS.bat calistir.
  pause & exit /b 1
 )
)
call flutter pub get
if errorlevel 1 goto fail
call flutter build apk --release
if errorlevel 1 goto fail
echo APK: build\app\outputs\flutter-apk\app-release.apk
echo Magaza yuklemesi icin kendi Android imzalama anahtarin ve AAB build gereklidir.
pause
exit /b 0
:fail
echo APK derlemesi basarisiz.
pause
exit /b 1
