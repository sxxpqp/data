#!/bin/bash
set -e

# kubeadm_1.28.15-1.1_amd64.deb
K8S_VERSION="1.28.15-1.1"

# --- Common System Preparation (Shared between CentOS and Ubuntu) ---

echo "Starting common system preparation..."
read -p "是否安装 containerd？(y/n): " install_containerd_choice

# 使用 Bash 的条件表达式（[[ ... ]]）和模式匹配进行判断
if [[ "$install_containerd_choice" =~ ^[Yy](es)?$ ]]; then
    echo "Installing containerd..."
    # 确保您的 containerd 安装脚本可靠且安全
    # 判断containerd是否已经安装
    if command -v containerd >/dev/null 2>&1; then
        echo "containerd 已经安装，跳过安装步骤。"
    else
        echo "containerd 未安装，开始安装..."
    curl -fsSL https://chfs.sxxpqp.top:8443/chfs/shared/docker/containerd/installcontainerd.sh | bash
    fi
else
    echo "Skipping containerd installation as requested."
fi
# Disable swap persistently
echo "Disabling swap..."
sed -ri 's/.*swap.*/#&/' /etc/fstab
swapoff -a && sysctl -w vm.swappiness=0

# Set ulimits (Fixed typos: soft, unlimited)
echo "Setting ulimits..."
ulimit -SHn 65535
cat >> /etc/security/limits.conf <<EOF
* soft nofile 655360
* hard nofile 131072
* soft nproc 655350
* hard nproc 655350
* soft memlock unlimited
* hard memlock unlimited
EOF

# Load required kernel modules immediately (needed for both OSes)
echo "Loading kernel modules..."
sudo modprobe overlay
sudo modprobe br_netfilter

# Configure Sysctl parameters (Shared config file)
cat <<EOF > /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
fs.may_detach_mounts = 1
vm.overcommit_memory=1
vm.panic_on_oom=0
fs.inotify.max_user_watches=89100
fs.file-max=52706963
fs.nr_open=52706963
net.netfilter.nf_conntrack_max=2310720
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl =15
net.ipv4.tcp_max_tw_buckets = 36000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_orphans = 327680
net.ipv4.tcp_orphan_retries = 3
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.ip_conntrack_max = 65536
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_timestamps = 0
net.core.somaxconn = 16384
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
net.ipv6.conf.lo.disable_ipv6 = 0
net.ipv6.conf.all.forwarding = 1
EOF

# Configuration files for modules-load.d and sysctl.d (for next boot)
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl settings immediately
echo "Applying sysctl settings..."
sysctl --system

# --- OS-Specific Configuration and Package Installation ---

echo "Configuring OS-specific dependencies and Kubernetes repositories..."

if [ -f /etc/centos-release ]; then
    echo "Detected CentOS: `cat /etc/centos-release`"
    
    # CentOS Specific Deps
    cat > /etc/NetworkManager/conf.d/calico.conf << EOF 
[keyfile]
unmanaged-devices=interface-name:cali*;interface-name:tunl*
EOF
    yum install ipvsadm ipset sysstat conntrack libseccomp -y
    systemctl restart NetworkManager
    setenforce 0 # Disable SELinux

    # Install K8s via Yum (Aliyun mirror)
    cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.28/rpm/
enabled=1
gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.28/rpm/repodata/repomd.xml.key
EOF
    yum install -y  --nogpgcheck kubelet=${K8S_VERSION} kubeadm=${K8S_VERSION} kubectl=${K8S_VERSION}
    systemctl enable kubelet

elif [ -f /etc/lsb-release ]; then
    echo "Detected Ubuntu: `cat /etc/lsb-release`"

    # Ubuntu Specific Deps
    apt update
    apt install -y ipvsadm ipset sysstat conntrack libseccomp2 
    apt-get update && apt-get install -y apt-transport-https


    # kubeadm kubelet kubectl 都安装就跳过 repository 设置和安装步骤
    if command -v kubeadm  && command -v kubelet && command -v kubectl; then
        echo "kubeadm kubelet kubectl 已经安装，跳过安装步骤。"
    else
        echo "kubeadm kubelet kubectl 未安装，开始安装..."
        curl -fsSL https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.28/deb/Release.key |
        gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg --yes
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.28/deb/ /" |
        tee /etc/apt/sources.list.d/kubernetes.list
    apt-get update
      
   # 判断是否安装kubeadm kubelet kubectl
   if command -v kubeadm >/dev/null 2>&1; then
        echo "kubeadm 已经安装，跳过安装步骤。"
    else
        echo "kubeadm 未安装，开始安装..."
        apt-get install -y kubeadm=${K8S_VERSION}
    fi

    if command -v kubelet >/dev/null 2>&1; then
        echo "kubelet 已经安装，跳过安装步骤。"
    else
        echo "kubelet 未安装，开始安装..."
         apt-get install -y   kubelet=${K8S_VERSION}
    fi
    if command -v kubectl >/dev/null 2>&1; then
        echo "kubectl 已经安装，跳过安装步骤。"
    else
        echo "kubectl 未安装，开始安装..."
           apt-get install -y    kubectl=${K8S_VERSION}
           systemctl enable kubelet
    fi
    # Install K8s via Apt (Aliyun mirror)
    fi
   

  


else
    echo "Unsupported OS"
    exit 1
fi

echo "Script finished successfully. K8s components installed and configured."
echo "kubeadm init  --upload-certs --image-repository dockerhub.ihome.sxxpqp.top:8443/google_containers  --control-plane-endpoint 172.16.0.49:6443"