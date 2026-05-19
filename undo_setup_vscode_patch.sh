# 备份
bk="$HOME/vscode_patch_backup_$(date +%F_%H%M%S)"
mkdir -p "$bk"

for f in \
  "$HOME/.ssh/rc" \
  "$HOME/.ssh/patch_all_code_servers.sh" \
  "$HOME/.vscode-server/server-env-setup" \
  "$HOME/.profile" \
  "$HOME/.bashrc" \
  "$HOME/.bash_profile" \
  "$HOME/.zshrc"
do
  [ -f "$f" ] && cp -a "$f" "$bk"/
done

# 1) 禁用你那个脚本写进 ~/.ssh/rc 的自动 patch
if [ -f ~/.ssh/rc ]; then
  sed -i '/patch_all_code_servers\.sh/d' ~/.ssh/rc
  [ -s ~/.ssh/rc ] || rm -f ~/.ssh/rc
fi

[ -f ~/.ssh/patch_all_code_servers.sh ] && \
  mv ~/.ssh/patch_all_code_servers.sh ~/.ssh/patch_all_code_servers.sh.disabled

# 2) 禁用 VS Code 自定义 glibc 环境
for f in ~/.profile ~/.bashrc ~/.bash_profile ~/.zshrc; do
  [ -f "$f" ] || continue
  sed -i \
    -e '/VSCODE_SERVER_CUSTOM_GLIBC_LINKER/d' \
    -e '/VSCODE_SERVER_CUSTOM_GLIBC_PATH/d' \
    -e '/VSCODE_SERVER_PATCHELF_PATH/d' \
    "$f"
done

# 这个文件如果存在，通常就是 VS Code Server 启动前注入环境变量用的
[ -f ~/.vscode-server/server-env-setup ] && \
  mv ~/.vscode-server/server-env-setup ~/.vscode-server/server-env-setup.disabled

# 3) 删除旧 skip-check 标记
rm -f /tmp/vscode-skip-server-requirements-check 2>/dev/null || true

# 4) 清掉坏掉的 VS Code Server，让它重新装干净版本
pkill -u "$USER" -f 'vscode-server|code-server' 2>/dev/null || true
rm -rf ~/.vscode-server ~/.vscode-remote
