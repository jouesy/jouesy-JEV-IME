# Copyright (c) 2026 JEV contributors. SPDX-License-Identifier: MIT
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

# A Windows PowerShell child of PowerShell 7 can inherit only Core module paths.
# Prefer the child host's own built-in modules without changing user settings.
if ($env:OS -eq 'Windows_NT' -and $PSVersionTable.PSEdition -eq 'Desktop') {
    $jevModuleRoot = Join-Path $PSHOME 'Modules'
    $env:PSModulePath = $jevModuleRoot + ';' + $env:PSModulePath
}

function Get-JevFileSha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    $stream = [IO.File]::OpenRead($Path)
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        return [BitConverter]::ToString($algorithm.ComputeHash($stream)).Replace('-', '').ToLowerInvariant()
    } finally {
        $algorithm.Dispose()
        $stream.Dispose()
    }
}

function Assert-JevWindowsX64 {
    param([switch]$RequireAdmin)
    if ($env:OS -ne 'Windows_NT') { throw 'JEV TSF requires Windows 11 x64.' }
    $arch = $env:PROCESSOR_ARCHITECTURE
    if ($env:PROCESSOR_ARCHITEW6432) { $arch = $env:PROCESSOR_ARCHITEW6432 }
    if ($arch -ne 'AMD64') { throw 'V0.1 supports x64 Windows only. ARM64 is not supported yet.' }
    if (-not [Environment]::Is64BitProcess) { throw 'Use 64-bit PowerShell.' }
    $build = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuildNumber
    if ([int]$build -lt 22000) { throw 'Windows 11 (build 22000 or newer) is required.' }
    if ($RequireAdmin) {
        $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            throw 'Open a 64-bit PowerShell window as Administrator and run this script again.'
        }
    }
}

function Invoke-JevNative {
    param([Parameter(Mandatory = $true)][string]$FilePath, [string[]]$Arguments = @())
    & $FilePath @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$FilePath failed (exit $LASTEXITCODE)." }
}

function Invoke-JevRegistration {
    param([Parameter(Mandatory = $true)][string]$Directory, [switch]$Unregister)
    $entries = @(
        @{ Tool = 'System32\regsvr32.exe'; Dll = 'JEVTIP_x64.dll' },
        @{ Tool = 'SysWOW64\regsvr32.exe'; Dll = 'JEVTIP_x86.dll' }
    )
    foreach ($entry in $entries) {
        $dll = Join-Path $Directory $entry.Dll
        if (-not (Test-Path -LiteralPath $dll -PathType Leaf)) { throw "Missing DLL: $dll" }
        $arguments = '/s "' + $dll + '"'
        if ($Unregister) { $arguments = '/u ' + $arguments }
        $process = Start-Process -FilePath (Join-Path $env:SystemRoot $entry.Tool) `
            -ArgumentList $arguments -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            throw "TSF registration failed for $($entry.Dll) (exit $($process.ExitCode))."
        }
    }
}

function Stop-JevSessionProcesses {
    $sessionId = (Get-Process -Id $PID).SessionId
    Get-Process -Name JEVServer, JEVConfig -ErrorAction SilentlyContinue |
        Where-Object { $_.SessionId -eq $sessionId } |
        Stop-Process -Force -ErrorAction Stop
}

function Test-JevPackage {
    param([Parameter(Mandatory = $true)][string]$Directory)
    $manifestPath = Join-Path $Directory 'manifest.json'
    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($manifest.product -ne 'JEV-IME' -or $manifest.architecture -ne 'windows-x64') {
        throw 'This is not a JEV Windows x64 package.'
    }
    $required = @('JEVServer.exe', 'JEVConfig.exe', 'JEVTIP_x64.dll', 'JEVTIP_x86.dll',
        'data/data.txt', 'data/data-plain-bpmf.txt', 'data/associated-phrases-v2.txt',
        'data/dictionary_service.json', 'data/bpmfvs-variants.txt', 'data/bpmfvs-pua.txt',
        'data/jev-product.json', 'data/opencc/tw2s.json', 'data/opencc/TSPhrases.ocd2',
        'data/opencc/TSCharacters.ocd2', 'data/opencc/TWVariantsRev.ocd2',
        'data/opencc/TWVariantsRevPhrases.ocd2')
    $packageRoot = [IO.Path]::GetFullPath($Directory).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    $seen = @{}
    foreach ($entry in $manifest.files) {
        $fullPath = [IO.Path]::GetFullPath((Join-Path $Directory $entry.path))
        if (-not $fullPath.StartsWith($packageRoot, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Manifest path escapes package: $($entry.path)"
        }
        if ($seen.ContainsKey($entry.path)) { throw "Duplicate manifest file: $($entry.path)" }
        $seen[$entry.path] = $true
        if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) { throw "Missing package file: $($entry.path)" }
        if ((Get-JevFileSha256 $fullPath) -ne $entry.sha256) {
            throw "Package checksum mismatch: $($entry.path)"
        }
    }
    foreach ($file in $required) {
        if (-not $seen.ContainsKey($file)) { throw "Manifest does not contain required file: $file" }
    }
    $product = Get-Content -LiteralPath (Join-Path $Directory 'data/jev-product.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($product.version -ne $manifest.version -or $product.clsid -ne $manifest.clsid) {
        throw 'Package product identity does not match manifest.'
    }
    return $manifest
}
