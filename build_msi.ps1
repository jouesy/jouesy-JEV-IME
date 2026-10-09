# Reproducible JEV x64 MSI using WiX 6.0.2.
[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')][string]$Configuration = 'Release',
    [switch]$SkipBuild,
    [switch]$RunTests
)
. (Join-Path $PSScriptRoot 'scripts/WindowsHelpers.ps1')
Assert-JevWindowsX64
$wixVersion = '6.0.2'
$product = Get-Content (Join-Path $PSScriptRoot 'data/jev-product.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $SkipBuild) { & (Join-Path $PSScriptRoot 'build.ps1') -Configuration $Configuration -RunTests:$RunTests }
$packageDir = Join-Path $PSScriptRoot "dist/JEV-IME-$($product.version)-win-x64"
$null = Test-JevPackage $packageDir
if (-not (Get-Command wix -ErrorAction SilentlyContinue)) {
    throw 'Install WiX first: dotnet tool install --global wix --version 6.0.2'
}
$actualVersion = (& wix --version).Trim()
if ($LASTEXITCODE -ne 0 -or $actualVersion -notmatch '^6\.0\.2([.+-]|$)') {
    throw "WiX 6.0.2 is required; found '$actualVersion'."
}
Invoke-JevNative wix @('extension', 'add', '-g', "WixToolset.UI.wixext/$wixVersion")
Invoke-JevNative wix @('extension', 'add', '-g', "WixToolset.Util.wixext/$wixVersion")
$generated = Join-Path $PSScriptRoot 'build_msi_generated'
New-Item -ItemType Directory -Path $generated -Force | Out-Null
$license = Get-Content (Join-Path $PSScriptRoot 'LICENSE.txt') -Raw
$escaped = $license.Replace('\', '\\').Replace('{', '\{').Replace('}', '\}')
$escaped = $escaped -replace '\r?\n', '\par '
Set-Content -LiteralPath "$generated/LICENSE.rtf" -Encoding ASCII -Value ('{\rtf1\ansi\deff0{\fonttbl{\f0 Arial;}}\f0\fs20 ' + $escaped + '}')
$msi = Join-Path $PSScriptRoot "dist/JEV-IME-$($product.version)-win-x64.msi"
Push-Location $PSScriptRoot
try {
    Invoke-JevNative wix @('build', 'installer/installer.wxs', 'installer/zh-TW.wxl',
        '-arch', 'x64', '-culture', 'zh-TW',
        '-ext', "WixToolset.UI.wixext/$wixVersion", '-ext', "WixToolset.Util.wixext/$wixVersion",
        '-d', "ProductVersion=$($product.version)", '-d', "UpgradeCode=$($product.upgradeCode)",
        '-b', "PackageDir=$packageDir", '-o', $msi)
    Write-Host "MSI: $msi"
} finally { Pop-Location }
