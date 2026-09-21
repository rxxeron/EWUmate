@echo off
echo =======================================================
echo Compiling EWUmate Production APK...
echo =======================================================
echo.
echo Running flutter build with --no-tree-shake-icons to preserve all Material Icons.
echo.

flutter build apk --release --no-tree-shake-icons

echo.
echo =======================================================
echo Build Complete! 
echo Your APK is ready at: build\app\outputs\flutter-apk\app-release.apk
echo =======================================================
pause
