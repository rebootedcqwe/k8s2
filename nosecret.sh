#!/bin/bash
#免密脚本，sshpass安装这个软件
#/root/.host 这个文件的格式手动生成
#主机名    IP地址    密码 
sed "s/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g" /etc/ssh/ssh_config -i
sed "s/#UseDNS yes/UseDNS no/g" /etc/ssh/sshd_config -i  
sed 's/GSSAPIAuthentication yes/GSSAPIAuthentication no/g' /etc/ssh/sshd_config -i  
sed "s/#StrictModes yes/StrictModes no/g" /etc/ssh/sshd_config -i
sed "s/#PubkeyAuthentication yes/PubkeyAuthentication yes/g" /etc/ssh/sshd_config -i
/bin/systemctl restart sshd.service
rm -f /root/.host
cat > /root/.host  <<EOF
master1 192.168.97.100 77777777
node1 192.168.97.102 77777777
node2 192.168.97.104 77777777
EOF
sleep 0.1
OLDIFS=$IFS
IFS=$'\n'
for line in $(cat /root/.host);do
  myip=$(echo $line |awk '{print $2}')
  mypwd=$(echo $line | awk '{print $3}')
  echo "$myip $mypwd"
  sshpass -p $mypwd ssh-copy-id -i /root/.ssh/id_rsa.pub $myip
done
IFS=$OLDIFS

#把ip地址单独取出来：
cat /root/.host | awk '{print $2}' > /root/.host.bak

#把主机名单独取出来：
cat /root/.host | awk '{print $1}' > /root/.host.zhujiming
