# Package integrity checks use temporary fixtures, not an installed IME.
$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts/WindowsHelpers.ps1')
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('jev-package-test-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path "$fixture/data/opencc" -Force | Out-Null
$checks = 0
function Expect-Rejected {
    param([scriptblock]$Action, [string]$Name)
    $rejected = $false
    try { & $Action | Out-Null } catch { $rejected = $true }
    if (-not $rejected) { throw "Not rejected: $Name" }
    $script:checks++
}
function Write-FixtureManifest {
    $script:manifest = @{
        product = 'JEV-IME'; version = '0.1.0'; architecture = 'windows-x64';
        clsid = '{F8D73A29-7959-4CE0-9336-516A86A59A1B}';
        files = @(Get-ChildItem $fixture -Recurse -File | Where-Object { $_.Name -ne 'manifest.json' } | ForEach-Object {
            @{ path = $_.FullName.Substring($fixture.Length + 1).Replace('\', '/');
               sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
        })
    }
    Save-FixtureManifest
}
function Save-FixtureManifest {
    $script:manifest | ConvertTo-Json -Depth 6 | Set-Content "$fixture/manifest.json" -Encoding UTF8
}
try {
    foreach ($file in @('JEVServer.exe', 'JEVConfig.exe', 'JEVTIP_x64.dll', 'JEVTIP_x86.dll',
            'data/data.txt', 'data/data-plain-bpmf.txt', 'data/associated-phrases-v2.txt',
            'data/dictionary_service.json', 'data/bpmfvs-variants.txt', 'data/bpmfvs-pua.txt',
            'data/opencc/tw2s.json', 'data/opencc/TSPhrases.ocd2', 'data/opencc/TSCharacters.ocd2',
            'data/opencc/TWVariantsRev.ocd2', 'data/opencc/TWVariantsRevPhrases.ocd2')) {
        Set-Content -LiteralPath (Join-Path $fixture $file) -Value 'test fixture'
    }
    Copy-Item -LiteralPath (Join-Path (Split-Path $PSScriptRoot -Parent) 'data/jev-product.json') -Destination "$fixture/data"
    Write-FixtureManifest
    $null = Test-JevPackage $fixture
    $checks++
    Add-Content "$fixture/JEVTIP_x64.dll" 'corruption'
    Expect-Rejected { Test-JevPackage $fixture } 'corrupted DLL'
    Write-FixtureManifest
    $manifest.files = @($manifest.files | Where-Object { $_.path -ne 'JEVTIP_x86.dll' })
    Save-FixtureManifest
    Expect-Rejected { Test-JevPackage $fixture } 'required file omitted from manifest'
    Write-FixtureManifest
    $manifest.files += $manifest.files[0]
    Save-FixtureManifest
    Expect-Rejected { Test-JevPackage $fixture } 'duplicate manifest path'
    Write-FixtureManifest
    $manifest.files += @{ path = '../outside.dll'; sha256 = '0' }
    Save-FixtureManifest
    Expect-Rejected { Test-JevPackage $fixture } 'path traversal'
    Write-FixtureManifest
    $manifest.version = '9.9.9'
    Save-FixtureManifest
    Expect-Rejected { Test-JevPackage $fixture } 'different product version'
    $hostCommand = Join-Path $PSHOME $(if ($env:OS -eq 'Windows_NT') { 'pwsh.exe' } else { 'pwsh' })
    if (-not (Test-Path $hostCommand)) { $hostCommand = Join-Path $PSHOME 'powershell.exe' }
    Invoke-JevNative $hostCommand @('-NoProfile', '-Command', 'exit 0')
    $checks++
    Expect-Rejected { Invoke-JevNative $hostCommand @('-NoProfile', '-Command', 'exit 7') } 'failed native command'
    Write-Host "Passed $checks package and command checks."
} finally { Remove-Item -LiteralPath $fixture -Recurse -Force }
