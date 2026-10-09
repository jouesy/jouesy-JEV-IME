# 本次開發驗證 — 2026-10-09

Windows 原生建置在 GitHub Actions 的 `windows-2025-vs2026` runner 執行：
Windows Server 2025、build 26100、Visual Studio 18 2026、MSVC 19.51.36260.0、
Windows SDK 10.0.26100.0。此紀錄區分自動驗證與 Windows 11 實機驗收。
上游來源及固定 commit 見 `NOTICE.md`。

| 已執行檢查 | 結果 |
| --- | --- |
| x64 TSF DLL、背景引擎、設定程式原生 Release 編譯 | 通過 |
| x86 TSF DLL 原生 Release 編譯 | 通過 |
| 九個 JEV CTest target | 全部通過 |
| 詞庫、四份 OpenCC 字典、相依授權及套件 SHA-256 | 通過 |
| NSIS 3.11 單檔 EXE 建置 | 通過 |
| 真實 EXE 安裝與解除安裝 | 通過 |

九個 Windows target 為 `JevRankingTest`、`JevPackageTest`、
`CandidateWindowTest`、`BugReproTest`、`IpcTest`、`ConfigControlStateTest`、
`PipeTest`、`InputMacroTest`、`JevOfflineEngineTest`。

原生二進位檔來自
[建置紀錄 37969277805](https://github.com/jouesy/jouesy-JEV-IME/actions/runs/37969277805)，
source revision `a289149c6d7d2ee6d7a2fa61b417dd772e86e2a9`。
該次建置的原生編譯、九個測試及二進位 ZIP 上傳步驟成功；後續舊版安裝器步驟失敗。
安裝器修正後的交付流程重用這份已測試的 ZIP，先以 Git diff 核對原生程式碼未變，
再更新安裝輔助腳本、重新計算 manifest 並重新驗證 EXE。

[交付紀錄 37972397632](https://github.com/jouesy/jouesy-JEV-IME/actions/runs/37972397632)
全部成功，installer revision `37aea7d8e86e7d15fd0c98e023f4551b7b1da7a7`。
實際啟動 EXE 並驗證 x64／x86 COM 註冊、所有檔案與字典 SHA-256、
JEVServer 啟動、目前帳號的輸入法啟用及 Windows 已安裝應用程式項目。
解除安裝後確認兩種 COM 註冊及安裝資訊均移除，個人資料的測試檔案未被修改。

安裝檔已發佈至 [V0.1.0 Release](https://github.com/jouesy/jouesy-JEV-IME/releases/tag/v0.1.0)。
已從公開下載連結重新下載 EXE，確認 Windows PE 格式、2,891,688 bytes，並核對
發佈的 SHA-256 校驗檔：

```text
08c9d3f65f12ebba46c2dfefb7487c70673b8135a00128c578a0b5e7cfaf818c
```

Linux 也完成 GCC 14.2.0、CMake 4.4.4、Ninja 1.13.2、PowerShell 7.5.4 的
Release 建置。三個 CTest target 均通過，共 55 個明確檢查：排序 23 項、
真實離線引擎 24 項、套件完整性 8 項。

```bash
cmake -S . -B build_portable -G Ninja \
  -DJEV_PORTABLE_ONLY=ON -DCMAKE_BUILD_TYPE=Release \
  -DJEV_POWERSHELL=/workspace/scratch/pwsh/pwsh
cmake --build build_portable -j 4
ctest --test-dir build_portable --output-on-failure
```

最後一個 PowerShell 路徑為測試環境的工具位置；其他電腦可省略此設定，
CMake 會尋找 `pwsh` 或 `powershell`。

Windows 11 的 `Win + Space` 畫面、Word／Chrome／LINE 打字、高 DPI、多帳號、
更新與長時間輸入仍待實機驗收，詳見 [Windows 驗收表](windows-validation.md)。
Windows Server 的自動檢查不代表已完成這些測試。

Jev API／Whisper／生成式文字修正目前未實作。WiX MSI 的安裝、升級、修復及
rollback 亦未完成驗證；本版交付以單一 EXE 為主。
