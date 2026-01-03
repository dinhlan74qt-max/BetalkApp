# Script để tự động sửa namespace cho các packages thiếu namespace
# Chạy script này sau mỗi lần chạy 'flutter pub get'

function Fix-Namespace {
    param(
        [string]$PackagePath,
        [string]$Namespace
    )
    
    if (Test-Path $PackagePath) {
        Write-Host "🔧 Đang sửa file build.gradle của $Namespace..." -ForegroundColor Yellow
        
        $content = Get-Content $PackagePath -Raw
        
        # Kiểm tra xem đã có namespace chưa
        if ($content -notmatch "namespace\s*=") {
            # Tìm block android { ... }
            if ($content -match "(android\s*\{)") {
                # Thêm namespace ngay sau dòng android {
                $namespaceLine = "    namespace = `"$Namespace`""
                $content = $content -replace "(android\s*\{)", "`$1`n$namespaceLine"
                
                Set-Content -Path $PackagePath -Value $content -NoNewline
                Write-Host "✅ Đã thêm namespace vào build.gradle của $Namespace" -ForegroundColor Green
            } else {
                Write-Host "⚠️ Không tìm thấy block android trong build.gradle" -ForegroundColor Red
            }
        } else {
            Write-Host "✅ Namespace đã có sẵn trong build.gradle của $Namespace" -ForegroundColor Green
        }
    } else {
        Write-Host "⚠️ Không tìm thấy file: $PackagePath" -ForegroundColor Yellow
        Write-Host "   (Có thể package chưa được tải về)" -ForegroundColor Gray
    }
}

# Sửa namespace cho isar_flutter_libs
$isarPath = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\isar_flutter_libs-3.1.0+1\android\build.gradle"
Fix-Namespace -PackagePath $isarPath -Namespace "dev.isar.isar_flutter_libs"

# Sửa namespace cho uni_links
$uniLinksPath = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\uni_links-0.5.1\android\build.gradle"
Fix-Namespace -PackagePath $uniLinksPath -Namespace "com.uni_links"

Write-Host "`n✅ Hoàn tất!" -ForegroundColor Green


