@echo off
echo ==========================================
echo       ComfyController APK Builder
echo ==========================================
echo.
echo Preparing build environment...
echo Using Local Gradle: .build_env\gradle-8.4\bin\gradle.bat

set "JAVA_HOME=%~dp0.build_env\jdk-17.0.9+8"
set "ANDROID_HOME=%~dp0.build_env\android-sdk"
set "PATH=%JAVA_HOME%\bin;%PATH%"

set "GRADLE_BIN=%~dp0.build_env\gradle-8.4\bin\gradle.bat"

if not exist "%GRADLE_BIN%" (
    echo Error: Gradle not found.
    echo Please ensure .build_env folder exists in the current directory.
    pause
    exit /b 1
)

echo.
echo Cleaning and building APK (Debug)...
echo.

call "%GRADLE_BIN%" clean assembleDebug

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ==========================================
    echo           BUILD SUCCESSFUL!
    echo ==========================================
    echo.
    echo Copying APK to root directory...
    copy "app\build\outputs\apk\debug\app-debug.apk" "ComfyController.apk" > nul
    echo.
    echo APK Location:
    echo %~dp0ComfyController.apk
    echo.
    echo Opening output directory...
    explorer /select,"%~dp0ComfyController.apk"
) else (
    echo.
    echo ==========================================
    echo           BUILD FAILED
    echo ==========================================
    echo Please check the error messages above.
)

echo.
pause