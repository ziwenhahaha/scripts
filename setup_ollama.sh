#!/bin/bash

# 定义颜色
BLUE='\033[0;34m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m' # 无颜色

# 总步骤数
TOTAL_STEPS=11
CURRENT_STEP=0

# 打印进度消息的函数
print_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    PERCENTAGE=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    echo -e "${BLUE}[${PERCENTAGE}%] ${BOLD}步骤 ${CURRENT_STEP}/${TOTAL_STEPS}:${NC} ${GREEN}$1${NC}"
}

# 获取当前用户名
USERNAME=$(whoami)

# Ollama 下载文件路径
OLLAMA_TGZ="/data1/$USERNAME/tmp/ollama-linux-amd64.tgz"
OLLAMA_INSTALL_DIR="/data1/$USERNAME/ollama"

# 1. 下载 Ollama
if [ ! -f "$OLLAMA_TGZ" ]; then
    print_progress "开始下载 Ollama"
    mkdir -p /data1/$USERNAME/tmp
    wget -c --no-check-certificate -O "$OLLAMA_TGZ" "https://github.com/ollama/ollama/releases/download/v0.9.6/ollama-linux-amd64.tgz"
    print_progress "Ollama 下载完成"
else
    print_progress "Ollama 已存在，跳过下载"
fi

# 2. 解压 Ollama
print_progress "解压 Ollama"
mkdir -p "$OLLAMA_INSTALL_DIR"
tar -xzf "$OLLAMA_TGZ" -C "$OLLAMA_INSTALL_DIR"
print_progress "Ollama 解压完成"

# 3. 配置环境变量
print_progress "配置环境变量"

# 检查并删除已有的配置
for VAR in "PATH" "OLLAMA_HOST" "OLLAMA_MODELS" "OLLAMA_TMPDIR" "OLLAMA_KEEP_ALIVE"; do
    grep -q "export $VAR=" $HOME/.bashrc && sed -i "/export $VAR=/d" $HOME/.bashrc
done

# 添加新配置
echo 'export PATH="'$OLLAMA_INSTALL_DIR'/bin:$PATH"' >> $HOME/.bashrc
echo 'export OLLAMA_HOST=0.0.0.0:11111' >> $HOME/.bashrc
echo 'export OLLAMA_MODELS="'$OLLAMA_INSTALL_DIR'/models"' >> $HOME/.bashrc
echo 'export OLLAMA_TMPDIR="/data1/tmp"' >> $HOME/.bashrc
echo 'export OLLAMA_KEEP_ALIVE=15m' >> $HOME/.bashrc
source $HOME/.bashrc
print_progress "环境变量配置完成"

# 4. 启动 Ollama 服务器
print_progress "启动 Ollama 服务器"
tmux new -d -s ollama-server "ollama serve"
print_progress "Ollama 服务器启动完成"

# 5. 删除安装包文件
print_progress "删除 Ollama 安装包文件"
rm -f "$OLLAMA_TGZ"

# 6. 最终提示
print_progress "环境配置成功，现在重启终端，输入 ollama run qwen:0.5b 试试叭~要记得先重启哦"
