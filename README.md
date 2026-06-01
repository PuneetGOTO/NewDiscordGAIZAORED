<h1 align="center">
  <br>
  Discord GAIZAORED Bot
  <br>
</h1>

<h4 align="center">多功能 Discord 機器人 | 音樂、管理、問答、直播通知、經濟系統 | 支援中英雙語</h4>
<h5 align="center">基於 <a href="https://github.com/Cog-Creators/Red-DiscordBot">Red-DiscordBot</a> 二次開發</h5>

<p align="center">
  <a href="https://www.python.org/downloads/">
     <img alt="Python" src="https://img.shields.io/badge/Python-3.9%2B-blue">
  </a>
  <a href="https://github.com/Rapptz/discord.py/">
     <img src="https://img.shields.io/badge/discord-py-blue.svg" alt="discord.py">
  </a>
  <a href="https://github.com/psf/black">
    <img src="https://img.shields.io/badge/code%20style-black-000000.svg" alt="Code Style: Black">
  </a>
</p>

<p align="center">
  <a href="#概述">概述</a>
  •
  <a href="#功能">功能</a>
  •
  <a href="#一鍵部署">一鍵部署</a>
  •
  <a href="#手動安裝">手動安裝</a>
  •
  <a href="#指令列表">指令列表</a>
  •
  <a href="#授權">授權</a>
</p>

---

# 概述

這是一個功能完整的 Discord 機器人，採用模組化設計，所有功能和指令皆可自由啟用/停用。
內建 **簡體中文 (zh-CN)** 與 **英文 (en-US)** 雙語支援，可隨時切換。

這是一個 **自託管機器人** – 你需要自行架設和維護自己的實例。

---

# 功能

內建 **19 個模組**，包含以下功能：

| 模組 | 功能 |
|------|------|
| 🛡️ **管理系統** | 踢出、封禁、解封、臨時封禁、軟封禁、批量封禁、語音封禁 |
| 🎵 **音樂播放** | YouTube、SoundCloud、本地文件、播放列表、隊列管理、等化器 |
| 📺 **直播通知** | Twitch、YouTube、Picarto 直播提醒 |
| 🎮 **問答遊戲** | 內建 50+ 題庫，支援自訂題庫 |
| 💰 **經濟系統** | 銀行、轉帳、老虎機、每日薪水、排行榜 |
| 🔇 **禁言系統** | 文字禁言、語音禁言、定時禁言 |
| ⚠️ **警告系統** | 可設定自動處罰階梯（警告→踢出→封禁） |
| 📝 **管理日誌** | 記錄所有管理操作 |
| 🚫 **過濾器** | 敏感詞過濾、自動刪除/處罰 |
| 🧹 **訊息清理** | 批量刪除訊息 |
| 📋 **自訂指令** | 建立自訂回應 |
| 🔗 **指令別名** | 為指令建立捷徑 |
| 🎨 **自助角色** | 用戶自行領取角色 |
| 📢 **公告系統** | 跨伺服器公告 |
| 🔒 **權限管理** | 精細指令/插件權限控制 |
| 📊 **通用工具** | 伺服器資訊、用戶資訊、擲骰、選擇、猜拳 |
| 🖼️ **圖片搜尋** | Giphy GIF 搜尋、Imgur 圖片搜尋 |
| 📥 **插件下載器** | 安裝第三方社群插件 |
| ⚙️ **核心系統** | 語言切換、前綴設置、自動免疫、黑白名單 |

---

# 一鍵部署 (Ubuntu)

```bash
git clone https://github.com/PuneetGOTO/NewDiscordGAIZAORED.git
cd NewDiscordGAIZAORED
sudo chmod +x deploy_redbot.sh
sudo ./deploy_redbot.sh
```

腳本會自動完成：
- ✅ 系統升級
- ✅ 安裝 Python 3.11 及所有依賴
- ✅ 安裝 Java (音樂功能可選)
- ✅ 配置 Discord Token、前綴、擁有者
- ✅ 設定默認語言為簡體中文
- ✅ 建立 systemd 服務 (開機自動啟動)

---

# 手動安裝

支援平台：**Windows / macOS / Linux**

### 1. 安裝 Python 3.9+

從 [python.org](https://www.python.org/downloads/) 下載安裝

### 2. 安裝依賴

```bash
cd NewDiscordGAIZAORED
pip install -e .
```

### 3. 創建實例

```bash
redbot-setup
```

按提示輸入實例名稱、數據路徑

### 4. 啟動機器人

```bash
redbot <實例名稱> --token <你的Token> --prefix !
```

啟動後在 Discord 中設定語言：

```
!set locale global zh-CN
```

---

# 語言切換

| 命令 | 說明 |
|------|------|
| `!set locale zh-CN` | 當前伺服器切換為簡體中文 |
| `!set locale en-US` | 切換為英文 |
| `!set locale global zh-CN` | 全局切換為簡體中文 |
| `!set locale default` | 恢復預設語言 |

---

# 指令列表

完整指令請參考上方功能表中的各模組說明，或在 Discord 中使用 `!help` 查看。

---

# 授權

本項目基於 [Red-DiscordBot](https://github.com/Cog-Creators/Red-DiscordBot) (Cog Creators) 二次開發，沿用 [GNU GPL v3](https://www.gnu.org/licenses/gpl-3.0.en.html) 授權。

原始項目版權所有 &copy; Cog Creators  
Red 名字來源於遊戲《Transistor》(Super Giant Games) 的主角  
Red 機器人插畫由 [Sinlaire](https://sinlaire.deviantart.com/) 創作  

本項目使用了 [discord.py](https://github.com/Rapptz/discord.py) 和 [discord.ext.menus](https://github.com/Rapptz/discord-ext-menus) (MIT License)。
