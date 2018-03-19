#!/bin/bash
## 解析ilogslave的run日志中VideoPlayStartSuccess关键字,将同一个用户在多个IP下播放的信息写入到异常IP名单文件 antileech.txt 中
##配置异常账号访问IP次数, 由于网络变化,一个用户是可能在多个IP下出现
#maxUserIPCount=0
#条件 if(C[a]>5) 用于配置一个账号在5个IP下访问时输出其IP信息
egrep VideoPlayStartSuccess /homed/ilogslave/log/run_*.log |awk -F'[ ,]' '{if($8 in S ) {if(!index(S[$8],$18)) {S[$8] =(S[$8]" "$18);C[$8] += 1;}}else {S[$8] = $18;C[$8] = 1}} END{for (a in S) if(C[a]>9) print S[a]}' > /r2/soft/antileech.txt
## 将空格转换为换行符
sed -i 's/ /\n/g' /r2/soft/antileech.txt
sort -n /r2/soft/antileech.txt | uniq > /r2/soft/blacklist.txt
sed -i 's/127.0.0.1//;/^[[:space:]]*$/d;s/^/add blacklist /; s/$/ timeout 300/' /r2/soft/blacklist.txt
#sed -i 's/^/add blacklist /; s/$/ timeout 300/' blacklist.txt

sleep 1
/sbin/ipset flush blacklist
/sbin/ipset restore -f blacklist.txt
