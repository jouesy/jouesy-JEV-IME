# Windows 11 V0.1 驗收紀錄

已在 Windows Server 2025 的 GitHub runner 完成原生編譯、九個 JEV 測試及
套件、EXE 安裝與解除安裝檢查，詳見 [驗證紀錄](verification.md)。下列 Windows 11 實機項目仍待驗收，
自動檢查通過不代表已完成應用程式打字測試。
測試時記錄 Windows build、CPU 架構、Visual Studio／SDK 版本、Office 位元、
Chrome／LINE 版本，以及建置的 source revision。

| 驗收項目 | 操作與預期 | 狀態 |
| --- | --- | --- |
| 建置 | `build.ps1 -RunTests`；x64、x86 DLL 與所有 tests 成功 | Windows runner 通過 |
| 套件 | 包含所有詞庫、4 份 OpenCC 字典及相依授權；SHA-256 全部吻合 | Windows runner 通過 |
| 註冊 | `verify_install.ps1` 檢查兩種 registry view 與 JEVServer | Windows runner 通過；Windows 11 待測 |
| 輸入法清單 | 登入後 `Win + Space` 看見 JEV；原有輸入法仍可切換 | 待測 |
| 記事本 | `su3cl3` 組字「你好」；Enter／Esc／Backspace／游標移動正常 | 待測 |
| 候選 | 數字、方向鍵、翻頁、滑鼠與 TSF 選字皆送出相同候選 | 待測 |
| Word x64 | 一般文件、表格、選取取代、標點、插入位置及撤銷 | 待測 |
| Word／應用程式 x86 | 32 位元程式可啟用 JEV、組字及送出 | 待測 |
| Chrome | 一般 input／textarea／contenteditable；焦點切換不串字 | 待測 |
| LINE | 聊天欄位組字、選字、Enter 行為與貼圖／對話切換 | 待測 |
| 密碼及唯讀欄位 | 不開啟候選、不輸出組字到錯誤欄位 | 待測 |
| 高權限程式 | 提升權限的記事本或工具中可打字 | 待測 |
| 個人詞庫 | 加詞、刪詞、排除詞；設定及詞庫重新登入後仍保留 | 待測 |
| 並存 | 同時安裝原版小麥注音；兩者候選、設定與詞庫互不影響 | 待測 |
| 多工作階段 | 兩位使用者／遠端桌面；各自的 server／pipe 不交叉組字 | 待測 |
| 高 DPI | 100%、150%、200%、多螢幕；候選貼近游標且不超出畫面 | 待測 |
| 完全斷網 | 打字、組字、設定及個人詞庫仍正常；沒有 AI 連線嘗試 | 待測 |
| 非英文路徑 | 中文帳號、含空白及中文的原始碼／安裝路徑 | 待測 |
| 腳本更新 | Word 開啟時使用新版本目錄；更新後登出登入使用新 DLL | 待測 |
| 註冊失敗復原 | 在 VM 模擬第二個 DLL 失敗，檢查舊版註冊復原及錯誤回報 | 待測 |
| EXE | 雙擊安裝、中文安裝畫面、已安裝應用程式及解除安裝 | 靜默安裝／移除在 runner 通過；Windows 11 UI 待測 |
| MSI | 安裝、升級、修復、失敗 rollback、解除安裝及重啟行為 | 待測 |
| 解除安裝 | JEV 註冊與自動啟動移除；個人詞庫及原版小麥不受影響 | runner 已驗證註冊清除與個人資料保留；Windows 11 並存待測 |

V1.0 發佈前還需處理程式簽章、安裝包簽章、長時間輸入壓力測試，以及 Windows
安全桌面／AppContainer／IPC 的完整檢查。ARM64 目前不在 V0.1 範圍。
