#!/bin/bash

# Date: 2018-04-12
# Author: Liu Yangfa
# Descrition: auto operation system install scripts
# Version: 1.0

#引入配置文件及日志文件和功能函数文件
source config.sh
source log.sh
source opsFun.sh

. /etc/init.d/functions
. ./optfun.sh
. /etc/profile
password="ipanel"
dbhost="127.0.0.1"
zabbix_url="http://zabbix.homed.me/zabbix"
filename="v1.1.0_20180409.tar.gz"
destination="/r2/maintain_scripts"
ipCollect="192.168.50.204"
agents=""
server="192.168.50.204"
#subject=$(awk -F'<|>' '/reports_subject/{print $3}' /usr/local/zabbix/etc/zabbix_monitor.conf)
#zabbix_user=$(awk -F'<|>' '/zabbix_user/{print $3}' /usr/local/zabbix/etc/zabbix_monitor.conf)
#zabbix_passwd=$(awk -F'<|>' '/zabbix_passwd/{print $3}' /usr/local/zabbix/etc/zabbix_monitor.conf)
subject="测试集群"
zabbix_user="zabbix"
zabbix_passwd="zabbix_passwd"

function checkVersion()
{
	local z=`python -V 2>&1 | awk '{print $2}' | awk -F"." '{print $1 $2}'`
	if [ "${z}" != "27" ];then
		echo "[ERROR] python version is not 2.7 !"
		exit 1
	fi
}

function checkConfig()
{
	if [[ ${subject} == "" || ${zabbix_user} == "" || ${zabbix_passwd} == "" ]];then
		echo "$(date +'%Y-%m-%d %H:%M:%S') 安装信息不完整.$(echo_warning)"
		exit 1
	fi
}

function unzipFile()
{
	#确认安装使用的压缩包是否存在
	if [ -s "${filename}" ];then
		echo "$(date +'%Y-%m-%d %H:%M:%S') 开始解压..." 
		#LANG=C unzip -o -q ${filename} -d ./ && echo "$(date +'%Y-%m-%d %H:%M:%S') ${filename}解压成功"
		LANG=C tar xf ${filename} -C ./ && echo "$(date +'%Y-%m-%d %H:%M:%S') ${filename}解压成功"
		chmod +x -R ops
	else
		LANG=C echo "$(date +'%Y-%m-%d %H:%M:%S') ${filename}解压失败，请检查安装包."
		exit 2
	fi
}

function installDir()
{
	#确认临时安装目录是否存在，不存在则创建，并移动安装所需文件到destination下
	if [ ! -d "${destination}" ];then
		LANG=C mkdir -p ${destination} && echo "$(date +'%Y-%m-%d %H:%M:%S') ${destination}临时安装目录创建成功."
		LANG=C mv ./ops ${destination} && echo "$(date +'%Y-%m-%d %H:%M:%S') 安装文件已经移动至临时安装目录${destination}."
	else
		LANG=C echo "$(date +'%Y-%m-%d %H:%M:%S') 目录已存在，是否进行安装，选择是则删除该目录，重新创建，选择否则退出当前安装."
		read -p "请选择是否继续安装(y/n):" yn
		if [ ${yn} = "n" ];then
			exit 0
		elif [ ${yn} = "y" ];then
			LANG=C rm -rf /r2/maintain_scripts && LANG=C mkdir -p ${destination}
			LANG=C mv ./ops ${destination} && echo "$(date +'%Y-%m-%d %H:%M:%S') 安装文件已经移动至临时安装目录."
		else
			echo "$(date +'%Y-%m-%d %H:%M:%S') 输入错误"
			exit 1
		fi
	fi
}

function modConfig()
{
	#切换操作目录
	LANG=C cd ${destination}/ops
	
	#修改collectAlerts相关配置
	LANG=C sed -i "5c passwd=${password}" ialert/config/ialert.conf
	LANG=C sed -i "6c host=${dbhost}" ialert/config/ialert.conf
	LANG=C cp -r operation/operation/settings_default.py operation/operation/settings.py
	LANG=C sed -i "/^name=/c name=${subject}" ialert/config/ialert.conf
	LANG=C sed -i "/^zabbix_url=/c zabbix_url=${zabbix_url}" ialert/config/ialert.conf
	LANG=C sed -i "/^zabbix_user=/c zabbix_user=${zabbix_user}" ialert/config/ialert.conf
	LANG=C sed -i "/^zabbix_passwd=/c zabbix_passwd=${zabbix_passwd}" ialert/config/ialert.conf
	#修改operation相关配置
	LANG=C sed -i "/[[:space:]]\{8\}'HOST'/c\        'HOST': '${dbhost}'," operation/operation/settings.py
	LANG=C sed -i "/[[:space:]]\{8\}'PASSWORD'/c\        'PASSWORD': '${password}'," operation/operation/settings.py
}

function main()
{
	checkVersion
	checkConfig
	unzipFile
	LANG=C cd ops/source/module
	if [ $? = "0" ];then
		#insVirenv
		installDepackge
		installBasicModule
		#installOtherModule
		installRequire
	fi
	
	LANG=C cd ../../..
	echo "当前目录$PWD"
	installDir
	modConfig
	echo "当前目录$PWD"
	initSql
	opsDep
	addConf
	changRabbitUser
	installElvesServer
	startUwsgi
	
}

main