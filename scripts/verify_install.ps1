# Copyright (c) 2026 JEV contributors. SPDX-License-Identifier: MIT
[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'WindowsHelpers.ps1')
Assert-JevWindowsX64
$installed = Get-ItemProperty 'HKLM:\SOFTWARE\JEV-IME' -ErrorAction Stop
$directory = $installed.InstallDir
$null = Test-JevPackage $directory
$product = Get-Content -LiteralPath (Join-Path $directory 'data/jev-product.json') -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($entry in @(
    @{ View = [Microsoft.Win32.RegistryView]::Registry64; Dll = 'JEVTIP_x64.dll' },
    @{ View = [Microsoft.Win32.RegistryView]::Registry32; Dll = 'JEVTIP_x86.dll' }
)) {
    $base = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::ClassesRoot, $entry.View)
    $registration = $base.OpenSubKey("CLSID\$($product.clsid)\InProcServer32")
    try {
        if (-not $registration) { throw "Missing JEV COM registration: $($entry.View)" }
        $expected = Join-Path $directory $entry.Dll
        if ($registration.GetValue('') -ne $expected) { throw "Wrong registered JEV DLL: $($entry.View)" }
        Write-Host "[PASS] COM $($entry.View): $expected"
    } finally {
        if ($registration) { $registration.Dispose() }
        $base.Dispose()
    }
}
$sessionId = (Get-Process -Id $PID).SessionId
$server = @(Get-Process -Name JEVServer -ErrorAction SilentlyContinue | Where-Object { $_.SessionId -eq $sessionId })
if ($server.Count -eq 0) { Write-Warning 'JEVServer is not running in this session. Launch JEVServer.exe or sign in again.' }
else { Write-Host '[PASS] JEVServer is running in the current Windows session.' }
Write-Host "[PASS] Package checksums and dictionaries: $directory"
Write-Host 'Next: Win + Space, then test Notepad, Word, Chrome and LINE. These manual checks are required.'
