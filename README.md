# 健身菜單 & 動作庫

一個給自己用的健身小工具:**收錄動作**(建立個人動作庫)+ **安排訓練菜單**(依訓練日排課表),解決「到健身房不知道練什麼、看到好動作不知道往哪放」的問題。

單一 HTML 檔、無 build。資料與圖片存在 **Supabase**(雲端),手機、電腦登入同一個帳號就會同步。

## 功能
- **動作庫**(預設首頁):依肌群(胸 / 背 / 肩 / 手臂 / 腿 / 臀 / 核心 / 全身)分組收合;爆發跳躍、腳踝穩定、重心轉移等特色做成**標籤**貼在動作上
  - 每個動作可存:器材、來源與來源連結(IG / YouTube)、教練提示、示範圖片
  - 右下角 ＋ 只要填名稱就能存,看到好動作可以先丟進來、之後再補
- **菜單**:依訓練日安排,從動作庫挑動作(可依部位 + 標籤篩選),填組數 × 次數
- **框架**:依身體區域的動作框架(退階 → 原始 → 進階)
- **匯出 / 匯入**:備份成 JSON(圖片會內嵌);匯入會取代雲端現有資料

## 架構
```
瀏覽器 ── 下載 index.html ──> Cloudflare(託管網頁,push main 自動部署)
   └──── 登入 / 讀寫資料 / 圖片 ──> Supabase(Postgres + Auth + Storage)
```
- 登入:Email + 密碼(Supabase Auth),只有一個帳號,已關閉公開註冊。
- 權限:資料表開啟 RLS,只有登入者本人能讀寫自己的資料;圖片放私有 bucket,依 user_id 分資料夾。
- 離線:會顯示上次載入的資料(唯讀),無法儲存。

## 建置 Supabase
資料表與權限定義在 [`supabase/schema.sql`](supabase/schema.sql),貼到 Supabase 的 SQL Editor 執行即可(可重複執行)。
`index.html` 內的 `SUPA_URL` / `SUPA_KEY` 是公開的 Project URL 與 publishable key,不是機密;**千萬不要放 service_role / secret key**。

## 首次登入
雲端是空的時候,會先把這個瀏覽器裡舊版(localStorage)的資料搬上去;沒有舊資料就放入預設動作庫。

## 部署
Cloudflare Workers 靜態資產,設定在 [`wrangler.jsonc`](wrangler.jsonc)。Deploy command 用 `npx wrangler deploy`。

## 文件
產品需求與路線圖:[`docs/PRD.md`](docs/PRD.md)
