# Enable or remove only the JEV profile in the current user's language list.
[CmdletBinding()]
param([switch]$Remove)
. (Join-Path $PSScriptRoot 'WindowsHelpers.ps1')
Assert-JevWindowsX64
$repoRoot = Split-Path $PSScriptRoot -Parent
$product = Get-Content -LiteralPath (Join-Path $repoRoot 'data/jev-product.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$tip = '0404:' + $product.clsid + $product.profileGuid
$list = Get-WinUserLanguageList
if ($Remove) {
    $changed = $false
    foreach ($language in $list) {
        if ($language.InputMethodTips.Contains($tip)) {
            $null = $language.InputMethodTips.Remove($tip)
            $changed = $true
        }
    }
    if ($changed) { Set-WinUserLanguageList -LanguageList $list -Force }
} else {
    $taiwan = $list | Where-Object { $_.LanguageTag -match '^zh(-Hant)?-TW$' } | Select-Object -First 1
    if (-not $taiwan) {
        $new = New-WinUserLanguageList 'zh-Hant-TW'
        $taiwan = $new[0]
        $list.Add($taiwan)
    }
    if (-not $taiwan.InputMethodTips.Contains($tip)) {
        $taiwan.InputMethodTips.Add($tip)
        Set-WinUserLanguageList -LanguageList $list -Force
    }
    Write-Host 'JEV enabled for the current Windows account. Sign out and sign in if Win + Space has not refreshed.'
}
