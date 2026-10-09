# 安裝 JEV 智慧注音

適用於 Windows 11 x64；ARM64 尚未支援。

1. [直接下載 JEV-Setup-0.1.0-win-x64.exe](https://github.com/jouesy/jouesy-JEV-IME/releases/download/v0.1.0/JEV-Setup-0.1.0-win-x64.exe)，
   或到 [Releases](https://github.com/jouesy/jouesy-JEV-IME/releases/tag/v0.1.0) 的 Assets 點選該檔案。
2. 雙擊 EXE，允許 Windows 的系統管理員權限提示，再按安裝。
3. 安裝完成後登出 Windows，再登入。
4. 按 `Win + Space`，選擇「JEV 智慧注音」。

不用安裝 Visual Studio、Python、CMake 或 WiX，也不用自行輸入 PowerShell
指令。安裝檔已包含 x64／x86 輸入法元件、注音引擎、設定程式與詞庫。

開始功能表的「JEV 智慧注音」資料夾提供設定與啟用捷徑。如果使用另一個
管理員帳號完成安裝，回到平常使用的帳號後，點「啟用 JEV 注音」，再重新登入。

要解除安裝，開啟 Windows「設定 → 應用程式 → 已安裝的應用程式」，找到
JEV 智慧注音。解除安裝會保留 `%APPDATA%\JEV-IME` 中的個人詞庫與設定。

V0.1 提供離線注音輸入與選字；尚未加入 Jev API、語音輸入或智慧文字修正。
這是尚未簽章的測試版本，Windows 11 的 Word／Chrome／LINE 相容性驗收狀態見
[Windows 驗收表](https://github.com/jouesy/jouesy-JEV-IME/blob/main/docs/windows-validation.md)。

## 開發者打包

Windows 建置電腦需安裝 NSIS 3.11。完成 `build.ps1` 後執行：

```powershell
.\build_exe.ps1 -SkipBuild
```

輸出為 `dist/JEV-Setup-0.1.0-win-x64.exe` 及 SHA-256 校驗檔。安裝器先解開
內嵌套件，驗證 manifest 中的檔案雜湊，然後執行套件中的註冊流程。原生編譯、
安裝及解除安裝檢查由 GitHub Actions 執行；應用程式相容性仍需在 Windows 11
實機驗收。
