@echo off
REM Script de tu dong sua namespace cho cac packages thieu namespace
REM Chay script nay sau moi lan chay 'flutter pub get'

echo Dang sua namespace cho cac packages...

REM Sua namespace cho isar_flutter_libs
set ISAR_PATH=%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\isar_flutter_libs-3.1.0+1\android\build.gradle
if exist "%ISAR_PATH%" (
    findstr /C:"namespace" "%ISAR_PATH%" >nul 2>&1
    if errorlevel 1 (
        powershell -Command "(Get-Content '%ISAR_PATH%' -Raw) -replace '(android\s*\{)', '$1`n    namespace = \"dev.isar.isar_flutter_libs\"' | Set-Content '%ISAR_PATH%' -NoNewline"
        echo Da sua namespace cho isar_flutter_libs
    ) else (
        echo isar_flutter_libs da co namespace
    )
) else (
    echo Khong tim thay isar_flutter_libs (co the chua duoc tai)
)

REM Sua namespace cho uni_links
set UNI_LINKS_PATH=%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\uni_links-0.5.1\android\build.gradle
if exist "%UNI_LINKS_PATH%" (
    findstr /C:"namespace" "%UNI_LINKS_PATH%" >nul 2>&1
    if errorlevel 1 (
        powershell -Command "(Get-Content '%UNI_LINKS_PATH%' -Raw) -replace '(android\s*\{)', '$1`n    namespace = \"com.uni_links\"' | Set-Content '%UNI_LINKS_PATH%' -NoNewline"
        echo Da sua namespace cho uni_links
    ) else (
        echo uni_links da co namespace
    )
) else (
    echo Khong tim thay uni_links (co the chua duoc tai)
)

REM Xoa package attribute trong AndroidManifest.xml cua uni_links
set MANIFEST_PATH=%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\uni_links-0.5.1\android\src\main\AndroidManifest.xml
if exist "%MANIFEST_PATH%" (
    findstr /C:"package=" "%MANIFEST_PATH%" >nul 2>&1
    if not errorlevel 1 (
        powershell -Command "(Get-Content '%MANIFEST_PATH%' -Raw) -replace '\s+package\s*=\s*\"[^\"]*\"', '' | Set-Content '%MANIFEST_PATH%' -NoNewline"
        echo Da xoa package attribute khoi AndroidManifest.xml
    ) else (
        echo AndroidManifest.xml da duoc sua roi
    )
)

echo.
echo Hoan tat!


