[CmdletBinding()]
param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..'))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scopes = @('lib/features', 'lib/widgets', 'lib/providers')
$violations = [System.Collections.Generic.List[string]]::new()
$patterns = @(
    @{ Name = 'direct infrastructure or generated import'; Regex = '(?im)^\s*import\s+.*(?:bridge/|database/|infrastructure/|src/rust/)' },
    @{ Name = 'Dio import'; Regex = '(?im)^\s*import\s+.*package:dio/' },
    @{ Name = 'direct bridge or generated API use'; Regex = '\b(?:Legado(?:Db|Engine)Bridge|rust_api)\b' },
    @{ Name = 'direct database or DAO use'; Regex = '\b(?:DatabaseHelper|[A-Za-z0-9_]*Dao)\b' },
    @{ Name = 'direct FRB adapter use'; Regex = '\bFrb[A-Za-z0-9_]*\b' },
    @{ Name = 'business HTTP client use'; Regex = '\b(?:Dio|HttpClient|IOHttpClientAdapter)\b' }
)

foreach ($scope in $scopes) {
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
                foreach ($pattern in $patterns) {
                    if ($lines[$index] -match $pattern.Regex) {
                        $relative = [System.IO.Path]::GetRelativePath($Root, $path)
                        $violations.Add("$relative`:$($index + 1) [$($pattern.Name)] $($lines[$index].Trim())")
                        break
                    }
                }
            }
        }
}

if ($violations.Count -eq 0) {
    Write-Host 'Architecture boundary check passed.'
    exit 0
}

Write-Host "Architecture boundary check found $($violations.Count) violation(s):"
$violations | ForEach-Object { Write-Host $_ }
exit 1
