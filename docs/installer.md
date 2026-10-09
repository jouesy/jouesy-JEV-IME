# JEV Windows 安裝器

一般使用者使用 `JEV-Setup-0.1.0-win-x64.exe`，操作見 [EXE 安裝說明](install-exe.md)。
EXE 使用 NSIS 3.11，內嵌完整套件，安裝時不需要下載開發工具或詞庫。

## 安裝行為

- 要求系統管理員權限，檢查原生 x64 架構及 Windows build 22000 以上。
- 驗證套件 manifest 中的 SHA-256，保留第三方授權。
- 複製至 `%ProgramFiles%\JEV-IME\版本-時間`，避免覆寫仍被應用程式載入的 DLL。
- 用各自位元的 `regsvr32` 註冊 x64／x86 TIP；註冊失敗會嘗試復原原先版本。
- 設定每位使用者登入時啟動 JEVServer，為安裝帳號啟用繁體中文 JEV profile。
- 在開始功能表加入設定、目前帳號啟用與解除安裝捷徑，並加入 Windows 已安裝應用程式清單。

安裝後重新登入，再用 `Win + Space` 切換。使用不同管理員帳號安裝時，在日常
使用的帳號點選開始功能表的「啟用 JEV 注音」。

解除安裝移除 JEV 自身的註冊、啟動設定與程式，保留 `%APPDATA%\JEV-IME` 的
個人資料。仍載入 DLL 的應用程式可能讓部分檔案延後至重新登入後才能清除。

安裝和移除診斷記錄位於執行帳號的 `%TEMP%\JEV-Setup.log` 與
`%TEMP%\JEV-Uninstall.log`。記錄安裝步驟及錯誤，不記錄打字內容。

## 建置與交付

```powershell
.\build.ps1 -Configuration Release -RunTests
.\build_exe.ps1 -SkipBuild
```

`build_exe.ps1` 固定使用 NSIS 3.11，指定 UTF-8 原始碼，以免繁體中文畫面受
建置電腦的系統編碼影響。輸出 EXE 與 `.sha256` 檔。

GitHub `build.yml` 執行原生編譯與 JEV 的九個 CTest target。
`package.yml` 可重用已測試的二進位檔；它先核對原生程式碼未變，再重新計算
套件 manifest、打包、執行真實 EXE 安裝與解除安裝檢查，通過後才發佈預覽版。

安裝驗證檢查檔案雜湊、兩種 COM registry view、背景程式、啟用 profile、
已安裝應用程式清單，以及解除安裝後保留個人資料。這不代替 Windows 11 中
Word／Chrome／LINE 等應用程式的實機驗收。

## 選用 MSI

`build_msi.ps1` 及 WiX 6.0.2 原始碼仍保留供開發使用。EXE 是本版主要交付形式；
MSI 的升級、修復及 rollback 測試尚未完成。兩種安裝方式使用同一 JEV identity，
切換方式前應先解除安裝原版本，避免兩個安裝器同時管理註冊。
