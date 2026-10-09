# JEV 注音 V0.1 第三方來源與授權

JEV 是 Win-McBopomofo 的衍生開發版。保留原作者的授權、程式碼註記、
注音引擎命名空間及詞庫；JEV 新增內容亦採 MIT 授權。

| 來源 | 固定版本 | 授權與用途 |
| --- | --- | --- |
| [Win-McBopomofo](https://github.com/openvanilla/win-mcbopomofo) | `978b39d5b83f45868c7170873d88528fa1cdd228` | MIT；Windows TSF、引擎、設定程式與詞庫 |
| [OpenCC](https://github.com/BYVoid/OpenCC) | `a712fff4369a22c583c7dbb3425e862b7bea180e` | Apache-2.0；沿用上游的選用繁簡轉換 |
| [NSIS](https://github.com/NSIS-Dev/nsis/tree/v311) | 3.11 | zlib/libpng；EXE 安裝器執行環境；LZMA 壓縮元件採 CPL-1.0 |

上游引擎包含 Gramambular2、Mandarin、BopomofoBraille 等元件，各原始碼
檔案的作者及授權註記均保留。OpenCC 及其相依元件的授權檔保存在
`third_party/OpenCC`，Windows 套件會複製至 `licenses/OpenCC`。

NSIS 執行環境及壓縮元件使用未修改的官方版本，原始碼可從上述固定版本連結
取得。完整授權附於 `licenses/NSIS-COPYING.txt`，並隨安裝套件散布。

本版未複製新酷音、Rime 或 PIME 的程式碼。Jev SDK、Jev 模型及 whisper.cpp
目前未納入套件，也未啟用相關 API 或錄音功能。
