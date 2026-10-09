# JEV 智慧注音 — Windows 11 V0.1

這是以 Win-McBopomofo 為基礎的原生 TSF 輸入法開發專案，提供獨立的 JEV
識別碼、輸入法名稱、安裝流程及使用者資料夾。目標是在 Windows 11 用
`Win + Space` 切換，並在一般應用程式中直接打字。

**[下載 Windows 11 x64 安裝檔：JEV-Setup-0.1.0-win-x64.exe](https://github.com/jouesy/jouesy-JEV-IME/releases/download/v0.1.0/JEV-Setup-0.1.0-win-x64.exe)**

[Releases 下載頁與校驗檔](https://github.com/jouesy/jouesy-JEV-IME/releases/tag/v0.1.0)
提供單一 EXE；Code 頁面提供原始碼。雙擊安裝，完成後登出再登入，再按
`Win + Space` 選擇「JEV 智慧注音」。一般使用者不用自行編譯，詳見
[EXE 安裝說明](docs/install-exe.md)。

已在 Windows runner 完成 x64／x86 原生編譯、九個 JEV 測試，以及真實 EXE
安裝／解除安裝檢查。此為尚未簽章的 V0.1 測試版；Word／Chrome／LINE 的
Windows 11 實機相容性仍待驗收，詳見 [驗證紀錄](docs/verification.md)。

已加入 JEV 候選排序介面與測試，但 V0.1 沒有連接 Jev API，沒有錄音或
Whisper，也沒有生成式文字修正。一般注音輸入使用本機詞庫；雲端功能預設關閉。

## Windows 建置及安裝

先安裝 Visual Studio 2026 C++ 桌面工作負載、x64/x86 MSVC、Windows SDK、
CMake 及 Python 3。原始碼 ZIP 已包含 OpenCC；若從此 JEV 專案的 Git 倉庫
取得原始碼，請使用 `--recurse-submodules`。

在 64 位元 Developer PowerShell 執行：

```powershell
.\build.ps1 -Configuration Release -RunTests
```

成功後，以系統管理員開啟 64 位元 PowerShell：

```powershell
.\install.ps1 -SkipBuild
```

登出再登入，按 `Win + Space` 選擇「JEV 智慧注音」。
建置腳本會產生 `dist/JEV-IME-0.1.0-win-x64.zip`。安裝 NSIS 3.11 後可打包單檔 EXE：

```powershell
.\build_exe.ps1 -SkipBuild
```

MSI 建置使用固定版本 WiX 6.0.2：

```powershell
dotnet tool install --global wix --version 6.0.2
.\build_msi.ps1 -SkipBuild
```

完整安裝、啟用、驗證及解除安裝步驟見 [Windows 操作手冊](docs/windows-quickstart.md)。

## 本次實作

- JEV 專用 COM CLSID、TSF profile、顯示屬性及語言列按鈕識別碼；與小麥注音
  使用不同 exe、候選視窗類別、通訊管道、mutex 與 AppData 路徑。
- 沿用離線注音引擎、詞庫、候選視窗及設定程式；x64 server 配合 x64/x86 TIP。
- `build.ps1` 檢查所有建置結果、必要詞庫及 OpenCC 字典；套件附 SHA-256 manifest
  與第三方授權。腳本安裝檢查兩種 TSF 註冊結果，可嘗試復原舊版。
- 候選排序只排列原候選，保留讀音及 raw value；未同意、過期、錯誤、無效或
  低信心回應均保留原排序。V0.1 不安裝 API provider。
- Windows／Linux 建置工作流程、EXE 安裝／解除安裝檢查及實機驗收表。

## Linux 核心驗證

這個 target 只驗證共用引擎，不能註冊 Windows 輸入法。

```bash
cmake -S . -B build_portable -DJEV_PORTABLE_ONLY=ON -DCMAKE_BUILD_TYPE=Release
cmake --build build_portable --parallel
ctest --test-dir build_portable --output-on-failure
```

若安裝了 PowerShell 7，CTest 也會執行套件完整性測試；可獨立執行
`pwsh -NoProfile -File tests/JevPackageTest.ps1`。

[架構與 API 邊界](docs/jev-architecture.md) ·
[Windows 驗收表](docs/windows-validation.md) ·
[本次驗證紀錄](docs/verification.md) ·
[來源與授權](NOTICE.md)

上游技術文件保留於 `docs/`，原版 README 保存於 `docs/upstream/README.md`。
其原始產品名稱、腳本或 ARM64 說明僅供上游參考；JEV 操作以本 README 及
Windows 操作手冊為準。
