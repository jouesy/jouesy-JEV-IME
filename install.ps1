# Build and install the native JEV V0.1 development version.
[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')][string]$BuildType = 'Release',
    [switch]$SkipBuild,
    [switch]$RunTests,
    [string]$InstallRoot = "$env:ProgramFiles\JEV-IME"
)
. (Join-Path $PSScriptRoot 'scripts/WindowsHelpers.ps1')
Assert-JevWindowsX64 -RequireAdmin
if (-not $SkipBuild) { & (Join-Path $PSScriptRoot 'build.ps1') -Configuration $BuildType -RunTests:$RunTests }
& (Join-Path $PSScriptRoot 'scripts/setup.ps1') -InstallRoot $InstallRoot
