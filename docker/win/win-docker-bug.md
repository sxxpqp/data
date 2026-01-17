#### 查看cpu是否开启虚拟化
systeminfo | findstr /i "Virtualization"

#### 报错一：

##### Docker Desktop - Unexpected WSL error

An unexpected error occurred while executing a WSL command.

Either shut down WSL down with wsl --shutdown, and/or reboot your machine. You can also try reinstalling WSL and/or Docker Desktop. If the issue persists, [collect diagnostics and submit an issue](https://docs.docker.com/desktop/troubleshoot/overview/?utm_source=docker_desktop_error_dialog#diagnose-from-the-terminal)

deploying WSL2 distributions

provisioning docker WSL distros: ensuring main distro is deployed: deploying "docker-desktop": importing WSL distro "找不到指定文件的虚拟磁盘支持提供程序。 \r\nError code: Wsl/Service/RegisterDistro/0xc03a0014\r\n" output="docker-desktop": exit code: 4294967295: running WSL command wsl.exe C:\WINDOWS\System32\wsl.exe --import docker-desktop <HOME>\AppData\Local\Docker\wsl\main C:\Program Files\Docker\Docker\resources\wsl\wsl-bootstrap.tar --version 2: 找不到指定文件的虚拟磁盘支持提供程序。

Error code: Wsl/Service/RegisterDistro/0xc03a0014

: exit status 0xffffffff

checking if isocache exists: CreateFile \\wsl$\docker-desktop-data\isocache\: The network name cannot be found.[⁠](https://docs.docker.com/support/?utm_source=docker_desktop_error_dialog#how-is-personal-diagnostic-data-handled-in-docker-desktop)

安装到d盘




#### 报错二：

执行wsl.exe --install Ubuntu-20.04报错了。

WslRegisterDistribution failed with error: 0xc03a0014

Error: 0xc03a0014 ???????????????????



Press any key to continue...

根据github查询到的解决办法：

1、打开设备管理器

2、点击系统设备

3、找到并开启一下设备：

Microsoft Hyper-V 虚拟化基础结构驱动程序
复合总线枚举器
Microsoft 虚拟驱动器枚举器
UMBus Root Bus Enumerator
NDIS 虚拟网络适配器枚举器
设备重定向器总线枚举器（如果适用）


#running engine: waiting for the Docker API: engine linux/wsl failed to run: starting WSL engine: error spotted in wslbootstrap log: "[2025-02-26T01:20:39.762592100Z][wsl-bootstrap][F] mounting base image /c/Program Files/Docker/Docker/resources/docker-desktop.iso on /tmp/docker-desktop-<USER>-ro: expected digest a9f8cc7082f33c3c8efdc39f0fcc7f7cfc5dc0711601f3ead58063717971fdb0 actual digest e3edc5ead2c7d2d4d787c090c1f3f8f03e92ba9d904efb25b9295a9e973caf11"
解决办法：现安装wsl 在卸载docker desktop 重新安装docker desktop


#Installing, this may take a few minutes...
WslRegisterDistribution failed with error: 0x80370102
Error: 0x80370102 ???????????????????

Press any key to continue...




# 启用适用于 Linux 的 Windows 子系统
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
# 启用虚拟机功能
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
# 下载 Linux 内核更新包
https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi
bcdedit /set hypervisorlaunchtype auto




net stop winnat
net start winnat

### 报错3 还有目录权限问题导致wsl无法启动
deploying WSL2 distributions
ensuring main distro is deployed: deploying "docker-desktop": preparing directory "D:\software\wsl\main" for WSL distro "docker-desktop": creating distro destination dir "D:\software\wsl\main": mkdir D:\software\wsl: Access is denied.
checking if isocache exists: CreateFile \wsl$\docker-desktop-data\isocache: The network name cannot be found.

修改目录权限
这个是安装4.4.4版本解决的

 ### 报错4 
 desktop": importing WSL distro "当前计算机配置不支持 WSL2。\r\n请启用“虚拟机平台”可选组件，并确保在 BIOS 中启用虚拟化。\r\n通过运行以下命令启用“虚拟机平台”: wsl.exe --install --no-distribution\r\n有关信息，请访问 https://aka.ms/enablevirtualization\r\n错误代码: Wsl/Service/RegisterDistro/CreateVm/HCS/HCS_E_HYPERV_NOT_INSTALLED\r\n" output="docker-desktop": exit code: 4294967295: running WSL command wsl.exe C:\WINDOWS\System32\wsl.exe --import docker-desktop D:\software\wsl\main D:\software\docker\docker\resources\wsl\wsl-bootstrap.tar --version 2: 当前计算机配置不支持 WSL2。
请启用“虚拟机平台”可选组件，并确保在 BIOS 中启用虚拟化。
通过运行以下命令启用“虚拟机平台”: wsl.exe --install --no-distribution
有关信息，请访问 https://aka.ms/enablevirtualization
错误代码: Wsl/Service/RegisterDistro/CreateVm/HCS/HCS_E_HYPERV_NOT_INSTALLED
: exit status 0xffffffff
checking if isocache exists: CreateFile \\wsl$\docker-desktop-data\isocache\: The network name cannot be found.

通过执行 
bcdedit /set hypervisorlaunchtype auto 

wsl --install --no-distribution 解决不了用下面

# 启用Windows子系统Linux（WSL）
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

# 启用虚拟机平台（WSL 2依赖）
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# 启用Hyper-V（部分系统需要，尤其是旧版本Windows 10）
dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V /all /norestart





##### 以上是因为没有安装wsl，解决办法：



### 更新 WSL

在 Windows 命令提示符或 PowerShell 中，以管理员身份运行以下命令来更新 WSL：

```
bash


复制代码
wsl --update --web-download

wsl --set-default-version 2

```

使用命令提示符或者Windows PowerShell执行一下代码获取列表

```
wsl --list --online
```

然后根据提示执行 wsl.exe --install 来安装 例如：

```
wsl.exe --install Ubuntu-20.04

wsl --install -d Ubuntu
```
