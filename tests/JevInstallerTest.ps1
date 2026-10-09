# End-to-end installer check for a disposable Windows build runner.
# Installs and removes JEV; do not run on a machine with an existing JEV install.
[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$InstallerPath)
. (Join-Path $PSScriptRoot '../scripts/WindowsHelpers.ps1')
Assert-JevWindowsX64 -RequireAdmin
if (Test-Path 'HKLM:\SOFTWARE\JEV-IME') { throw 'This test requires a clean Windows runner without JEV.' }
$product = Get-Content (Join-Path $PSScriptRoot '../data/jev-product.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$userDirectory = Join-Path $env:APPDATA 'JEV-IME'
$sentinel = Join-Path $userDirectory ('installer-test-' + [Guid]::NewGuid().ToString('N') + '.txt')
New-Item -ItemType Directory -Path $userDirectory -Force | Out-Null
Set-Content -LiteralPath $sentinel -Value 'Personal data must survive uninstall.' -Encoding UTF8
$sentinelHash = (Get-FileHash -LiteralPath $sentinel -Algorithm SHA256).Hash
$uninstaller = $null
try {
    # Start-Process -Wait waits for the entire descendant tree on Windows.
    # JEVServer intentionally stays running after setup, so wait only for the
    # installer process and enforce a deadline for genuine installer hangs.
    $process = Start-Process -FilePath (Resolve-Path -LiteralPath $InstallerPath).Path -ArgumentList '/S' -PassThru
    if (-not $process.WaitForExit(240000)) {
        $log = Join-Path $env:TEMP 'JEV-Setup.log'
        if (Test-Path -LiteralPath $log) { Get-Content -LiteralPath $log | Write-Host }
        throw 'Installer did not finish within four minutes.'
    }
    if ($process.ExitCode -ne 0) {
        $log = Join-Path $env:TEMP 'JEV-Setup.log'
        if (Test-Path -LiteralPath $log) { Get-Content -LiteralPath $log | Write-Host }
        throw "Installer returned $($process.ExitCode)."
    }
    $installed = Get-ItemProperty 'HKLM:\SOFTWARE\JEV-IME' -ErrorAction Stop
    if ($installed.InstallationType -ne 'EXE') { throw 'Installer did not record EXE ownership.' }
    if ($installed.Version -ne $product.version) { throw 'Incorrect installed version.' }
    & (Join-Path $installed.InstallDir 'scripts/verify_install.ps1')
    $session = (Get-Process -Id $PID).SessionId
    $server = @(Get-Process -Name JEVServer -ErrorAction SilentlyContinue | Where-Object { $_.SessionId -eq $session })
    if ($server.Count -eq 0) { throw 'Installed JEVServer did not start.' }
    $run = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run').'JEV-IME-Server'
    if ($run -ne ('"' + (Join-Path $installed.InstallDir 'JEVServer.exe') + '"')) { throw 'Incorrect sign-in startup path.' }
    $tip = '0404:' + $product.clsid + $product.profileGuid
    $enabled = @(Get-WinUserLanguageList | Where-Object { $_.InputMethodTips.Contains($tip) })
    if ($enabled.Count -eq 0) { throw 'JEV was not enabled for the installing account.' }
    $arp = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\JEV-IME'
    if ($arp.DisplayVersion -ne $product.version) { throw 'JEV is missing from installed apps.' }
    $uninstaller = Join-Path (Split-Path $installed.InstallDir -Parent) 'Uninstall.exe'
    if (-not (Test-Path -LiteralPath $uninstaller)) { throw 'Missing uninstaller.' }
    Write-Host '[PASS] EXE installs both TSF clients, dictionaries, server, current-user profile and installed-apps entry.'
} finally {
    if (-not $uninstaller -and (Test-Path 'HKLM:\SOFTWARE\JEV-IME')) {
        $directory = (Get-ItemProperty 'HKLM:\SOFTWARE\JEV-IME').InstallDir
        $uninstaller = Join-Path (Split-Path $directory -Parent) 'Uninstall.exe'
    }
    if ($uninstaller -and (Test-Path -LiteralPath $uninstaller)) {
        $process = Start-Process -FilePath $uninstaller -ArgumentList '/S' -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            $log = Join-Path $env:TEMP 'JEV-Uninstall.log'
            if (Test-Path -LiteralPath $log) { Get-Content -LiteralPath $log | Write-Host }
            throw "Uninstaller returned $($process.ExitCode)."
        }
    }
}
if (Test-Path 'HKLM:\SOFTWARE\JEV-IME') { throw 'Install metadata remains after uninstall.' }
if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\JEV-IME') { throw 'Installed-apps entry remains after uninstall.' }
foreach ($view in @([Microsoft.Win32.RegistryView]::Registry64, [Microsoft.Win32.RegistryView]::Registry32)) {
    $base = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::ClassesRoot, $view)
    $registration = $base.OpenSubKey("CLSID\$($product.clsid)\InProcServer32")
    try {
        if ($registration) { throw "COM registration remains after uninstall: $view." }
    } finally {
        if ($registration) { $registration.Dispose() }
        $base.Dispose()
    }
}
if ((Get-FileHash -LiteralPath $sentinel -Algorithm SHA256).Hash -ne $sentinelHash) { throw 'Uninstall modified personal data.' }
Remove-Item -LiteralPath $sentinel
Write-Host '[PASS] EXE uninstalls both TSF clients and installed-apps entry while preserving personal data.'
Write-Host 'This runner check does not replace Windows 11 application compatibility testing.'
