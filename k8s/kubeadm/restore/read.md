# 源master迁移到新的master
## hosts
hostnamectl set-hostname k8s-node1
## ip
ip a == 172.16.0.190
# 确保你的主机名能解析到本地，否则 API Server 拉不起来
echo "172.16.0.190 k8s-node1" >> /etc/hosts

通过etcd-restore.sh  恢复etcd数据  需要修改配置文件 ip name  db文件位置
 

copy /etc/kubernetes/pki /etc/kubernetes/pki


kubeadm init --config=kubeadm-config.yaml \
  --ignore-preflight-errors=DirAvailable--etc-kubernetes-pki,DirAvailable--var-lib-etcd 


