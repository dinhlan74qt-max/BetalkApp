# Script de tu dong sua namespace cho cac packages
# Chay script nay sau moi lan chay 'flutter pub get'

function Fix-Namespace {
    param(
        [string]$PackagePath,
        [string]$Namespace
    )
    
    if (Test-Path $PackagePath) {
        Write-Host "Dang sua file build.gradle..." -ForegroundColor Yellow
        
        $content = Get-Content $PackagePath -Raw
        
        if ($content -notmatch "namespace\s*=") {
            if ($content -match "android\s*\{") {
                $namespaceLine = "    namespace = `"$Namespace`""
                $content = $content -replace "(android\s*\{)", "`$1`n$namespaceLine"
                
                Set-Content -Path $PackagePath -Value $content -NoNewline
                Write-Host "Da them namespace: $Namespace" -ForegroundColor Green
            }
        } else {
            Write-Host "Namespace da co san" -ForegroundColor Green
        }
    } else {
        Write-Host "Khong tim thay file: $PackagePath" -ForegroundColor Yellow
    }
}

# Sua namespace cho isar_flutter_libs
$isarPath = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\isar_flutter_libs-3.1.0+1\android\build.gradle"
Fix-Namespace -PackagePath $isarPath -Namespace "dev.isar.isar_flutter_libs"

# Sua namespace cho uni_links
$uniLinksPath = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\uni_links-0.5.1\android\build.gradle"
Fix-Namespace -PackagePath $uniLinksPath -Namespace "com.uni_links"

# Xoa package attribute trong AndroidManifest.xml cua uni_links
$manifestPath = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\uni_links-0.5.1\android\src\main\AndroidManifest.xml"
if (Test-Path $manifestPath) {
    Write-Host "Dang sua AndroidManifest.xml cua uni_links..." -ForegroundColor Yellow
    $manifestContent = Get-Content $manifestPath -Raw
    if ($manifestContent -match 'package\s*=\s*"[^"]*"') {
        $manifestContent = $manifestContent -replace '\s+package\s*=\s*"[^"]*"', ''
        Set-Content -Path $manifestPath -Value $manifestContent -NoNewline
        Write-Host "Da xoa package attribute khoi AndroidManifest.xml" -ForegroundColor Green
    } else {
        Write-Host "AndroidManifest.xml da duoc sua roi" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Hoan tat!" -ForegroundColor Green

