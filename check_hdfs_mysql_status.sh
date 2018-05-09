#!/bin/bash
#-----------------------------------------------------------------------------------
# name:check_hdfs_mysql_status.sh
# version:1.5
# createTime:2017-08-21
# description:检查商用集群HDFS和MySQL状态
# author:liuyf
# email:liuyf@ipanel.cn
# github:https://github.com/liuyangfa
#-----------------------------------------------------------------------------------
# check_mysql_sync：检查数据库主从同步
# check_mysql_backup：检查数据库备份文件信息
# check_resume_namenode：检查namenode拉起脚本是否加入定时任务
# check_fsimage_time：检查fsimage文件信息
# check_fsimage_time：检查fsimage文件信息
# insert_status:向邮件内容中写入对整个集群状态的判断结果
# post_email：发送邮件
#-----------------------------------------------------------------------------------
# Version1.0
# 简单获取对应的条目信息
# Version1.1
# 对获取的条目信息就行简单判断来确定状态是否正常
# Version1.2
# 修复fsimage文件时间判断异常的问题
# Version1.3
# 兼容不同版本MySQL(5.5-5.7)主从判断时参数不同造成的判断异常问题
# Version1.4
# 1.修改输出重定向位置，标准输出定为邮件内容，错误输出丢弃
# 2.删除抄送邮件组
# Version1.5
# 将各检测项检查结果统一放置在开头

source /etc/profile
export  LANG="zh_CN.UTF-8"
exec > /tmp/info.tmp
exec 2> /dev/null

function say_info()
{
	echo "Hi All:"
	echo -e "	下面是${project_name}的HDFS及MySQL检查情况。"
	echo ""
	echo ""
	echo "=========================我是分割线===================================="
	echo ""
}

function check_mysql_sync()
{
	status1=$(mysql -uroot -p${mysql_passwd} -hslave2 -e 'show slave status\G' | awk '/Slave_IO_Running:/ {print $2} /Slave_SQL_Running:/ {print $2}' | tr '\n' ' ')
	status2=$(mysql -uroot -p${mysql_passwd} -hslave4 -e 'show slave status\G' | awk '/Slave_IO_Running:/ {print $2} /Slave_SQL_Running:/ {print $2}' | tr '\n' ' ')
	status3=$(mysql -uroot -p${mysql_passwd} -hslave6 -e 'show slave status\G' | awk '/Slave_IO_Running:/ {print $2} /Slave_SQL_Running:/ {print $2}' | tr '\n' ' ')
	if [[ ${status1} == 'Yes Yes ' && ${status2} == 'Yes Yes ' && ${status3} == 'Yes Yes ' ]];then
		info1='1. MySQL数据库主从同步【正常】'
		echo "${info1}"
	elif [[ ${status1} == 'Yes No ' || ${status1} == 'No No ' || ${status1} == 'No Yes ' ]];then
		info1='1. [Warning] slave2数据库主从同步【异常】'
		echo "${info1}"
	elif [[ ${status2} == 'Yes No ' || ${status2} == 'No No ' || ${status2} == 'No Yes ' ]];then
		info1='1. [Warning] slave4数据库主从同步【异常】'
		echo "${info1}"
	elif [[ ${status3} == 'Yes No ' || ${status3} == 'No No ' || ${status3} == 'No Yes ' ]];then
		info1='1. [Warning] slave6数据库主从同步【异常】'
		echo "${info1}"
	else
		info1='====slave${i}数据库主从同步异常===='
		echo "${info1}"
	fi

	for i in 2 4 6
	do
		echo "----------------slave${i}数据库主从同步信息------------------"
		mysql -uroot -p${mysql_passwd} -hslave${i} -e "show slave status\G"
		echo ""
	done
}

function check_mysql_backup()
{
	size1=$(ssh slave2 "find ${mysql_backup_path} -maxdepth 1 -ctime -1 -name '*.sql' | xargs stat -c %s | awk 'BEGIN {sum=0} {sum+=\$1} END {print sum}'")
	size2=$(ssh slave4 "find ${mysql_backup_path} -maxdepth 1 -ctime -1 -name '*.sql' | xargs stat -c %s | awk 'BEGIN {sum=0} {sum+=\$1} END {print sum}'")
	size3=$(ssh slave6 "find ${mysql_backup_path} -maxdepth 1 -ctime -1 -name '*.sql' | xargs stat -c %s | awk 'BEGIN {sum=0} {sum+=\$1} END {print sum}'")
	if [[ ${size1} -gt 10000000 && ${size2} -gt 10000000 && ${size3} -gt 10000000 ]];then
		info2='2. MySQL数据库定期备份【正常】'
		echo "${info2}"
	else
		info2='2. MySQL数据库定期备份【异常】'
		echo "${info2}"
	fi

	for i in 2 4 6
	do
		echo "-------------------slave${i}数据库备份信息---------------------"
		ssh slave${i} "ls -trlh ${mysql_backup_path} | tail -5"
		echo ""
	done
}


function check_resume_namenode()
{
	cron_m=$(ssh master "crontab -l | grep resume_namenode" | tr -d '\n')
	cronfile_m=$(ssh master "ls /hadoop/hadoop-2.6.4/bin/resume_namenode.sh" | tr -d '\n')
	cron_sm=$(ssh secondmaster "crontab -l | grep resume_namenode" | tr -d '\n')
	cronfile_sm=$(ssh secondmaster "ls /hadoop/hadoop-2.6.4/bin/resume_namenode.sh" | tr -d '\n')

	if [[ ${cron_m} != "" && ${cronfile_m} != "" && ${cron_sm} != "" && ${cronfile_sm} != "" ]];then
		info3='3. NameNode定时拉起【正常】'
		echo "${info3}"
	else
		info3='3. NameNode定时拉起【异常】'
		echo "${info3}"
	fi

	for hostname in master secondmaster
	do
		echo "--------------${hostname}的namenode拉起定时任务及对应的执行脚本--------------"
		ssh ${hostname} "crontab -l | grep resume_namenode;ls -lh /hadoop/hadoop-2.6.4/bin/resume_namenode.sh"
		echo ""
	done
}

function check_fsimage_time()
{
	fs_num_m=$(ssh master "find /r2/hadoopdata/namenode/dfs/name/current/ -type f -atime -1| grep fsimage | xargs stat -c %x | awk -F'[ |.]' 'BEGIN{date=strftime(\"%Y-%m-%d\");hour=strftime(\"%H\")-3;mini=strftime(\"%M\");sec=strftime(\"%S\");if(hour<10) time=0hour\":\"mini\":\"sec;else time=hour\":\"mini\":\"sec}{if(\$1==date&&\$2>time){print \$0,time}}' | wc -l")
	fs_num_sm=$(ssh secondmaster "find /r2/hadoopdata/namenode/dfs/name/current/ -type f -atime -1| grep fsimage | xargs stat -c %x | awk -F'[ |.]' 'BEGIN{date=strftime(\"%Y-%m-%d\");hour=strftime(\"%H\")-3;mini=strftime(\"%M\");sec=strftime(\"%S\");if(hour<10) time=0hour\":\"mini\":\"sec;else time=hour\":\"mini\":\"sec}{if(\$1==date&&\$2>time){print \$0,time}}' | wc -l")
	if [[ ${fs_num_m} -ge 4  && ${fs_num_sm} -ge 4 ]];then
		info4='4. fsimage文件同步【正常】'
		echo "${info4}"
	else
		info4='4. fsimage文件同步【异常】'
		echo "${info4}"
	fi
	for hostname in master secondmaster
	do
		echo "------------------------${hostname}的fsimage信息--------------------------"
		ssh ${hostname} "ls -lhtr /r2/hadoopdata/namenode/dfs/name/current/fsimage* | tail -5"
		echo ""
	done
}

function check_hdfs_proccess()
{
	pro_m=$(ssh master /usr/java/jdk1.7.0_55/bin/jps | grep -E 'NameNode|DFSZKFailoverController' | awk '{print $2}' | tr '\n' ' ')
	pro_sm=$(ssh secondmaster /usr/java/jdk1.7.0_55/bin/jps | grep -E 'NameNode|DFSZKFailoverController' | awk '{print $2}' | tr '\n' ' ')
	if [[ (${pro_m} == 'NameNode DFSZKFailoverController ' || ${pro_m} == 'DFSZKFailoverController NameNode ') && (${pro_sm} == 'NameNode DFSZKFailoverController ' || ${pro_sm} == 'DFSZKFailoverController NameNode ') ]];then
		info5='5. HDFS进程【正常】'
		echo "${info5}"
	else
		info5='5. HDFS进程【异常】'
		echo "${info5}"
	fi
	for hostname in master secondmaster
	do
		echo "--------------------------${hostname}的NameNode进程信息-----------------------"
		ssh ${hostname} "/usr/java/jdk1.7.0_55/bin/jps | grep -E 'NameNode|DFSZKFailoverController'"
		echo ""
	done
}

function post_email()
{
	if [ -e /tmp/info.tmp ];then
		mailx -s "${topic}" -r check_hdfs_mysql@ipanel.cn ${recipients} < /tmp/info.tmp
	fi
}

function check_cron()
{
	if [ "$(crontab -l | grep check_hdfs_mysql_status)" = "" ] && [ -x /homed/check_hdfs_mysql_status.sh ];then
		echo "30 8 */2 * * sh /homed/check_hdfs_mysql_status.sh &> /dev/null &" >> /var/spool/cron/root
	fi
}

function insert_status()
{
	if [[ ${status1} == 'Yes Yes ' && ${status2} == 'Yes Yes ' && ${status3} == 'Yes Yes ' && ${size1} -gt 10000000 && ${size2} -gt 10000000 && ${size3} -gt 10000000 && ${cron_m} != "" && ${cronfile_m} != "" && ${cron_sm} != "" && ${cronfile_sm} != "" && ${fs_num_m} -ge 4  && ${fs_num_sm} -ge 4 && (${pro_m} == 'NameNode DFSZKFailoverController ' || ${pro_m} == 'DFSZKFailoverController NameNode ') && (${pro_sm} == 'NameNode DFSZKFailoverController ' || ${pro_sm} == 'DFSZKFailoverController NameNode ') ]];then
		sed -i "3 a【重要信息】${project_name}HDFS和MySQL主备检查【正常】" /tmp/info.tmp
		sed -i "4 a${info1}" /tmp/info.tmp
		sed -i "5 a${info2}" /tmp/info.tmp
		sed -i "6 a${info3}" /tmp/info.tmp
		sed -i "7 a${info4}" /tmp/info.tmp
		sed -i "8 a${info5}" /tmp/info.tmp
	else
		sed -i "3 a【重要信息】${project_name}HDFS和MySQL主备检查【存在异常】" /tmp/info.tmp
		sed -i "4 a${info1}" /tmp/info.tmp
		sed -i "5 a${info2}" /tmp/info.tmp
		sed -i "6 a${info3}" /tmp/info.tmp
		sed -i "7 a${info4}" /tmp/info.tmp
		sed -i "8 a${info5}" /tmp/info.tmp

	fi
}

function main()
{
	mysql_backup_path="/r2/bak_sql/"
	mysql_passwd=$(grep '<db_name>homed_dtvs</db_name>' -A 2 /homed/config_comm.xml | grep db_password | awk -F'[<|>]' '{print $3}' | tr -d '\n')
	project_name=$(grep pname /homed/config_comm.xml  | awk -F'[<|>]' '{print $3}' | tr -d '\n')
	topic="[${project_name}][HDFS与MySQL状态汇总]-$(date +%Y-%m-%d)"
	recipients="homed-maintain@ipanel.cn"
	check_cron
	say_info
	check_mysql_sync
	check_mysql_backup
	check_resume_namenode
	check_fsimage_time
	check_hdfs_proccess
	insert_status
	post_email
}
main
