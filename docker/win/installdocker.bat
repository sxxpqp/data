@echo off
setlocal

REM 设置下载链接
set WSL_URL=https://chfs.sxxpqp.top:8443/chfs/shared/docker/win/wsl.2.3.24.0.x64.msi  REM WSL 的 MSI 安装链接
set DOCKER_URL=https://chfs.sxxpqp.top:8443/chfs/shared/docker/win/Docker%20Desktop%20Installer.exe  REM Docker Desktop 的安装链接

REM 设置安装路径为当前工作目录
set DOCKER_INSTALL_PATH=%CD%\Docker Desktop Installer.exe  REM Docker 安装位置

REM 下载 WSL
echo Downloading WSL...
curl -L -o wsl_installer.msi %WSL_URL%
if errorlevel 1 (
    echo Failed to download WSL installer!
    exit /b 1
)

REM 安装 WSL
echo Installing WSL...
start /wait msiexec /i wsl_installer.msi /quiet /norestart
if errorlevel 1 (
    echo WSL installation failed!
    exit /b 1
)

REM 下载 Docker Desktop
echo Downloading Docker Desktop...
curl -L -o "%DOCKER_INSTALL_PATH%" %DOCKER_URL%
if errorlevel 1 (
    echo Failed to download Docker Desktop installer!
    exit /b 1
)

REM 安装 Docker Desktop with specified options
echo Installing Docker Desktop...
start /wait "" "%DOCKER_INSTALL_PATH%" install --backend=wsl-2 --installation-dir=D:\software\docker\docker --wsl-default-data-root=D:\software\wsl --accept-license
if errorlevel 1 (
    echo Docker Desktop installation failed! Attempting to uninstall...

    REM 尝试卸载 Docker Desktop
    start /wait "Docker Desktop Uninstaller" "C:\Program Files\Docker\Docker\uninstall.exe"
    if errorlevel 1 (
        echo Docker uninstallation after failed installation failed!
        exit /b 1
    )
    echo Docker Desktop uninstalled successfully after failed installation.
    exit /b 1
)

echo Installation completed. Please restart your computer if required.
pause
endlocal