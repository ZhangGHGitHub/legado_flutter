# <js> 书源兼容性回归（REFACTOR_PLAN #2）
# 用法: .\scripts\run_js_compat.ps1

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

$CargoCommand = Get-Command cargo.exe -ErrorAction SilentlyContinue
$FlutterCommand = Get-Command flutter -ErrorAction SilentlyContinue

if ($null -eq $CargoCommand) {
    throw "cargo.exe was not found; Rust JS compatibility gate cannot run."
}
if ($null -eq $FlutterCommand) {
    throw "flutter was not found; Flutter JS compatibility gate cannot run."
}

Write-Host "=== Rust js_compatibility (offline) ===" -ForegroundColor Cyan
Push-Location (Join-Path $ProjectRoot "rust\legado_engine")
try {
    & $CargoCommand.Path test --locked --offline --test js_compatibility
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
    Pop-Location
}

Write-Host "`n=== Flutter JsCompatAnalyzer ===" -ForegroundColor Cyan
& $FlutterCommand.Path test --no-pub test/services/js_compat_analyzer_test.dart test/integration/js_compatibility_test.dart
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "`n=== js compat 全部通过 ===" -ForegroundColor Green
