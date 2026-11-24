@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo MG Ile Ogren v1.1.5 - kaynak ve widget testleri
call flutter pub get
if errorlevel 1 goto fail
call flutter analyze
if errorlevel 1 goto fail
call flutter test
if errorlevel 1 goto fail
echo.
echo Kontroller tamamlandi. Android icin: flutter run -d emulator-5554
pause
exit /b 0
:fail
echo.
echo Kontrollerden biri hata verdi. Ilk hatayi inceleyin.
pause
exit /b 1
