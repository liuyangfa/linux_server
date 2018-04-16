#!/bin/bash

# Date: 2018-04-12
# Author: Liu Yangfa
# Descrition: configuration info
# Version: 1.0

#安装包文件名
installFileName="v1.1.0_20180409.tar.gz"
#运维系统部署路径
dstPath="/r2/maintain_scripts"
#需要部署agent的IP范围，例：10.129.17.10-20 10.129.17.30-40 10.129.17.100
ipRange="192.168.50.204"
#agent端IP的集合，该变量值通过函数自动计算，将ipRange的值分解成标准的IP地址集合
agentIps=""
#Server服务器的IP地址，单个IP
serverIp="192.168.50.204"
#运维数据库服务器的IP地址
dbHost="127.0.0.1"
#运维数据库密码
dbPasswd="ipanel"
#zabbix系统访问链接，例：http://10.129.16.90/zabbix
zabbixUrl="http://zabbix.homed.me/zabbix"
#zabbix所在集群的集群名称，例：大连运营集群
homedSubject="部署测试"
#访问zabbix系统的用户名
zabbixUser="zabbix"
#访问zabbix系统的密码
zabbixPasswd="zabbix_passwd"
#运维系统相关安装包路径
sourcePath="/r2/maintain_scripts/ops/source"
#Elves系统路径
elvesPath="/r2/maintain_scripts/ops/elves"
#rabbitmq路径
rabbitPath="/usr/local/operations/rabbitmq"
#kafka路径
kafkaPath="/usr/local/operations/kafka"
#nginx路径
nginxPath="/usr/local/openresty/nginx"
#nginx根目录
nginxRoot="/homed/homedbigdata/httpdata/clusterdata"
#ops目录
opsRoot="/r2/maintain_scripts/ops"
##python2.7路径
#pyPath="/usr/local/operations/python27"
##operations路径
#opsPath="/usr/local/operations"