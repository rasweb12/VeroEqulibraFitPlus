param(
  [string]$ApiBaseUrl = 'http://10.0.2.2:5000'
)
$flutter = 'C:\develop\flutter\bin\flutter.bat'
& $flutter run --dart-define="API_BASE_URL=$ApiBaseUrl"
