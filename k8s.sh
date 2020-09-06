#!/bin/bash
###是1个master 2个node脚本 ，
###k8s安装脚本1.17.3版本,centos7
###分别在每一台执行

#######################################
A()
{
if [ `whoami` != "root" ];then
 echo "root is no"
 exit 0
else
 echo "root is ok"
fi
sleep 3

file="/root/k8s_1_17_3.tar"
if [ ! -f "$file" ]; then
  echo "/root/k8s_1_17_3.tar does not exist,need Upload it to /root directory"
  exit 0
else
  echo "/root/images.tar   is  exist!!!"
fi


b=`cat /etc/redhat-release |awk 'NR==1' |  awk -F '[ ]+' '{print $4}'| cut -d . -f 1`
if [ $b != "7" ];then
 echo "centos7.X is no"
 exit 0
else
 echo "centos7.X ok"
fi
sleep 3

#read -p "Please input your name: " name
#echo "read name, name is $name"
#Please input your name: oliver
#read name, name is oliver

read -p "Please input your hostname: " name
hostnamectl --static set-hostname $name
sleep 1

rm -f /var/run/yum.pid
yum -y install wget net-tools nfs-utils lrzsz gcc gcc-c++ make cmake libxml2-devel openssl-devel curl curl-devel unzip sudo ntp libaio-devel wget vim ncurses-devel autoconf automake zlib-devel  python-devel epel-release openssh-server socat  ipvsadm conntrack ntpdate iptables-services sshpass
sleep 0.1
}
#######################
B()
{
systemctl stop firewalld.service
systemctl disable firewalld.service

systemctl stop iptables.service
systemctl disable iptables


swapoff -a
sed -i 's/.*swap.*/#&/' /etc/fstab

sed  -i  '7  s/enforcing/disabled/g'  /etc/selinux/config
setenforce 0
}

C()
{
ntpdate cn.pool.ntp.org
sleep 0.1

> /etc/sysctl.d/k8s.conf
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sleep 0.1
sysctl --system
sleep 0.1
}
D()
{
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
sleep 0.1
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
sleep 0.1
yum makecache fast
sleep 0.1

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
EOF

sleep 0.1


yum clean all
sleep 0.1
yum makecache fast
sleep 0.1
yum -y update
sleep 0.1
yum -y install yum-utils device-mapper-persistent-data lvm2
sleep 0.1
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
sleep 0.1

rm -f /var/run/yum.pid
yum install -y docker-ce-19*
systemctl enable docker  
systemctl start docker

cat > /etc/docker/daemon.json <<EOF
{
 "exec-opts": ["native.cgroupdriver=systemd"],
 "log-driver": "json-file",
 "log-opts": {
   "max-size": "100m"
  },
 "storage-driver": "overlay2",
 "storage-opts": [
   "overlay2.override_kernel_check=true"
  ]
}
EOF
sleep 0.1
systemctl daemon-reload  
systemctl restart docker
systemctl status docker
}


E()
{
echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables
echo 1 >/proc/sys/net/bridge/bridge-nf-call-ip6tables
echo """
vm.swappiness = 0
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
""" > /etc/sysctl.conf
sysctl -p
sleep 0.1
}

F()
{
cat >/etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
ipvs_modules="ip_vs ip_vs_lc ip_vs_wlc ip_vs_rr ip_vs_wrr ip_vs_lblc ip_vs_lblcr ip_vs_dh ip_vs_sh ip_vs_fo ip_vs_nq ip_vs_sed ip_vs_ftp nf_conntrack"
for kernel_module in \${ipvs_modules}; do
 /sbin/modinfo  -F  filename \${kernel_module}> /dev/null 2>&1
 if [ \$? -eq 0 ]; then
 /sbin/modprobe \${kernel_module}
 fi
done
EOF
sleep 0.1
chmod 755  /etc/sysconfig/modules/ipvs.modules  &&  bash  /etc/sysconfig/modules/ipvs.modules  &&  modprobe  ip_vs  && lsmod| grep ip_vs
sleep 0.1
}

G()
{
yum install kubeadm-1.17.3 kubelet-1.17.3 -y
systemctl enable kubelet
kubelet --version
docker load -i /root/k8s_1_17_3.tar
}

###################################################

echo "脚本在5秒后开始执行，后悔还来得及 The script started executing in 5 seconds, and now it's too late to regret"
sleep 5

A
B
C
D
E
F
G

