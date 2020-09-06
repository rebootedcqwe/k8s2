#!/bin/bash
#批量全部删除docker镜像
echo "批量全部删除docker镜像!!!!!!!"
sleep 30
docker images > vbn
awk '{print $1}' vbn | grep -v REPOSITORY > bnm
awk '{print $2}' vbn | grep -v TAG  > fgh
paste -d':' bnm fgh > mkk.txt
sed -i /none/d mkk.txt 
aa=`awk '{maxnf=NF;maxnr=NR;for(i=1;i<=NF;i++) a[NR,i]=$i}END{for(i=1;i<=maxnf;i++){for(j=maxnr;j>=0;j--) printf a[j,i]" ";printf "\n"}}' mkk.txt`
docker rmi -f  $aa
rm -f vbn bnm fgh mkk.txt 
