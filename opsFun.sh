#!/bin/bash

# Date: 2018-04-12
# Author: Liu Yangfa
# Descrition: Functional function 
# Version: 1.0

#引入文件
source ./config.sh
source ./log.sh


function installReModule()
{
	local package=$1
	
	if [[ "${package}" =~ .zip$ ]];then
		logInfo "${package}开始解压"
		unzip -q ${package} -d ./ && logInfo "${package}解压成功" || logError "${package}解压失败"
		cd ${package%.*} && python setup.py install &> /dev/null
		if [ "$?" = "0" ];then
			cd -
			logInfo "${package%-*}安装成功"
			if [ -d "${package%.*}" ];then
				rm -rf ${package%.*}
			fi
		else
			logError "${package%.*.*}安装失败"
			exit 1
		fi
	elif [[ "${package}" =~ .tar.gz$ ]];then
		logInfo "${package}开始解压"
		tar xf ${package} && logInfo "${package}解压成功" || logInfo "${package}解压失败"
		cd ${package%.*.*} && python setup.py install &> /dev/null
		if [ "$?" = "0" ];then
			cd -
			logInfo "${package%-*}安装成功"
			if [ -d "${package%.*.*}" ];then
				rm -rf ${package%.*.*}
			fi
		else
			logError "${package%.*.*}安装失败"
			exit 1
		fi
	fi

}

function installBasicModule()
{
	local pypi="pypiserver-1.2.1.zip"
	local setuptools="setuptools-38.2.4.zip"
	local pip="pip-9.0.3.tar.gz"
	local sgit="setuptools-git-1.2.tar.gz"
	
	cd ${sourcePath}/module || exit 1
	if [ -d "${setuptools%.*}" ];then rm -rf ${setuptools%.*};fi
	if [ -d "${pypi%.*}" ];then rm -rf ${pypi%.*};fi
	if [ -d "${pip%.*.*}" ];then rm -rf ${pip%.*.*};fi
	if [ -d "${sgit%.*.*}" ];then rm -rf ${sgit%.*.*};fi
	
	for pkgs in ${setuptools} ${sgit} ${pip} ${pypi}
	do
		if [[ -e "${pkgs}" ]];then
			installReModule ${pkgs}
		else
			logWarn "${pkgs}不存在"
 		fi
	done
}

function startPypiServer()
{
	
	netstat -antlp | grep tcp.*:60000.*LISTEN &> /dev/null
	if [ "$?" = "0" ];then
		logInfo "60000端口已经被占用，请修改脚本或者杀掉占用该端口的程序后重新运行脚本"
		exit 1
	else
		pypi-server -p 60000 . &
		if [ $(ps -ef | egrep -v grep | grep pypi | wc -l) -gt 0 ];then
			logInfo "pypi-server启动成功"
		else
			logError "pypi-server启动失败"
			exit 1
		fi
	fi
}

function stopPypiServer()
{
	pid=$(netstat -atnlp | egrep "tcp.*:60000.*LISTEN" | awk '{print $7}' | cut -d'/' -f1)
	if [ "${pid}" != "" ];then
		kill -9 $pid &> /dev/null
		if [ $(netstat -atnlp | egrep "tcp.*:60000.*LISTEN") ];then
			logWarn "pypi-server正在运行"
		else
			logInfo "pypi-server已经停止运行"
		fi
	fi
}

function installRequire()
{
	startPypiServer
	pip install --extra-index-url http://127.0.0.1:60000 -r requirements.txt
	stopPypiServer
}

#暂时废弃，使用installRequire函数安装
#function installOtherModule()
#{
#	local otherModule="django uwsgi djangorestframework"
#	
#	startPypiServer
#	for pkg in ${otherModule}
#	do
#		pn=$(echo "${pkg%%-*}" | tr 'A-Z' 'a-z')
#		pip install --extra-index-url http://127.0.0.1:60000 ${pn} &> /dev/null
#		tmp=$(pip freeze | awk -F'=' '{print $1}' | grep -iE "^${pn}$" | tr 'A-Z' 'a-z')
#		if [[ ${tmp} =~ ^${pn}$ ]];then
#			echo "$(date +'%Y-%m-%d %H:%M:%S') ${pn}安装成功.$(echo_success)"
#		else
#			echo "$(date +'%Y-%m-%d %H:%M:%S') ${pn}安装失败.$(echo_failure)"
#			if [[ ${pkg} =~ ^uwsgi ]];then
#				echo "$(date +'%Y-%m-%d %H:%M:%S') 必须先安装gcc\gcc-c++\python-devel等C编译的相关工具或者库."
#			fi
#			stopPypiServer
#			exit 1
#		fi
#	done
#	stopPypiServer
#}

#安装python连接MySQL数据库的驱动库
function installMySQLdb()
{
	if [ $(rpm -qa | grep MySQL-python | wc -l) -eq 1 ];then
		logInfo "MySQL-python已安装"
	else
		yum install MySQL-python -y &> /dev/null
		if [ $? = "0" ];then
			logInfo "MySQL-python安装成功"
		else
			logError "MySQL-python安装失败"
			exit 1
		fi
	fi
}

#安装系统运行环境依赖
function installDepackge()
{
	local package="gcc gcc-c++ python-devel MySQL-python gdb"
	local wheel="python-wheel-0.24.0-2.el7.noarch.rpm"

	cd ${sourcePath}/module || exit 1
	for pkg in ${package}
	do
		yum install ${pkg} -y &> /dev/null
		if [ $? = "0" ];then
			logInfo "${pkg}安装成功"
		else
			logError "${pkg}安装失败"
			exit 1
		fi
	done
	
	if [ -s ${wheel} ] && [ $(rpm -qa | grep python-wheel | wc -l) -eq 0 ];then
		rpm -ivh ${wheel} &> /dev/null && logInfo "${wheel}安装成功" ||  logError "${wheel}安装失败"
	elif [ $(rpm -qa | grep python-wheel | wc -l) -ge 1 ];then
		logInfo "${wheel}已安装"
	else
		logError "出现错误"
	fi
	
	installMySQLdb
}

#function installPy27()
#{
#	local pName="Python-2.7.14.tar.xz"
#	cd ${sourcePath}/package || exit 1
#	
#	logInfo "${pName}开始解压"
#	tar xf ${pName}
#	if [ $? -eq 0 ];then
#		logInfo "${pName}解压成功"
#	else
#		logError "${pName}解压失败"
#		exit 1
#	fi
#	
#	cd ${pName%.*.*} || exit 1
#	./configuration --prefix=${pyPath} --enable-optimizations && make && make install
#	if [ "$?" = "0" ];then
#		cd -
#		logInfo "${pName%.*.*}安装成功"
#		if [ -d "${pName%.*.*}" ];then
#			rm -rf ${pName%.*.*}
#		fi
#	else
#		logError "${pName%-*}安装失败"
#		exit 1
#	fi
#}

#function createVirenv()
#{
#	cd ${opsPath} || exit 1
#	
#	if [ ! -d "envPy27" ];then
#		virtualenv --python=${pyPath}/bin/python2.7 --no-site-packages --no-setuptools --no-pip ${opsPath}/envPy27
#		source ${opsPath}/envPy27/bin/activate && logInfo "虚拟环境已激活"
#		installDepackge
#		installBasicModule
#		installOtherModule
#		deactivate
#	else
#		source envPy27/bin/activate && logInfo "虚拟环境已激活"
#		installDepackge
#		installBasicModule
#		installOtherModule
#		deactivate
#	fi
#}

#function installVirenv()
#{
#	local virenv="virtualenv-15.2.0.tar.gz"
#	cd ${sourcePath}/package || exit 1
#	
#	logInfo "${virenv}开始解压"
#	tar xf ${virenv}
#	if [ $? -eq 0 ];then
#		logInfo "${virenv}解压成功"
#	else
#		logError "${virenv}解压失败"
#		exit 1
#	fi
#	
#	cd ${virenv%.*.*} && python setup.py install &> /dev/null
#	if [ "$?" = "0" ];then
#		cd -
#		logInfo "${virenv%-*}安装成功"
#		if [ -d "${virenv%.*.*}" ];then
#			rm -rf ${virenv%.*.*}
#		fi
#		createVirenv
#	else
#		logError "${virenv%-*}安装失败"
#		exit 1
#	fi
#}

#==============================================================================
#
#自动化运维平台数据库初始化
#
#==============================================================================

function initSql()
{
	source /etc/profile
	cd ${sourcePath}/..
	logInfo "开始初始化数据库"
	mysql -uroot -p${dbPasswd} < ${opsRoot}/sql/ops_initial.sql &> /dev/null
	if [ $? -eq 0 ];then
		logInfo "数据库初始化成功"
	else
		logError "数据库初始化失败"
		exit 1
	fi
	
	#Django同步数据库 (sql写入py文件)
	cd operation && python manage.py makemigrations
	if [ "$?" = 0 ];then
		logInfo "migrations目录创建成功"
	else
		logError "migrations目录创建失败"
		exit 1
	fi
	
	#py文件同步到数据库 (model和数据库表结构已存在时，只需要将py文件中的数据migrations)
	python manage.py migrate --fake-initial && python manage.py migrate --database=elves --fake-initial
	if [ "$?" = "0" ];then
		logInfo "Django数据库同步成功"
	else
		logError "Django数据库同步失败"
		exit 1
	fi
	
	#cd ${sourcePath}/..
	source /etc/profile
	local num=$(mysql -uroot -p${dbPasswd} -e "select username from auto_operation.auth_user;" 2> /dev/null | grep admin | wc -l)
	if [ $num -eq 0 ];then
		mysql -uroot -p${dbPasswd} < ${opsRoot}/sql/admin.sql && logInfo "超级用户创建成功"
		logInfo "在operation目录下运行命令：python manage.py runserver 0.0.0.0:7000，进行初步体验，访问链接为http://ip:7000/maintain。默认用户名为admin，密码为admin12345"
	else
		logInfo "超级用户已存在"
		logInfo "在operation目录下运行命令：python manage.py runserver 0.0.0.0:7000，进行初步体验，访问链接为http://ip:7000/maintain。默认用户名为admin，密码为admin12345"
	fi
	
	mysql -uroot -p${dbPasswd} < ${opsRoot}/sql/ops_20180409.sql && logInfo "增量sql执行成功" || logWarn "增量sql执行失败"
}

function opsDep()
{
	local cmd="${rabbitPath}/sbin"
	local kdir="${kafkaPath}"
	cd ${sourcePath}/package || exit 1
	
	if [ "$(rpm -qa | grep otp_src)" = "" ];then
		yum localinstall -y otp_src-20.1-1.el7.centos.x86_64.rpm &> /dev/null
		if [ $? -eq 0 ];then
			logInfo "otp_src安装成功"
		else
			logError "otp_src安装失败"
			exit 1
		fi
	else
		logWarn "otp_src已安装"
	fi

	if [ "$(rpm -qa | grep rabbitmq)" = "" ];then
		yum localinstall -y rabbitmq-3.6.14-1.el7.centos.x86_64.rpm &> /dev/null && logInfo "RabbitMQ安装成功" || logError "RabbitMQ安装失败"
		sleep 5
		netstat -antlp | grep beam.smp &> /dev/null && logInfo "RabbitMQ运行中" || logWarn "RabbitMQ没有运行"
	else
		logInfo "RabbitMQ已安装"
		netstat -antlp | grep beam.smp &> /dev/null && logInfo "RabbitMQ运行中" || logWarn "RabbitMQ没有运行"
	fi

	if [ ! -d '${kdir}' ];then
		mkdir -p ${kdir}
		logInfo  "kafka解压中"
		tar xf kafka-2.12.tar.gz -C ./
		if [ $? -eq 0 ];then
			logInfo "kafka解压成功"
		else
			logError "kafka解压失败"
			exit 1
		fi
		
		if [ -d "kafka-2.12" ];then
			cp -rf kafka-2.12/* ${kdir}/
			rm -rf kafka-2.12
			logInfo "kafka安装成功"
		fi
		cd ${kdir}/bin || exit 1
		sh start.sh
		${kafkaPath}/jdk1.8.0_161/bin/jps | grep Kafka
		if [ $? -eq 0 ];then
			logInfo "kafka启动成功"
		else
			logError "kafka启动失败"
			exit 1
		fi
	else
		logInfo "kafka已安装"
		${kafkaPath}/jdk1.8.0_161/bin/jps | grep Kafka
		if [ $? -eq 0 ];then
			logInfo "kafka运行中"
		else
			logError "kafka没有运行"
			exit 1
		fi
	fi
}

function changRabbitUser()
{
	local cmd="${rabbitPath}/sbin"
	local num=$(netstat -antlp | grep beam.smp | grep LISTEN | wc -l)
	if [  $num -ge 2 ];then
		sleep 1
		logInfo "开始处理rabbitMQ用户信息"
		source /etc/profile
		local guest="$(${cmd}/rabbitmqctl list_users | grep guest | awk '{print $1}')"
		local elves="$(${cmd}/rabbitmqctl list_users | grep elves | awk '{print $1}')"
		if [ "${guest}" = "guest" ];then
			${cmd}/rabbitmqctl delete_user guest
		fi
		
		if [ "${elves}" != "elves" ];then
			${cmd}/rabbitmqctl add_user elves elves
			${cmd}/rabbitmqctl set_user_tags elves administrator
			${cmd}/rabbitmqctl set_permissions -p "/" elves ".*" ".*" ".*"
			logInfo "elves用户的权限设置情况如下: $(${cmd}/rabbitmqctl list_user_permissions elves)"
			${cmd}/rabbitmq-plugins enable rabbitmq_management
			if [ "$(netstat -antlp | grep beam.smp | grep LISTEN | grep 15672 | wc -l)" = "1" ];then
				logInfo "插件启用成功，请使用http://ip:15672来访问RabbitMQ的web管理界面。默认用户名为elves，密码为elves"
			fi
		else
			logInfo "elves用户已经存在"
		fi	
	else
		logError "RabbitMQ没有安装或者没有运行，请检查"
	fi
}

function addConf()
{
	cd ${sourcePath} || exit 1
	#拷贝uwsgi.ini和ops到指定位置
	if [ -d "/usr/local/openresty/nginx/conf.d/" ];then
		cp -f ./config/openresty/conf.d/{uwsgi.ini,ops.cfg} ${nginxPath}/conf.d/ && logInfo "配置文件添加成功"
	else
		logWarn "${nginxPath}/conf.d/目录不存在，请手动处理后重新运行该脚本"
		exit 1
	fi
	
	cp -rf ./config/openresty/resty/kafka ${nginxPath}/openstar/lib/ && logInfo "kafka插件安装成功" || logWarn "kafka插件安装失败"
	chmod 755 ${nginxPath}/openstar/lib/kafka/*

	local result=$(grep 'ops.cfg' ${nginxPath}/conf.d/homed.conf)
	if [ -z "${result}" ];then
		local opsCfg="        include /usr/local/openresty/nginx/conf.d/ops.cfg;"
        sed -i -e "3a${opsCfg}" ${nginxPath}/conf.d/homed.conf &> /dev/null
        if [ $? -ne 0 ];then
            logError "插入ops.cfg到homed.conf失败"
            exit 1
        fi
	fi
}

function startUwsgi()
{
	local status="$(cd ${dstPath}/ops/sbin/;sh uwsgi.sh status)"
	local rabbitNum="netstat -atnlp | grep beam.smp | grep LISTEN | wc -l"
	
	if [ "${rabbitNum}" = "3" ];then
		logError "rabbitMQ没有启动，请先手动启动之后，再重新运行该脚本"
		exit 1
	fi
	if [ -f "${nginxPath}/conf.d/uwsgi.ini" ];then
		if [[ "${status}" =~ .*stoped$ ]];then
			cd ${dstPath}/ops/sbin/ && sh uwsgi.sh start
			if [ $? = "0" ];then
				logInfo "uwsgi服务启动成功，记得手动重启openresty"
			else
				logWarn "uwsgi服务启动失败"
			fi
		elif [[ "${status}" =~ .*running$ ]];then
			logInfo "uwsgi服务运行中"
		fi
	else
		logWarn "uwsgi.ini不存在，请检查后，手动启动uwsgi，然后再重启openresty"
	fi
}

#===========================================================================================================
#
# 安装Elves_Server
#
#===========================================================================================================

function installElvesServer()
{
	local rootDir="${nginxRoot}"
	cd ${dstPath}/ops || exit 1
	#软连接
	if [ -d "${rootDir}" ] && [ ! -L "${rootDir}/elves" ];then
		ln -s /r2/maintain_scripts/ops/elves/apps/zip ${rootDir}/elves && echo logInfo "创建软连接成功" || logWarn "创建软连接失败"
	elif [ -L "${rootDir}/elves" ];then
		logInfo "elves软连接已存在"
	else
		logError "创建软连接异常，请手动处理"
	fi
	
	#Server端安装
	cd elves/server && logInfo "开始进行Elves_Server安装."
	if [ $? -eq 0 ];then
		sed -i "s/#mysql_password#/${dbPasswd}/" supervisor/conf/conf.properties
		sed -i "s/#server_ip#/${dbHost}/" supervisor/conf/conf.properties
		if [ ! -x "run.sh" ];then
			chmod 755 -R *
			./run.sh start &> /dev/null
			elvesNum="$(${kafkaPath}/jdk1.8.0_161/bin/jps | grep elves | wc -l)"
			if [ $? -eq 0 ] && [ $elvesNum -ge 4 ];then
				logInfo "Elves_Server启动成功"
			else
				logWarn "Elves_Server只启动了${elvesNum}个进程，启动失败"
			fi
		elif [ -x "run.sh" ];then
			chmod 755 -R *
			./run.sh start &> /dev/null
			if [ $(${kafkaPath}/jdk1.8.0_161/bin/jps | grep elves | wc -l) -ge 4 ];then
				logInfo "Elves_Server启动成功"
			else
				logError "Elves_Server启动失败"
			fi
		else
			logError "Elves_server启动故障"
		fi
	else
		logError "Elves_Server安装异常，请检查"
		exit 1
	fi
}



#===========================================================================================================
#
# 安装Elves_Agent
#
#===========================================================================================================

function getIps()
{
	local ips=""
	for host in ${ipRange}
	do
		if [[ ${host} =~ .*-.* ]];then
			ip1=$(echo ${host} | awk -F'.' '{print $1"."$2"."$3"."}')
			ip2=$(echo ${host} | awk -F'[.|-]' '{print $4".."$5}')
			for ip in $(eval echo {"${ip2}"})
			do
				ips="${ips} ${ip1}${ip}"
			done
			agentIps=${ips}
			logInfo "agentIps： ${agentIps}"
		else
			agentIps=${host}
			logInfo "agentIps： ${agentIps}"
		fi
	done

}

function checkServerStatus()
{
	local pNum=$(${kafkaPath}/jdk1.8.0_161/bin/jps | grep elves | wc -l)
	
	if [ ${pNum} -ge 4 ];then
		logInfo "Elves_Server正在运行"
		return 0
	else
		logWarn "Elves_Server没有运行"
		return 1
	fi
}

function startAgent()
{
	local ip="$1"
	local result=checkServerStatus
	if [ $result = 0 ];then
		ssh ${ip} "cd ${elvesPath}/agent && ./control start" && logInfo "Agent 启动成功，IP是：" || logInfo "Agent 启动失败，IP是："
	fi
}

#====================================
#1.创建目录
#2.同步agent
#3.修改cfg.json
#====================================

function installElvesAgent()
{
	local cfgDir="${dstPath}/ops/elves/agent/conf"
	local example="${cfgDir}/cfg.example.json"
	local cfg="${cfgDir}/cfg.json"
	local agentDir="${dstPath}/ops/elves"
	local commands="if [ ! -d ${dstPath} ];then mkdir -p ${agentDir};fi"
	local ips=${agentIps}
	local es=${serverIp}
	
	for ip in ${ips}
	do
		ssh ${ip} "${commands}"
		rsync -a ${agentDir}/agent ${ip}:${agentDir} &> /dev/null
	done
	
	for ip in ${ips}
	do
		local name="$(ssh -q $ip hostname)"
		cp -f ${example} ${cfg}
		sed -i "s/#server_ip#/${es}/" ${cfg}
		sed -i "s/#hostname#/${name}/" ${cfg}
		sed -i "s/#agent_ip#/${ip}/" ${cfg}
		
		rsync -arv ${cfg} ${ip}:${cfgDir}/
		if [ -f ${cfg} ] && [ "${ip}" != "${es}" ];then
			rm -rf ${cfg}
		fi
		logInfo "Elves_Agent of ${ip} 安装成功"
		startAgent
	done	
}