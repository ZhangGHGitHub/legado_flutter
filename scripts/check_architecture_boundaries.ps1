[CmdletBinding()]
param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..'))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$presentationPatterns = @(
    @{ Name = 'direct infrastructure or generated import'; Regex = '(?im)^\s*import\s+.*(?:bridge/|database/|infrastructure/|src/rust/)' },
    @{ Name = 'Dio import'; Regex = '(?im)^\s*import\s+.*package:dio/' },
    @{ Name = 'direct bridge or generated API use'; Regex = '\b(?:Legado(?:Db|Engine)Bridge|rust_api)\b' },
    @{ Name = 'direct database or DAO use'; Regex = '\b(?:DatabaseHelper|[A-Za-z0-9_]*Dao)\b' },
    @{ Name = 'direct FRB adapter use'; Regex = '\bFrb[A-Za-z0-9_]*\b' },
    @{ Name = 'business HTTP client use'; Regex = '\b(?:Dio|HttpClient|IOHttpClientAdapter)\b' }
)

$coreLayerPatterns = @(
    @{ Name = 'direct infrastructure or generated import'; Regex = '(?im)^\s*import\s+[''\"](?:(?:\.\./)+(?:bridge|database|infrastructure|src/rust)/|package:[^/''\"]+/(?:bridge|database|infrastructure|src/rust)/)' },
    $presentationPatterns[2],
    @{ Name = 'direct database or DAO use'; Regex = '(?-i:\b(?:DatabaseHelper|[A-Za-z0-9_]*Dao)\b)' },
    $presentationPatterns[4]
)

$domainModelPatterns = @(
    @{ Name = 'outer layer or infrastructure import'; Regex = '(?im)^\s*import\s+[''\"](?:(?:\.\./)+(?:features|widgets|providers|services|infrastructure|bridge|database|src/rust)/|package:[^/''\"]+/(?:features|widgets|providers|services|infrastructure|bridge|database|src/rust)/)' },
    @{ Name = 'Dio import or use'; Regex = '(?im)^\s*import\s+[''\"]package:dio/|\b(?:Dio|IOHttpClientAdapter)\b' },
    @{ Name = 'HttpClient use'; Regex = '\bHttpClient\b' },
    @{ Name = 'SharedPreferences import or use'; Regex = '(?im)^\s*import\s+[''\"]package:shared_preferences/|\bSharedPreferences\b' },
    @{ Name = 'file_picker import or use'; Regex = '(?im)^\s*import\s+[''\"]package:file_picker/|\bFilePicker\b' },
    @{ Name = 'path_provider import or use'; Regex = '(?im)^\s*import\s+[''\"]package:path_provider/|\b(?:getApplicationCacheDirectory|getApplicationDocumentsDirectory|getApplicationSupportDirectory|getDownloadsDirectory|getExternalCacheDirectories|getExternalStorageDirectories|getExternalStorageDirectory|getLibraryDirectory|getTemporaryDirectory)\b' }
)

$ruleGroups = @(
    @{
        Name = 'presentation direct infrastructure access'
        Scopes = @('lib/features', 'lib/widgets', 'lib/providers')
        Patterns = $presentationPatterns
    },
    @{
        Name = 'core layer direct infrastructure access'
        Scopes = @('lib/services', 'lib/application')
        Patterns = $coreLayerPatterns
    },
    @{
        Name = 'domain and model purity'
        Scopes = @('lib/domain', 'lib/model', 'lib/models')
        Patterns = $domainModelPatterns
    },
    @{
        Name = 'feature direct SharedPreferences access'
        Scopes = @('lib/features')
        Patterns = @(
            @{ Name = 'SharedPreferences import or use'; Regex = '(?im)^\s*import\s+.*package:shared_preferences/|\bSharedPreferences\b' }
        )
    },
    @{
        Name = 'feature direct business service access'
        Scopes = @('lib/features')
        Patterns = @(
            @{ Name = 'business service import'; Regex = '(?im)^\s*import\s+[''\"](?:package:[^''\"]+/)?(?:\.\./)*services/' }
        )
    }
)

$violationsByGroup = [ordered]@{}

foreach ($group in $ruleGroups) {
    $violations = [System.Collections.Generic.List[string]]::new()

    foreach ($scope in $group.Scopes) {
        $directory = Join-Path $Root $scope
        if (-not (Test-Path -LiteralPath $directory)) {
            continue
        }

        Get-ChildItem -LiteralPath $directory -File -Recurse -Filter '*.dart' |
            ForEach-Object {
                $path = $_.FullName
                $lines = @(Get-Content -LiteralPath $path)
                for ($index = 0; $index -lt $lines.Count; $index++) {
                    $line = $lines[$index].Trim()
                    if ($line.StartsWith('//') -or $line.StartsWith('*')) {
                        continue
                    }
                    foreach ($pattern in $group.Patterns) {
                        if ($lines[$index] -match $pattern.Regex) {
                            $relative = [System.IO.Path]::GetRelativePath($Root, $path)
                            $violations.Add("$relative`:$($index + 1) [$($pattern.Name)] $($lines[$index].Trim())")
                            break
                        }
                    }
                }
            }
    }

    if ($violations.Count -gt 0) {
        $violationsByGroup[$group.Name] = $violations
    }
}

if ($violationsByGroup.Count -eq 0) {
    Write-Host 'Architecture boundary check passed.'
    exit 0
}

$total = ($violationsByGroup.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
Write-Host "Architecture boundary check found $total violation(s):"
foreach ($entry in $violationsByGroup.GetEnumerator()) {
    Write-Host ""
    Write-Host "[$($entry.Key)] $($entry.Value.Count) violation(s)"
    $entry.Value | ForEach-Object { Write-Host $_ }
}
exit 1
