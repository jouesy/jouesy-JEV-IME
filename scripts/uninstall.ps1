# Copyright (c) 2026 JEV contributors. SPDX-License-Identifier: MIT
[CmdletBinding()]
param([string]$LogPath = '')
if ($LogPath) { Start-Transcript -LiteralPath $LogPath -Force | Out-Null }
. (Join-Path $PSScriptRoot 'WindowsHelpers.ps1')
Assert-JevWindowsX64 -RequireAdmin
$key = 'HKLM:\SOFTWARE\JEV-IME'
$installed = Get-ItemProperty -LiteralPath $key -ErrorAction SilentlyContinue
if (-not $installed) { Write-Host 'JEV is not registered as installed.'; return }
if ($installed.PSObject.Properties['InstallationType'] -and $installed.InstallationType -eq 'MSI') {
    throw 'Uninstall the MSI from Windows Settings > Apps > Installed apps.'
}
$directory = $installed.InstallDir
$null = Test-JevPackage $directory
Stop-JevSessionProcesses
Invoke-JevRegistration $directory -Unregister
Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Name 'JEV-IME-Server' -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $key -Recurse
try { & (Join-Path $PSScriptRoot 'enable_tip.ps1') -Remove } catch { Write-Warning "Could not remove the current user's language-list entry: $_" }
try {
    Remove-Item -LiteralPath $directory -Recurse -Force
} catch {
    Write-Warning "JEV is unregistered. Some files are still loaded; sign out or restart before removing this directory: $directory"
}
Write-Host 'JEV has been unregistered. Your AppData/JEV-IME dictionary and preferences are preserved.'
