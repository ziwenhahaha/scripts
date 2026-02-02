#!/bin/bash

INSTALL_DIR="/opt/node-v22"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# === [新增] 强制 sudo 检测 ===
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[Error] 权限不足！请使用 sudo 运行此脚本。${NC}"
  echo -e "示例: ${YELLOW}sudo ./update_ai_agents.sh${NC}"
  exit 1
fi

echo -e "${YELLOW}=== 开始批量更新 AI Agents ===${NC}"

if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${RED}[Error] 目录不存在，请先部署。${NC}"
    exit 1
fi

update_agent() {
    PKG_NAME=$1
    CMD_NAME=$2
    
    echo -e "${GREEN}[Update] 正在更新 $CMD_NAME ($PKG_NAME)...${NC}"
    
    # 尝试更新
    "$INSTALL_DIR/bin/npm" install -g "$PKG_NAME" --force || echo -e "${RED}[!] 更新 $PKG_NAME 失败${NC}"

    # 重新确保链接存在
    if [ -f "$INSTALL_DIR/bin/$CMD_NAME" ]; then
        ln -sf "$INSTALL_DIR/bin/$CMD_NAME" "/usr/bin/$CMD_NAME"
    fi
}

# 依次更新三个工具
update_agent "@anthropic-ai/claude-code@latest" "claude"
update_agent "@google/gemini-cli@latest" "gemini"
update_agent "@openai/codex@latest" "codex"

echo -e "${GREEN}[+] 修复权限...${NC}"
chmod -R 755 "$INSTALL_DIR"

echo -e "${GREEN}=== 更新完成 ===${NC}"
