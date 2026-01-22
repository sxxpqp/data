# 更新地址 https://mirrors.huaweicloud.com/jenkins/updates/update-center.json

sed -i 's#updates.jenkins.io/download#mirrors.huaweicloud.com/jenkins#g' /var/lib/jenkins/updates/default.json
sed -i 's/www.google.com/www.baidu.com/g' /var/lib/jenkins/updates/default.json