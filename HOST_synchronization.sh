#!/bin/bash
> /root/ip.txt
> /root/host.txt
#集群主机主机名
for i in `cat /root/.host.bak`; do ssh $i hostname ;  done > /root/host.txt
#集群ip
for i in `cat /root/.host.bak`; do ssh $i ip a |  awk 'NR==9' |  awk -F '[: ]+' '{print $3}'|cut -d/ -f 1 ;  done > /root/ip.txt
#主机名和ip拼接在一起，发送到集群所有主机
paste /root/ip.txt /root/host.txt  >> /etc/hosts
for i in `cat /root/.host.bak`; do scp /etc/hosts root@$i:/etc  ;  done 
