#!/bin/bash
# ============================================================
#  Red-DiscordBot 一鍵部署腳本 (Ubuntu 20.04/22.04/24.04)
#  [zh-CN] 中文/英文雙語機器人
#
#  用法: chmod +x deploy_redbot.sh && sudo ./deploy_redbot.sh
# ============================================================

set -euo pipefail

# ───── 顏色定義 ─────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

BOT_DIR="/opt/redbot"
LOG_FILE="/var/log/redbot_deploy.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ───── 記錄函數 ─────
log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $*" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*" | tee -a "$LOG_FILE"; }
err() { echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE"; exit 1; }
info() { echo -e "${CYAN}[INFO]${NC}  $*"; }

# ───── 初始化日誌 ─────
echo "" > "$LOG_FILE"
log "Red-DiscordBot 一鍵部署腳本啟動"

# ───── 權限檢查 ─────
if [[ $EUID -ne 0 ]]; then
    err "請使用 sudo 執行此腳本: sudo ./deploy_redbot.sh"
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                  ║${NC}"
echo -e "${GREEN}║       Red-DiscordBot 一鍵部署腳本                  ║${NC}"
echo -e "${GREEN}║       Ubuntu 20.04/22.04/24.04                    ║${NC}"
echo -e "${GREEN}║       支援 zh-CN / en-US 雙語                      ║${NC}"
echo -e "${GREEN}║                                                  ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================
#  第一步：收集所有必要資訊
# ============================================================
log ">>> 收集部署資訊 <<<"
echo ""

# ─ Discord Bot Token ─
echo -e "${CYAN}[1/6] Discord Bot Token${NC}"
echo "  從 https://discord.com/developers/applications 獲取"
echo "  (輸入時不會顯示，按 Ctrl+C 可取消)"
while true; do
    read -s -p "  Token: " DISCORD_TOKEN
    echo ""
    if [[ -z "$DISCORD_TOKEN" ]]; then
        warn "Token 不能為空"
        continue
    fi
    if [[ ${#DISCORD_TOKEN} -lt 50 ]]; then
        warn "Token 長度不足，請確認是否正確"
        continue
    fi
    break
done

# ─ Bot Owner ID ─
echo ""
echo -e "${CYAN}[2/6] Bot 擁有者 Discord ID${NC}"
echo "  啟用 Discord 開發者模式後，右鍵點擊你的頭像 > 複製 ID"
while true; do
    read -p "  Owner ID: " OWNER_ID
    if [[ -z "$OWNER_ID" ]]; then
        warn "Owner ID 不能為空"
        continue
    fi
    if ! [[ "$OWNER_ID" =~ ^[0-9]+$ ]]; then
        warn "Owner ID 必須是純數字"
        continue
    fi
    break
done

# ─ Command Prefix ─
echo ""
echo -e "${CYAN}[3/6] 指令前綴${NC}"
echo "  例如: ! 或 = 或 .  (可多個，用空格分隔)"
read -p "  Prefix [預設: !]: " CMD_PREFIX
CMD_PREFIX=${CMD_PREFIX:-!}

# ─ Instance Name ─
echo ""
echo -e "${CYAN}[4/6] 實例名稱${NC}"
echo "  用於區分多個機器人實例，只能包含英文字母/數字/底線"
read -p "  Instance Name [預設: mybot]: " INSTANCE_NAME
INSTANCE_NAME=${INSTANCE_NAME:-mybot}

# ─ 是否需要 Lavalink (音樂功能) ─
echo ""
echo -e "${CYAN}[5/6] 是否啟用音樂功能 (需安裝 Java 21)${NC}"
read -p "  安裝 Java/Lavalink? (y/n) [預設: y]: " INSTALL_AUDIO
INSTALL_AUDIO=${INSTALL_AUDIO:-y}

# ─ 是否設置為開機自啟 ─
echo ""
echo -e "${CYAN}[6/6] 是否設置 systemd 服務 (開機自動啟動)${NC}"
read -p "  創建 systemd 服務? (y/n) [預設: y]: " INSTALL_SERVICE
INSTALL_SERVICE=${INSTALL_SERVICE:-y}

# ───── 匯總確認 ─────
echo ""
echo -e "${GREEN}════════════════════════════════════${NC}"
echo -e "${GREEN}  請確認以下資訊：${NC}"
echo -e "${GREEN}════════════════════════════════════${NC}"
echo "  Token     : ${DISCORD_TOKEN:0:10}...${DISCORD_TOKEN: -10}"
echo "  Owner ID  : $OWNER_ID"
echo "  Prefix    : $CMD_PREFIX"
echo "  Instance  : $INSTANCE_NAME"
echo "  音樂功能  : $INSTALL_AUDIO"
echo "  systemd  : $INSTALL_SERVICE"
echo -e "${GREEN}════════════════════════════════════${NC}"
read -p "確認無誤？繼續安裝？(y/n): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    log "使用者取消安裝"
    exit 0
fi

# ============================================================
#  第二步：系統升級 & 安裝依賴
# ============================================================
log ">>> 開始系統升級與依賴安裝 <<<"

# ─ 更新 apt ─
log "更新 apt 套件列表..."
apt-get update -y >> "$LOG_FILE" 2>&1

log "升級系統套件 (這可能需要幾分鐘)..."
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y >> "$LOG_FILE" 2>&1

# ─ 安裝基礎工具 ─
log "安裝基礎工具 (git, curl, wget, build-essential)..."
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    git curl wget build-essential software-properties-common \
    ca-certificates gnupg lsb-release >> "$LOG_FILE" 2>&1

# ─ 安裝 Python 3.11 ─
log "安裝 Python 3.11..."
PYTHON_VERSION=""

# 檢測並安裝 Python
if command -v python3.11 &> /dev/null; then
    PYTHON_VERSION="3.11"
    log "Python 3.11 已安裝"
elif command -v python3.10 &> /dev/null; then
    PYTHON_VERSION="3.10"
    log "Python 3.10 已安裝"
elif command -v python3.9 &> /dev/null; then
    PYTHON_VERSION="3.9"
    log "Python 3.9 已安裝"
else
    log "安裝 Python 3.11..."
    # 根據 Ubuntu 版本選擇安裝方式
    UBUNTU_CODENAME=$(lsb_release -cs)
    case "$UBUNTU_CODENAME" in
        noble|oracular)  # 24.04+
            DEBIAN_FRONTEND=noninteractive apt-get install -y python3.11 python3.11-venv python3.11-dev >> "$LOG_FILE" 2>&1
            PYTHON_VERSION="3.11"
            ;;
        jammy)  # 22.04
            DEBIAN_FRONTEND=noninteractive apt-get install -y python3.11 python3.11-venv python3.11-dev >> "$LOG_FILE" 2>&1
            PYTHON_VERSION="3.11"
            ;;
        focal)  # 20.04
            add-apt-repository -y ppa:deadsnakes/ppa >> "$LOG_FILE" 2>&1
            apt-get update -y >> "$LOG_FILE" 2>&1
            DEBIAN_FRONTEND=noninteractive apt-get install -y python3.11 python3.11-venv python3.11-dev >> "$LOG_FILE" 2>&1
            PYTHON_VERSION="3.11"
            ;;
        *)
            warn "未知的 Ubuntu 版本: $UBUNTU_CODENAME，嘗試通用安裝..."
            add-apt-repository -y ppa:deadsnakes/ppa >> "$LOG_FILE" 2>&1 || true
            apt-get update -y >> "$LOG_FILE" 2>&1
            DEBIAN_FRONTEND=noninteractive apt-get install -y python3.11 python3.11-venv python3.11-dev >> "$LOG_FILE" 2>&1
            PYTHON_VERSION="3.11"
            ;;
    esac
fi

# ─ 確保 pip 可用 ─
log "安裝 pip..."
if ! command -v pip3 &> /dev/null; then
    DEBIAN_FRONTEND=noninteractive apt-get install -y python3-pip >> "$LOG_FILE" 2>&1
fi

# 升級 pip
python3 -m pip install --upgrade pip >> "$LOG_FILE" 2>&1

# ─ 安裝 Java (Lavalink 音頻需要) ─
if [[ "$INSTALL_AUDIO" =~ ^[Yy]$ ]]; then
    log "安裝 Java 21 (用於 Lavalink 音樂系統)..."
    if ! command -v java &> /dev/null; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y openjdk-21-jre-headless >> "$LOG_FILE" 2>&1 || \
        DEBIAN_FRONTEND=noninteractive apt-get install -y openjdk-17-jre-headless >> "$LOG_FILE" 2>&1 || \
        DEBIAN_FRONTEND=noninteractive apt-get install -y default-jre-headless >> "$LOG_FILE" 2>&1
    fi
    java -version 2>&1 | head -1 | tee -a "$LOG_FILE"
fi

log "系統依賴安裝完成"

# ============================================================
#  第三步：部屬機器人文件
# ============================================================
log ">>> 部署機器人檔案 <<<"

# ─ 創建 bot 目錄 ─
mkdir -p "$BOT_DIR"

# ─ 查找 redbot 源碼 ─
# 優先級: 腳本所在目錄 > /tmp/redbot > 從 GitHub 克隆
SOURCE_DIR=""
if [[ -d "$SCRIPT_DIR/redbot" ]] && [[ -f "$SCRIPT_DIR/pyproject.toml" ]]; then
    SOURCE_DIR="$SCRIPT_DIR"
    log "在腳本目錄中找到 Red 源碼: $SOURCE_DIR"
elif [[ -d "/tmp/redbot_src" ]]; then
    SOURCE_DIR="/tmp/redbot_src"
    log "使用預先複製的源碼: $SOURCE_DIR"
fi

if [[ -n "$SOURCE_DIR" ]]; then
    log "複製 Red-DiscordBot 文件到 $BOT_DIR..."
    rsync -a --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' \
        --exclude='.pytest_cache' --exclude='.mypy_cache' \
        "$SOURCE_DIR/" "$BOT_DIR/" >> "$LOG_FILE" 2>&1
else
    log "從 GitHub 克隆 Red-DiscordBot..."
    git clone --depth 1 https://github.com/Cog-Creators/Red-DiscordBot.git "$BOT_DIR" >> "$LOG_FILE" 2>&1
    # 注意: 從 GitHub 克隆的版本可能還沒翻譯。你需要先將翻譯好的 zh-CN.po 文件覆蓋進去
    warn "從 GitHub 克隆的版本可能缺少中文翻譯"
    warn "請確保已將翻譯好的 zh-CN.po 文件放入對應目錄"
fi

# 設置權限
chown -R root:root "$BOT_DIR"

# ============================================================
#  第四步：安裝 Python 依賴
# ============================================================
log ">>> 安裝 Python 依賴 <<<"

cd "$BOT_DIR"

# 安裝 Red-DiscordBot
log "安裝 Red-DiscordBot 及其依賴 (這可能需要幾分鐘)..."
python3 -m pip install -e . >> "$LOG_FILE" 2>&1 || {
    warn "使用 -e 安裝失敗，嘗試安裝 requirements..."
    python3 -m pip install -r requirements/base.txt >> "$LOG_FILE" 2>&1
    python3 -m pip install -e . --no-deps >> "$LOG_FILE" 2>&1
}

log "Python 依賴安裝完成"

# ============================================================
#  第五步：初始化機器人實例
# ============================================================
log ">>> 初始化機器人實例 <<<"

DATA_PATH="/var/lib/redbot/$INSTANCE_NAME"
mkdir -p "$DATA_PATH"

# 運行 redbot-setup
log "建立實例: $INSTANCE_NAME"
redbot-setup --no-prompt \
    --instance-name "$INSTANCE_NAME" \
    --data-path "$DATA_PATH" \
    --backend json >> "$LOG_FILE" 2>&1 || {
    # 如果已存在，覆蓋
    redbot-setup --no-prompt \
        --instance-name "$INSTANCE_NAME" \
        --data-path "$DATA_PATH" \
        --backend json \
        --overwrite-existing-instance >> "$LOG_FILE" 2>&1
}

log "實例創建完成"

# ============================================================
#  第六步：配置機器人 (token, prefix, owner)
# ============================================================
log ">>> 配置機器人參數 <<<"

# 使用 --no-prompt 和 --token --prefix --owner 來跳過交互式配置
# 第一次啟動時這些參數會自動保存到 config

log "寫入初始配置..."
# 使用 --edit 模式保存 token、owner 到 config (永久儲存)
redbot "$INSTANCE_NAME" \
    --edit \
    --no-prompt \
    --owner "$OWNER_ID" \
    --token "$DISCORD_TOKEN" \
    --prefix "$CMD_PREFIX" >> "$LOG_FILE" 2>&1

log "機器人配置完成"

# ============================================================
#  第七步：設置語言為簡體中文
# ============================================================
log ">>> 設置語言為簡體中文 (zh-CN) <<<"

# 需要先啟動機器人才能設置語言
# 這裡我們寫入 config 來設置 locale
CONFIG_FILE="$DATA_PATH/core/settings.json"

# 確保目錄存在
mkdir -p "$(dirname "$CONFIG_FILE")"

# 如果 settings.json 不存在，創建並設置 locale
if [[ ! -f "$CONFIG_FILE" ]]; then
    cat > "$CONFIG_FILE" << 'CONFEOF'
{
    "GLOBAL": {
        "locale": "zh-CN"
    },
    "GUILD": {},
    "MEMBER": {},
    "ROLE": {},
    "USER": {},
    "CHANNEL": {},
    "PREFIX": {},
    "COMMAND": {},
    "IGNORED": {}
}
CONFEOF
else
    # 如果已存在，用 python 修改
    python3 -c "
import json, sys
try:
    with open('$CONFIG_FILE', 'r') as f:
        data = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    data = {}
if 'GLOBAL' not in data:
    data['GLOBAL'] = {}
data['GLOBAL']['locale'] = 'zh-CN'
with open('$CONFIG_FILE', 'w') as f:
    json.dump(data, f, indent=4)
print('locale 已設為 zh-CN')
" >> "$LOG_FILE" 2>&1
fi

log "語言已設置為簡體中文 (zh-CN)"

# ============================================================
#  第八步：創建 systemd 服務
# ============================================================
if [[ "$INSTALL_SERVICE" =~ ^[Yy]$ ]]; then
    log ">>> 創建 systemd 服務 <<<"

    SERVICE_NAME="redbot-$INSTANCE_NAME"

    cat > "/etc/systemd/system/$SERVICE_NAME.service" << SERVICEEOF
[Unit]
Description=Discord GAIZAORED Bot - $INSTANCE_NAME
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=$BOT_DIR
ExecStart=$(which redbot) $INSTANCE_NAME --no-prompt
Restart=on-failure
RestartSec=15
StandardOutput=journal
StandardError=journal
SyslogIdentifier=$SERVICE_NAME

NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ReadWritePaths=$DATA_PATH /var/log
ProtectHome=yes
ReadOnlyPaths=$BOT_DIR

[Install]
WantedBy=multi-user.target
SERVICEEOF

    # 重載 systemd 並啟用服務
    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"

    log "systemd 服務已創建: systemctl start $SERVICE_NAME"

    # 啟動機器人
    read -p "是否立即啟動機器人? (y/n) [預設: y]: " START_NOW
    START_NOW=${START_NOW:-y}
    if [[ "$START_NOW" =~ ^[Yy]$ ]]; then
        systemctl start "$SERVICE_NAME"
        sleep 3
        systemctl status "$SERVICE_NAME" --no-pager || true
    fi
else
    log "跳過 systemd 服務創建 (手動啟動: redbot $INSTANCE_NAME --token '<token>' --prefix '$CMD_PREFIX')"
fi

# ============================================================
#  完成
# ============================================================
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                  ║${NC}"
echo -e "${GREEN}║        部署完成! 🎉                               ║${NC}"
echo -e "${GREEN}║                                                  ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}  實例名稱   :${NC} $INSTANCE_NAME"
echo -e "${CYAN}  資料目錄   :${NC} $DATA_PATH"
echo -e "${CYAN}  機器人目錄 :${NC} $BOT_DIR"
echo -e "${CYAN}  指令前綴   :${NC} $CMD_PREFIX"
echo -e "${CYAN}  默認語言   :${NC} zh-CN (簡體中文)"
echo ""
if [[ "$INSTALL_SERVICE" =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}  服務名稱   :${NC} $SERVICE_NAME"
    echo ""
    echo -e "${YELLOW}  常用指令:${NC}"
    echo "    systemctl start $SERVICE_NAME    # 啟動"
    echo "    systemctl stop $SERVICE_NAME     # 停止"
    echo "    systemctl restart $SERVICE_NAME  # 重啟"
    echo "    systemctl status $SERVICE_NAME   # 狀態"
    echo "    journalctl -u $SERVICE_NAME -f   # 查看日誌"
fi
echo ""
echo ""
echo -e "${YELLOW}  首次啟動後，在 Discord 中執行以下指令以啟用斜槓指令 (/):${NC}"
echo "    ${CMD_PREFIX}slash sync              (同步全部 / 指令到 Discord)"
echo ""
echo -e "${YELLOW}  Discord 中切換語言:${NC}"
echo "    ${CMD_PREFIX}set locale zh-CN       (當前伺服器改為中文)"
echo "    ${CMD_PREFIX}set locale en-US       (切回英文)"
echo "    ${CMD_PREFIX}set locale global zh-CN (全局改為中文)"
echo ""
echo -e "${GREEN}  日誌文件: $LOG_FILE${NC}"

# 清理敏感資訊 (token 從日誌中移除 - 但保留在 systemd env 中)
sed -i "s/$DISCORD_TOKEN/***TOKEN***/g" "$LOG_FILE" 2>/dev/null || true
