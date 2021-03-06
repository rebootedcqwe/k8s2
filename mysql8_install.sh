#!/bin/bash
A()
{
file="/root/mysql-8.0.17-linux-glibc2.12-x86_64.tar.xz"
if [ ! -f "$file" ]; then
  echo "mysql-8.0.17-linux-glibc2.12-x86_64.tar.xz does not exist,need Upload it to /root directory"
  exit 0
else
  echo "mysql-8.0.17-linux-glibc2.12-x86_64.tar.xz   is  exist!!!"
fi

if [ `whoami` != "root" ];then
 echo "root is no"
 exit 0
else
 echo "root is ok"
fi

a=`cat /etc/redhat-release |awk 'NR==1' |  awk -F '[ ]+' '{print $4}'| cut -d . -f 1`
if [ $a != "7" ];then
 echo "centos7.X is no"
 exit 0
else
 echo "centos7.X ok"
fi
}

IPtables()
{
systemctl stop firewalld.service
systemctl disable firewalld.service
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
cd ~
tar xvJf  mysql-8.0.17-linux-glibc2.12-x86_64.tar.xz
#cp -r mysql-5.7.17-linux-glibc2.5-x86_64 /usr/local/
cp -r  mysql-8.0.17-linux-glibc2.12-x86_64 /usr/local/
cd /usr/local 
mv mysql-8.0.17-linux-glibc2.12-x86_64/ mysql-8.0.17
ln -s mysql-8.0.17 mysql
useradd -r -M -s /sbin/nologin mysql
chown -Rf mysql.mysql  /usr/local/mysql-8.0.17
chown -Rf mysql.mysql /usr/local/mysql
chgrp -R mysql /usr/local/mysql-8.0.17
cd /usr/local/mysql/
rm /etc/my.cnf -f
rm -rf /usr/local/mysql/data/
/usr/local/mysql/bin/mysqld --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data     --initialize    >&  /root/mima.txt
rm /etc/my.cnf -f
cp -a  /usr/local/mysql/support-files/my-default.cnf   /etc/my.cnf
/usr/local/mysql/bin/mysqld_safe --defaults-file=/etc/my.cnf  &
sleep 2
ln -s /usr/local/mysql/bin/mysql /usr/bin/mysql
ln -s /usr/local/mysql/bin/mysqladmin /usr/bin/mysqladmin
rm    -f    /etc/init.d/mysqld
cp -a /usr/local/mysql/support-files/mysql.server  /etc/init.d/mysqld
/etc/init.d/mysqld restart
/etc/init.d/mysqld restart
chkconfig --level 35 mysqld on
a=`cat /root/mima.txt  |  awk 'NR==2'|awk -F '[ ]+' '{print $13}'` 
echo -n "mysql_newpasswd:"
read b
mysqladmin -uroot  -p"$a"  password "$b"
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
cp /etc/my.cnf.d/mysql-clients.cnf  /etc/my.cnf.d/mysql-clients.cnf.bak
> /etc/my.cnf.d/mysql-clients.cnf
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
">> /etc/my.cnf.d/mysql-clients.cnf
touch /usr/local/mysql/mysqld.pid
mkdir /usr/local/mysql/log
touch /usr/local/mysql/log/mysqld.log
mkdir /usr/local/mysql/data/binlog/
touch /usr/local/mysql/data/binlog/mysql-bin.log
chown -Rf mysql.mysql  /usr/local/mysql-8.0.11
chown -Rf mysql.mysql /usr/local/mysql
service mysqld restart
mysql -uroot -p$b -e "select version();"
if [ $? -ne 0 ]
then
echo "mysql install fail"
else
echo "Mysql is ok!!!"
fi
}



echo "========================================================================="
A
sleep 7
IPtables
selinux
#yum1
canshu
B
C
