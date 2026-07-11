# <js> 书源兼容性回归（REFACTOR_PLAN #2）
# 用法: .\scripts\run_js_compat.ps1

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

$CargoBin = Join-Path $env:USERPROFILE ".cargo\bin"
$CargoExe = Join-Path $CargoBin "cargo.exe"
$env:Path = "$CargoBin;" + $env:Path

Write-Host "=== Rust js_compatibility (offline) ===" -ForegroundColor Cyan
Push-Location (Join-Path $ProjectRoot "rust\legado_engine")
try {
    if (-not (Test-Path $CargoExe)) {
        Write-Host "未找到 cargo，跳过 Rust 测试" -ForegroundColor Yellow
    } else {
        $prevEap = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        & $CargoExe test --test js_compatibility 2>&1 | Write-Host
        $ErrorActionPreference = $prevEap
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
} finally {
    Pop-Location
}

Write-Host "`n=== Flutter JsCompatAnalyzer ===" -ForegroundColor Cyan
flutter test test/services/js_compat_analyzer_test.dart test/integration/js_compatibility_test.dart
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "`n=== js compat 全部通过 ===" -ForegroundColor Green
