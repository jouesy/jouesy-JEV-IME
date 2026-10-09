# JEV V0.1 實作與後續介面

```text
Windows 應用程式
  ↓ TSF 鍵盤事件／edit session
JEVTIP.dll（x64 或 x86，沿用上游 Client）
  ↔ 依 Windows Session ID 區分的 JEV named pipe
JEVServer.exe
  → 小麥注音 KeyHandler／ReadingGrid／繁體中文詞庫
  → InputController → 候選視窗／同一份 TSF 候選資料
  → JevRanking（預設關閉；V0.1 沒有 API provider）
JEVConfig.exe → %APPDATA%\JEV-IME\jev.ini
```

V0.1 沿用上游成熟的引擎及目錄，沒有為符合示意目錄而搬動所有既有檔案。
`src/Client`、`src/Server`、`src/Common`、`src/ConfigApp` 為實際 Windows 程式；
`src/JevEngine` 是新增的候選排序邊界。`data/jev-product.json` 是產品名稱、
版本與 GUID 的來源，CMake 產生 `JevIdentity.h`，安裝腳本讀取相同 JSON。

JEV 專用 CLSID、profile、display attribute、語言列按鈕、IPC 名稱、視窗類別、
exe 名稱及使用者資料夾均與原版分開。Windows 要求的 `GUID_LBI_INPUTMODE`
仍保留系統指定值。引擎類別與 `McBopomofo` 命名空間保留，方便追蹤上游修正。

## 排序契約

`CandidateRanker.h` 定義候選 ID、讀音、文字、generation、組字上下文及機率。
`RankCandidates` 只回傳原始候選的索引排列；沒有生成或替換文字的 API。
完整候選的 `reading`、`value`、`rawValue` 由 InputController 一起搬動，因此
數字選字、滑鼠、TSF UI element 與引擎送字使用相同順序。

預設 `enabled=false`、`cloudConsent=false`，且伺服器不安裝任何 provider。
即使程式取得 scores，仍必須同時滿足啟用及同意。回應必須對應完全相同的
generation、上下文與候選集合；少候選、多候選、重複或未知 ID、NaN／無限值、
超出 0–1 的機率均會保留原排序。預設最大機率門檻 0.65，前兩名差距門檻 0.10；
這是初始產品門檻，並非已對 Jev 實測校準的信心度。

`CandidateScoreProvider::lookup` 僅容許立即讀取本機快取。它不在鍵盤執行緒
呼叫網路。V0.1 的 controller hook 支援已有的有效快取；即時非同步回應、
背景預取與視窗更新時機仍是 V0.2 的工作。provider 例外會回到原本注音流程。
標點選單不會經過排序。

## V0.2 的必要實作

- 使用實際 Jev SDK／API 文件建立 adapter，驗證認證、候選機率格式及超時。
- 在設定程式新增明確的同意流程，說明傳送的資料及關閉方式。API key 使用
  Windows Credential Manager，不存入明文 ini、詞庫、記錄或原始碼。
- 背景 worker、限流、取消、短期快取及 circuit breaker；TSF DLL 與按鍵執行緒
  不等待外部服務。使用者開始移動候選或選字後凍結順序，避免候選位置突變。
- 以 generation 加候選快照比對回應；切換文件、重設、Esc、停用、失焦後丟棄
  過期結果。密碼欄位及其他敏感輸入模式禁止讀取或傳送上下文。
- 建立可控的模擬 API 測試，再以使用者提供的憑證執行端到端測試。

V0.1 不會擷取 Word／LINE 內已輸入的文字，也不會自動傳送組字至外部服務。
沿用的線上字典功能僅在使用者主動選擇查字時開啟外部網頁。

## 語音與修正的下一階段

V0.4 才加入 whisper.cpp、音訊裝置管理、模型下載與按鍵錄音；使用者看到繁體
文字草稿並確認後，透過 TSF edit session 送到仍有焦點的文字欄位。焦點切換後
不可送到另一個程式。台灣用語、標點及繁簡轉換必須獨立測試，不能假設 Whisper
一定直接輸出繁體中文。V0.1 不附模型、不使用麥克風、沒有語音示範按鈕。

智慧文字修正須顯示建議並由使用者確認；Jev 只處理既定選项的判斷，生成式
修正使用獨立的規則或其他模型。這些模組目前是開發規格，尚未實作。
