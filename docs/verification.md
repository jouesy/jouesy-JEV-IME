# 本次開發驗證 — 2026-10-09

執行環境：Linux x86_64、GCC 14.2.0、CMake 4.4.4、Ninja 1.13.2、
PowerShell 7.5.4。上游來源及固定 commit 見 `NOTICE.md`。

| 已執行檢查 | 結果 |
| --- | --- |
| Release 模式編譯共用注音核心及排序程式 | 通過 |
| `JevRankingTest`，23 項排序／同意／無效回應／過期回應檢查 | 通過 |
| `JevOfflineEngineTest`，24 項真實詞庫、注音鍵位、組字、選字與個人詞庫檢查 | 通過 |
| `JevPackageTest.ps1`，8 項套件完整性、路徑、版本及 native exit code 檢查 | 通過 |
| PowerShell 原始碼語法解析 | 通過 |
| WiX XML 解析、GUID 與版本資料產生、Git whitespace 檢查 | 通過 |

CTest 的三個測試 target 均通過，共 55 個明確檢查。

```bash
cmake -S . -B build_portable -G Ninja \
  -DJEV_PORTABLE_ONLY=ON -DCMAKE_BUILD_TYPE=Release \
  -DJEV_POWERSHELL=/workspace/scratch/pwsh/pwsh
cmake --build build_portable -j 4
ctest --test-dir build_portable --output-on-failure
```

最後一個 PowerShell 路徑是本次測試環境的工具位置；其他電腦可省略此設定，
CMake 會尋找 `pwsh` 或 `powershell`。原始碼套件不包含該工具或 Linux 編譯產物。

Windows TSF、候選 UI、IPC、控制項及新增 controller 整合測試已列入
Windows CMake／GitHub Actions，但本次沒有 Windows runner，未執行。
GitHub Actions 只是提交的工作流程定義，沒有聲稱遠端工作已成功。

WiX 6.0.2 CLI 也明確表示只支援 Windows；Linux 上嘗試編譯安裝器會遭遇其
Windows 路徑處理限制，不能用來驗證 MSI。XML 解析通過只代表檔案結構可讀。
本次没有已建置或已驗證的 Windows EXE、DLL、MSI；沒有嘗試在 Linux 註冊 TSF。

請依 `windows-validation.md` 完成 Windows 建置、註冊、應用程式相容性、
更新與解除安裝驗收。Jev API／Whisper／生成式文字修正目前未實作，也未實測。
