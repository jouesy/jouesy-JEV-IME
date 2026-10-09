# Build the single-file JEV installer. Requires NSIS 3.11 on the build machine.
[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')][string]$Configuration = 'Release',
    [switch]$SkipBuild,
    [switch]$RunTests,
    [string]$MakeNsis = ''
)
. (Join-Path $PSScriptRoot 'scripts/WindowsHelpers.ps1')
Assert-JevWindowsX64
if (-not $SkipBuild) { & (Join-Path $PSScriptRoot 'build.ps1') -Configuration $Configuration -RunTests:$RunTests }
$product = Get-Content (Join-Path $PSScriptRoot 'data/jev-product.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$packageDir = Join-Path $PSScriptRoot "dist/JEV-IME-$($product.version)-win-x64"
$null = Test-JevPackage $packageDir
if (-not $MakeNsis) {
    $command = Get-Command makensis -ErrorAction SilentlyContinue
    if ($command) { $MakeNsis = $command.Source }
    else { $MakeNsis = Join-Path ${env:ProgramFiles(x86)} 'NSIS/makensis.exe' }
}
if (-not (Test-Path -LiteralPath $MakeNsis)) { throw 'Install NSIS 3.11 or supply -MakeNsis with the path to makensis.exe.' }
$version = (& $MakeNsis /VERSION).Trim()
if ($LASTEXITCODE -ne 0 -or $version -notmatch '^v?3\.11([.-]|$)') { throw "NSIS 3.11 is required; found '$version'." }
$output = Join-Path $PSScriptRoot "dist/JEV-Setup-$($product.version)-win-x64.exe"
Invoke-JevNative $MakeNsis @('/V3', '/INPUTCHARSET', 'UTF8', "/DPACKAGE_DIR=$packageDir",
    "/DPRODUCT_VERSION=$($product.version)", "/DOUTPUT_FILE=$output",
    (Join-Path $PSScriptRoot 'installer/JEV-Setup.nsi'))
$hash = (Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content -LiteralPath "$output.sha256" -Encoding ASCII -Value "$hash  $([IO.Path]::GetFileName($output))"
Write-Host "EXE: $output"
Write-Host "SHA256: $hash"
