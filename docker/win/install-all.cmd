@echo off
echo === Windows Docker Desktop 自动化安装脚本 ===

rem 1. 检查 Docker 是否已安装
set "dockerPath=%ProgramFiles%\Docker\Docker\Docker Desktop.exe"
if exist "%dockerPath%" (
    echo Docker Desktop 已安装在: %dockerPath%
) else (
    echo 未检测到 Docker Desktop。
)

rem 2. 直接用 DISM 启用 Hyper-V
echo 启用 Hyper-V 功能...
dism /online /enable-feature /featurename:Microsoft-Hyper-V-All /LimitAccess /ALL

rem 3. 安装 WSL
echo 安装 WSL...
if not exist "%~dp0wsl.2.4.13.0.x64.msi" (
    echo 请手动下载 WSL 2 安装包到本目录: https://chfs.sxxpqp.top:8443/chfs/shared/docker/win/wsl.2.4.13.0.x64.msi
    pause
)
if exist "%~dp0wsl.2.4.13.0.x64.msi" (
    echo 正在安装 WSL 2...
    msiexec.exe /i "%~dp0wsl.2.4.13.0.x64.msi" /quiet /norestart
) else (
    echo 未找到 WSL 安装包，跳过 WSL 安装。
)

rem 4. 安装 Docker Desktop（如未安装）
if not exist "%dockerPath%" (
    if not exist "%~dp0DockerDesktopInstaller.exe" (
        echo 请手动下载 Docker Desktop 安装包到本目录: https://chfs.sxxpqp.top:8443/chfs/shared/docker/win/Docker%20Desktop%20Installer4.42.1.exe
        pause
    )
    if exist "%~dp0DockerDesktopInstaller.exe" (
        echo 开始静默安装 Docker Desktop...
        "%~dp0DockerDesktopInstaller.exe" install --quiet
        echo Docker Desktop 安装完成。
    ) else (
        echo 安装包未找到，无法安装。
    )
) else (
    echo 跳过 Docker Desktop 安装。
)

echo 建议每一步完成后重启电脑，以确保设置生效。
echo 脚本执行完毕。
pause