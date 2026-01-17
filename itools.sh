#!/bin/bash
# set -euo pipefail  #

# iTools 简易安装脚本 - 支持 CentOS/Ubuntu
# 安装后可通过 `itools` 命令直接使用

# 定义工具基本信息
TOOL_NAME="itools"
BIN_DIR="/usr/local/bin"
TOOL_URL="https://chfs.sxxpqp.top:8443/chfs/shared/itools"  # 替换为实际下载地址
TOOL_PATH="$BIN_DIR/$TOOL_NAME"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'  # 重置颜色

# 检查系统类型
check_system() {
    if [ -f /etc/debian_version ]; then
        SYSTEM="ubuntu"
        echo -e "${GREEN}检测到 Ubuntu 系统${NC}"
    elif [ -f /etc/redhat-release ]; then
        SYSTEM="centos"
        echo -e "${GREEN}检测到 CentOS 系统${NC}"
    else
        echo -e "${RED}不支持的系统，仅支持 Ubuntu 或 CentOS${NC}"
        exit 1
    fi
}

# 检查并创建安装目录
prepare_install() {
    echo -e "${YELLOW}准备安装目录...${NC}"
    sudo mkdir -p "$BIN_DIR"
    sudo chmod 755 "$BIN_DIR"
}

# 下载并安装工具
install_tool() {
    echo -e "${YELLOW}下载 iTools 工具...${NC}"
    sudo curl -fsSL "$TOOL_URL" -o "$TOOL_PATH"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}下载失败！请检查网络连接${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}设置执行权限...${NC}"
    sudo chmod +x "$TOOL_PATH"
    
    # 验证安装
    if [ -x "$TOOL_PATH" ]; then
        echo -e "${GREEN}iTools 安装完成！${NC}"
        # echo -e "${GREEN}现在可以使用 `itools` 命令${NC}"
    else
        echo -e "${RED}安装失败！无法执行工具${NC}"
        exit 1
    fi
}

# 主函数
main() {
    echo -e "${GREEN}===== iTools 安装程序 ====${NC}"
    check_system
    # prepare_install
    install_tool
}

# 执行主函数
main