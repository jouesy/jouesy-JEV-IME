# Copyright (c) 2026 JEV contributors. SPDX-License-Identifier: MIT
[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')][string]$Configuration = 'Release',
    [switch]$RunTests
)
. (Join-Path $PSScriptRoot 'scripts/WindowsHelpers.ps1')
Assert-JevWindowsX64
$product = Get-Content (Join-Path $PSScriptRoot 'data/jev-product.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$testFlag = if ($RunTests) { 'ON' } else { 'OFF' }
$x64 = Join-Path $PSScriptRoot 'build_x64'
$x86 = Join-Path $PSScriptRoot 'build_x86'
Push-Location $PSScriptRoot
try {
    Invoke-JevNative cmake @('-S', '.', '-B', $x64, '-A', 'x64', "-DJEV_BUILD_TESTS=$testFlag", '-DSKIP_OPENCC_DICT=OFF')
    Invoke-JevNative cmake @('--build', $x64, '--config', $Configuration, '--target', 'third_party/OpenCC/data/Dictionaries')
    if ($RunTests) {
        Invoke-JevNative cmake @('--build', $x64, '--config', $Configuration, '--parallel')
        Invoke-JevNative ctest @('--test-dir', $x64, '-C', $Configuration, '--output-on-failure')
    } else {
        Invoke-JevNative cmake @('--build', $x64, '--config', $Configuration, '--parallel', '--target', 'JEVTIP', 'JEVServer', 'JEVConfig')
    }
    Invoke-JevNative cmake @('-S', '.', '-B', $x86, '-A', 'Win32', '-DJEV_BUILD_TESTS=OFF', '-DSKIP_OPENCC_DICT=ON')
    Invoke-JevNative cmake @('--build', $x86, '--config', $Configuration, '--parallel', '--target', 'JEVTIP')

    $packageName = "JEV-IME-$($product.version)-win-x64"
    $stage = Join-Path $PSScriptRoot "dist/$packageName"
    if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
    New-Item -ItemType Directory -Path "$stage/data/opencc", "$stage/scripts", "$stage/licenses" -Force | Out-Null
    foreach ($file in @('JEVServer.exe', 'JEVConfig.exe')) {
        Copy-Item -LiteralPath "$x64/bin/$Configuration/$file" -Destination $stage
    }
    Copy-Item -LiteralPath "$x64/bin/$Configuration/JEVTIP.dll" -Destination "$stage/JEVTIP_x64.dll"
    Copy-Item -LiteralPath "$x86/bin/$Configuration/JEVTIP.dll" -Destination "$stage/JEVTIP_x86.dll"
    foreach ($file in @('data.txt', 'data-plain-bpmf.txt', 'associated-phrases-v2.txt',
            'dictionary_service.json', 'bpmfvs-variants.txt', 'bpmfvs-pua.txt', 'jev-product.json')) {
        Copy-Item -LiteralPath "data/$file" -Destination "$stage/data"
    }
    Copy-Item -LiteralPath 'third_party/OpenCC/data/config/tw2s.json' -Destination "$stage/data/opencc"
    foreach ($file in @('TSPhrases.ocd2', 'TSCharacters.ocd2', 'TWVariantsRev.ocd2', 'TWVariantsRevPhrases.ocd2')) {
        Copy-Item -LiteralPath "$x64/third_party/OpenCC/data/$file" -Destination "$stage/data/opencc"
    }
    foreach ($file in @('WindowsHelpers.ps1', 'setup.ps1', 'uninstall.ps1', 'verify_install.ps1', 'enable_tip.ps1')) {
        Copy-Item -LiteralPath "scripts/$file" -Destination "$stage/scripts"
    }
    Copy-Item -LiteralPath 'installer/Install-JEV.ps1' -Destination $stage
    Copy-Item -LiteralPath 'installer/Uninstall-JEV.ps1' -Destination $stage
    Copy-Item -LiteralPath 'docs/install-exe.md' -Destination "$stage/README.md"
    Copy-Item -LiteralPath 'docs/windows-validation.md' -Destination $stage
    Copy-Item -LiteralPath 'LICENSE.txt', 'NOTICE.md' -Destination $stage
    Copy-Item -LiteralPath 'licenses/NSIS-COPYING.txt' -Destination "$stage/licenses"
    # Retain all OpenCC and bundled dependency license notices in binary packages.
    $openccRoot = (Resolve-Path 'third_party/OpenCC').Path
    Get-ChildItem -LiteralPath $openccRoot -Recurse -File |
        Where-Object { $_.Name -match '^(LICENSE|COPYING|NOTICE)(\..*)?$' } |
        ForEach-Object {
            $relative = $_.FullName.Substring($openccRoot.Length + 1)
            $destination = Join-Path "$stage/licenses/OpenCC" $relative
            New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
            Copy-Item -LiteralPath $_.FullName -Destination $destination
        }
    $revision = 'source-archive'
    if (Test-Path '.git') {
        $revision = (& git rev-parse HEAD).Trim()
        if ($LASTEXITCODE -ne 0) { throw 'Unable to read source revision.' }
    }
    $entries = @(Get-ChildItem -LiteralPath $stage -Recurse -File | Sort-Object FullName | ForEach-Object {
        @{ path = $_.FullName.Substring($stage.Length + 1).Replace('\', '/');
           sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
    })
    @{ product = 'JEV-IME'; version = $product.version; architecture = 'windows-x64';
       configuration = $Configuration; clsid = $product.clsid; sourceRevision = $revision;
       files = $entries } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath "$stage/manifest.json" -Encoding UTF8
    $null = Test-JevPackage $stage
    $zip = Join-Path $PSScriptRoot "dist/$packageName.zip"
    Compress-Archive -LiteralPath @((Get-ChildItem -LiteralPath $stage).FullName) -DestinationPath $zip -Force
    Write-Host "Built and verified: $stage"
    Write-Host "ZIP: $zip"
} finally {
    Pop-Location
}
