#!/bin/bash

# Date: 2018-04-12
# Author: Liu Yangfa
# Descrition: auto operation system install scripts
# Version: 1.0

#引入配置文件及日志文件和功能函数文件
source ./config.sh
source ./log.sh
source ./opsFun.sh

#系统python版本检测
function checkVersion()
{
	local version="$(python -V 2>&1|awk '{print $2}')"
	if [[ "${version}" =~ ^2.7.* ]];then
		logInfo "Python 版本是2.7"
	elif [[ "${version}" =~ ^2.6.* ]];then
		logWarn "Python版本为${version}，不符合运维系统运行最低要求。请手动安装Python2.7版本，通过虚拟python环境运行改系统"
	else
		logError "运行异常请检查"
		exit 1
	fi
}

#运维系统安装包解压
function unzipFile()
{
	local fileName="${installFileName}"
	local currentPath="$(dirname $0 && echo $pwd)"
	cd ${currentPath}

	if [ -s "${fileName}" ];then
		logInfo "${fileName}开始解压..." 
		#LANG=C unzip -o -q ${fileName} -d ./ && logInfo "${fileName}解压成功"
		tar xf ${fileName} -C ./ && logInfo "${filename}解压成功"
		chmod +x -R ops
	else
		logInfo "${fileName}解压失败，请检查安装包"
		exit 1
	fi
}

#安装运维系统到指定目录
function installDir()
{
	local currentPath="$(dirname $0 && echo $pwd)"
	cd ${currentPath}
	
	if [ ! -d "${dstPath}" ];then
		mkdir -p ${dstPath} && logInfo "${dstPath}目录创建成功"
		if [ -d ];then
			mv ./ops ${dstPath} && logInfo "ops目录已移至${dstPath}目录下"
		else
			logError "ops目录不存在，请检查!"
			exit 1
		fi
	else
		logWarn "目录已存在，是否进行安装，选择是则删除该目录，重新创建，选择否则退出当前安装"
		read -p "$(date +'%F %T') [INFO] 请选择是否继续安装(y/n):" yn
		if [ ${yn} = "n" ] || [ ${yn} = "N" ];then
			exit 0
		elif [ ${yn} = "y" ] || [ ${yn} = "Y" ];then
			rm -rf /r2/maintain_scripts && mkdir -p ${dstPath}
			mv ./ops ${dstPath} && logInfo "ops目录已移至${dstPath}目录下"
		else
			logError "输入错误"
			exit 1
		fi
	fi
}

#修改配置文件
function modOpsConfig()
{
	#修改collectAlerts相关配置
	sed -i "5c passwd=${dbPasswd}" ${opsRoot}/ialert/config/ialert.conf
	sed -i "6c host=${dbHost}" ${opsRoot}/ialert/config/ialert.conf
	sed -i "/^name=/c name=${homedSubject}" ${opsRoot}/ialert/config/ialert.conf
	sed -i "/^zabbix_url=/c zabbix_url=${zabbixUrl}" ${opsRoot}/ialert/config/ialert.conf
	sed -i "/^zabbix_user=/c zabbix_user=${zabbixUser}" ${opsRoot}/ialert/config/ialert.conf
	sed -i "/^zabbix_passwd=/c zabbix_passwd=${zabbixPasswd}" ${opsRoot}/ialert/config/ialert.conf
	#修改operation相关配置
	cp -f ${opsRoot}/operation/operation/settings_default.py ${opsRoot}/operation/operation/settings.py
	sed -i "/[[:space:]]\{8\}'HOST'/c\        'HOST': '${dbHost}'," ${opsRoot}/operation/operation/settings.py
	sed -i "/[[:space:]]\{8\}'PASSWORD'/c\        'PASSWORD': '${dbPasswd}'," ${opsRoot}/operation/operation/settings.py
	logInfo "配置文件修改完毕"
}

function main()
{
	checkVersion
	unzipFile
	installDir
	modOpsConfig

	installDepackge
	installBasicModule
	installRequire
	
	initSql
	opsDep
	addConf
	changRabbitUser
	installElvesServer
	startUwsgi
	getIps
	installElvesAgent
}

main
