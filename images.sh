#!/bin/bash
#docker镜像批量一次性导出一个tar文件
docker images > vbn
awk '{print $1}' vbn | grep -v REPOSITORY > bnm
awk '{print $2}' vbn | grep -v TAG  > fgh
paste -d':' bnm fgh > mkk.txt
sed -i /none/d mkk.txt 
aa=`awk '{maxnf=NF;maxnr=NR;for(i=1;i<=NF;i++) a[NR,i]=$i}END{for(i=1;i<=maxnf;i++){for(j=maxnr;j>=0;j--) printf a[j,i]" ";printf "\n"}}' mkk.txt`
rm -f aaaa.tar
docker save -o aaaa.tar $aa
rm -f vbn bnm fgh mkk.txt 
