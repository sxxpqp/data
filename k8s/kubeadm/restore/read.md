# 源master迁移到新的master

# 源master 节点 步骤
获取hostname 和 ip
hostnamectl
获取证书 pki/ca.crt  pki/ca.key  
tar -zcvf pki.tar.gz  pki/ca.crt  pki/ca.key
备份etcd数据
etcdctl snapshot save etcd-snapshot.db



# 目的节点 步骤
## hosts
hostnamectl set-hostname k8s-node1
## ip
ip a == 172.16.0.190
# 确保你的主机名能解析到本地，否则 API Server 拉不起来
echo "172.16.0.190 k8s-node1" >> /etc/hosts
# 通过etcdctl 恢复数据 到 新节点 172.16.0.190
通过etcd-restore.sh  恢复etcd数据  需要修改配置文件 ip name  db文件位置
 
# 恢复证书
tar -zxvf pki.tar.gz  -C /

# 安装
kubeadm init --config=kubeadm-config.yaml \
  --ignore-preflight-errors=DirAvailable--etc-kubernetes-pki,DirAvailable--var-lib-etcd 


