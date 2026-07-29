[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$checkScript = Resolve-Path (Join-Path $PSScriptRoot '..\check_architecture_boundaries.ps1')
$pwsh = Join-Path $PSHOME 'pwsh.exe'
$fixtureRoot = Join-Path ([System.IO.Path]::GetTempPath()) "legado-architecture-boundaries-$([guid]::NewGuid())"

function Set-FixtureFile {
    param(
        [Parameter(Mandatory)]
        [string]$RelativePath,
        [Parameter(Mandatory)]
        [string]$Content
    )

    $path = Join-Path $fixtureRoot $RelativePath
    $directory = Split-Path -Parent $path
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
    Set-Content -LiteralPath $path -Value $Content -Encoding utf8NoBOM
}

function Invoke-Check {
    $output = & $pwsh -NoProfile -File $checkScript -Root $fixtureRoot 2>&1 | Out-String
    return @{ ExitCode = $LASTEXITCODE; Output = $output }
}

function Assert-Equal {
    param($Expected, $Actual, [string]$Message)
    if ($Expected -ne $Actual) {
        throw "$Message Expected: '$Expected'; actual: '$Actual'."
    }
}

function Assert-Match {
    param([string]$Pattern, [string]$Actual, [string]$Message)
    if ($Actual -notmatch $Pattern) {
        throw "$Message Pattern: '$Pattern'. Output:`n$Actual"
    }
}

try {
    Set-FixtureFile 'lib/domain/book.dart' "import 'dart:convert';`nclass Book {}"
    Set-FixtureFile 'lib/models/chapter.dart' "import '../domain/book.dart';`nclass Chapter {}"
    Set-FixtureFile 'lib/bootstrap/app_bootstrap.dart' "import '../infrastructure/frb_adapter.dart';`nfinal adapter = FrbBookAdapter();"

    $clean = Invoke-Check
    Assert-Equal 0 $clean.ExitCode 'Pure domain/models and the directory-authorized bootstrap should pass.'
    Assert-Match 'Architecture boundary check passed\.' $clean.Output 'Expected the clean fixture to pass.'

    Set-FixtureFile 'lib/domain/invalid_domain.dart' @"
import '../features/book_page.dart';
import '../widgets/book_tile.dart';
import '../providers/book_provider.dart';
import '../services/book_service.dart';
import '../infrastructure/book_adapter.dart';
import '../bridge/book_bridge.dart';
import '../database/book_database.dart';
import '../src/rust/api.dart';
final client = HttpClient();
"@
    Set-FixtureFile 'lib/models/invalid_model.dart' @"
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
"@

    $invalid = Invoke-Check
    Assert-Equal 1 $invalid.ExitCode 'Forbidden domain/models dependencies should fail.'
    Assert-Match '\[domain and model purity\] 13 violation\(s\)' $invalid.Output 'Expected grouped domain/models violations.'
    Assert-Match 'outer layer or infrastructure import' $invalid.Output 'Expected the outer-layer dependency violation.'
    Assert-Match 'Dio import or use' $invalid.Output 'Expected the Dio capability violation.'
    Assert-Match 'HttpClient use' $invalid.Output 'Expected the HttpClient capability violation.'
    Assert-Match 'SharedPreferences import or use' $invalid.Output 'Expected the SharedPreferences capability violation.'
    Assert-Match 'file_picker import or use' $invalid.Output 'Expected the file_picker capability violation.'
    Assert-Match 'path_provider import or use' $invalid.Output 'Expected the path_provider capability violation.'

    Write-Host 'Architecture boundary script tests passed.'
}
finally {
    if (Test-Path -LiteralPath $fixtureRoot) {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
    }
}
