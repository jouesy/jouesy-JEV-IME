# JEV Windows 腳本

- `../build.ps1`：編譯 x64 程式及 x86 TSF、驗證詞庫、建立 ZIP 和檔案 manifest。
- `../install.ps1`：建置後安裝；`-SkipBuild` 使用既有套件。
- `setup.ps1`：驗證套件並安裝至新的版本目錄，檢查 regsvr32 exit code。
- `enable_tip.ps1`：在目前使用者語言清單新增 JEV；`-Remove` 只移除 JEV。
- `verify_install.ps1`：檢查套件、兩個 COM registry view 及本工作階段 server。
- `uninstall.ps1`：解除腳本版註冊及自動啟動，保留 AppData 個人資料。
- `../build_msi.ps1`：使用 WiX 6.0.2 打包 MSI；MSI 由 Windows 已安裝應用程式解除。

建置不需要管理員權限；安裝及解除安裝需要管理員權限。腳本不強制關閉
一般應用程式，更新後登出再登入。詳細步驟見 `docs/windows-quickstart.md`。
