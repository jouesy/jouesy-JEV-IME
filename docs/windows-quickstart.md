# JEV 智慧注音 V0.1 — Windows 11 x64

這是原生 Windows TSF 輸入法的開發版。V0.1 使用離線注音引擎，提供組字、
候選選字、個人詞庫與設定程式。雲端 Jev、語音辨識及智慧文字修正尚未啟用。

一般使用者請從 [Releases](https://github.com/jouesy/jouesy-JEV-IME/releases) 下載
單一 EXE，依 [安裝說明](install-exe.md) 操作。下列指令供開發者從原始碼建置。
Windows 原生編譯及安裝／移除驗證由 GitHub Actions 執行；Word／Chrome／LINE
的 Windows 11 實機相容性仍需依驗收表確認。

## 從原始碼建置

保留本 JEV 專案的修改，解壓縮原始碼套件後進入 `JEV-IME` 目錄。套件已包含
固定版本的 OpenCC 原始碼，無需重新下載上游輸入法。

需要 Visual Studio 2026「使用 C++ 的桌面開發」工作負載、x64/x86 MSVC、
Windows SDK、CMake 3.20+ 及 Python 3。從 Visual Studio 的 64 位元 Developer
PowerShell 執行：

```powershell
.\build.ps1 -Configuration Release -RunTests
```

建置不需要系統管理員權限。腳本會編譯 x64 TSF、伺服器、設定工具，以及
x86 TSF DLL；任何建置、測試或資料檔缺失都會中止。

成功後產生：

```text
dist/JEV-IME-0.1.0-win-x64/
dist/JEV-IME-0.1.0-win-x64.zip
```

## 安裝與切換

原始碼工作區：以系統管理員開啟 64 位元 PowerShell，執行：

```powershell
.\install.ps1 -SkipBuild
```

已建置的 ZIP 套件：解壓縮後在套件目錄執行：

```powershell
.\Install-JEV.ps1
```

腳本會檢查套件 SHA-256、複製至 `%ProgramFiles%\JEV-IME\版本-時間`、
註冊兩種位元的 TSF DLL，並設定每位使用者登入時啟動 JEVServer。
腳本不會強制關閉 Word、LINE 或瀏覽器；舊 DLL 可能持續由應用程式載入，
更新後請登出再登入。

按 `Win + Space` 選擇「JEV 智慧注音」。若以不同的系統管理員帳號安裝，
請在實際打字的帳號、一般 64 位元 PowerShell 中執行安裝目錄內的：

```powershell
.\scripts\enable_tip.ps1
```

此指令只新增 JEV 到目前帳號的繁體中文（台灣）語言項目，保留既有語言、
輸入法與順序。若清單尚未更新，請登出再登入。

驗證檔案及兩種位元的 COM 註冊：

```powershell
.\scripts\verify_install.ps1
```

啟動設定介面：執行安裝目錄中的 `JEVConfig.exe`，或使用語言列的「設定」。
EXE 安裝亦提供開始功能表的「JEV 設定」捷徑。

## 解除安裝

腳本版請以系統管理員執行安裝套件中的 `Uninstall-JEV.ps1`，或從原始碼執行：

```powershell
.\scripts\uninstall.ps1
```

MSI 版請使用 Windows「設定 → 應用程式 → 已安裝的應用程式」。兩種方式均保留
`%APPDATA%\JEV-IME` 的個人詞庫與偏好設定。仍被應用程式載入的 DLL 要等登出或
重啟後才會釋放；腳本更新留下的舊版本目錄可在重新登入後手動清理。

## 產生 MSI

另外需要 .NET 8 SDK 與固定版本的 WiX：

```powershell
dotnet tool install --global wix --version 6.0.2
.\build_msi.ps1 -SkipBuild
```

輸出為 `dist/JEV-IME-0.1.0-win-x64.msi`。UI 與 Util 擴充亦固定使用 6.0.2。
MSI 原始碼已備妥；安裝、升級、修復及 rollback 尚未完成驗證。首次安裝／更新 MSI 後請登出
再登入，讓 JEVServer 在使用者自己的工作階段啟動。從腳本版改用 MSI 前先解除
安裝腳本版，個人資料會保留。

## 最小驗收

在記事本先輸入標準鍵盤的 `su3cl3`，應可組成「你好」，再按 Enter 送出。
按 Down 或 Space 開啟候選，測試數字選字、翻頁、Esc、Backspace，以及
Shift 中英文切換。

請依 `windows-validation.md` 的表格檢查 Word、Chrome、LINE、32 位元應用程式、
重新登入、與原版小麥注音並存及解除安裝。檔案／註冊檢查通過不代表這些驗收
已通過。
