#!/bin/bash

# === 变量配置 ===
NODE_VER="v22.9.0"
# Ubuntu 18.04 专用兼容版 (Glibc 2.17)
DOWNLOAD_URL="https://unofficial-builds.nodejs.org/download/release/${NODE_VER}/node-${NODE_VER}-linux-x64-glibc-217.tar.gz"
INSTALL_DIR="/opt/node-v22"
TEMP_DIR="/tmp/node_install"

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# === [新增] 强制 sudo 检测 ===
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[Error] 权限不足！请使用 sudo 运行此脚本。${NC}"
  echo -e "示例: ${YELLOW}sudo ./deploy_ai_agents.sh${NC}"
  exit 1
fi

echo -e "${YELLOW}=== 开始部署 AI Agent 全家桶 (Claude + Gemini + Codex) ===${NC}"

# --- 第一阶段：Node环境 ---
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}[!] 清理旧环境...${NC}"
    rm -rf "$INSTALL_DIR"
fi

echo -e "${GREEN}[+] 下载 Node.js 兼容版...${NC}"
mkdir -p $TEMP_DIR
wget -q --show-progress -O "$TEMP_DIR/node.tar.gz" "$DOWNLOAD_URL"

echo -e "${GREEN}[+] 解压安装...${NC}"
tar -xf "$TEMP_DIR/node.tar.gz" -C /opt/
mv $(ls -d /opt/node-*-linux-x64-glibc-217) "$INSTALL_DIR"

# 链接核心引擎
rm -f /usr/bin/node /usr/bin/npm /usr/bin/npx
ln -s "$INSTALL_DIR/bin/node" /usr/bin/node
ln -s "$INSTALL_DIR/bin/npm" /usr/bin/npm
ln -s "$INSTALL_DIR/bin/npx" /usr/bin/npx

# --- 第二阶段：安装 Agents ---

# 定义一个安装并链接的函数
install_agent() {
    PKG_NAME=$1  # npm 包名
    CMD_NAME=$2  # 期望的命令名 (如 claude)
    
    echo -e "${GREEN}[+] 正在安装 $PKG_NAME ...${NC}"
    
    # 尝试安装，如果失败不退出脚本 (|| true)
    "$INSTALL_DIR/bin/npm" install -g "$PKG_NAME" --force || echo -e "${RED}[!] 安装 $PKG_NAME 失败 (可能包不存在)${NC}"

    # 检查二进制文件是否存在
    TARGET_BIN="$INSTALL_DIR/bin/$CMD_NAME"
    
    if [ -f "$TARGET_BIN" ]; then
        echo -e "${GREEN}    -> 检测到 $CMD_NAME，正在创建链接...${NC}"
        rm -f "/usr/bin/$CMD_NAME"
        ln -s "$TARGET_BIN" "/usr/bin/$CMD_NAME"
        echo -e "${GREEN}    -> $CMD_NAME 安装成功！${NC}"
    else
        echo -e "${RED}    -> 跳过 $CMD_NAME (未找到可执行文件)${NC}"
    fi
}

# 1. 安装 Claude Code (已知稳定)
install_agent "@anthropic-ai/claude-code@latest" "claude"

# 2. 安装 Gemini CLI (用户指定)
install_agent "@google/gemini-cli@latest" "gemini"

# 3. 安装 OpenAI Codex (容错处理)
install_agent "@openai/codex@latest" "codex"

# --- 第三阶段：收尾 ---
echo -e "${GREEN}[+] 修复全员权限...${NC}"
chmod -R 755 "$INSTALL_DIR"
rm -rf $TEMP_DIR

echo -e "${GREEN}=== 部署结束 ===${NC}"
echo -e "请运行: ${YELLOW}hash -r${NC}"
