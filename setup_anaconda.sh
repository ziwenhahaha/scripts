#!/bin/bash

# 颜色设置
BLUE='\033[0;34m'
GREEN='\033[0;32m'
BOLD='\033[1m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # 重置颜色

# 进度变量
CURRENT_STEP=0
TOTAL_STEPS=6  # 增加步骤数，因为可能有SSL验证相关操作

# 打印进度消息的函数
print_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    PERCENTAGE=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    echo -e "${BLUE}[${PERCENTAGE}%] ${BOLD}步骤 ${CURRENT_STEP}/${TOTAL_STEPS}:${NC} ${GREEN}$1${NC}"
}

# 获取当前用户名
USERNAME=$(whoami)
INSTALL_PATH="/home/$USERNAME"

# 创建安装目录和临时目录（如果不存在）
print_progress "创建安装目录..."
mkdir -p $INSTALL_PATH

# 检查Anaconda安装文件是否已经存在
ANACONDA_INSTALLER="$INSTALL_PATH/anaconda.sh"
if [ -f "$ANACONDA_INSTALLER" ]; then
    print_progress "检测到Anaconda安装文件已存在，跳过下载步骤..."
else
    # 下载最新版本的Anaconda（Linux 64位）
    print_progress "正在尝试下载Anaconda安装程序..."
    wget https://repo.anaconda.com/archive/Anaconda3-2024.06-1-Linux-x86_64.sh -O $ANACONDA_INSTALLER
    
    # 检查下载是否成功，如果失败则提供选项使用不安全下载
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}警告：下载失败，可能是SSL证书验证问题。${NC}"
        echo -n -e "是否尝试使用不安全方式下载(--no-check-certificate)? (y/n): "
        read -r ssl_response
        
        if [[ "$ssl_response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            echo -e "${RED}警告：使用不安全连接下载可能会带来安全风险！${NC}"
            print_progress "正在使用不安全方式下载Anaconda安装程序..."
            wget --no-check-certificate https://repo.anaconda.com/archive/Anaconda3-2024.06-1-Linux-x86_64.sh -O $ANACONDA_INSTALLER
            
            if [ $? -ne 0 ]; then
                echo -e "${RED}即使使用不安全方式，下载Anaconda安装程序仍然失败，请检查网络连接。${NC}"
                rm $ANACONDA_INSTALLER
                exit 1
            fi
        else
            echo "下载Anaconda安装程序失败，脚本终止。"
            rm $ANACONDA_INSTALLER
            exit 1
        fi
    fi
fi

# 给安装脚本执行权限
print_progress "给予安装脚本执行权限..."
chmod +x $ANACONDA_INSTALLER

# 执行安装（使用-b进行批处理安装，-p指定安装路径）
print_progress "正在安装Anaconda到 $INSTALL_PATH/anaconda3 ..."
bash $ANACONDA_INSTALLER -b -p $INSTALL_PATH/anaconda3

# 验证安装是否成功
if [ $? -ne 0 ]; then
    echo -e "${RED}安装Anaconda失败。${NC}"
    exit 1
fi

# 配置环境变量
print_progress "配置环境变量..."
echo "export PATH=$INSTALL_PATH/anaconda3/bin:\$PATH" >> ~/.bashrc

# 清理临时文件
print_progress "清理临时文件..."
rm $ANACONDA_INSTALLER

# 初始化conda
print_progress "初始化conda..."
$INSTALL_PATH/anaconda3/bin/conda init bash

echo -e "\n${GREEN}${BOLD}Anaconda安装完成!${NC}\n"
echo -e "要激活Anaconda环境，您需要开始新的bash会话。"
echo -n -e "是否立即执行新的bash会话? (y/n): "
read -r response

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo -e "${GREEN}正在启动新的bash会话...${NC}"
    exec bash
else
    echo -e "\n要手动激活环境，请执行: ${BOLD}exec bash${NC}"
    echo -e "${GREEN}祝您使用愉快！${NC}"
fi
