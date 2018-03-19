#!/bin/bash

redis_srv_ips=$(ssh master "egrep 'export pub_redis_ips' /homed/allips.sh" | awk -F'"' '{print $2}')

if [ -z "$redis_srv_ips" ]; then
    echo "allips.sh not find redis_srv_ips"
    exit 1
fi

REDISPORT=7379
for REDISIP in ${redis_srv_ips}
do
    ssh master "cd /homed/redis/bin && ./redis-cli.exe -p $REDISPORT -h $REDISIP -w ipanel info Replication | grep 'role:master'" &> /dev/null
    if [ $? == 0 ];then
		num=$(ssh master "cd /homed/redis/bin/ && ./redis-cli.exe -h $REDISIP -p $REDISPORT -w ipanel hlen user_playtoken_info" | tr -d '\n' | awk -F')' '{print $NF}')
		if [ "${num}" == "0" ] || [ "${num}" == "" ];then
			echo "$(date +'%Y-%m-%d %H:%M:%S') user_playtoken_info is null."
		else
			echo "$(date +'%Y-%m-%d %H:%M:%S') user_playtoken_info=${num}, start del user_playtoken_info..."
			ssh master "cd /homed/redis/bin/ && ./redis-cli.exe -h $REDISIP -p $REDISPORT -w ipanel del user_playtoken_info" &> /dev/null
			if [ $? == "0" ];then
				echo "$(date +'%Y-%m-%d %H:%M:%S') user_playtoken_info del success."
			else
				echo "$(date +'%Y-%m-%d %H:%M:%S') user_playtoken_info del failure."
			fi
		fi
    fi
done
