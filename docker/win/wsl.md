您必须运行 Windows 10 版本 2004 及更高版本（内部版本 19041 及更高版本）或 Windows 11 才能使用以下命令。
PowerShell
`
wsl --update --web-download

查看wsl版本
`
wsl  -v
wsl -l -v
`
`
查看可安装的版本
`
wsl --list --online
`

`
wsl --set-default-version 2
`
旧版安装
`
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
`
`
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
`

### 使用 Docker 设置 NVIDIA CUDA
```
curl https://chfs.sxxpqp.top:8443/chfs/shared/docker/install-docker-qh.sh | sh
```
```
sudo service docker start
```
```
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
```
```
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-docker-keyring.gpg
```
```
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-docker-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
```
```
sudo apt-get update
```
```
sudo apt-get install -y nvidia-docker2

```
```
ln -sf /usr/lib/wsl/lib/libcuda.so.1.1 /usr/lib/wsl/lib/libcuda.so.1

nvidia-docker2
nvidia-container-toolkit
nvidia-container-toolkit-base
libnvidia-container1:amd64
libnvidia-container-tools
```

```
docker run --gpus all -it --shm-size=1g --ulimit memlock=-1 --ulimit stack=67108864 nvcr.io/nvidia/tensorflow:20.03-tf2-py3
```
```
cd nvidia-examples/cnn/
```

```
python resnet.py --batch_size=64
```

### conda 安装 
```
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
conda create --name directml python=3.7 -y
conda activate directml
```
### TensorFlow-DirectML：
```
pip install tensorflow-directml
sudo apt install libblas3 libomp5 liblapack3
pip install torch-directml
```

### 多gpu
```
export MESA_D3D12_DEFAULT_ADAPTER_NAME="<NameFromDeviceManager>"
```