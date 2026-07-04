@echo off
echo ============================================
echo   Amina Platform - Release Build Script
echo   Version 1.0.29 (Build 29)
echo ============================================
echo.

echo [1/5] Cleaning project...
call flutter clean
if %errorlevel% neq 0 (
    echo ERROR: Flutter clean failed!
    pause
    exit /b 1
)
echo.

echo [2/5] Getting dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Flutter pub get failed!
    pause
    exit /b 1
)
echo.

echo [3/5] Running code analysis...
call flutter analyze
if %errorlevel% neq 0 (
    echo WARNING: Code analysis found issues. Continue anyway? (Y/N)
    choice /C YN /M "Continue"
    if errorlevel 2 exit /b 1
)
echo.

echo [4/5] Building App Bundle for Google Play...
call flutter build appbundle --release
if %errorlevel% neq 0 (
    echo ERROR: Build failed!
    pause
    exit /b 1
)
echo.

echo [5/5] Building APK (split per ABI)...
call flutter build apk --release --split-per-abi
if %errorlevel% neq 0 (
    echo ERROR: APK build failed!
    pause
    exit /b 1
)
echo.

echo ============================================
echo   Build Completed Successfully!
echo ============================================
echo.
echo Output files:
echo - App Bundle: build\app\outputs\bundle\release\app-release.aab
echo - APKs: build\app\outputs\flutter-apk\
echo.
echo Next steps:
echo 1. Upload app-release.aab to Google Play Console
echo 2. Fill in release notes from release_notes_v1.0.29.txt
echo 3. Submit for review
echo.
pause
