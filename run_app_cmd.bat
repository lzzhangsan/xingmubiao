@echo off
cd /d "E:\1.mybiancheng\xingmubiao"
echo Starting Flutter app...
flutter run --verbose
if %errorlevel% neq 0 (
    echo Flutter run failed with error code %errorlevel%
    echo Trying to build APK instead...
    flutter build apk --debug
)
pause

