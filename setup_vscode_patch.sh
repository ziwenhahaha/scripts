#!/bin/bash

# 定义颜色
BLUE='\033[0;34m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m' # 无颜色

# 总步骤数
TOTAL_STEPS=12
CURRENT_STEP=0

# 打印进度消息的函数
print_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    PERCENTAGE=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    echo -e "${BLUE}[${PERCENTAGE}%] ${BOLD}步骤 ${CURRENT_STEP}/${TOTAL_STEPS}:${NC} ${GREEN}$1${NC}"
}

# 检查当前用户是否为root用户
if [ "$EUID" -eq 0 ]; then
    echo "请勿以超级用户身份运行此脚本。"
    exit 1
fi

# 获取patchelf的路径
PATCHELF_PATH=$(which patchelf)

# 检查patchelf路径是否存在
if [ ! -x "$PATCHELF_PATH" ]; then
    echo "错误: 未安装patchelf或路径无效，请先安装。"
    exit 1
fi

# 使用conda来按照bison
if ! command -v conda &> /dev/null; then
    echo "错误: conda未安装，请先安装Anaconda或Miniconda。"
    exit 1
fi

# 在/tmp中，先检查是否有vscode-skip-server-requirements-check文件，如果没有则touch创建
if [ ! -f "/tmp/vscode-skip-server-requirements-check" ]; then
    touch /tmp/vscode-skip-server-requirements-check
fi
print_progress "创建/tmp/vscode-skip-server-requirements-check文件"

conda install -y bison
print_progress "安装bison"

# 定义glibc相关路径
GLIBC_VERSION="2.28"
GLIBC_DIR="$HOME/.local/src/opt/glibc-$GLIBC_VERSION"
GLIBC_TAR="$HOME/.local/src/opt/glibc-$GLIBC_VERSION.tar.gz"
GLIBC_INSTALL_DIR="$HOME/.local/opt/glibc-$GLIBC_VERSION"

# 开始构建glibc
echo "开始下载和构建glibc..."
print_progress "开始构建glibc"

# 创建必要的目录
mkdir -p ~/.local/src/opt
mkdir -p ~/.local/opt
print_progress "创建目录"

# 检查glibc是否已下载
if [ ! -f "$GLIBC_TAR" ]; then
    # 下载glibc
    cd ~/.local/src/opt
    wget --no-check-certificate https://ftp.gnu.org/gnu/glibc/glibc-$GLIBC_VERSION.tar.gz
    print_progress "下载glibc"
else
    echo "glibc已下载，跳过下载步骤。"
    print_progress "跳过下载glibc"
fi

# 检查glibc是否已解压并构建
if [ ! -d "$GLIBC_DIR" ]; then
    # 解压
    tar -zxvf "$GLIBC_TAR" -C ~/.local/src/opt
    print_progress "解压glibc"

    # 安装glibc
    cd "$GLIBC_DIR"
    mkdir build && cd build
    ../configure --prefix="$GLIBC_INSTALL_DIR" --disable-profile --enable-add-ons --disable-werror
    make -j16  # 根据CPU核心自行设置，用于并行加速
    make install
    print_progress "安装glibc"
else
    echo "glibc已构建，跳过构建步骤。"
    print_progress "跳过构建glibc"
fi

echo "glibc构建和安装完成。"
print_progress "完成glibc构建"

# 创建补丁脚本路径
PATCH_SCRIPT="$HOME/.ssh/patch_all_code_servers.sh"
print_progress "创建补丁脚本"

# 创建补丁脚本
cat << EOF > "$PATCH_SCRIPT"
#!/bin/bash

# 定义VSCode服务器的根目录
VSCODE_SERVER_ROOT="\$HOME/.vscode-server/bin"

# 检查VSCode服务器根目录是否存在
if [ ! -d "\$VSCODE_SERVER_ROOT" ]; then
    exit 1
fi

# 检查patchelf是否安装
if [ ! -x "$PATCHELF_PATH" ]; then
    exit 1
fi

# 获取patchelf的路径
PATCHELF_PATH="$PATCHELF_PATH"

# 迭代每个子目录
for dir in "\$VSCODE_SERVER_ROOT"/*; do
    if [ -d "\$dir" ]; then
        # 定义node路径
        CODE_SERVER_NODE_PATH="\$dir/node"
        
        # 检查node文件是否存在
        if [ ! -f "\$CODE_SERVER_NODE_PATH" ]; then
            continue
        fi

        # 获取当前的解释器
        CURRENT_INTERPRETER=\$($PATCHELF_PATH --print-interpreter "\$CODE_SERVER_NODE_PATH" 2>/dev/null)
        EXPECTED_INTERPRETER="\$HOME/.local/opt/glibc-2.28/lib/ld-linux-x86-64.so.2"  # 替换为您期望的interpreter路径

        # 检查并应用补丁
        if [ "\$CURRENT_INTERPRETER" != "\$EXPECTED_INTERPRETER" ]; then
            \$PATCHELF_PATH --set-rpath "\$HOME/.local/opt/glibc-2.28/lib:/lib:/lib64:/lib/x86_64-linux-gnu:/usr/lib:/usr/lib64:/usr/lib/x86_64-linux-gnu:/usr/local/lib" "\$CODE_SERVER_NODE_PATH"
            \$PATCHELF_PATH --set-interpreter "\$EXPECTED_INTERPRETER" "\$CODE_SERVER_NODE_PATH"
            echo "补丁应用成功：\$CODE_SERVER_NODE_PATH"
        fi
    fi
done
EOF

# 赋予patch脚本执行权限
chmod +x "$PATCH_SCRIPT"
print_progress "赋予补丁脚本执行权限"

# 创建或更新~/.ssh/rc文件
SSH_RC_FILE="$HOME/.ssh/rc"
print_progress "创建或更新SSH rc文件"

# 检查并创建~/.ssh/rc文件
if [ ! -f "$SSH_RC_FILE" ]; then
    touch "$SSH_RC_FILE"
fi

# 添加执行补丁脚本的行
if ! grep -q "$PATCH_SCRIPT" "$SSH_RC_FILE"; then
    echo "$PATCH_SCRIPT" >> "$SSH_RC_FILE"
fi

# 赋予~/.ssh/rc文件执行权限
chmod 700 "$SSH_RC_FILE"
print_progress "赋予SSH rc文件执行权限"

# 提示用户
echo "设置完成！"
echo "请确认已替换 $PATCH_SCRIPT 中的解释器路径为实际路径。"
