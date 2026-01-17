
# 创建Containerd的配置文件
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml

# 修改Containerd的配置文件
sed -i "s#SystemdCgroup\ \=\ false#SystemdCgroup\ \=\ true#g" /etc/containerd/config.toml
cat /etc/containerd/config.toml | grep SystemdCgroup
sed -i "s#registry.k8s.io#k8s.chenby.cn#g" /etc/containerd/config.toml
cat /etc/containerd/config.toml | grep sandbox_image
sed -i "s#config_path\ \=\ \"\"#config_path\ \=\ \"/etc/containerd/certs.d\"#g" /etc/containerd/config.toml
cat /etc/containerd/config.toml | grep certs.d






# 配置加速器
mkdir /etc/containerd/certs.d/docker.io -pv
cat > /etc/containerd/certs.d/docker.io/hosts.toml << EOF
server = "https://docker.io"
[host."https://docker.chenby.cn"]
  capabilities = ["pull", "resolve"]
EOF
# 启动并设置为开机启动



systemctl daemon-reload
systemctl enable --now containerd.service
systemctl stop containerd.service
systemctl start containerd.service
systemctl restart containerd.service
systemctl status containerd.service

ctr --debug image pull docker.io/library/busybox:latest --hosts-dir /etc/containerd/certs.d

crictl pull  docker.io/library/busybox:latest 
crictl pull docker.io/library/hello-world



kk version --show-supported-k8s