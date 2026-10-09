# Copyright (c) 2026 JEV contributors. SPDX-License-Identifier: MIT
[CmdletBinding()]
param([string]$SourceDir = '', [string]$InstallRoot = "$env:ProgramFiles\JEV-IME", [string]$LogPath = '')
if ($LogPath) { Start-Transcript -LiteralPath $LogPath -Force | Out-Null }
. (Join-Path $PSScriptRoot 'WindowsHelpers.ps1')
Assert-JevWindowsX64 -RequireAdmin
if (-not $SourceDir) {
    $repoRoot = Split-Path $PSScriptRoot -Parent
    $product = Get-Content (Join-Path $repoRoot 'data/jev-product.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $SourceDir = Join-Path $repoRoot "dist/JEV-IME-$($product.version)-win-x64"
}
$SourceDir = (Resolve-Path -LiteralPath $SourceDir).Path
$manifest = Test-JevPackage $SourceDir
$key = 'HKLM:\SOFTWARE\JEV-IME'
$runKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
$previous = Get-ItemProperty -LiteralPath $key -ErrorAction SilentlyContinue
$previousDirectory = $null
if ($previous) {
    if ($previous.PSObject.Properties['InstallationType'] -and $previous.InstallationType -eq 'MSI') {
        throw 'An MSI installation exists. Upgrade it with the JEV MSI installer.'
    }
    if ($previous.PSObject.Properties['InstallDir']) { $previousDirectory = $previous.InstallDir }
}
$oldRun = Get-ItemProperty -LiteralPath $runKey -ErrorAction SilentlyContinue
$oldRunValue = $null
if ($oldRun -and $oldRun.PSObject.Properties['JEV-IME-Server']) { $oldRunValue = $oldRun.'JEV-IME-Server' }
# A new version directory avoids overwriting DLLs still loaded by applications.
$stamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss-fff')
$target = Join-Path $InstallRoot "$($manifest.version)-$stamp"
New-Item -ItemType Directory -Path $target -Force | Out-Null
Get-ChildItem -LiteralPath $SourceDir -Force | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $target -Recurse -Force
}
$null = Test-JevPackage $target
Invoke-JevNative (Join-Path $env:SystemRoot 'System32/icacls.exe') @($target, '/grant', '*S-1-15-2-1:(OI)(CI)(RX)', '/T', '/Q')
$registrationStarted = $false
try {
    Stop-JevSessionProcesses
    $registrationStarted = $true
    Invoke-JevRegistration $target
    New-Item -Path $key -Force | Out-Null
    New-ItemProperty -Path $key -Name InstallDir -Value $target -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $key -Name Version -Value $manifest.version -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $key -Name InstallationType -Value 'Scripts' -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $runKey -Name 'JEV-IME-Server' -Value ('"' + (Join-Path $target 'JEVServer.exe') + '"') -PropertyType String -Force | Out-Null
    Start-Process -FilePath (Join-Path $target 'JEVServer.exe') -WorkingDirectory $target
} catch {
    $failure = $_
    if ($registrationStarted) {
        try {
            Invoke-JevRegistration $target -Unregister
            if ($previousDirectory -and (Test-Path -LiteralPath $previousDirectory)) {
                Invoke-JevRegistration $previousDirectory
                New-ItemProperty -Path $key -Name InstallDir -Value $previousDirectory -PropertyType String -Force | Out-Null
                if ($previous.PSObject.Properties['Version']) {
                    New-ItemProperty -Path $key -Name Version -Value $previous.Version -PropertyType String -Force | Out-Null
                }
                Start-Process -FilePath (Join-Path $previousDirectory 'JEVServer.exe') -WorkingDirectory $previousDirectory
            } else { Remove-Item -LiteralPath $key -Recurse -ErrorAction SilentlyContinue }
            if ($oldRunValue) {
                New-ItemProperty -Path $runKey -Name 'JEV-IME-Server' -Value $oldRunValue -PropertyType String -Force | Out-Null
            } else { Remove-ItemProperty -Path $runKey -Name 'JEV-IME-Server' -ErrorAction SilentlyContinue }
        } catch { Write-Warning "Could not fully restore the previous installation: $_" }
    }
    throw $failure
}
try { & (Join-Path $target 'scripts/enable_tip.ps1') } catch {
    Write-Warning "TSF is registered. Enable it for your normal Windows account with scripts/enable_tip.ps1: $_"
}
Write-Host "Installed JEV $($manifest.version) in $target"
Write-Host 'Sign out and sign in, then press Win + Space to select JEV.'
& (Join-Path $target 'scripts/verify_install.ps1')
