@echo off
echo Starting Flutter build and run process...
echo.

echo Step 1: Cleaning project...
C:\src\flutter\bin\flutter.bat clean

echo.
echo Step 2: Getting dependencies...
C:\src\flutter\bin\flutter.bat pub get

echo.
echo Step 3: Building APK...
C:\src\flutter\bin\flutter.bat build apk --debug

echo.
echo Step 4: Installing and running on device...
C:\src\flutter\bin\flutter.bat run -d JB85PZ9TBUUC5PIB

echo.
echo Process completed!
pause

