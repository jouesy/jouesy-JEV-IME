# Binary-package entry point. Run in 64-bit Administrator PowerShell.
[CmdletBinding()]
param([string]$InstallRoot = "$env:ProgramFiles\JEV-IME")
& (Join-Path $PSScriptRoot 'scripts/setup.ps1') -SourceDir $PSScriptRoot -InstallRoot $InstallRoot
