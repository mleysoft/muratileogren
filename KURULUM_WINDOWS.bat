@echo off
chcp 65001 >nul
cd /d "%~dp0"
call "%~dp0GUNCELLE_WINDOWS.bat"
exit /b %errorlevel%
