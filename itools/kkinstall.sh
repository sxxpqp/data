#!/bin/bash

# KK工具安装脚本
# 检测工具是否存在，存在则跳过安装

KK_PATH="/usr/bin/kk"
DOWNLOAD_URL="https://chfs.sxxpqp.top:8443/chfs/shared/itools/kk"

# 检查KK是否已安装
if [ -f "$KK_PATH" ]; then
    echo "KK工具已存在于 $KK_PATH，跳过安装"
    exit 0
fi

# 执行安装
echo "未检测到KK工具，开始安装..."
sudo curl -L -o "$KK_PATH" "$DOWNLOAD_URL" || { echo "下载失败"; exit 1; }
sudo chmod +x "$KK_PATH" || { echo "权限设置失败"; exit 1; }

# 验证安装
if [ -x "$KK_PATH" ]; then
    echo "KK工具安装成功!"
else
    echo "安装失败，工具不可执行"
    exit 1
fi