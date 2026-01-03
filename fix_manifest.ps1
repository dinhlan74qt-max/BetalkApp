# Script de xoa package attribute trong AndroidManifest.xml cua uni_links
# Chay script nay sau moi lan chay 'flutter pub get'

$manifestPath = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\uni_links-0.5.1\android\src\main\AndroidManifest.xml"

if (Test-Path $manifestPath) {
    Write-Host "Dang sua AndroidManifest.xml cua uni_links..." -ForegroundColor Yellow
    
    $content = Get-Content $manifestPath -Raw
    
    # Xoa package attribute khoi manifest tag
    # Tim pattern: <manifest xmlns:... package="name.avioli.unilinks">
    if ($content -match 'package\s*=\s*"[^"]*"') {
        $content = $content -replace '\s+package\s*=\s*"[^"]*"', ''
        
        Set-Content -Path $manifestPath -Value $content -NoNewline
        Write-Host "Da xoa package attribute khoi AndroidManifest.xml" -ForegroundColor Green
    } else {
        Write-Host "Khong tim thay package attribute trong AndroidManifest.xml" -ForegroundColor Green
    }
} else {
    Write-Host "Khong tim thay file: $manifestPath" -ForegroundColor Yellow
    Write-Host "   (Co the package chua duoc tai ve)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Hoan tat!" -ForegroundColor Green

