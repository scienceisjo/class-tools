@echo off
cd /d "%~dp0"
echo ============================================
echo   PDF Tool - starting local server...
echo   (Keep the small minimized window open.)
echo   Close that window to quit the program.
echo ============================================
start "PDF-Tool-Server" /min python -m http.server 8777 --directory "%~dp0"
timeout /t 1 /nobreak >nul
start "" "http://localhost:8777/index.html"
exit
