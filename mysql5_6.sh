#!/bin/bash
A()
{
file="/root/mysql-5.6.30-linux-glibc2.5-x86_64.tar.gz"
if [ ! -f "$file" ]; then
  echo "mysql-5.6.30-linux-glibc2.5-x86_64.tar.gz does not exist,need Upload it to /root directory"
  exit 0
fi

if [ `whoami` != "root" ];then
 echo "root is no"
 exit 0
else
 echo "root is ok"
fi

a=`cat /etc/redhat-release |awk 'NR==1' |  awk -F '[ ]+' '{print $3}'`
if [ $a != "6.5" ];then
 echo "centos6.5 is no"
 exit 0
else
 echo "centos6.5 ok"
fi
}

iptables()
{
service iptables stop
chkconfig  iptables off
service NetworkManager stop
chkconfig NetworkManager off
setenforce 0
}

selinux()
{
var=`cat   /etc/selinux/config |  awk 'NR==7' |  awk -F '[=]+' '{print $2}' `
if [ "$var" != "disabled" ]
then
sed  -i  '7  s/enforcing/disabled/g'  /etc/selinux/config
else
echo "Selinux has been closed ,need reboot effective"
fi
}

host()
{
b=`cat /etc/sysconfig/network  | grep "HOSTNAME" | awk -F '[ =]+' '{print $2}'`
echo -n "input_new_hostname:"
read a
sed -i "s#$b#$a#g"   /etc/sysconfig/network
}

yum1()
{
rm -f /var/run/yum.pid
yum -y install libicu-devel patch gcc-c++ readline-devel zlib-devel libffi-devel openssl-devel make autoconf automake libtool bison libxml2-devel libxslt-devel libyaml-devel zlib-devel openssl-devel cpio expat-devel gettext-devel curl-devel perl-ExtUtils-CBuilder perl-ExtUtils-MakeMaker wget lrzsz
}
#################################################
canshu()
{
echo "
kernel.shmmax = 68719476736
# Controls the maximum number of shared memory segments, in pages
kernel.shmall = 4294967296
fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.shmall = 2097152
kernel.shmmax = 4195024896
kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048586
net.ipv4.ip_local_port_range = 9000 65500
# The following 1 line added by Vertica tools. 2016-03-24 09:24:00
vm.max_map_count = 512088
" >>  /etc/sysctl.conf
/sbin/sysctl -p
echo "
session    required     pam_limits.so
" >> /etc/pam.d/login
echo "
echo never > /sys/kernel/mm/redhat_transparent_hugepage/enabled
" >>  /etc/rc.local
cat >> /etc/security/limits.conf <<EOF
*                soft    nproc           65536
*                hard    nproc           65536
*                soft    nofile          65536
*                hard    nofile          65536
EOF
}
B()
{
tar -zxf mysql-5.6.30-linux-glibc2.5-x86_64.tar.gz -C /usr/local/
useradd -r -M -s /sbin/nologin mysql
cd /usr/local
mv mysql-5.6.30-linux-glibc2.5-x86_64/ mysql
useradd -r -M -s /sbin/nologin mysql
chown -Rf mysql.mysql /usr/local/mysql
/usr/local/mysql/scripts/mysql_install_db  --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data
sleep  2
rm  -f /etc/my.cnf
cp  /usr/local/mysql/support-files/my-default.cnf  /etc/my.cnf
cp  /usr/local/mysql/support-files/mysql.server /etc/init.d/mysql
echo '
export MYSQL_HOME=/usr/local/mysql
export PATH=$MYSQL_HOME/bin:$PATH
'  >> /etc/profile
source /etc/profile
chkconfig --add mysql
chkconfig mysql on
service mysql restart
service mysql restart
echo -n "mysql_newpasswd:"
read b
mysqladmin -u root password "$b"
mysql -uroot -p$b -e "select version();"
if [ $? -ne 0 ]
then
echo "mysql install fail"
else
echo "Mysql is ok!!!"
fi
}

C()
{
cp  /etc/my.cnf  /etc/my.cnf.bak
> /etc/my.cnf
echo "
[client]
port = 3306
socket = /usr/local/mysql/mysql.sock
[mysqld]
port = 3306
socket = /usr/local/mysql/mysql.sock
skip-external-locking
key_buffer_size = 16M
max_allowed_packet = 1M
table_open_cache = 64
sort_buffer_size = 512K
net_buffer_length = 8K
read_buffer_size = 256K
read_rnd_buffer_size = 512K
myisam_sort_buffer_size = 8M
max_connections = 256
skip-name-resolve
log_bin = /usr/local/mysql/data/binlog/mysql-bin.log
server-id = 1
[mysqldump]
quick
max_allowed_packet = 16M
[mysql]
no-auto-rehash
# Remove the next comment character if you are not familiar with SQL
#safe-updates
[myisamchk]
key_buffer_size = 20M
sort_buffer_size = 20M
read_buffer = 2M
write_buffer = 2M
[mysqlhotcopy]
interactive-timeout
[mysqld_safe]
log-error=/usr/local/mysql/log/mysqld.log
pid-file=/usr/local/mysql/mysqld.pid
">> /etc/my.cnf 
touch /usr/local/mysql/mysqld.pid
mkdir /usr/local/mysql/log
touch /usr/local/mysql/log/mysqld.log
mkdir /usr/local/mysql/data/binlog/
touch /usr/local/mysql/data/binlog/mysql-bin.log
chown -Rf mysql.mysql /usr/local/mysql
service mysql restart
mysql -uroot -p$b -e "select version();"
if [ $? -ne 0 ]
then
echo "mysql install fail"
else
echo "Mysql is ok!!!"
fi
}


A
iptables
selinux
host
yum1
canshu
B
C



/usr/local/python/bin/python3