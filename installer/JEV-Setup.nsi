; Copyright (c) 2026 JEV contributors. SPDX-License-Identifier: MIT
Unicode true
!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "x64.nsh"

!ifndef PACKAGE_DIR
  !error "PACKAGE_DIR must contain a verified JEV Windows binary package"
!endif
!ifndef PRODUCT_VERSION
  !error "PRODUCT_VERSION is required"
!endif
!ifndef OUTPUT_FILE
  !error "OUTPUT_FILE is required"
!endif
!ifdef BUILD_WINDOWS
  !define PACKAGE_FILES "${PACKAGE_DIR}\*"
!else
  !define PACKAGE_FILES "${PACKAGE_DIR}/*"
!endif

Name "JEV 智慧注音 ${PRODUCT_VERSION}"
OutFile "${OUTPUT_FILE}"
InstallDir "$PROGRAMFILES64\JEV-IME"
RequestExecutionLevel admin
SetCompressor /SOLID lzma
SetCompressorDictSize 32
VIProductVersion "${PRODUCT_VERSION}.0"
VIAddVersionKey /LANG=1028 "ProductName" "JEV 智慧注音"
VIAddVersionKey /LANG=1028 "FileDescription" "JEV 智慧注音安裝程式"
VIAddVersionKey /LANG=1028 "FileVersion" "${PRODUCT_VERSION}"
VIAddVersionKey /LANG=1028 "ProductVersion" "${PRODUCT_VERSION}"
VIAddVersionKey /LANG=1028 "LegalCopyright" "Copyright 2026 JEV contributors; MIT License"

!define MUI_ABORTWARNING
!define MUI_WELCOMEPAGE_TITLE "安裝 JEV 智慧注音"
!define MUI_WELCOMEPAGE_TEXT "將 JEV 注音輸入法安裝至 Windows 11。$\r$\n$\r$\n安裝完成並重新登入後，即可使用 Win + Space 切換。$\r$\n$\r$\n此版本提供離線注音輸入與選字。"
!define MUI_FINISHPAGE_TITLE "JEV 智慧注音安裝完成"
!define MUI_FINISHPAGE_TEXT "請登出 Windows 再登入，然後按 Win + Space 選取「JEV 智慧注音」。$\r$\n$\r$\n開始功能表中可以開啟設定，也可以為目前帳號啟用 JEV。"
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "${PACKAGE_DIR}/LICENSE.txt"
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "TradChinese"

Var PackagePath
Var InstalledVersionDir
Var PowershellPath
Var ProcessResult
Var ProcessOutput

Function .onInit
  ${IfNot} ${IsNativeAMD64}
    MessageBox MB_OK|MB_ICONSTOP "此版本需要 Windows 11 x64；目前尚不支援 ARM64。" /SD IDOK
    SetErrorLevel 1
    Quit
  ${EndIf}
  SetRegView 64
  ReadRegStr $0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentBuildNumber"
  ${If} $0 < 22000
    MessageBox MB_OK|MB_ICONSTOP "此版本需要 Windows 11（組建 22000 或更新）。" /SD IDOK
    SetErrorLevel 1
    Quit
  ${EndIf}
  ReadRegStr $0 HKLM "SOFTWARE\JEV-IME" "InstallationType"
  ${If} $0 == "MSI"
    MessageBox MB_OK|MB_ICONSTOP "請先從 Windows 設定解除安裝現有的 JEV MSI 版本，再執行此安裝程式。" /SD IDOK
    SetErrorLevel 1
    Quit
  ${EndIf}
  ; NSIS is a 32-bit process. Sysnative launches the 64-bit PowerShell host.
  StrCpy $PowershellPath "$WINDIR\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
  InitPluginsDir
FunctionEnd

Section "JEV 智慧注音" SecMain
  SetShellVarContext all
  SetRegView 64
  StrCpy $PackagePath "$PLUGINSDIR\JEV-package"
  SetOutPath "$PackagePath"
  File /r "${PACKAGE_FILES}"
  DetailPrint "正在安裝及註冊 JEV 輸入法…"
  nsExec::ExecToStack /TIMEOUT=180000 '"$PowershellPath" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$PackagePath\scripts\setup.ps1" -SourceDir "$PackagePath" -InstallRoot "$INSTDIR"'
  Pop $ProcessResult
  Pop $ProcessOutput
  DetailPrint "$ProcessOutput"
  ${If} $ProcessResult != 0
    MessageBox MB_OK|MB_ICONSTOP "JEV 安裝失敗（代碼：$ProcessResult）。$\r$\n$\r$\n$ProcessOutput" /SD IDOK
    SetErrorLevel 1
    Abort
  ${EndIf}
  ReadRegStr $InstalledVersionDir HKLM "SOFTWARE\JEV-IME" "InstallDir"
  ${If} $InstalledVersionDir == ""
    MessageBox MB_OK|MB_ICONSTOP "無法確認 JEV 安裝目錄，安裝未完成。" /SD IDOK
    SetErrorLevel 1
    Abort
  ${EndIf}
  WriteRegStr HKLM "SOFTWARE\JEV-IME" "InstallationType" "EXE"
  SetOutPath "$INSTDIR"
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\JEV-IME" "DisplayName" "JEV 智慧注音"
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\JEV-IME" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\JEV-IME" "Publisher" "JEV"
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\JEV-IME" "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\JEV-IME" "DisplayIcon" "$InstalledVersionDir\JEVConfig.exe"
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\JEV-IME" "UninstallString" '$\"$INSTDIR\Uninstall.exe$\"'
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\JEV-IME" "QuietUninstallString" '$\"$INSTDIR\Uninstall.exe$\" /S'
  WriteRegDWORD HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\JEV-IME" "NoModify" 1
  WriteRegDWORD HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\JEV-IME" "NoRepair" 1
  CreateDirectory "$SMPROGRAMS\JEV 智慧注音"
  SetOutPath "$InstalledVersionDir"
  CreateShortcut "$SMPROGRAMS\JEV 智慧注音\JEV 設定.lnk" "$InstalledVersionDir\JEVConfig.exe"
  CreateShortcut "$SMPROGRAMS\JEV 智慧注音\啟用 JEV 注音.lnk" "$WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe" '-NoLogo -NoProfile -ExecutionPolicy Bypass -File "$InstalledVersionDir\scripts\enable_tip.ps1"' "$InstalledVersionDir\JEVConfig.exe"
  CreateShortcut "$SMPROGRAMS\JEV 智慧注音\解除安裝 JEV.lnk" "$INSTDIR\Uninstall.exe"
  SetErrorLevel 0
SectionEnd

Function un.onInit
  SetRegView 64
  SetShellVarContext all
  StrCpy $PowershellPath "$WINDIR\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
  ReadRegStr $InstalledVersionDir HKLM "SOFTWARE\JEV-IME" "InstallDir"
  ReadRegStr $0 HKLM "SOFTWARE\JEV-IME" "InstallationType"
  ${If} $0 != "EXE"
    MessageBox MB_OK|MB_ICONSTOP "目前的 JEV 版本不是由此安裝程式管理。請從 Windows 設定解除安裝。" /SD IDOK
    SetErrorLevel 1
    Abort
  ${EndIf}
  ${If} $InstalledVersionDir == ""
    MessageBox MB_OK|MB_ICONSTOP "找不到 JEV 安裝資訊。" /SD IDOK
    SetErrorLevel 1
    Abort
  ${EndIf}
FunctionEnd

Section "Uninstall"
  DetailPrint "正在解除註冊 JEV 輸入法…"
  nsExec::ExecToStack /TIMEOUT=180000 '"$PowershellPath" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$InstalledVersionDir\scripts\uninstall.ps1"'
  Pop $ProcessResult
  Pop $ProcessOutput
  DetailPrint "$ProcessOutput"
  ${If} $ProcessResult != 0
    MessageBox MB_OK|MB_ICONSTOP "JEV 解除安裝失敗（代碼：$ProcessResult）。$\r$\n$\r$\n$ProcessOutput" /SD IDOK
    SetErrorLevel 1
    Abort
  ${EndIf}
  DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\JEV-IME"
  Delete "$SMPROGRAMS\JEV 智慧注音\JEV 設定.lnk"
  Delete "$SMPROGRAMS\JEV 智慧注音\啟用 JEV 注音.lnk"
  Delete "$SMPROGRAMS\JEV 智慧注音\解除安裝 JEV.lnk"
  RMDir "$SMPROGRAMS\JEV 智慧注音"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir "$INSTDIR"
  SetErrorLevel 0
SectionEnd
