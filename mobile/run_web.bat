@echo off
cd /d "%~dp0"
flutter run -d web-server --web-port 8765 --web-hostname 127.0.0.1
