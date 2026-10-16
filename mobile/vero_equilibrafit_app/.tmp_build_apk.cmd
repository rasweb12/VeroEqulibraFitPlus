@echo off
"C:\develop\flutter\bin\flutter.bat" build apk --debug --dart-define=API_BASE_URL=https://veroequlibrafitplus.onrender.com > .tmp_apk_build.log 2>&1
echo %ERRORLEVEL% > .tmp_apk_build.exit
