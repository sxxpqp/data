#!/bin/bash

# containerd 二进制卸载脚本
# 注意：请谨慎执行，确保已备份重要数据

# 定义 containerd 相关路径（可根据实际安装情况修改）
CONTAINERD_BIN_DIR="/usr/bin"
CONTAINERD_CONFIG_DIR="/etc/containerd"
CONTAINERD_STATE_DIR="/var/lib/containerd"
CONTAINERD_SERVICE_FILE="/usr/lib/systemd/system/containerd.service"
CONTAINERD_SERVICE_FILE1="/etc/systemd/system/containerd.service"
CONTAINERD_LOG_DIR="/var/log/containerd"

# 停止 containerd 服务
echo "==== 停止 containerd 服务 ===="
if systemctl status containerd &>/dev/null; then
    systemctl stop containerd
    systemctl disable containerd
    echo "containerd 服务已停止并禁用"
else
    echo "containerd 服务未运行"
fi

# 确认是否删除数据目录（默认保留）
# read -p "是否删除 containerd 数据目录 (${CONTAINERD_STATE_DIR})? (y/N): " DEL_DATA
DEL_DATA=${DEL_DATA:-y}

# 卸载二进制文件
echo "==== 卸载 containerd 二进制文件 ===="
if [ -d "$CONTAINERD_BIN_DIR" ]; then
    BIN_FILES=("containerd" "containerd-shim" "containerd-shim-runc-v2" "ctr" "crictl")
    for file in "${BIN_FILES[@]}"; do
        file_path="$CONTAINERD_BIN_DIR/$file"
        if [ -f "$file_path" ]; then
            rm -f "$file_path"
            echo "已删除二进制文件: $file_path"
        fi
    done
else
    echo "二进制目录 $CONTAINERD_BIN_DIR 不存在"
fi

# 删除配置文件
echo "==== 删除配置文件 ===="
if [ -d "$CONTAINERD_CONFIG_DIR" ]; then
    rm -rf "$CONTAINERD_CONFIG_DIR"
    echo "已删除配置目录: $CONTAINERD_CONFIG_DIR"
else
    echo "配置目录 $CONTAINERD_CONFIG_DIR 不存在"
fi

# 删除服务文件
echo "==== 删除服务配置 ===="
if [ -f "$CONTAINERD_SERVICE_FILE" ]; then
    rm -f "$CONTAINERD_SERVICE_FILE"
    rm -f "$CONTAINERD_SERVICE_FILE1"
    systemctl daemon-reload
    echo "已删除服务文件: $CONTAINERD_SERVICE_FILE"
    # echo "已删除服务文件: $CONTAINERD_SERVICE_FILE1"
else
    echo "服务文件 $CONTAINERD_SERVICE_FILE 不存在"
fi

# 删除日志目录（可选）
echo "==== 删除日志文件 ===="
if [ -d "$CONTAINERD_LOG_DIR" ]; then
    rm -rf "$CONTAINERD_LOG_DIR"
    echo "已删除日志目录: $CONTAINERD_LOG_DIR"
else
    echo "日志目录 $CONTAINERD_LOG_DIR 不存在"
fi

# 删除数据目录（可选）
if [ "$DEL_DATA" == "y" ] || [ "$DEL_DATA" == "Y" ]; then
    echo "==== 删除数据目录 ===="
    if [ -d "$CONTAINERD_STATE_DIR" ]; then
        rm -rf "$CONTAINERD_STATE_DIR"
        echo "已删除数据目录: $CONTAINERD_STATE_DIR"
    else
        echo "数据目录 $CONTAINERD_STATE_DIR 不存在"
    fi
else
    echo "数据目录 $CONTAINERD_STATE_DIR 已保留，如需删除请手动操作"
fi

# 清理残留进程
echo "==== 清理残留进程 ===="
pkill -9 containerd
pkill -9 ctr
pkill -9 crictl

echo "==== containerd 二进制卸载完成 ===="
echo "注意：如果通过包管理器安装（如 apt/yum），请使用对应包管理器卸载"