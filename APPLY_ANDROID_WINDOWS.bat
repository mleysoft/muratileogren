@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo [1/4] Android native notification bridge installed...
call dart run scripts\repair_android_launch.dart
if errorlevel 1 goto fail
echo [2/4] Clearing old compilation artifacts...
call flutter clean
if errorlevel 1 goto fail
echo [3/4] Resolving dependencies...
call flutter pub get
if errorlevel 1 goto fail
echo [4/4] Starting emulator...
call flutter run -d emulator-5554
if errorlevel 1 goto fail
exit /b 0
:fail
echo Error: please send the first failure message from above.
pause
exit /b 1
